#!/usr/bin/env nextflow

indices_file = file(params.indices_file)
demux_dir = file(params.demux_dir)
metadata_file = file(params.metadata_file)

assay_list = params.assay?.tokenize(',')
assay_ch = Channel.fromList(assay_list)
assay_ch.into {assay_ch_a; assay_ch_b}

if (params.skip_demux) {
	setup_ch = Channel.empty()
  skip_demux_ch = Channel.value(params.project_id)
} else {
  setup_ch = Channel.value(params.project_id)
  skip_demux_ch = Channel.empty()
}

process '00-setup-a' {
  publishDir(
    path: "${project}_${assay}_results",
    mode: params.publish_dir_mode,
  )

  input:
    val project from setup_ch
    val assay from assay_ch_a
    file indices_file from indices_file
    file metadata_file from metadata_file

  output:
    tuple val(project), val(assay), path("${project}_amplicon_analysis") into demux_ch

  script:
    """
    00-setup.sh -p $project

    cp $projectDir/*${assay}*R1*fastq.gz ${project}_amplicon_analysis/00-raw-data/
    cp $projectDir/*${assay}*R2*fastq.gz ${project}_amplicon_analysis/00-raw-data/
    cp $projectDir/${project}_${assay}_Fw.fa ${project}_amplicon_analysis/00-raw-data/indices/
    cp $projectDir/${project}_${assay}_Rv.fa ${project}_amplicon_analysis/00-raw-data/indices/
    cp $projectDir/Sample_name_rename_pattern_${project}_${assay}.txt ${project}_amplicon_analysis/00-raw-data/indices/
    cp $projectDir/$metadata_file ${project}_amplicon_analysis/06-report/${project}_metadata.csv
    cp $projectDir/$indices_file ${project}_amplicon_analysis/00-raw-data/indices/${project}_indices.csv
    """
}

process '01-demultiplex' {
  publishDir(
    path: "${project}_${assay}_results",
    mode: params.publish_dir_mode,
  )

  input:
    tuple val(project), val(assay), path("${project}_amplicon_analysis") from demux_ch
    val cores from params.cores

  output:
    tuple val(project), val(assay), path("${project}_amplicon_analysis") into rename_ch  
  
  script:
    """
    cd ${project}_amplicon_analysis
    01-demultiplex.sh -v $project -a $assay -c $cores
    """
}

process '02-rename_demux' {
   publishDir(
    path: "${project}_${assay}_results",
    mode: params.publish_dir_mode,
  )

  input:
    tuple val(project), val(assay), path("${project}_amplicon_analysis") from rename_ch

  output:
    tuple val(project), val(assay), path("${project}_amplicon_analysis") into tmp_ch_a

  script:
    """
    cd ${project}_amplicon_analysis
    02-rename_demux.sh -v $project -a $assay
    """
}

process '00-setup-b' {
  publishDir(
    path: "${project}_${assay}_results",
    mode: params.publish_dir_mode,
  )

  input:
    val project from skip_demux_ch
    val assay from assay_ch_b
    file indices_file from indices_file
    file metadata_file from metadata_file
    file demux_dir from demux_dir

  output:
    tuple val(project), val(assay), path("${project}_amplicon_analysis") into tmp_ch_b

  script:
    """
    00-setup.sh -p $project

    cp $projectDir/$indices_file ${project}_amplicon_analysis/00-raw-data/indices/${project}_indices.csv
    mkdir ${project}_amplicon_analysis/01-demultiplexed/$assay
    cp $projectDir/$demux_dir/*$assay* ${project}_amplicon_analysis/01-demultiplexed/$assay
    cp $projectDir/$metadata_file ${project}_amplicon_analysis/06-report/${project}_metadata.csv
    """
}

seqkit_ch = (params.skip_demux ? tmp_ch_b : tmp_ch_a)

process '03-seqkit_stats' {
  publishDir(
    path: "${project}_${assay}_results",
    mode: params.publish_dir_mode,
  )

  input:
    tuple val(project), val(assay), path("${project}_amplicon_analysis") from seqkit_ch
    val cores from params.cores

  output:
    tuple val(project), val(assay), path("${project}_amplicon_analysis") into dada2_ch
  
  script:
    """
    cd ${project}_amplicon_analysis
    touch logs/03-seqkit_stats.log
    03-seqkit_stats.sh -v $project -a $assay -c $cores
    """
}

process '04-DADA2' {
  publishDir(
    path: "${project}_${assay}_results",
    mode: params.publish_dir_mode,
  )

  input:
    tuple val(project), val(assay), path("${project}_amplicon_analysis") from dada2_ch
    val option from params.dada_option
    val cores from params.cores
    val min_overlap from params.merge_pairs_min_overlap
    val max_mismatch from params.merge_pairs_max_mismatch

  output:
    tuple val(project), val(assay), path("${project}_amplicon_analysis") into reorg_in_ch

  script:
    """
    export ANALYSIS="/mnt/scratch/${project}_amplicon_analysis"
    Rscript /opt/amplicon_pipeline/04-DADA2.R -v $project -a $assay -p $option -c $cores -m $min_overlap -M $max_mismatch
    """
}

