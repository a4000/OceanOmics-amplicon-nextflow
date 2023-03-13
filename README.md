# OceanOmics Amplicon Nextfllow Pipeline


<p align="center">
  <img width="330" height="300" src="img/OceanOmics.png">
</p>


## Overview
This repository contains the Nextflow version of the OceanOmics amplicon sequencing pipeline using Docker. 


## Dependencies

### Install `nextflow`

To run this pipeline, you must install `nextflow` on your system. You can follow the installation instructions [here](https://www.nextflow.io/docs/latest/getstarted.html#installation). Alternatively, you can install `nextflow` via `miniconda` (instructions below).


### Install `docker`

To run this pipeline, you must alse install `docker` on your system. You can follow the installation instructions [here](https://docs.docker.com/engine/install/). Alternatively, you can install `docker` via `miniconda` (instructions below). 


### Install `miniconda`

To install `nextflow` and `docker` with `miniconda`, please install `miniconda` on your system, as per the instructions [here](https://conda.io/projects/conda/en/latest/user-guide/install/linux.html). 

Then follow the below commands to create a conda environment and install `nextflow` and `docker` to that environment.
```
conda create --name amplicon_env
conda activate amplicon_env
conda install -c bioconda nextflow
conda install -c conda-forge docker
```

You can deactivate this environment with
```
conda deactivate amplicon_env
```

You can always activate the environment again with 
```
conda activate amplicon_env
```


## Git Clone

You can clone this repository to your local machine with
```
git clone https://github.com/a4000/OceanOmics-amplicon-nextflow.git
```

## Command to run pipeline

Before running the pipeline, make sure main.nf and nextflow.config are in the same directory.
Instructions on configuring the nextflow.config file can be found below.
To run this pipeline from the same directory as main.nf and nextflow.config, you can use the command.
```
nextflow run main.nf
```

The first time you run the pipeline on your system will be slow because the docker image will need to be built.
The docker image will only need to be built once on your system.


## nextflow.config

The parameters in the nextflow.config file can all be set at the command line. 
Alternatively, they can be set in the nextflow.config file.
The parameters in the config file are listed below.


### Parameters to skip steps

`skip_demux` is set to true by default because the demultiplex step in this pipeline is unique to OceanOmics.

`skip_lulu` is set to false by default, but can be set to true if you wish to skip the LULU step.


### Mandatory parameters

`project_id` the ID of your project.

`assay` is the assays used in your project. 
If you are using multiple assays, please separate the assays with commas (e.g., "16S,MiFish").

`metadata_file` should be a csv file with 'Sample ID' as a column.

`scripts_dir` directory to the scripts directory cloned from the Github repo.

`resources_dir` directory to the resources directory cloned from the Github repo.

`sequencing_run_id` can be left blank if you don't have a sequencing run ID.

`publish_dir_mode` is set to "symlink" by default.
Other publish mode options can be viewed [here](https://www.nextflow.io/docs/latest/process.html#publishdir).

`publish_dir_mode_final` is set to "move" by default. This is the publish mode of the final process in the pipeline.
I chose this setting as the default so that the your results directories will have the actual results files instead of symbolic links.

`database_option` is set to "ocom" by default, other options include "nt" and "custom", but those options haven't been tested yet.

`dada_option` is set to "TRUE" by default.
This parameter can be set to "TRUE" for pooled analysis, "FALSE" for independant analysis, or "pseudo" for pseudo analysis.
More information about these settings can be found [here](https://benjjneb.github.io/dada2/pool.html).

`merge_pairs_min_overlap` is set to 12 by default.
This is the minumum overlap required for merging reads.

`merge_pairs_max_mismatch` is set to 0 by default. 
This is the maximum mismatches allowed in overlap region.

`optimise_tree` is set to false by default.
This will optimise the phylogenetic tree produced in the phyloseq object (Warning: this option can be slow).

`control_grep_patterns`
This is the patterns used to label the control samples. Please separate with commas (e.g., "WC,FC,EB").

`trim_side` 
Trim on the left or right side of the reads

`single_end` set to false by default.
Set this to true if your reads are single end.


### Mandatory parameters if using the --skip_demux option

`demux_dir` should be set to the directory containing you demultiplexed files (with extensions  _${assay}.[12].fq.gz).
(e.g., Sample1_16S.1.fq.gz and Sample1_16S.2.fq.gz)


### Mandatory files if not using the --skip_demux option

These files must all exist in the directory conaining the main.nf and nextflow.config files.
These files can't be symbolic links.

- Fw index file with the name "${project_id}_${assay}_Fw.fa" (e.g., ABV4_16S_Fw.fa)
- Rv index file with the name "${project_id}_${assay}_Rv.fa" (e.g., ABV4_16S_Rv.fa)
- Sample rename pattern file with the name "Sample_name_rename_pattern_${project_id}_${assay}.txt" (e.g., Sample_name_rename_pattern_ABV4_16S.txt)
- Raw data read 1 with the name "*${assay}*R1*fastq.gz" (e.g., AbrolhosV4_MiFish_Fish16S_S1_R1_001.fastq.gz)
- Raw data read 2 with the name "*${assay}*R2*fastq.gz" (e.g., AbrolhosV4_MiFish_Fish16S_S1_R2_001.fastq.gz)


### Index files

This is the head output of a Fw index file
```
>16S-41F
TCGCCTTA
>16S-42F
CTAGTACG
>16S-43F
TTCTGCCT
>16S-44F
GCTCAGGA
>16S-45F
AGGAGTCC
```


### Sample rename pattern file

This is the head output of a sample rename pattern file
```
16S-41F-16S-57R.R[12].fq.gz RS1_CL_L1_1_16S.#1.fq.gz
16S-42F-16S-57R.R[12].fq.gz RS1_CL_L2_4_16S.#1.fq.gz
16S-43F-16S-57R.R[12].fq.gz RS1_CL_S1_2_16S.#1.fq.gz
16S-44F-16S-57R.R[12].fq.gz RS1_CL_S2_5_16S.#1.fq.gz
16S-45F-16S-57R.R[12].fq.gz RS1_CL_S4_3_16S.#1.fq.gz
16S-46F-16S-57R.R[12].fq.gz RS1_IM_L2_1_16S.#1.fq.gz
16S-47F-16S-57R.R[12].fq.gz RS1_IM_L3_4_16S.#1.fq.gz
16S-48F-16S-57R.R[12].fq.gz RS1_IM_S2_2_16S.#1.fq.gz
16S-49F-16S-57R.R[12].fq.gz RS1_IM_S3_5_16S.#1.fq.gz
16S-50F-16S-57R.R[12].fq.gz RS1_ME_L1_3_16S.#1.fq.gz
```


## Aditional notes

- It's worth noting that the config file has `resume` set to true as default. This causes nextflow to try to resume previous pipeline runs if they exist. This can be commented out in the config file if you would like to disable this feature.

- You can remove information from nextflow about the last pipeline run with the command
```
nextflow clean -f
```

- This amplicon pipeline only works with a minimum of three samples.


## Authors and contributors
Jessica Pearce  
Sebastian Rauschert  
Priscila Goncalves  
Philipp Bayer  
Adam Bennett