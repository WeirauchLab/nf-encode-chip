include { BAM_TO_TA         } from "../../modules/encode/bam_to_ta/main"
include { CREATE_PSEUDOREPS } from "../../modules/encode/create_pseudoreplicates/main"
include { CAT_FILES         } from "../../modules/local/cat_files/main"

workflow TASK_TAGALIGN {
	take:
	ch_bam                 // [ val(meta), path(bam) ]
	pseudorep_seed         // integer
	skip_pseudoreplication // boolean
	save_tagAlign          // boolean

	main:

	ch_tagalign = Channel.empty()

	BAM_TO_TA(ch_bam)
	ch_tagalign = BAM_TO_TA.out.tagAlign

	if(!skip_pseudoreplication){
		CREATE_PSEUDOREPS(
			ch_tagalign,
			pseudorep_seed
		)
		CREATE_PSEUDOREPS.out.tagAlign
			.transpose()
			.map { meta, ta ->
				def new_meta = meta.clone()
				new_meta.sample_type = "pr"
				def (pr_full, pr_rep) = (ta.toString() =~ /.*pr(\d+)\.tagAlign\.gz$/)[0]
				new_meta.pr_rep = "pr${pr_rep}"
				new_meta.id = "${new_meta.sample_id}_${new_meta.pr_rep}"
				[ new_meta, ta ]
			}
			.set { ch_pr_ta }

		ch_tagalign
			| mix(ch_pr_ta)
			| map {meta, ta ->
				def new_meta = meta.clone()
				new_meta.pr_rep = new_meta.pr_rep ?: []
				[ new_meta, ta ]
			}
			| set { ch_tagalign }
	}

	// generate pooled tagAlign
	ch_tagalign
		| branch {meta, ta -> 
			no_ctrl: !meta.control_id
				return [meta + [control_type: []], ta]
			ctrl: meta.control_id
				return [meta.control_id, meta, ta]
		}
		| set{ch_tagalign_ctrl_branches}

	ch_tagalign_ctrl_branches.ctrl
		| join(
			ch_tagalign.map{meta, ta -> [meta.sample_id]},
			by: 0
		)
		| map{control_id, meta, ta -> [meta, ta, "sample"]}
		| set{ch_tagalign_ctrl_sample_annotated}
	
	ch_tagalign_ctrl_branches.ctrl
		| join(
			ch_tagalign.map{meta, ta -> [meta.group]},
			by: 0
		)
		| map{control_id, meta, ta -> [meta, ta, "pooled"]}
		| set{ch_tagalign_ctrl_group_annotated}
	

	ch_tagalign_ctrl_sample_annotated
		| mix(ch_tagalign_ctrl_group_annotated)
		| groupTuple(by: [0,1])
		| map {meta, ta, control_types -> 
			[meta + [control_type: control_types], ta]
		}
		| mix(ch_tagalign_ctrl_branches.no_ctrl)
		| set{ch_tagalign}

	ch_tagalign
		| map{meta, ta -> 
			[
				meta.subMap("group", "single_end", "chip_mode","sample_type","pr_rep"),
				meta.subMap("sample_id","control_id","control_type"),
				ta
			]
		}
		| groupTuple(by: 0)
		| map { meta, sample_meta, ta_list ->
			def new_meta = meta.clone()
			new_meta.sample_type = "pooled"
			//[id: [new_meta.group,new_meta.sample_type,]]
			new_meta.sample_id  = sample_meta.collect{it.sample_id}.flatten().unique()
			new_meta.control_id = sample_meta.collect{it.control_id}.flatten().unique()
			new_meta.control_type = sample_meta.collect{it.control_type}.flatten().unique()
			def new_meta_id = new_meta.pr_rep ? [new_meta.group,new_meta.sample_type,new_meta.pr_rep] : [new_meta.group,new_meta.sample_type]
			new_meta_id = new_meta_id.join("_")
			[
				[id: new_meta_id] + new_meta,
				ta_list
			]
		}
		| filter {meta, ta_list -> ta_list.size() > 1}
		| set{ch_pooled_ta_input}


	CAT_FILES(ch_pooled_ta_input,"tagAlign.gz")
	ch_tagalign = ch_tagalign.mix(CAT_FILES.out.output)

	publish:
	ch_tagalign >> (save_tagAlign ? "encode/tagAlign" : null)

	emit:
	tagAlign = ch_tagalign

}