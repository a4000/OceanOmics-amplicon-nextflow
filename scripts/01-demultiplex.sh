#!/bin/bash

#..........................................................................................
# Demultiplex the raw data
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


# Too avoid too many open files error
#..........................................................................................
ulimit -S -n 4096


# Activate cutadapt-v4.1 conda environment
#..........................................................................................
eval "$(conda shell.bash hook)"
conda activate cutadapt-v4.1


# Loop through each assay (e.g., '16S' and 'MiFish')
#..........................................................................................
for a in "${assay[@]}"
do
    input_directory="${wd}/00-raw-data"
    output_folder="${wd}/01-demultiplexed/${a}"
    read1=$(ls $input_directory/*${a}*R1*fastq.gz* | grep -v 'Undetermined*')
    read2=$(ls $input_directory/*${a}*R2*fastq.gz* | grep -v 'Undetermined*')


    # Create the output folder, if it does not already exist
    #..........................................................................................
    mkdir -p ${wd}/01-demultiplexed/${a}


    # Cutadapt v4.1
    #..........................................................................................
    # | The -g and -G option specify that we are dealing with combinatorial adapters.
    # | As per cutadapt documentation llumina’s combinatorial dual indexing strategy uses
    # | a set of indexed adapters on R1 and another one on R2. Unlike unique dual indexes (UDI),
    # | all combinations of indexes are possible.
    # | this is another difference: the output will assign the name from the forward and reverse
    # | reads that were identified with the dual index
    # |
    # |the '^' in front of file (^file:) means that we anchor the tags to the beginning of the read!
    #..........................................................................................

    cutadapt -j ${cores} \
        -e 0.15 \
        --no-indels \
        -g ^file:${input_directory}/indices/${voyageID}_${a}_Fw.fa  \
        -G ^file:${input_directory}/indices/${voyageID}_${a}_Rv.fa \
        -o ${output_folder}/{name1}-{name2}.R1.fq.gz \
        -p ${output_folder}/{name1}-{name2}.R2.fq.gz \
        --report=full \
        --minimum-length 1 \
        $read1 $read2
done