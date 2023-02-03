#!/bin/bash

#..........................................................................................
# Lowest Common Ancestor (LCA) analysis to determine most accurate taxa assignments for each ASV
# This is the script to run the LCA scripts from eDNAFlow and loop through the assays
#..........................................................................................


# Get options from main.nf
#..........................................................................................
while getopts v:a:d:w: flag 
do
    case "${flag}" in
        v) voyageID=${OPTARG};;
        a) assay+=("$OPTARG");;
        d) database=${OPTARG};;
        w) wd=${OPTARG};;
    esac
done


# Activate pytaxonkit conda environment
#..........................................................................................
eval "$(conda shell.bash hook)"
conda activate pytaxonkit


# If the user used the 'nt' database
#..........................................................................................
if [ "$database" == "nt" ];
then
    # Loop through each assay (e.g., '16S' and 'MiFish')
    #..........................................................................................
    for a in ${assay[@]}
    do
        python ${wd}/scripts/LCA/runAssign_collapsedTaxonomy.py \
        ${wd}/03-dada2/${voyageID}_${a}_lca_input.tsv \
        ${wd}/05-taxa/blast_out/${voyageID}_${a}_nt.tsv \
        100 98 1 \
        ${wd}/05-taxa/LCA_out/${voyageID}_${a}_nt_LCA.tsv
    done
fi


# If the user used a custom database
#..........................................................................................
if [ "$database" == "custom" ];
then
    # Loop through each assay (e.g., '16S' and 'MiFish')
    #..........................................................................................
    for a in ${assay[@]}
    do
        python ${wd}/scripts/LCA/runAssign_collapsedTaxonomy.py \
        ${wd}/03-dada2/${voyageID}_${a}_lca_input.tsv \
        ${wd}/05-taxa/blast_out/${voyageID}_${a}_blast_results.tsv \
        100 98 1 \
        ${wd}/05-taxa/LCA_out/${voyageID}_${a}_LCA.tsv
  done
fi