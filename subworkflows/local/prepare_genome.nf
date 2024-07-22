
include { GZIP_GUNZIP as GUNZIP_GENOME        } from '../../modules/local/gzip/gunzip/main'
include { GZIP_GUNZIP as GUNZIP_GTF           } from '../../modules/local/gzip/gunzip/main'
include { GZIP_GUNZIP as GUNZIP_BL_PEAKS      } from '../../modules/local/gzip/gunzip/main'
include { SAMTOOLS_FAIDX                      } from '../../modules/local/samtools/faidx/main'
include { SAMTOOLS_FAIDX_CHR                  } from '../../modules/local/samtools/faidx_chr/main'
include { BOWTIE2_BUILD                       } from '../../modules/local/bowtie2/build/main'
include { UNTAR as UNTAR_BOWTIE2_INDEX        } from '../../modules/nf-core/untar/main'

workflow PREPARE_GENOME {
	take:
	genome_fasta     // string
	gtf              // string
	gensz            // int or string
	bowtie2_index    // string
	blacklist_peaks  // string
	save_reference   // boolean

	main:
	
	// unzip genome fasta
	if (genome_fasta.endsWith('.gz')){
		GUNZIP_GENOME([[id: file(genome_fasta).simpleName ], file(genome_fasta) ])
		ch_genome_fasta = GUNZIP_GENOME.out.gunzip
	} else {
		ch_genome_fasta = channel.value([ [id: file(genome_fasta).simpleName ], file(genome_fasta) ])
	}

	// unzip gtf file if necessary
	if (!gtf){
		ch_gtf = channel.value([[:],[]])
	} else if (gtf.endsWith('.gz')){
		GUNZIP_GTF([[id: file(gtf).simpleName ], file(gtf) ])
		ch_gtf = GUNZIP_GTF.out.gunzip
	} else {
		ch_gtf = channel.value([ [id: file(gtf).simpleName ], file(gtf) ])
	}

	// generate chr sizes file if necessary
	SAMTOOLS_FAIDX(ch_genome_fasta)
	ch_genome_fai  = SAMTOOLS_FAIDX.out.fai

	if (!gensz) {
		ch_genome_fai
			.map{ it[1] }
			.splitCsv(sep: '\t')
			.map {it -> it[1].toInteger() }
			.reduce {x,y -> x + y}
			.set {ch_gensz}
	} else {
		ch_gensz = channel.value(gensz)
	}

	// ----------------------------------------------------------------------- //
	// Prepare bowtie2 index
	// ----------------------------------------------------------------------- //

	// TODO: The pre-built indices need to be reassessed

	if (!bowtie2_index) {
		BOWTIE2_BUILD(ch_genome_fasta)
		ch_bowtie2_index = BOWTIE2_BUILD.out.index
	} else if ( bowtie2_index.endsWith('.tar.gz') || bowtie2_index.endsWith('.tar') ) {
		UNTAR_BOWTIE2_INDEX([[id: file(bowtie2_index).simpleName ], file(bowtie2_index) ])
		ch_bowtie2_index = UNTAR.out.untar
	} else {
		ch_bowtie2_index = channel.value([ [id: file(bowtie2_index).simpleName ], file(bowtie2_index) ])
	}

	if(blacklist_peaks && blacklist_peaks.endsWith(".gz")) {
		GUNZIP_BL_PEAKS([[id: file(blacklist_peaks).simpleName ], file(blacklist_peaks) ])
		ch_blacklist_peaks = GUNZIP_BL_PEAKS.out.gunzip
	} else if (blacklist_peaks) {
		ch_blacklist_peaks = channel.value([ [id: file(blacklist_peaks).simpleName ], file(blacklist_peaks) ])
	} else {
		ch_blacklist_peaks = channel.value([[:],[]])
	}

	emit:
	genome_fasta       = ch_genome_fasta    // channel: [ val(meta), path(genome_fasta) ]
	genome_fai         = ch_genome_fai      // channel: [ val(meta), path(fai) ]
	gensz              = ch_gensz           // int or string
	bowtie2_index      = ch_bowtie2_index   // channel: [ val(meta), path(bowtie2_index) ]
	blacklist_peaks	   = ch_blacklist_peaks // channel: [ val(meta), path(blacklist_peaks) ]
	gtf                = ch_gtf             // channel: [ val(meta), path(gtf) ]

	publish:
	ch_bowtie2_index >> (save_reference ? "genome/bowtie2" : null)
}