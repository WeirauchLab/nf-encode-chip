#!/usr/bin/env Rscript

library(cli)
library(argparse)

parser <- ArgumentParser()
parser$add_argument("--gtf")
parser$add_argument("--fai")
parser$add_argument("--type", nargs = "+")
parser$add_argument("--gene-id-col", default = "gene_name")
parser$add_argument("--gene-id-type", default = "SYMBOL")
parser$add_argument("--mode", default = "basalPlusExt")
parser$add_argument("--basal-upstream", default = 5000, type = "numeric")
parser$add_argument("--basal-downstream", default = 1000, type = "numeric")
parser$add_argument("--extension", default = 1000000, type = "numeric")
parser$add_argument("--prefix", default = "extended_tss")
opt <- parser$parse_args()


library(tidyverse)
library(rtracklayer)
library(plyranges)
library(rGREAT)

read_gtf <-
    function(file, type_filter = NULL, gene_id_col = "gene_id") {
        cli_inform("Reading GTF file: {file}")
        gtf <- rtracklayer::import(file)
        if (!is.null(type_filter)) {
            cli_inform("Selecting for types in GTF: {type_filter}")
            gtf <- gtf[gtf$type %in% type_filter]
        }
        if (length(gtf) == 0) cli_abort("Cannot continue, there are no entries in the GTF!")

        # Now filter the GTF again so that each entry has a gene_id
        if (!gene_id_col %in% colnames(mcols(gtf))) cli_abort("Gene ID column not found in the GTF GRanges object: {gene_id_col}")
        cli_inform("Using gene IDs from the following attribute: {gene_id_col}")
        mcols(gtf)[["gene_id"]] <- mcols(gtf)[[gene_id_col]]

        cli_inform("Removing entries without a gene ID")
        gtf <- gtf[!is.na(gtf$gene_id)]

        if (length(gtf) == 0) cli_abort("Cannot continue, there are no entries in the GTF! Check that your gene ID column is correct.")

        cli_inform("Final GTF size:  {length(gtf)}")
        gtf
    }


read_fai <-
    function(file, delim = "\t", col_names = F, chr_col = 1, length_col = 2) {
        if (is.null(file)) {
            cli_inform("No chr sizes provided. Returning NULL.")
            return(NULL)
        }

        df <- read_delim(file, delim = delim, col_names = col_names)
        set_names(df[[length_col]], df[[1]])
    }


# 1. Prepare GTF / chromosome sizes
cli_h1("Preparing GTF")
gtf <- read_gtf(opt$gtf, type_filter = opt$type, gene_id_col = opt$gene_id_col)
cli_h1("Preparing chr sizes")
fai <- read_fai(opt$fai)


# 2. Extend TSS
cli_h1("TSS Extension")

cli_ul(
    items =
        c(
            "mode: {opt$mode}",
            "gene_id_type: {opt$gene_id_type}",
            "basal_upstream: {opt$basal_upstream}",
            "basal_downstream: {opt$basal_downstream}",
            "extension: {opt$extension}"
        )
)

extended_tss <-
    extendTSS(
        gene = gtf,
        seqlengths = fai,
        gene_id_type = opt$gene_id_type,
        mode = opt$mode,
        basal_upstream = opt$basal_upstream,
        basal_downstream = opt$basal_downstream
    )

# 3. Export the result
output_file <- paste0(opt$prefix, ".rds")
cli_inform("TSS extended. Exporting to: {output_file}")
saveRDS(extended_tss, output_file)