process 'Reorganise' {
  publishDir(
    path: "${project}_${assay}_results",
    mode: params.publish_dir_mode,
  )

  input:
    tuple val(project), val(assay), path("${project}_amplicon_analysis") from reorg_in_ch

  output:
    tuple val(project), val(assay), path("${project}_amplicon_analysis") into reorg_out_ch

  script:
    """
    cd ${project}_amplicon_analysis
    #Reorganise.sh $project $assay
    touch logs/reorganise.log
    mkdir -p 01-demultiplexed/$assay/Controls
    [ ! -f 01-demultiplexed/$assay/*EB* ] || mv 01-demultiplexed/$assay/*EB* 01-demultiplexed/$assay/Controls 2>>logs/reorganise.log
    [ ! -f 01-demultiplexed/$assay/*FC* ] || mv 01-demultiplexed/$assay/*FC* 01-demultiplexed/$assay/Controls 2>>logs/reorganise.log
    [ ! -f 01-demultiplexed/$assay/*WC* ] || mv 01-demultiplexed/$assay/*WC* 01-demultiplexed/$assay/Controls 2>>logs/reorganise.log
    """
}

reorg_out_ch.into {skip_lulu_ch; lulu_in_ch}

if (params.skip_lulu) {
  lulu_in_ch = Channel.empty()
}

process '05-run_LULU' {
  publishDir(
    path: "${project}_${assay}_results",
    mode: params.publish_dir_mode,
  )

  input:
    tuple val(project), val(assay), path("${project}_amplicon_analysis") from lulu_in_ch

  output:
    tuple val(project), val(assay), path("${project}_amplicon_analysis") into lulu_out_ch

  script:
    """
    export CODE="/opt/amplicon_pipeline/"
    export ANALYSIS="/mnt/scratch/${project}_amplicon_analysis"
    05-run_LULU.sh -v $project -a $assay
    """
}

blast_ch = (params.skip_lulu ? skip_lulu_ch : lulu_out_ch)

process '06-run_blast' {
  publishDir(
    path: "${project}_${assay}_results",
    mode: params.publish_dir_mode,
  )

  input:
    tuple val(project), val(assay), path("${project}_amplicon_analysis") from blast_ch
    val database from params.database_option
    val cores from params.cores

  output:
    tuple val(project), val(assay), path("${project}_amplicon_analysis") into lca_in_ch

  script:
    """
    cd ${project}_amplicon_analysis
    touch logs/06-run_blast.log
    touch logs/06-run_blast.nt.log
    touch logs/06-run_blast_nt_database_information.log
    export ANALYSIS="/mnt/scratch/${project}_amplicon_analysis"
    06-run_blast.sh -v $project -a $assay -d $database -c $cores
    """
}

process '07-run_LCA' {
  publishDir(
    path: "${project}_${assay}_results",
    mode: params.publish_dir_mode,
  )

  input:
    tuple val(project), val(assay), path("${project}_amplicon_analysis") from lca_in_ch
    val database from params.database_option

  output:
    tuple val(project), val(assay), path("${project}_amplicon_analysis") into lca_out_ch

  script:
    """
    cd ${project}_amplicon_analysis 
    touch logs/07-run_LCA.log
    touch logs/07-run_LCA_taxdump_linecounts.log
    touch logs/07-run_LCA_taxdump_md5sums.log
    export CODE="/opt/amplicon_pipeline/"
    07-run_LCA.sh -v $project -a $assay -d $database
    """
}

lca_out_ch.into {skip_filt_ch; lca_filt_in_ch}

if (params.database_option != "nt") {
  lca_filt_in_ch = Channel.empty()
}

process '07.1-LCA_filter_nt_only' {
  publishDir(
    path: "${project}_${assay}_results",
    mode: params.publish_dir_mode,
  )

  input:
    tuple val(project), val(assay), path("${project}_amplicon_analysis") from lca_filt_in_ch

  output:
    tuple val(project), val(assay), path("${project}_amplicon_analysis") into lca_filt_out_ch

  script:
    """
    export ANALYSIS="/mnt/scratch/${project}_amplicon_analysis"
    Rscript /opt/amplicon_pipeline/07.1-LCA_filter_nt_only.R -v $project -a $assay
    """
}

decontam_ch = (params.database_option != "nt" ? skip_filt_ch : lca_filt_out_ch)

process '08-Decontam' {
  publishDir(
    path: "${project}_${assay}_results",
    mode: params.publish_dir_mode,
  )

  input:
    tuple val(project), val(assay), path("${project}_amplicon_analysis") from decontam_ch
    val database from params.database_option

  output:
    tuple val(project), val(assay), path("${project}_amplicon_analysis") into phyloseq_ch

  script:
    """
    export ANALYSIS="/mnt/scratch/${project}_amplicon_analysis"
    Rscript /opt/amplicon_pipeline/08-Decontam.R -v $project -a $assay -o $database
    """
}

process '09-create_phyloseq_object' {
  publishDir(
    path: "${project}_${assay}_results",
    mode: params.publish_dir_mode,
  )

  input:
    tuple val(project), val(assay), path("${project}_amplicon_analysis") from phyloseq_ch
    val database from params.database_option
    val cores from params.cores

  output:
    tuple val(project), val(assay), path("${project}_amplicon_analysis") into report_ch

  script:
    """
    export ANALYSIS="/mnt/scratch/${project}_amplicon_analysis"
    Rscript /opt/amplicon_pipeline/09-create_phyloseq_object.R -v $project -a $assay -o $database -c $cores
    """
}

process '10-amplicon_report' {
  publishDir(
    path: "${project}_${assay}_results",
    mode: params.publish_dir_mode_final,
  )

  input:
    tuple val(project), val(assay), path("${project}_amplicon_analysis") from report_ch
    val seq_run from params.sequencing_run_id

  output:
    tuple val(project), val(assay), path("${project}_amplicon_analysis") into final_ch

  script:
    """
    cd ${project}_amplicon_analysis
    10-amplicon_report.sh -v $project -a $assay -r $seq_run
    """
}