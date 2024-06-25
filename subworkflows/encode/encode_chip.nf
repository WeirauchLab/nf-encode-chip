include { TASK_ALIGN          } from "./task_align"
include { TASK_FILTER         } from "./task_filter"
include { TASK_MACS2          } from "./task_macs2"
include { TASK_POSTPROC_PEAKS } from "./task_postproc_peaks"
include { TASK_IDR            } from "./task_idr_peaks"

include { BAM_TO_TA         } from "../../modules/encode/bam_to_ta/main"
include { CREATE_PSEUDOREPS } from "../../modules/encode/create_pseudoreplicates/main"
include { RUN_SPP           } from "../../modules/local/phantompeakqualtools/run_spp/main"
include { EXTRACT_XCOR      } from "../../modules/local/phantompeakqualtools/extract_xcor/main"
include { CAT_FILES         } from "../../modules/local/cat_files/main"

workflow ENCODE_CHIP {
	take:
	ch_fastq
	ch_fasta
	ch_fai
	ch_gensz
	ch_bowtie2_index
	ch_bowtie2_mito_index
	multimapping
	local_mode
	mapq_threshold
	ch_chr_filter
	pseudorep_seed
	ch_blacklist_peaks
	ch_idr_threshold_col
	ch_idr_threshold

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
	ch_tagalign = BAM_TO_TA.out.tagAlign

	if(true){
		CREATE_PSEUDOREPS(
			ch_tagalign,
			pseudorep_seed
		)

		ch_tagalign
			.mix(
				CREATE_PSEUDOREPS.out.pr1
					.map{meta, tagalign ->
						def new_meta = meta.clone()
						new_meta.sample_type = "pr1"
						new_meta.id = new_meta.id + "_pr1"
						[ new_meta, tagalign ]
					}
			)
			.mix(
				CREATE_PSEUDOREPS.out.pr2
					.map{meta, tagalign ->
						def new_meta = meta.clone()
						new_meta.sample_type = "pr2"
						new_meta.id = new_meta.id + "_pr2"
						[ new_meta, tagalign ]
					}
			)
			.set { ch_tagalign }
	}

	ch_tagalign
		.map{meta, ta ->
			def group_meta = [group: meta.group, single_end: meta.single_end, sample_type: meta.sample_type]
			[group_meta, ta]
		}
		.groupTuple(by: 0)
		.filter{meta, ta -> ta.size() > 1}
		.map{meta, ta -> 
			def new_meta = meta.clone()
			new_meta.sample_type = meta.sample_type + "_pooled"
			new_meta.id = [new_meta.group,new_meta.sample_type].join("_") 
			[new_meta, ta]
		}
		.set { ch_pool_ta_input }

	CAT_FILES(ch_pool_ta_input,"tagAlign.gz")

	ch_tagalign = ch_tagalign.mix(CAT_FILES.out.output)
	
	
	// run SPP on processed tagAligns to get fragment length
	RUN_SPP(
		ch_tagalign,
		"tf",
		"chrM"
	)
	EXTRACT_XCOR(RUN_SPP.out.rdata)

	RUN_SPP.out.spp
		.join(ch_tagalign, by: 0)
		.map{meta, spp, ta ->
			def new_meta = meta.clone()
			new_meta.frag_len = spp.readLines()[0].split("\t")[2] - ~/,.*/
			[ new_meta, ta ]
		}
		.set { ch_processed_tagalign }

	TASK_MACS2(
		ch_processed_tagalign,
		ch_fai,
		ch_gensz
	)

	TASK_POSTPROC_PEAKS(
		TASK_MACS2.out.narrowPeak,
		ch_blacklist_peaks,
		ch_chr_filter
	)

	TASK_IDR(
		TASK_POSTPROC_PEAKS.out.narrowPeak,
		ch_idr_threshold_col,
		ch_idr_threshold
	)


	publish:
	BAM_TO_TA.out.tagAlign >> "tagAlign/"

	emit:
	tagAlign = BAM_TO_TA.out.tagAlign
	dedup_bam = TASK_FILTER.out.bam
	dedup_bai = TASK_FILTER.out.bai
	xcor_csv = EXTRACT_XCOR.out.csv

}