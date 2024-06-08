include { TASK_ALIGN } from "./task_align"

workflow ENCODE_CHIP {
	take:
	ch_fastq
	ch_fasta
	ch_bowtie2_index
	ch_bowtie2_mito_index
	multimapping
	local_mode

	main:

	TASK_ALIGN(
		ch_fastq,
		ch_fasta,
		ch_bowtie2_index,
		multimapping,
		local_mode
	)


	//publish:

}