#..........................................................................................
# ANALYSIS OF AMPLICON DATA: Filtering LCA results for NCBI nt results only
#..........................................................................................

suppressPackageStartupMessages(library(tidyverse)) 
suppressPackageStartupMessages(library(RColorBrewer)) 
suppressPackageStartupMessages(library(readr))
suppressPackageStartupMessages(library(optparse))


# Get options from main.nf
#..........................................................................................
option_list = list(
  make_option(c("-v", "--voyage"), action="store", default=NA, type='character',
              help="voyage identifier code"),
  make_option(c("-a", "--assay"), action="store", default=NA, type='character',
              help="assay, e.g. '16S' or 'MiFish"),
  make_option(c("-w", "--wd"), action="store", default=NA, type='character',
              help="working directory"))

opt = parse_args(OptionParser(option_list=option_list))

voyage <- opt$voyage
assay  <- opt$assay
wd <- opt$wd


# Read in LCA results
#..........................................................................................
lca_results <- read_delim(paste0(wd, "/05-taxa/LCA_out/", voyage, "_", assay, "_nt_LCA.tsv"))


# Filter for only chordates (removes all bacterial and euykaryote contaminants, except for mammals)
#..........................................................................................
lca_filtered <- lca_results %>%
  filter(!(domain %in% lca_results$domain[grep(NA, (lca_results$domain))])) %>%
  filter(!(domain %in% lca_results$domain[grep("Bacteria", (lca_results$domain))])) %>%
  filter(!(domain %in% lca_results$domain[grep("Archaea", (lca_results$domain))])) %>%
  filter(!(domain %in% lca_results$domain[grep("dropped", (lca_results$domain))])) %>%
  filter(!(phylum %in% lca_results$phylum[grep(NA, (lca_results$phylum))])) %>%
  filter(!(phylum %in% lca_results$phylum[grep("Chlorophyta", (lca_results$phylum))])) %>%
  filter(!(phylum %in% lca_results$phylum[grep("Bacillariophyta", (lca_results$phylum))])) %>%
  filter(!(phylum %in% lca_results$phylum[grep("dropped", (lca_results$phylum))])) %>%
  filter(!(class %in% lca_results$class[grep(NA, (lca_results$class))])) %>%
  filter(!(class %in% lca_results$class[grep("Mammalia", (lca_results$class))])) %>%
  filter(!(class %in% lca_results$class[grep("Pelagophyceae", (lca_results$class))])) %>%
  filter(!(class %in% lca_results$class[grep("Cryptophyceae", (lca_results$class))])) %>%
  filter(!(class %in% lca_results$class[grep("Aves", (lca_results$class))])) %>%
  filter(!(class %in% lca_results$class[grep("Caudoviricetes", (lca_results$class))])) %>%
  filter(!(class %in% lca_results$class[grep("Florideophyceae", (lca_results$class))])) %>%
  filter(!(class %in% lca_results$class[grep("Asteroidea", (lca_results$class))])) %>%
  filter(!(class %in% lca_results$class[grep("Ophiuroidea", (lca_results$class))])) %>%
  filter(!(class %in% lca_results$class[grep("Hexanauplia", (lca_results$class))])) %>%
  filter(!(class %in% lca_results$class[grep("dropped", (lca_results$class))]))


# Write new csv
#..........................................................................................
write.csv(lca_filtered, file = paste0(wd, "/05-taxa/LCA_out/LCA_filtered_", voyage, "_", assay, "_nt.csv"))
