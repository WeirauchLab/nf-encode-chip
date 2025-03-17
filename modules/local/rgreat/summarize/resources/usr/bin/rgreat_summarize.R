#!/usr/bin/env Rscript

library(cli)
library(argparse)

parser <- ArgumentParser()
parser$add_argument("--prefix", default = "summary")
parser$add_argument("results", nargs = "+", help = "Results files")

opt <- parser$parse_args()

library(tidyverse)
library(openxlsx)

results_df <- read_csv(opt$results)
results_split <- split(results_df, ~ results_df$gmt_id)
results_names <- names(results_split)
results_names <- str_replace_all(results_names, "[^a-zA-Z0-9]", "_")
results_names <- paste(1:length(results_names), results_names, sep = "_")
results_names <- str_trunc(results_names, width = 31, ellipsis = "")
names(results_split) <- results_names

write.xlsx(results_split, paste0(opt$prefix, ".xlsx"), asTable = TRUE)
