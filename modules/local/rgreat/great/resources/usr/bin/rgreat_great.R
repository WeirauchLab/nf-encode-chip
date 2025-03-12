#!/usr/bin/env Rscript

library(cli)
library(argparse)

parser <- ArgumentParser()
parser$add_argument("--bed", help = "Bed / peak file to use as input")
parser$add_argument("--tss", help = "extended TSS RDS to use")
parser$add_argument("--gmt", help = "GMT-formatted library of gene sets")
parser$add_argument("--padj-method", default = "BH", help = "Method to pass to p.adjust")
parser$add_argument("--prefix", default = "great")

opt <- parser$parse_args()


library(tidyverse)
library(GenomicRanges)
library(rGREAT)
library(rtracklayer)

read_gmt <- function(file, split = "\t+") {
    if (!file.exists(file)) cli_abort("GMT file not found: {file}")
    cli_inform("Importing GMT file: {file}")
    lines <- readLines(file)
    lines <- strsplit(lines, split = split)
    lines <-
        set_names(
            map(lines, ~ .x[-1]),
            map_chr(lines, ~ .x[1])
        )
    lines
}

prepare_peak <-
    function(file) {
        if (!file.exists(file)) cli_abort("Peak file not found: {file}")
        cli_inform("Importing peak file: {file}")
        rtracklayer::import(file)
    }

prepare_tss <-
    function(file) {
        if (!file.exists(file)) cli_abort("TSS RDS file not found: {file}")
        cli_inform("Importing extended TSS: {file}")
        readRDS(file)
    }

process_results <-
    function(great_obj, padj_method = "BH") {
        n_gene_total <- length(unique(great_obj@extended_tss$gene_id))
        df <-
            as_tibble(great_obj@table) |>
            mutate(
                log10_p_value =
                    pbinom(
                        q = observed_region_hits - 1,
                        size = great_obj@n_total,
                        prob = genome_fraction,
                        lower.tail = F,
                        log.p = T
                    ),
                log10_p_value = log10_p_value / log(10),
                p_value = 10^log10_p_value,
                p_adjust = p.adjust(p_value, method = padj_method)
            ) |>
            dplyr::relocate(log10_p_value, .before = p_value) |>
            mutate(
                log10_p_value_hyper =
                    phyper(
                        q = (observed_gene_hits - 1),
                        m = gene_set_size,
                        n = (n_gene_total - gene_set_size),
                        k = great_obj@n_gene_gr,
                        lower.tail = FALSE,
                        log.p = TRUE
                    ),
                log10_p_value_hyper = log10_p_value_hyper / log(10),
                p_value_hyper = 10^log10_p_value_hyper,
                p_adjust_hyper = p.adjust(p_value_hyper, method = padj_method)
            ) |>
            dplyr::relocate(log10_p_value_hyper, .before = p_value_hyper)

        df
    }

export_results_df <-
    function(df, output_file) {
        cli_inform("Exporting results to CSV: {output_file}")
        write_csv(df, output_file, col_names = T)
    }

bed_gr <- prepare_peak(opt$bed)
tss <- prepare_tss(opt$tss)
gene_set <- read_gmt(opt$gmt)
gr_res <- great(gr = bed_gr, gene_sets = gene_set, extended_tss = tss)
res_df <- process_results(gr_res, padj_method = opt$padj_method)
export_results_df(res_df, output_file = paste0(opt$prefix, ".csv"))
