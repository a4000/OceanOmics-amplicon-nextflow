#!/bin/bash

voyageID=
#assay=

#..........................................................................................
usage()
{
    printf "Usage: $0 -v <voyageID>\t<string>\n\t\t\t -a <assay; use flag multiple times for multiple assays>\t<string>\n\n";
    exit 1;
}
while getopts v:a: flag
do
    case "${flag}" in
        v) voyageID=${OPTARG};;
        a) assay+=("$OPTARG");;
        *) usage;;
    esac
done
if [ "${voyageID}" == ""  ]; then usage; fi
#if [ "${assay[@]}" == ""  ]; then usage; fi


for a in "${assay[@]}"
do
    # get around small bug where a is empty, leading to nonsense commands
    if [[ -z "${a}" ]];
    then
       continue
    fi
    
    eval "$(conda shell.bash hook)"
    conda activate pytaxonkit
    echo  "Running LULU on ${voyageID} ${a}"

    # For the containerised version: if the CODE path is present,
    # change to the CODE directory
    if [ -n "$CODE" ]
        then cd $CODE;
    fi

    bash LULU/01-lulu_create_match_list.sh -v ${voyageID} -a ${a}
        
    Rscript LULU/02-LULU.R -v ${voyageID} -a ${a}

    # Activate amplicon conda environent for seqkit
    eval "$(conda shell.bash hook)"
    conda activate amplicon

 	# Next we need to curate the fasta files from DADA2 to only include the ASVs output by LULU
    echo curating ${voyageID} ${a} fasta file

    # For the containerised version: if the ANALYSIS path is present,
    # change to the ANALYSIS directory
    if [ -n "$ANALYSIS" ]
        then cd $ANALYSIS;
    fi

    cat 04-LULU/LULU_curated_counts_${voyageID}_${a}.csv | \
    cut -d "," -f1 | \
    sed 1,1d | \
    seqkit grep -f - 03-dada2/${voyageID}_${a}.fa -o 04-LULU/LULU_curated_fasta_${voyageID}_${a}.fa
done