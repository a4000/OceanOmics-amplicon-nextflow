#!/bin/bash

# Organising samples into sites fro DADA2 input
# The query was run seperate for 16S and MiFish assays

# name voyage and assay
voyage=$1
assay=$2
wd=$3


declare -a SITES=("AB1_AUV01_15 AB1_AUV01_N_10 AB1_AUV03_45 AB1_AUV03_N_40 AB1_AUV03_N_40 AB1_AUV04_15 AB1_AUV04_N_15 AB1_AUV06_35 \
AB1_AUV06_N_35 AB1_C-153_N_40 AB1_Deep3_40 AB1_DeepChannel_40 AB1_DeepKelp_40 AB1_E_D1_N_40 AB1_E_D2_N_40 AB1_E_S1_N_10 AB1_E_S2_N_10 \
AB1_E_S3_N_10 AB1_EastWallabi_10 AB1_ES_D_01_35 AB1_Kelp1_10 AB1_P_W_D1_N_40 AB1_P_W_S_10 AB1_PW_D_40 AB1_PW_D01_50 AB1_PW_S_10 \
AB1_TurtleBay_5 AB1_WA_177_10 AB1_WA46_10 AB1_WA115_10 AB1_WA115_15 AB1_WA176_10 AB1_WA177_5 AB1_WA181_5 AB1_WestWallabi_10 \
GC1_D2 GC1_D5 GC1_S1 GC1_S2 GC1_S3 GC1_S4 JU1_D1_40 JU1_D2_40 JU1_D3_40")
declare -a SAMPLES=({1..5} "WC")

for site in ${SITES[@]}
 do
	mkdir ${wd}/01-demultiplexed/${assay}/${voyage}_${site}
done

for site in ${SITES[@]}
 do
  for sample in ${SAMPLES[@]}
    do
       cp ${wd}/01-demultiplexed/${assay}/${site}_${sample}_${assay}.[12].fq.gz ${wd}/01-demultiplexed/${assay}/${voyage}_${site}
 done
done

mkdir ${wd}/01-demultiplexed/${assay}/Controls
mv ${wd}/01-demultiplexed/${assay}/*EB* ${wd}/01-demultiplexed/${assay}/Controls
mv ${wd}/01-demultiplexed/${assay}/*BC* ${wd}/01-demultiplexed/${assay}/Controls
mv ${wd}/01-demultiplexed/${assay}/*BL* ${wd}/01-demultiplexed/${assay}/Controls
mv ${wd}/01-demultiplexed/${assay}/NTC* ${wd}/01-demultiplexed/${assay}/Controls
mv ${wd}/01-demultiplexed/${assay}/GC1_D_WC* ${wd}/01-demultiplexed/${assay}/Controls
mv ${wd}/01-demultiplexed/${assay}/AB1_WC* ${wd}/01-demultiplexed/${assay}/Controls