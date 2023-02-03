#!/bin/bash

#..........................................................................................
# Create QC stats for the demultiplexed data
#..........................................................................................


# Get options from main.nf
#..........................................................................................
while getopts v:a:c:w: flag
do
    case "${flag}" in
        v) voyageID=${OPTARG};;
        a) assay+=("$OPTARG");;
        c) cores=${OPTARG};;
        w) wd=${OPTARG};;
    esac
done


# Activate amplicon conda environment
#..........................................................................................
eval "$(conda shell.bash hook)"
conda activate amplicon


# Loop through each assay (e.g., '16S' and 'MiFish')
#..........................................................................................
for a in ${assay[@]}
do   
    # Create stats and save to file
    #..........................................................................................
    seqkit stats -j ${cores} -b ${wd}/01-demultiplexed/${a}/*.fq.gz -a > ${wd}/02-QC/Sample_statistics_${voyageID}_${a}.txt
done