#!/usr/bin/env nextflow

indices_file = file(params.indices_file)
demux_dir = file(params.demux_dir)
metadata_file = file(params.metadata_file)
raw_data_R1 = file(params.raw_data.R1)
raw_data_R2 = file(params.raw_data.R2)
sample_rename_pattern = file(params.sample_rename_pattern)
Fw_index = file(params.Fw_index)
Rv_index = file(params.Rv_index)

setup_ch = Channel.of(params.voyage_id)

if (params.skip_demux) {
	setup_ch = Channel.empty()
  skip_demux_ch = Channel.of(params.voyage_id)
} 

process '00-setup-a' {
  publishDir(
    path: params.publish_dir, 
    mode: params.publish_dir_mode,
  )

  input:
    val voyage from setup_ch
    val assay from params.assay
    val indices_file from indices_file
    val metadata_file from metadata_file
    val raw_data_R1 from raw_data_R1
    val raw_data_R2 from raw_data_R2
    val sample_rename_pattern from sample_rename_pattern
    val Fw_index from Fw_index
    val Rv_index from Rv_index

  output:
    tuple val(voyage), path("${voyage}_amplicon_analysis") into demux_ch

  script:
  """
  00-setup.sh -p $voyage

  cp $projectDir/$raw_data_R1 ${voyage}_amplicon_analysis/00-raw-data/${voyage}_${assay}_R1.fastq.gz
  cp $projectDir/$raw_data_R2 ${voyage}_amplicon_analysis/00-raw-data/${voyage}_${assay}_R2.fastq.gz
  cp $projectDir/$indices_file ${voyage}_amplicon_analysis/00-raw-data/indices/${voyage}_indices.csv
  cp $projectDir/$Fw_index ${voyage}_amplicon_analysis/${voyage}_${assay}_Fw.fa
  cp $projectDir/$Rv_index ${voyage}_amplicon_analysis/${voyage}_${assay}_Fw.Rv
  cp $projectDir/$sample_rename_pattern ${voyage}_amplicon_analysis/Sample_name_rename_pattern_${voyage}_${assay}.txt
  cp $projectDir/$metadata_file ${voyage}_amplicon_analysis/06-report/${voyage}_metadata.csv
  """
}

process '01-demultiplex' {
  publishDir(
    path: params.publish_dir, 
    mode: params.publish_dir_mode,
  )

  input:
    tuple val(voyage), path("${voyage}_amplicon_analysis") from demux_ch
    val assay from params.assay
    val cores from params.cores

  output:
    tuple val(voyage), path("${voyage}_amplicon_analysis") into rename_ch  
  
  """
  01-demultiplex.sh -v $voyage -a $assay -c $cores
  """
}

process '02-rename_demux' {
   publishDir(
    path: params.publish_dir, 
    mode: params.publish_dir_mode,
  )

  input:
    tuple val(voyage), path("${voyage}_amplicon_analysis") from rename_ch
    val assay from params.assay

  output:
    tuple val(voyage), path("${voyage}_amplicon_analysis") into tmp_ch_a

  """
  02-rename_demux.sh -v $voyage -a $assay
  """
}

process '00-setup-b' {
  publishDir(
    path: params.publish_dir, 
    mode: params.publish_dir_mode,
  )

  input:
    val voyage from skip_demux_ch
    val assay from params.assay
    file indices_file from indices_file
    file metadata_file from metadata_file
    file demux_dir from demux_dir

  output:
    tuple val(voyage), path("${voyage}_amplicon_analysis") into tmp_ch_b

  """
  00-setup.sh -p $voyage

  cp $projectDir/$indices_file ${voyage}_amplicon_analysis/00-raw-data/indices/${voyage}_indices.csv
  mkdir ${voyage}_amplicon_analysis/01-demultiplexed/$assay
  cp $projectDir/$demux_dir/* ${voyage}_amplicon_analysis/01-demultiplexed/$assay
  cp $projectDir/$metadata_file ${voyage}_amplicon_analysis/06-report/${voyage}_metadata.csv
  """
}

seqkit_ch = (params.skip_demux ? tmp_ch_b : tmp_ch_a)

process '03-seqkit_stats' {
  publishDir(
    path: params.publish_dir, 
    mode: params.publish_dir_mode,
  )

  input:
    tuple val(voyage), path("${voyage}_amplicon_analysis") from seqkit_ch
    val assay from params.assay
    val cores from params.cores

  output:
    tuple val(voyage), path("${voyage}_amplicon_analysis") into dada2_ch
  
  """
  cd ${voyage}_amplicon_analysis
  touch logs/03-seqkit_stats.log
  03-seqkit_stats.sh -v $voyage -a $assay -c $cores
  """
}

process '04-DADA2' {
  publishDir(
    path: params.publish_dir, 
    mode: params.publish_dir_mode,
  )

  input:
    tuple val(voyage), path("${voyage}_amplicon_analysis") from dada2_ch
    val assay from params.assay
    val option from params.dada_option
    val cores from params.cores

  output:
    tuple val(voyage), path("${voyage}_amplicon_analysis") into reorg_ch

  """
  cd ${voyage}_amplicon_analysis
  export ANALYSIS=""
  Rscript /opt/amplicon_pipeline/04-DADA2.R -v $voyage -a $assay -p $option -c $cores
  """
}

