#..........................................................................................
# ANALYSIS OF AMPLICON DATA: DADA2
#..........................................................................................

# All functions for dada2 are in a seperate script now.
# Seperate functions for the pooled, the site specific and
# the fixed error rate dada2 analysis

suppressPackageStartupMessages(library(dada2))
suppressPackageStartupMessages(library(tidyverse))
suppressPackageStartupMessages(library(RColorBrewer))
suppressPackageStartupMessages(library(readr))
suppressPackageStartupMessages(library(optparse))


# Get options from main.nf
#..........................................................................................
option_list <- list(
  make_option(c("-v", "--voyage"), action = "store", default = NA, type = 'character',
              help = "voyage identifier code"),
  make_option(c("-a", "--assay"), action = "store", default = NA, type = 'character',
              help = "assay, e.g. '16S' or 'MiFish"),
  make_option(c("-o", "--option"), action = "store", default = NA, type = 'character',
              help = "pooled, site or fixed error"),
  make_option(c("-c", "--cores"), action = "store", default = 20, type = 'integer',
              help = "number of cores, default 20"),
  make_option(c("-w", "--wd"), action = "store", default = NA, 
              type = "character", help = "working directory")) 

opt = parse_args(OptionParser(option_list=option_list))

voyage          <- opt$voyage
assay           <- opt$assay
option          <- opt$option
cores           <- opt$cores
wd              <- opt$wd


#...................................................................................... 
# WE CALL THE SCRIPT WE NEED BASED ON THE OPTIONS INPUT
#...................................................................................... 

if(option == "pooled"){
  
  source(paste0(wd, "/scripts/dada/dada2_pooled.R"))
  
}

if(option == "site"){
  
  source(paste0(wd, "/scripts/dada/dada2_site_spec_error.R"))
  
}

if(option == "fixed"){
  
  source(paste0(wd, "/scripts/dada/dada2_site_error_fixed.R"))
  
}