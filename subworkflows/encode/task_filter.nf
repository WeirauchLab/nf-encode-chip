include { RM_LOWQ_READS         } from '../../modules/encode/rm_lowq_reads/main'
include { PICARD_MARKDUPLICATES } from '../../modules/local/picard/markDuplicates/main'
include { RM_DUPLICATES         } from '../../modules/encode/rm_dup/main'
include { SAMTOOLS_INDEX        } from '../../modules/local/samtools/index/main'

workflow TASK_FILTER {
	take:
	ch_bam
	ch_mapq_threshold
	ch_fasta
	ch_fai
	ch_chr_filter

	main:

	RM_LOWQ_READS(
		ch_bam,
		ch_mapq_threshold
	)

	PICARD_MARKDUPLICATES(
		RM_LOWQ_READS.out.bam
	)

	RM_DUPLICATES(
		PICARD_MARKDUPLICATES.out.bam
	)

	// TODO: RM chromosomes?

	SAMTOOLS_INDEX(
		RM_DUPLICATES.out.bam
	)

	// TODO: publish channels
	publish:
	RM_DUPLICATES.out.bam  >> "bam"
	SAMTOOLS_INDEX.out.bai >> "bam"

	emit:
	bam = RM_DUPLICATES.out.bam
	bai = SAMTOOLS_INDEX.out.bai

}