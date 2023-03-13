#!/usr/bin/env nextflow

demux_dir = file(params.demux_dir)
metadata_file = file(params.metadata_file)
scripts_dir = file(params.scripts_dir)
resources_dir = file(params.resources_dir)

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
    file metadata_file from metadata_file
    file scripts_dir from scripts_dir
    file resources_dir from resources_dir

  output:
    tuple val(project), val(assay), path("${project}_amplicon_analysis") into demux_ch

  script:
    """
    bash $projectDir/scripts/00-setup.sh -p $project

    cp $projectDir/*${assay}*R1*fastq.gz ${project}_amplicon_analysis/00-raw-data/
    cp $projectDir/*${assay}*R2*fastq.gz ${project}_amplicon_analysis/00-raw-data/
    cp $projectDir/${project}_${assay}_Fw.fa ${project}_amplicon_analysis/00-raw-data/indices/
    cp $projectDir/${project}_${assay}_Rv.fa ${project}_amplicon_analysis/00-raw-data/indices/
    cp $projectDir/Sample_name_rename_pattern_${project}_${assay}.txt ${project}_amplicon_analysis/00-raw-data/indices/
    cp $metadata_file ${project}_amplicon_analysis/06-report/${project}_metadata.csv
    """
}

process '01-demultiplex' {
  publishDir(
    path: "${project}_${assay}_results",
    mode: params.publish_dir_mode,
  )

  input:
    tuple val(project), val(assay), path("${project}_amplicon_analysis") from demux_ch

  output:
    tuple val(project), val(assay), path("${project}_amplicon_analysis") into rename_ch  
  
  script:
    """
    cd ${project}_amplicon_analysis
    01-demultiplex.sh -v $project -a $assay -c ${task.cpus}
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
    file metadata_file from metadata_file
    file demux_dir from demux_dir
    file scripts_dir from scripts_dir
    file resources_dir from resources_dir

  output:
    tuple val(project), val(assay), path("${project}_amplicon_analysis") into tmp_ch_b

  script:
    """
    bash $projectDir/scripts/00-setup.sh -p $project

    mkdir ${project}_amplicon_analysis/01-demultiplexed/$assay
    cp $demux_dir/*$assay* ${project}_amplicon_analysis/01-demultiplexed/$assay
    cp $metadata_file ${project}_amplicon_analysis/06-report/${project}_metadata.csv
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

  output:
    tuple val(project), val(assay), path("${project}_amplicon_analysis") into dada2_in_ch
  
  script:
    """
    cd ${project}_amplicon_analysis
    touch logs/03-seqkit_stats.log
    03-seqkit_stats.sh -v $project -a $assay -c ${task.cpus}
    """
}

process '04-DADA2' {
  publishDir(
    path: "${project}_${assay}_results",
    mode: params.publish_dir_mode,
  )

  input:
    tuple val(project), val(assay), path("${project}_amplicon_analysis") from dada2_in_ch
    val option from params.dada_option
    val min_overlap from params.merge_pairs_min_overlap
    val max_mismatch from params.merge_pairs_max_mismatch
    val trim_side from params.trim_side
    val single_end from params.single_end

  output:
    tuple val(project), val(assay), path("${project}_amplicon_analysis") into dada2_out_ch

  script:
    """
    export ANALYSIS="/mnt/scratch/${project}_amplicon_analysis"
    #Rscript /opt/amplicon_pipeline/04-DADA2.R -v $project -a $assay -p $option -c ${task.cpus} -m $min_overlap -x $max_mismatch  -s $trim_side -o $trim_R1 -t $trim_R2 -i $single_end

    if [[ $assay == 16S ]]
    then
      Rscript /opt/amplicon_pipeline/04-DADA2.R -v $project -a $assay -p $option -c ${task.cpus} -m $min_overlap -x $max_mismatch  -s $trim_side -o 20 -t 22 -i $single_end
    fi
    if [[ $assay == MiFish ]]
    then
      Rscript /opt/amplicon_pipeline/04-DADA2.R -v $project -a $assay -p $option -c ${task.cpus} -m $min_overlap -x $max_mismatch  -s $trim_side -o 21 -t 27 -i $single_end
    fi
    """
}

dada2_out_ch.into {skip_lulu_ch; lulu_in_ch}

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

  output:
    tuple val(project), val(assay), path("${project}_amplicon_analysis") into lca_in_ch

  script:
    """
    cd ${project}_amplicon_analysis
    touch logs/06-run_blast.log
    touch logs/06-run_blast.nt.log
    touch logs/06-run_blast_nt_database_information.log
    export ANALYSIS="/mnt/scratch/${project}_amplicon_analysis"
    06-run_blast.sh -v $project -a $assay -d $database -c ${task.cpus}
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
    val control_grep_patterns from params.control_grep_patterns

  output:
    tuple val(project), val(assay), path("${project}_amplicon_analysis") into phyloseq_ch

  script:
    """
    export ANALYSIS="/mnt/scratch/${project}_amplicon_analysis"
    Rscript /opt/amplicon_pipeline/08-Decontam.R -v $project -a $assay -o $database -c $control_grep_patterns
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
    val optimise_tree from params.optimise_tree

  output:
    tuple val(project), val(assay), path("${project}_amplicon_analysis") into report_ch

  script:
    """
    export ANALYSIS="/mnt/scratch/${project}_amplicon_analysis"
    Rscript /opt/amplicon_pipeline/09-create_phyloseq_object.R -v $project -a $assay -o $database -c ${task.cpus} -t $optimise_tree
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
    val database from params.database_option

  output:
    tuple val(project), val(assay), path("${project}_amplicon_analysis") into final_ch

  script:
    """
    cd ${project}_amplicon_analysis
    export CODE="/opt/amplicon_pipeline/"
    export ANALYSIS="/mnt/scratch/${project}_amplicon_analysis"
    if [ -z $seq_run ]
    then
      10-amplicon_report.sh -v $project -a $assay -d $database
    else
      10-amplicon_report.sh -v $project -a $assay -d $database -r $seq_run
    fi
    """
}