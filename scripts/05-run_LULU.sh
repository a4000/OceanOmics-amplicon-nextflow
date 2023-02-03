#!/bin/bash

#..........................................................................................
# Run LULU
#..........................................................................................


# Get options from main.nf
#..........................................................................................
while getopts v:a:w: flag
do
    case "${flag}" in
        v) voyageID=${OPTARG};;
        a) assay+=("$OPTARG");;
        w) wd=${OPTARG};;
    esac
done


# Loop through each assay (e.g., '16S' and 'MiFish')
#..........................................................................................
for a in "${assay[@]}"
do
    # Activate pytaxonkit conda environment
    #..........................................................................................
    eval "$(conda shell.bash hook)"
    conda activate pytaxonkit


    # We need to run separate scripts to perform the LULU step
    #..........................................................................................
    bash ${wd}/scripts/LULU/01-lulu_create_match_list.sh -v ${voyageID} -a ${a} -w ${wd}
        
    Rscript ${wd}/scripts/LULU/02-LULU.R -v ${voyageID} -a ${a} -w ${wd}


    # Activate amplicon conda environment
    #..........................................................................................
    eval "$(conda shell.bash hook)"
    conda activate amplicon


    # Next we need to curate the fasta files from DADA2 to only include the ASVs output by LULU
    #..........................................................................................
    cat ${wd}/04-LULU/LULU_curated_counts_${voyageID}_${a}.csv | \
    cut -d "," -f1 | \
    sed 1,1d | \
    seqkit grep -f - ${wd}/03-dada2/${voyageID}_${a}.fa -o ${wd}/04-LULU/LULU_curated_fasta_${voyageID}_${a}.fa
done