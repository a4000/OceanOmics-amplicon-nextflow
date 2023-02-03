#!/bin/bash

#..........................................................................................
# Blast query to get available taxa
# This is the script to run blastn on the LULU curated DADA2 results using the NCBI nt database
# The query was run seperate for each assay
#..........................................................................................


# Get options from main.nf
#..........................................................................................
while getopts v:a:d:c:w: flag
do
    case "${flag}" in
        v) voyageID=${OPTARG};;
        a) assay+=("$OPTARG");;
        d) database=${OPTARG};;
        c) cores=${OPTARG};;
        w) wd=${OPTARG};;
    esac
done


# If the user wishes to use the 'nt' database
#..........................................................................................
if [ "${database}" == "nt" ];
then
    # Loop through each assay (e.g., '16S' and 'MiFish')
    #..........................................................................................
    for a in ${assay[@]}
    do
        bash ${wd}/scripts/blast/run_blastnt.sh -v ${voyageID} -a ${a} -c ${cores} -w ${wd}
    done
fi


# If the user wishes to use a custom database
#..........................................................................................
if [ "${database}" == "custom" ];
then
    # Activate pytaxonkit conda environment
    #..........................................................................................
    eval "$(conda shell.bash hook)"
    conda activate pytaxonkit


    # Loop through each assay (e.g., '16S' and 'MiFish')
    #..........................................................................................
    for a in ${assay[@]}
    do
        python ${wd}/scripts/blast/blast-16S-MiFish.py \
        --dada2_file ${wd}/04-LULU/LULU_curated_fasta_${voyageID}_${a}.fa \
        --out_path ${wd}/05-taxa/blast_out/${voyageID}_ \
        --database ${a}
    done
fi