#!/bin/bash

#..........................................................................................
# Create a R markdown report using output from the amplicon pipeline
#..........................................................................................


# Get options from main.nf
#..........................................................................................
while getopts v:a:r:w: flag
do
    case "${flag}" in
        v) voyageID=${OPTARG};;
        a) assay+=("$OPTARG");;
        r) sequencing_run=${OPTARG};;
        w) wd=${OPTARG};;
    esac
done




# We need to build the assay string in the correct format for the r markdown script (e.g. '16S,MiFish')
#..........................................................................................
assay_rmd_input=
for a in "${assay[@]}"
do
    assay_rmd_input="${assay_rmd_input},${a}"
done
assay_rmd_input="${assay_rmd_input:1}"


# We also need to get the numbers of the samples randomly chosen for creating the quality profile plots
# We can get these numbers from the file names of the plots
#..........................................................................................
random_samples=
sample_plots=($(ls ${wd}/03-dada2/QC_plots/"${voyageID}"_qualityprofile_Fs_*_"${assay[0]}"_raw.png))
prefix=${wd}/03-dada2/QC_plots/${voyageID}_qualityprofile_Fs_
suffix=_${assay[0]}_raw.png

for i in "${sample_plots[@]}"
do
    sample="$i"
    sample=${sample#"$prefix"}
    sample=${sample%"$suffix"}
    random_samples="${random_samples},${sample}"
done
random_samples="${random_samples:1}"


# Render the R markdown document
#..........................................................................................
Rscript -e "rmarkdown::render('${wd}/scripts/report/amplicon_report.Rmd',params=list(voyage = '${voyageID}', assays = '${assay_rmd_input}', random_samples = '${random_samples}', sequencing_run = '${sequencing_run}', wd = '${wd}'))"


# Move the R markdown report to the report directory
#..........................................................................................
mv ${wd}/scripts/report/amplicon_report.html ${wd}/06-report