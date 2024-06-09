include { TASK_ALIGN } from "./task_align"
include { TASK_FILTER } from "./task_filter"

include { BAM_TO_TA         } from "../../modules/encode/bam_to_ta/main"
include { CREATE_PSEUDOREPS } from "../../modules/encode/create_pseudoreplicates/main"
include { RUN_SPP           } from "../../modules/local/phantompeakqualtools/run_spp/main"
include { EXTRACT_XCOR      } from "../../modules/local/phantompeakqualtools/extract_xcor/main"

workflow ENCODE_CHIP {
	take:
	ch_fastq
	ch_fasta
	ch_fai
	ch_bowtie2_index
	ch_bowtie2_mito_index
	multimapping
	local_mode
	mapq_threshold
	ch_chr_filter
	pseudorep_seed

	main:

	TASK_ALIGN(
		ch_fastq,
		ch_fasta,
		ch_bowtie2_index,
		multimapping,
		local_mode
	)

	TASK_FILTER(
		TASK_ALIGN.out.bam,
		mapq_threshold,
		ch_fasta,
		ch_fai,
		ch_chr_filter
	)

	BAM_TO_TA(
		TASK_FILTER.out.bam
	)

	RUN_SPP(
		BAM_TO_TA.out.tagAlign,
		"tf",
		"chrM"
	)

	EXTRACT_XCOR(RUN_SPP.out.rdata)


	BAM_TO_TA.out.tagAlign
		.map{meta, tagalign ->
			[ meta.group, meta, tagalign ]
		}
		.groupTuple(by: 0)
		.branch{group, meta, tagalign ->
			single: tagalign.size() == 1
				return [meta[0], tagalign]
			multiple: tagalign.size() > 1
				return [[id: group + "_pooled"], tagalign]
		}
		.set { ch_tagalign_branched }
	
	ch_tagalign_branched.single
		.view()


	CREATE_PSEUDOREPS(
		BAM_TO_TA.out.tagAlign,
		pseudorep_seed
	)

	//CREATE_PSEUDOREPS.out.tagAlign.view()


	publish:
	BAM_TO_TA.out.tagAlign >> "tagAlign/"

	emit:
	tagAlign = BAM_TO_TA.out.tagAlign

}