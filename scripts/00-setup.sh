#!/bin/bash

#..........................................................................................
# Setup the directory structure
#..........................................................................................


# Get options from main.nf
#..........................................................................................
while getopts p:w: flag
do
    case "${flag}" in
        p) projectID=${OPTARG};;
        w) wd=${OPTARG};;
    esac
done


# Set up the directory structure
#..........................................................................................
mkdir -p ${wd}/00-raw-data/indices
mkdir -p ${wd}/01-demultiplexed
mkdir -p ${wd}/02-QC
mkdir -p ${wd}/03-dada2/QC_plots
mkdir -p ${wd}/03-dada2/tmpfiles
mkdir -p ${wd}/03-dada2/errorModel
mkdir -p ${wd}/04-LULU
mkdir -p ${wd}/05-taxa/blast_out
mkdir -p ${wd}/05-taxa/LCA_out
mkdir -p ${wd}/06-report


# Place a README.md in every folder
#..........................................................................................
touch ${wd}/README.md

echo "# Step:" >> ${wd}/README.md
echo "# Analyst:" >> ${wd}/README.md
echo "# Data locations:" >> ${wd}/README.md
echo "# Script used:" >> ${wd}/README.md
echo "# Software version:" >> ${wd}/README.md
echo "# Problems encountered:" >> ${wd}/README.md

parallel cp ${wd}/README.md ::: ${wd}/01-demultiplexed \
      ${wd}/02-QC \
      ${wd}/03-dada2 \
      ${wd}/04-LULU \
      ${wd}/05-taxa \
      ${wd}/06-report


# Remove the readme file from the main folder structure
#..........................................................................................
rm ${wd}/README.md


# Create a general README for this project
#..........................................................................................
touch ${wd}/README.md
echo "# Project:" >> ${wd}/README.md
echo "# Analyst:" >> ${wd}/README.md
echo "# Overview:" >> ${wd}/README.md