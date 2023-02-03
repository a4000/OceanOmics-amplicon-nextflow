#!/usr/bin/env nextflow

setup_ch = Channel.of(params.voyage_id)

if (params.skipDemux) {
	setup_ch = Channel.empty()
  skip_demux_ch = Channel.of(params.voyage_id)
} 

process '00-setup-a' {
  input:
    val voyage from setup_ch
    val assay from params.assay
    val indices_file from params.indices_file
    val metadata_file from params.metadata_file
    val raw_data_R1 from params.raw_data.R1
    val raw_data_R2 from params.raw_data.R2
    val sample_rename_pattern from params.sample_rename_pattern
    val Fw_index from params.Fw_index
    val Rv_index from params.Rv_index
    val setup_script from params.setup_script
  output:
    val voyage into demux_ch

  script:
  """
  bash $PWD/scripts/$setup_script -p $voyage -w $PWD
  cp $raw_data_R1 $PWD/00-raw-data/${voyage}_${assay}_R1.fastq.gz
  cp $raw_data_R2 $PWD/00-raw-data/${voyage}_${assay}_R2.fastq.gz
  cp $indices_file $PWD/00-raw-data/indices/${voyage}_indices.csv
  cp $Fw_index $PWD/00-raw-data/indices/${voyage}_${assay}_Fw.fa
  cp $Rv_index $PWD/00-raw-data/indices/${voyage}_${assay}_Rv.fa
  cp $sample_rename_pattern $PWD/00-raw-data/indices/Sample_name_rename_pattern_${voyage}_${assay}.txt
  cp $metadata_file $PWD/06-report/${voyage}_metadata.csv
  """
}


process '01-demultiplex' {
  input:
    val voyage from demux_ch
    val assay from params.assay
    val cores from params.cores
    val demultiplex_script from params.demultiplex_script
  output:
    val voyage into rename_ch  
  
  """
  bash $PWD/scripts/$demultiplex_script -v $voyage -a $assay -c $cores -w $PWD
  """
}

process '02-rename_demux' {
  input:
    val voyage from rename_ch
    val assay from params.assay
    val rename_script from params.rename_script
  output:
    val voyage into tmp_ch_a

  """
  bash $PWD/scripts/$rename_script -v $voyage -a $assay -w $PWD
  """
}

process '00-setup-b' {
  input:
    val voyage from skip_demux_ch
    val assay from params.assay
    val indices_file from params.indices_file
    val metadata_file from params.metadata_file
    val demux_dir from params.demux_dir
    val setup_script from params.setup_script

  output:
    val voyage into tmp_ch_b

  """
  bash $PWD/scripts/$setup_script -p $voyage -w $PWD
  cp $indices_file $PWD/00-raw-data/indices/${voyage}_indices.csv
  cp $demux_dir/* $PWD/01-demultiplexed/$assay
  """
}

seqkit_ch = (params.skipDemux ? tmp_ch_b : tmp_ch_a)

process '03-seqkit_stats' {
  input:
    val voyage from seqkit_ch
    val assay from params.assay
    val cores from params.cores
    val seqkit_script from params.seqkit_script
  output:
    val voyage into dada2_ch
  
  """
  bash $PWD/scripts/$seqkit_script -v $voyage -a $assay -c $cores -w $PWD
  """
}

process '04-DADA2' {
  input:
    val voyage from dada2_ch
    val assay from params.assay
    val option from params.dada_option
    val cores from params.cores
    val dada2_script from params.dada2_script
  output:
    val voyage into reorg_ch

  """
  Rscript $PWD/scripts/$dada2_script -v $voyage -a $assay -o $option -c $cores -w $PWD
  """
}

process 'Reorganise' {
  input:
    val voyage from reorg_ch
    val assay from params.assay
    val reorganise_script from params.reorganise_script
  output:
    val voyage into lulu_ch

  """
  bash $PWD/scripts/$reorganise_script $voyage $assay $PWD
  """
}

process '05-run_LULU' {
  input:
    val voyage from lulu_ch
    val assay from params.assay
    val lulu_script from params.lulu_script
  output:
    val voyage into blast_ch

  """
  bash $PWD/scripts/$lulu_script -v $voyage -a $assay -w $PWD
  """
}

process '06-run_blast' {
  input:
    val voyage from blast_ch
    val assay from params.assay
    val database from params.database_option
    val cores from params.cores
    val blast_script from params.blast_script
  output:
    val voyage into lca_ch

  """
  bash $PWD/scripts/$blast_script -v $voyage -a $assay -d $database -c $cores -w $PWD
  """
}

process '07-run_LCA' {
  input:
    val voyage from lca_ch
    val assay from params.assay
    val database from params.database_option
    val lca_script from params.lca_script
  output:
    val voyage into lca_filt_ch

  """
  bash $PWD/scripts/$lca_script -v $voyage -a $assay -d $database -w $PWD
  """
}

process '07.1-LCA_filter_nt_only' {
  input:
    val voyage from lca_filt_ch
    val assay from params.assay
    val lca_filter_script from params.lca_filter_script
  output:
    val voyage into decontam_ch

  """
  Rscript $PWD/scripts/$lca_filter_script -v $voyage -a $assay -w $PWD
  """
}

process '08-Decontam' {
  input:
    val voyage from decontam_ch
    val assay from params.assay
    val database from params.database_option
    val decontam_script from params.decontam_script
  output:
    val voyage into phyloseq_ch

  """
  Rscript $PWD/scripts/$decontam_script -v $voyage -a $assay -o $database -w $PWD
  """
}

process '09-create_phyloseq_object' {
  input:
    val voyage from phyloseq_ch
    val assay from params.assay
    val database from params.database_option
    val cores from params.cores
    val phyloseq_script from params.phyloseq_script
  output:
    val voyage into report_ch

  """
  Rscript $PWD/scripts/$phyloseq_script -v $voyage -a $assay -o $database -c $cores -w $PWD
  """
}

process '10-amplicon_report' {
  input:
    val voyage from report_ch
    val assay from params.assay
    val seq_run from params.sequencing_run_id
    val report_script from params.report_script

  """
  bash $PWD/scripts/$report_script -v $voyage -a $assay -r $seq_run -w $PWD
  """
}

