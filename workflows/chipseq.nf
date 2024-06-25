
include { PREPARE_FASTQ       } from "../subworkflows/local/prepare_fastq"
include { PREPARE_GENOME      } from "../subworkflows/local/prepare_genome"
include { ENCODE_CHIP         } from "../subworkflows/encode/encode_chip2"
include { SOURMASH_CLASSIFIER } from "../subworkflows/local/sourmash_classifier"
include { DEEPTOOLS_BAMCOVERAGE } from "../modules/local/deeptools/bamCoverage/main"

include { MULTIQC } from "../modules/local/multiqc/main"

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
		params.bowtie2_mito_index,
		params.blacklist_peaks
	)

	Channel
		.fromList(samplesheetToList(params.input, "assets/schema_input.json"))
		.map{ meta, fq1, fq2 -> [ meta + [sample_type: "sample"], fq1, fq2 ] }
		.set{ch_input}
	
	PREPARE_FASTQ(
		ch_input,
		params.read_length_reads ? params.read_length_reads : []
	)
	ch_multiqc_fastqc_raw     = PREPARE_FASTQ.out.fastqc_raw_zip.collect{it[1]}.ifEmpty{[]}
	ch_multiqc_fastqc_trimmed = PREPARE_FASTQ.out.fastqc_trimmed_zip.collect{it[1]}.ifEmpty{[]}


	ENCODE_CHIP(
		PREPARE_FASTQ.out.fastq,
		PREPARE_GENOME.out.genome_fasta,
		PREPARE_GENOME.out.genome_fai,
		PREPARE_GENOME.out.gensz,
		PREPARE_GENOME.out.bowtie2_index,
		PREPARE_GENOME.out.bowtie2_mito_index,
		params.multimapping ? params.multimapping : [],
		params.local_mode,
		params.mapq_threshold ? params.mapq_threshold : [],
		params.chr_filter ? params.chr_filter : [],
		params.pseudorep_seed ? params.pseudorep_seed : 0,
		PREPARE_GENOME.out.blacklist_peaks,
		params.idr_threshold_col ? params.idr_threshold_col : "p.value",
		params.idr_threshold ? params.idr_threshold : 0.05,
		params.mito_chr_name ?: [],
		params.chip_mode ?: "tf"
	)

	//DEEPTOOLS_BAMCOVERAGE(
	//	ENCODE_CHIP.out.dedup_bam.join(ENCODE_CHIP.out.dedup_bai, by: 0),
	//	params.deeptools_bamcoverage_args ?: []
	//)


	//if (params.enable_sourmash) {
	//	SOURMASH_CLASSIFIER(
	//		PREPARE_FASTQ.out.fastq,
	//		params.sourmash_db ? file(params.sourmash_db) : [],
	//		params.sourmash_params ? params.sourmash_params : []
	//	)
	//}

	//MULTIQC(
	//	params.multiqc_config ? file(params.multiqc_config) : [],
	//	ch_multiqc_fastqc_raw,
	//	Channel.topic('fastp_json').collect{it[1]}.ifEmpty{[]},
	//	ch_multiqc_fastqc_trimmed,
	//	Channel.topic('bowtie2_align_log').collect{it[1]}.ifEmpty{[]},
	//	Channel.topic('picard_markduplicates_log').collect{it[1]}.ifEmpty{[]},
	//	Channel.topic('spp_log').collect{it[1]}.ifEmpty{[]},
	//	Channel.topic('sourmash_gather_csv').collect{it[1]}.ifEmpty{[]},
	//	ENCODE_CHIP.out.xcor_csv.collect{it[1]}.ifEmpty{[]}
	//)

	//publish:
	//MULTIQC.out >> "multiqc"
	//DEEPTOOLS_BAMCOVERAGE.out.bigwig >> "deeptools/bamCoverage"


}