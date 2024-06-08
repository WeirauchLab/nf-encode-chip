

include { TASK_ALIGN  } from '../subworkflows/encode/task_align.nf'
include { TASK_FILTER } from '../subworkflows/encode/task_filter.nf'

workflow CHIP {
	take:
	ch_fastq
	bowtie2_index
	genome_fasta
	genome_fai
	rm_chrs_regex
	
	main:

	// align the reads to the genome
	TASK_ALIGN(
		ch_fastq,
		bowtie2_index
	)

	// filter alignments for quality / dup
	TASK_FILTER(
		TASK_ALIGN.out.bam,
		genome_fasta,
		genome_fai,
		rm_chrs_regex
	)

}