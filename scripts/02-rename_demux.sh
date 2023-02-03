#!/bin/bash

#..........................................................................................
# Rename all demultiplexed files to the sample names
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
    # get around small bug where a is empty, leading to nonsense commands
    if [[ -z "${a}" ]];
    then
       continue
    fi

    # We need to change the working directory for the mmv command
    #..........................................................................................
    cd ${wd}/01-demultiplexed/${a}


    # Here we reference the rename pattern files in the raw data folder, 
    # which contains the information that maps the index ID pairings with the sample IDs
    #..........................................................................................
    mmv < ${wd}/00-raw-data/indices/Sample_name_rename_pattern_${voyageID}_${a}.txt -g
   

    # Move the unnamed and unknowns into separate folders 
    #..........................................................................................
    mkdir -p ${wd}/01-demultiplexed/${a}/unknown ${wd}/01-demultiplexed/${a}/unnamed
    mv ${wd}/01-demultiplexed/${a}/*unknown*.fq.gz ${wd}/01-demultiplexed/${a}/unknown
    mv ${wd}/01-demultiplexed/${a}/${a}-* ${wd}/01-demultiplexed/${a}/unnamed  
done