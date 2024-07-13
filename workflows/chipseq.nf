
include { PREPARE_FASTQ       } from "../subworkflows/local/prepare_fastq"
include { PREPARE_GENOME      } from "../subworkflows/local/prepare_genome"
include { ENCODE_CHIP         } from "../subworkflows/encode/encode_chip"
include { METAGENOMICS        } from "../subworkflows/local/metagenomics"
include { DEEPTOOLS           } from "../subworkflows/local/deeptools"
include { HOMER_FINDMOTIFSGENOME } from "../modules/local/homer/findmotifsgenome/main"
include { HOMER_POSTPROC_FINDMOTIFSGENOME } from "../modules/local/homer/postproc_findmotifsgenome/main" 

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
		params.bowtie2_index,
		params.blacklist_peaks
	)

	Channel
		.fromList(samplesheetToList(params.input, "assets/schema_input.json"))
		.map{ meta, fq1, fq2 -> [ meta + [sample_type: "sample"], fq1, fq2 ] }
		.set{ch_input}
	
	PREPARE_FASTQ(
		ch_input,
		params.read_length_reads ? params.read_length_reads : [],
		params.fastp_extra_args,
		params.skip_adapter_trimming,
		params.save_trimmed_fastq
	)
	ch_multiqc_fastqc_raw     = PREPARE_FASTQ.out.fastqc_raw_zip.collect{it[1]}.ifEmpty{[]}
	ch_multiqc_fastqc_trimmed = PREPARE_FASTQ.out.fastqc_trimmed_zip.collect{it[1]}.ifEmpty{[]}


	ENCODE_CHIP(
		PREPARE_FASTQ.out.fastq,
		PREPARE_GENOME.out.genome_fasta,
		PREPARE_GENOME.out.genome_fai,
		PREPARE_GENOME.out.gensz,
		PREPARE_GENOME.out.bowtie2_index,
		params.multimapping ? params.multimapping : [],
		params.local_mode ?: false,
		params.mapq_threshold ? params.mapq_threshold : [],
		params.chr_filter ? params.chr_filter : [],
		params.pseudorep_seed ? params.pseudorep_seed : 0,
		PREPARE_GENOME.out.blacklist_peaks,
		params.idr_threshold_col ? params.idr_threshold_col : "p.value",
		params.idr_threshold ? params.idr_threshold : 0.05,
		params.mito_chr_name ?: [],
		params.chip_mode ?: "tf",
		params.skip_peak_filtering ?: false,
		params.skip_idr ?: false,
		params.skip_overlap ?: false
	)

	DEEPTOOLS(
		ENCODE_CHIP.out.bam_filtered,
		ENCODE_CHIP.out.bam_filtered_index,
		params.skip_bamcoverage
	)

	METAGENOMICS(
		PREPARE_FASTQ.out.fastq,
		params.sourmash_db ? file(params.sourmash_db) : [],
		params.skip_sourmash,
		params.kraken2_db ? file(params.kraken2_db) : [],
		params.skip_kraken2
	)

	ch_homer_peak_inputs = Channel.empty()
	ch_homer_peak_inputs = ch_homer_peak_inputs
		.mix(ENCODE_CHIP.out.idr_reproducible_peaks)
		.mix(ENCODE_CHIP.out.overlap_reproducible_peaks)

	ch_homer_findmotifsgenome_results = Channel.empty()
	if(!params.skip_homer_findmotifsgenome) {
		HOMER_FINDMOTIFSGENOME(
			ch_homer_peak_inputs,
			PREPARE_GENOME.out.genome_fasta,
			params.homer_motif_lib ? file(params.homer_motif_lib) : []
		)
		HOMER_POSTPROC_FINDMOTIFSGENOME(HOMER_FINDMOTIFSGENOME.out.knownResults)
		ch_homer_findmotifsgenome_results = HOMER_POSTPROC_FINDMOTIFSGENOME.out.tsv
	}

	Channel.topic('encode_reproducibility_json')
		.branch{meta, peak ->
			idr: meta.mode == "idr"
			overlap: meta.mode == "overlap"
		}
		.set{ch_reproducibility_peaks_branched}

	

	Channel.topic('versions')
		.unique()
		.map{ process, name, version -> [process, "  ${name}: \"${version}\""] }
		.groupTuple(by: 0)
		.map{ process, name_versions ->
			def name_versions_collapsed = name_versions.join("\n")
			"${process}:\n${name_versions_collapsed}"
		}
		.set{ch_versions}

	MULTIQC(
		params.multiqc_config ? file(params.multiqc_config) : [],
		ch_multiqc_fastqc_raw,
		Channel.topic('fastp_json').collect{it[1]}.ifEmpty{[]},
		ch_multiqc_fastqc_trimmed,
		ENCODE_CHIP.out.bowtie2_log.collect{it[1]}.ifEmpty{[]},
		ENCODE_CHIP.out.filtered_flagstat.collect{it[1]}.ifEmpty{[]},
		ENCODE_CHIP.out.picard_metrics.collect{it[1]}.ifEmpty{[]},
		Channel.topic('spp_log').collect{it[1]}.ifEmpty{[]},
		METAGENOMICS.out.sourmash_gather_csv.collect{it[1]}.ifEmpty{[]},
		METAGENOMICS.out.kraken2_report.collect{it[1]}.ifEmpty{[]},
		Channel.topic('spp_xcorr').filter{meta,csv -> meta.sample_type in ["sample"]}.collect{it[1]}.ifEmpty{[]},
		ch_reproducibility_peaks_branched.idr.collect{it[1]}.ifEmpty{[]},
		ch_reproducibility_peaks_branched.overlap.collect{it[1]}.ifEmpty{[]},
		DEEPTOOLS.out.fingerprint_metrics.collect{it[1]}.ifEmpty{[]},
		DEEPTOOLS.out.fingerprint_counts.collect{it[1]}.ifEmpty{[]},
		ch_homer_findmotifsgenome_results.collect{it[1]}.ifEmpty{[]},
		ch_versions.collectFile(name: "software_mqc_versions.yml", newLine: true)
	)

	publish:
	MULTIQC.out >> "multiqc"
	HOMER_FINDMOTIFSGENOME.out >> "homer/findMotifsGenome/raw"
	HOMER_POSTPROC_FINDMOTIFSGENOME.out >> "homer/findMotifsGenome/postproc"
	//DEEPTOOLS_BAMCOVERAGE.out.bigwig >> "deeptools/bamCoverage"


}