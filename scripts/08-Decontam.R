#..........................................................................................
# ANALYSIS OF AMPLICON DATA: Decontamination of LCA results
#..........................................................................................

suppressPackageStartupMessages(library(tidyverse)) 
suppressPackageStartupMessages(library(RColorBrewer)) 
suppressPackageStartupMessages(library(readr))
suppressPackageStartupMessages(library(optparse))
suppressPackageStartupMessages(library(dplyr))


# Get options from main.nf
#..........................................................................................
option_list = list(
  make_option(c("-v", "--voyage"), action="store", default=NA, type='character',
              help="voyage identifier code"),
  make_option(c("-a", "--assay"), action="store", default=NA, type='character',
              help="assay, e.g. '16S' or 'MiFish"),
  make_option(c("-o", "--option"), action="store", default=NA, type='character',
              help="nt or custom blast database"),
  make_option(c("-w", "--wd"), action="store", default=NA, type='character',
              help="working directory")) 

opt = parse_args(OptionParser(option_list=option_list))

voyage <- opt$voyage
assay  <- opt$assay
option <- opt$option
wd <- opt$wd


# Get vector of control files that end in .1.fq.gz
#..........................................................................................
suffix <- paste0("_", assay, ".1.fq.gz")
controls <- list.files(paste0(wd, "/01-demultiplexed/", assay, "/Controls/"), pattern = paste0("*", suffix))


# The water controls might be in the site folders
#..........................................................................................
water_suffix <- paste0("WC", suffix)
water_controls <- list.files(paste0(wd, "/01-demultiplexed/", assay, "/"), pattern = paste0("*", water_suffix), recursive = TRUE)                       
water_controls <- basename(water_controls)


# Concatenate the two vectors and remove the suffix
#..........................................................................................
controls <- c(controls, water_controls)
controls <- sub(suffix, "", controls)


# If the user used the 'nt' database
#..........................................................................................
if(option == "nt") {
    # Read in filtered LCA results
    #..........................................................................................
    lca_tab <- read_csv(paste0(wd, "/05-taxa/LCA_out/LCA_filtered_", voyage, "_", assay, "_nt.csv"))
   

    # The 'Contam' column will flag all potential contaminant ASV sequences
    #..........................................................................................
    lca_tab$Contam <- "False"
   

    # Flag all ASV sequences identified in any control samples
    #..........................................................................................
    for (i in controls) {
        lca_tab$Contam[lca_tab[i] > 0] <- "True"
    }
   

    # Convert the LCA table to the correct structure
    #..........................................................................................
    lca_tab <- lca_tab %>%
      relocate(OTU, .before = domain) %>%
      rename(ASV = OTU)
   

    # Write final output with contam labels
    #..........................................................................................
    write_csv(lca_tab, file = paste0(wd, "/05-taxa/", voyage, "_", assay, "_contam_table_nt.csv"))
   

    # Create final file with no contaminants
    #..........................................................................................
    nocontam <- read_csv(file = paste0(wd, "/05-taxa/", voyage, "_", assay, "_contam_table_nt.csv"))
    nocontam$Contam
    nocontam <- subset(nocontam, Contam=="FALSE")
   
    nocontam <- nocontam %>% 
      select(where(~ any(. != 0)))
   
    write_csv(nocontam, file = paste0(wd, "/05-taxa/", voyage, "_", assay, "_nocontam_nt.csv"))
}


# If the user used a custom database
#..........................................................................................
if(option == "custom"){
    # Read in LCA results
    #..........................................................................................
    lca_tab <- read_delim(paste0(wd, "/05-taxa/LCA_out/", voyage, "_", assay, "_LCA.tsv"))
   

    # The 'Contam' column will flag all potential contaminant ASV sequences
    #..........................................................................................
    lca_tab$Contam <- "False"
   
    
    # Flag all ASV sequences identified in any control samples
    #..........................................................................................
    for (i in controls){
      lca_tab$Contam[lca_tab[i] >0] <- "True"
    }
   

    # Convert the LCA table to the correct structure
    #..........................................................................................
    lca_tab <- lca_tab %>%
      relocate(OTU, .before = domain) %>%
      rename(ASV = OTU)
   

    # Write final output with contam labels
    #..........................................................................................
    write_csv(lca_tab, file = paste0(wd, "/05-taxa/", voyage, "_", assay, "_contam_table.csv"))
   

    # Create final file with no contaminants
    #..........................................................................................
    nocontam <- read_csv(file = paste0(wd, "/05-taxa/", voyage, "_", assay, "_contam_table.csv"))
    nocontam$Contam
    nocontam <- subset(nocontam, Contam=="FALSE")
   
    nocontam <- nocontam %>% 
      select(where(~ any(. != 0)))
   
    write_csv(nocontam, file = paste0(wd, "/05-taxa/", voyage, "_", assay, "_nocontam.csv"))
}