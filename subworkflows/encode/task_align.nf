include { BOWTIE2_ALIGN    } from '../../modules/local/bowtie2/align/main'


workflow TASK_ALIGN {
	take:
	ch_fastq
	ch_fasta
	ch_bowtie2_index
	multimapping
	local_mode

	main:

	BOWTIE2_ALIGN(
		ch_fastq,
		ch_fasta,
		ch_bowtie2_index,
		[
			multimapping ? "--mm ${multimapping}" : "",
			local_mode ? "--local" : ""
		].join(" ")
	)

	emit:
	bam = BOWTIE2_ALIGN.out.bam

	

}