process 'Reorganise' {
  publishDir(
    path: params.publish_dir, 
    mode: params.publish_dir_mode,
  )

  input:
    tuple val(voyage), path("${voyage}_amplicon_analysis") from reorg_ch
    val assay from params.assay

  output:
    tuple val(voyage), path("${voyage}_amplicon_analysis") into lulu_ch

  """
  cd ${voyage}_amplicon_analysis
  RS_Reorganise.sh $voyage $assay
  """
}

process '05-run_LULU' {
  publishDir(
    path: params.publish_dir, 
    mode: params.publish_dir_mode,
  )

  input:
    tuple val(voyage), path("${voyage}_amplicon_analysis") from lulu_ch
    val assay from params.assay

  output:
    tuple val(voyage), path("${voyage}_amplicon_analysis") into blast_ch

  """
  cd ${voyage}_amplicon_analysis
  05-run_LULU.sh -v $voyage -a $assay
  """
}

process '06-run_blast' {
  publishDir(
    path: params.publish_dir, 
    mode: params.publish_dir_mode,
  )

  input:
    tuple val(voyage), path("${voyage}_amplicon_analysis") from blast_ch
    val assay from params.assay
    val database from params.database_option
    val cores from params.cores

  output:
    tuple val(voyage), path("${voyage}_amplicon_analysis") into lca_ch

  """
  cd ${voyage}_amplicon_analysis
  touch logs/06-run_blast.log
  touch logs/06-run_blast.nt.log
  touch logs/06-run_blast_nt_database_information.log
  06-run_blast.sh -v $voyage -a $assay -d $database -c $cores
  """
}

process '07-run_LCA' {
  publishDir(
    path: params.publish_dir, 
    mode: params.publish_dir_mode,
  )

  input:
    tuple val(voyage), path("${voyage}_amplicon_analysis") from lca_ch
    val assay from params.assay
    val database from params.database_option

  output:
    tuple val(voyage), path("${voyage}_amplicon_analysis") into lca_filt_ch

  """
  cd ${voyage}_amplicon_analysis
  touch logs/07-run_LCA.log
  touch logs/07-run_LCA_taxdump_linecounts.log
  touch logs/07-run_LCA_taxdump_md5sums.log
  07-run_LCA.sh -v $voyage -a $assay -d $database
  """
}

process '07.1-LCA_filter_nt_only' {
  publishDir(
    path: params.publish_dir, 
    mode: params.publish_dir_mode,
  )

  input:
    tuple val(voyage), path("${voyage}_amplicon_analysis") from lca_filt_ch
    val assay from params.assay

  output:
    tuple val(voyage), path("${voyage}_amplicon_analysis") into decontam_ch

  """
  cd ${voyage}_amplicon_analysis
  export ANALYSIS=""
  Rscript /opt/amplicon_pipeline/07.1-LCA_filter_nt_only.R -v $voyage -a $assay
  """
}

process '08-Decontam' {
  publishDir(
    path: params.publish_dir, 
    mode: params.publish_dir_mode,
  )

  input:
    tuple val(voyage), path("${voyage}_amplicon_analysis") from decontam_ch
    val assay from params.assay
    val database from params.database_option

  output:
    tuple val(voyage), path("${voyage}_amplicon_analysis") into phyloseq_ch

  """
  cd ${voyage}_amplicon_analysis
  export ANALYSIS=""
  Rscript /opt/amplicon_pipeline/08-Decontam.R -v $voyage -a $assay -o $database
  """
}

process '09-create_phyloseq_object' {
  publishDir(
    path: params.publish_dir, 
    mode: params.publish_dir_mode,
  )

  input:
    tuple val(voyage), path("${voyage}_amplicon_analysis") from phyloseq_ch
    val assay from params.assay
    val database from params.database_option
    val cores from params.cores

  output:
    tuple val(voyage), path("${voyage}_amplicon_analysis") into report_ch

  """
  cd ${voyage}_amplicon_analysis
  export ANALYSIS=""
  Rscript /opt/amplicon_pipeline/09-create_phyloseq_object.R -v $voyage -a $assay -o $database -c $cores
  """
}

process '10-amplicon_report' {
  publishDir(
    path: params.publish_dir, 
    mode: params.publish_dir_mode,
  )

  input:
    tuple val(voyage), path("${voyage}_amplicon_analysis") from report_ch
    val assay from params.assay
    val seq_run from params.sequencing_run_id

  output:
    tuple val(voyage), path("${voyage}_amplicon_analysis") into final_ch

  """
  cd ${voyage}_amplicon_analysis
  10-amplicon_report.sh -v $voyage -a $assay -r $seq_run
  """
}

//MAYBE HAVE FINAL PROCESS THAT MOVES EVERYTHING TO $PWD