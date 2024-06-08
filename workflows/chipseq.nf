
include { PREPARE_FASTQ  } from "../subworkflows/local/prepare_fastq"
include { PREPARE_GENOME } from "../subworkflows/local/prepare_genome"
include { ENCODE_CHIP    } from "../subworkflows/encode/encode_chip"

//include { TASK_ALIGN    } from "../subworkflows/encode/task_align"

include { validateParameters; paramsHelp; paramsSummaryLog; samplesheetToList } from 'plugin/nf-schema'
// Validate input parameters
validateParameters()
// Print summary of supplied parameters
log.info paramsSummaryLog(workflow)

workflow CHIPSEQ {

	PREPARE_GENOME(
		params.fasta,
		params.chrom_sizes,
		params.gensz,
		params.mito_fasta,
		params.mito_chr_name,
		params.bowtie2_index,
		params.bowtie2_mito_index
	)

	Channel
		.fromList(samplesheetToList(params.input, "assets/schema_input.json"))
		.set{ch_input}
	
	PREPARE_FASTQ(
		ch_input,
		params.read_length_reads ? params.read_length_reads : []
	)

	ENCODE_CHIP(
		PREPARE_FASTQ.out.fastq,
		PREPARE_GENOME.out.genome_fasta,
		PREPARE_GENOME.out.genome_fai,
		PREPARE_GENOME.out.bowtie2_index,
		PREPARE_GENOME.out.bowtie2_mito_index,
		params.multimapping ? params.multimapping : [],
		params.local_mode,
		params.mapq_threshold ? params.mapq_threshold : [],
		params.chr_filter ? params.chr_filter : [],
		params.pseudorep_seed ? params.pseudorep_seed : 0
	)


}