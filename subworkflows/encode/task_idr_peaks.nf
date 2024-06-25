include { IDR_PEAKS } from '../../modules/encode/idr/main'


def create_pooled_idr_pairs(ch_pooled, ch_peaks){
	ch_pooled
		.map{meta, peaks -> 
			def new_meta = [:]
			new_meta.group = meta.group
			new_meta.single_end = meta.single_end
			[new_meta, peaks]
		}
		.combine(
			ch_peaks
				.map{meta, peaks -> 
					def new_meta = [:]
					new_meta.group = meta.group
					new_meta.single_end = meta.single_end
					[new_meta, peaks]
				}
			,
			by: 0
		)
		.combine(
			ch_peaks
				.map{meta, peaks -> 
					def new_meta = [:]
					new_meta.group = meta.group
					new_meta.single_end = meta.single_end
					[new_meta, peaks]
				}
			,
			by: 0
		)
		.filter{meta, peaks1, peaks2, peaks3 -> peaks2 != peaks3}
		.map{meta, peaks1, peaks2, peaks3 ->
			[meta, peaks1, [peaks2,peaks3].sort() ]
		}
		.distinct()
}

def create_sample_idr_pairs(ch_samples, ch_pr){
	ch_samples
		.map{meta, peaks -> 
			def new_meta = [:]
			new_meta.sample_id = meta.sample_id
			new_meta.group = meta.group
			new_meta.single_end = meta.single_end
			[new_meta, peaks]
		}
		.combine(
			ch_pr
				.map{meta, peaks -> 
					def new_meta = [:]
					new_meta.sample_id = meta.sample_id
					new_meta.group = meta.group
					new_meta.single_end = meta.single_end
					[new_meta, peaks]
				}
			,
			by: [0]
		)
		.groupTuple(by: [0,1])
		.map{meta, peaks1, peaks2 ->
			[meta, peaks1, peaks2.sort()]
		}
}


workflow TASK_IDR {
	take:
	ch_narrowPeak
	ch_idr_thresh_col
	ch_idr_threshold

	main:
	
	ch_narrowPeak
		.branch{meta, ta ->
			sample: meta.sample_type == "sample"
			pr1: meta.sample_type == "pr1"
			pr2: meta.sample_type == "pr2"
			sample_pooled: meta.sample_type == "sample_pooled"
			pr1_pooled: meta.sample_type == "pr1_pooled"
			pr2_pooled: meta.sample_type == "pr2_pooled"
		}
		.set{ch_peak_branched}


	ch_idr_inputs = Channel.empty()

	ch_peak_branched.sample_pooled
		.map{meta,peak ->
			def group_criteria = [group: meta.group, single_end: meta.single_end]
			[group_criteria, peak]
		}
		.join(
			ch_peak_branched.pr1_pooled
				.map{meta,peak ->
				def group_criteria = [group: meta.group, single_end: meta.single_end]
				[group_criteria, peak]
			},
			by: 0
		)
		.join(
			ch_peak_branched.pr2_pooled
				.map{meta,peak ->
				def group_criteria = [group: meta.group, single_end: meta.single_end]
				[group_criteria, peak]
			},
			by: 0
		)
		.map{meta, peak1, peak2, peak3 ->
			def new_id = meta.group + "_pooled_pr1-vs-pr2"
			[[id: new_id] + meta, peak1, [peak2, peak3]]
		}
		.set {ch_idr_pooled_vs_pr}
	
	ch_peak_branched.sample
		.map{meta,peak ->
			def group_criteria = [sample_id: meta.sample_id, group: meta.group, single_end: meta.single_end]
			[group_criteria, peak]
		}
		.join(
			ch_peak_branched.pr1
				.map{meta,peak ->
				def group_criteria = [sample_id: meta.sample_id, group: meta.group, single_end: meta.single_end]
				[group_criteria, peak]
			},
			by: 0
		)
		.join(
			ch_peak_branched.pr1
				.map{meta,peak ->
				def group_criteria = [sample_id: meta.sample_id, group: meta.group, single_end: meta.single_end]
				[group_criteria, peak]
			},
			by: 0
		)
		.map{meta, peak1, peak2, peak3 ->
			def new_id = meta.sample_id + "_pr1-vs-pr2"
			[[id: new_id] + meta, peak1, [peak2, peak3]]
		}
		.set {ch_idr_sample_vs_pr}

	//create_pooled_idr_pairs(ch_narrowPeak_branched.pooled, ch_narrowPeak_branched.pr).view()
	//.set {ch_narrowPeak_pooled_conserv_idr}
		
	//ch_narrowPeak_pooled_conserv_idr.view()
	



	Channel.empty()
	//	.mix(ch_narrowPeak_sample_idr)
		.set{ch_idr_input}
	
	IDR_PEAKS(
		ch_idr_input,
		ch_idr_thresh_col,
		ch_idr_threshold
	)
	IDR_PEAKS.out.narrowPeak
		.map{meta, peaks -> 
			def new_meta = meta.clone()
			new_meta.peak_number = peaks.countLines()
			[new_meta, peaks]
		}

}