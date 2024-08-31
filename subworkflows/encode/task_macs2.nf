include { MACS2_CALLPEAK         } from '../../modules/encode/macs2/callpeak'
include { MACS2_BDGCMP           } from '../../modules/encode/macs2/bdgcmp'

workflow TASK_MACS2 {
	take:
	ch_tagalign // [ val(meta), path(tagAlign) ]
	ch_faidx    // [ val(meta), path(faidx) ]
	ch_gensz	// integer or string
	max_peaks   // integer

	main:

	ch_narrowPeak  = Channel.empty()
	ch_fc_bigwig   = Channel.empty()
	ch_pval_bigwig = Channel.empty()

	//ch_tagalign.view()
	//	| filter {meta, ta -> meta.sample_type == "pooled"}
	//	//| branch {meta, ta ->
	//	//	pooled: !meta.pr_rep
	//	//	pooled_pr: meta.pr_rep
	//	//}
	//	| set{ch_pooled_ta}

	ch_tagalign
		| branch{meta, ta ->
			no_ctrl: !meta.control_id
				return [meta, ta, []]
			ctrl_pooled:  meta.sample_type in ["sample", "pr"] && meta.control_type.contains("pooled")
				return [ [meta.control_id, meta.pr_rep, "pooled"], meta, ta ]
			ctrl_sample: meta.sample_type in ["sample", "pr"] && meta.control_type.contains("sample")
				return [ [meta.control_id, meta.pr_rep, meta.sample_type], meta, ta ]
			pooled_ctrl_group: meta.sample_type == "pooled" && meta.control_type.contains("pooled")
				return [ meta.control_id, meta, ta ]
			pooled_ctrl_sample: meta.sample_type == "pooled" && meta.control_type.contains("sample")
				return [ meta.control_id, meta, ta ]
		}
		| set{ch_tagalign_branches}

	ch_tagalign_branches.ctrl_sample
		| join(
			ch_tagalign.map{meta, ta -> [[meta.sample_id, meta.pr_rep, meta.sample_type], ta]},
			by: 0
		)
		| map{ key, meta, ta, ctrl -> [meta, ta, ctrl] }
		| set{ch_tagalign_ctrl_sample}
	ch_tagalign_branches.ctrl_pooled
		| join(
			ch_tagalign.map{meta, ta -> [[meta.group, meta.pr_rep, meta.sample_type], ta]},
			by: 0
		)
		| map{ key, meta, ta, ctrl -> [meta, ta, ctrl] }
		| set{ch_tagalign_ctrl_pooled}

	ch_tagalign_branches.pooled_ctrl_sample
		| transpose(by: 0)
		| join(
			ch_tagalign.map{ meta, ta -> [meta.sample_id, meta.group] }
		)
		| distinct()
		| map{control_id, meta, ta, group -> [[group, meta.pr_rep, "pooled"], meta, ta]}
		| join(
			ch_tagalign.map{meta, ta -> [[meta.group, meta.pr_rep, meta.sample_type], ta]},
			by: 0
		)
		| map{key, meta, ta, ctrl -> [meta, ta, ctrl]}
		| set{ch_tagalign_ctrl_pooled_sample}

	ch_tagalign_branches.pooled_ctrl_group
		| transpose(by: 0)
		| map{ ctrl_group, meta, ta -> [[ctrl_group, meta.pr_rep, "pooled"], meta, ta] }
		| join(
			ch_tagalign.map{ meta, ta -> [[meta.group, meta.pr_rep, meta.sample_type], ta] }
		)
		| distinct()
		| map{key, meta, ta, ctrl -> [meta, ta, ctrl]}
		| set{ch_tagalign_ctrl_pooled_group}

	ch_tagalign_branches.no_ctrl
		| mix(ch_tagalign_ctrl_sample)
		| mix(ch_tagalign_ctrl_pooled)
		| mix(ch_tagalign_ctrl_pooled_sample)
		| mix(ch_tagalign_ctrl_pooled_group)
		| set{ch_macs2_input}

	MACS2_CALLPEAK(
		ch_macs2_input,
		ch_faidx,
		ch_gensz,
		max_peaks
	)
	ch_narrowPeak = MACS2_CALLPEAK.out.narrowPeak

	MACS2_CALLPEAK.out.treat_pileup
		.join(MACS2_CALLPEAK.out.control_lambda, by: 0)
		.join(ch_tagalign, by: 0)
		.map {meta, treat, control, ta ->
			def new_meta = meta.clone()
			new_meta.nreads = ta.countLines()
			new_meta.rpm_scale = new_meta.nreads / 1000000
			[new_meta, treat, control, ta, new_meta.rpm_scale]
		}
		.set{ch_bdgcmp_input}

	MACS2_BDGCMP(
		ch_bdgcmp_input,
		ch_faidx
	)
	ch_fc_bigwig   = MACS2_BDGCMP.out.fc_bigwig
	ch_pval_bigwig = MACS2_BDGCMP.out.pval_bigwig


	publish:
	ch_narrowPeak   >> "encode/macs2/raw"
	ch_fc_bigwig    >> "encode/macs2/signal"
	ch_pval_bigwig  >> "encode/macs2/signal"

	emit:
	narrowPeak  = ch_narrowPeak
	fc_bigwig   = ch_fc_bigwig
	pval_bigwig = ch_pval_bigwig


}