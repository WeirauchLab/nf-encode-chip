
include { GZIP_GUNZIP as GUNZIP_GENOME        } from '../../modules/local/gzip/gunzip/main'
include { GZIP_GUNZIP as GUNZIP_BL_PEAKS      } from '../../modules/local/gzip/gunzip/main'
include { SAMTOOLS_FAIDX                      } from '../../modules/local/samtools/faidx/main'
include { SAMTOOLS_FAIDX_CHR                  } from '../../modules/local/samtools/faidx_chr/main'
include { BOWTIE2_BUILD                       } from '../../modules/local/bowtie2/build/main'

workflow PREPARE_GENOME {
	take:
	genome_fasta
	chrom_sizes
	gensz
	bowtie2_index
	blacklist_peaks

	main:
	
	// unzip genome fasta
	if (genome_fasta.endsWith('.gz')){
		GUNZIP_GENOME([[id: file(genome_fasta).simpleName ], file(genome_fasta) ])
		ch_genome_fasta = GUNZIP_GENOME.out.gunzip
	} else {
		ch_genome_fasta = channel.value([ [id: file(genome_fasta).simpleName ], file(genome_fasta) ])
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

	// genome
	// TODO: The pre-built indices need to be reassessed
	if (!bowtie2_index) {
		BOWTIE2_BUILD(ch_genome_fasta)
		ch_bowtie2_index = BOWTIE2_BUILD.out.index
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

	

	// TODO: update output path comments
	emit:
	genome_fasta       = ch_genome_fasta // path(fasta)
	genome_fai         = ch_genome_fai
	gensz              = ch_gensz        // int or string
	bowtie2_index      = ch_bowtie2_index // path(bowtie2_index)
	blacklist_peaks	   = ch_blacklist_peaks // [ val(meta), path(blacklist_peaks) ]
}