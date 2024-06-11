include { IDR_PEAKS } from '../../modules/encode/idr/main'

workflow TASK_IDR {
	take:
	ch_narrowPeak
	ch_idr_thresh_col
	ch_idr_threshold

	main:
	ch_narrowPeak
		.map{meta, peaks ->
			def group = [
				sample_id: meta.sample_id,
				group: meta.group,
				single_end: meta.single_end
			]
			[group, meta, peaks]
		}
		.branch{group, meta, peaks ->
			samples: meta.sample_type == "sample"
			pr: meta.sample_type == "pr"
			pooled: meta.sample_type == "pooled"
		}
		.set { ch_narrowPeak_branched }

	ch_narrowPeak_branched.samples
		.combine(ch_narrowPeak_branched.pr, by: 0)
		.map{group, meta,peaks1,meta2,peaks2 -> [meta, peaks1, peaks2]}
		.groupTuple(by: [0,1])
		.map{meta, peaks1, peaks2 ->
		def new_meta = meta.clone()
		new_meta.id = meta.id + "_pr1-vs-pr2"
		new_meta.idr_type = "optimal"
		[new_meta, peaks1, peaks2]
		}
		.set{ch_narrowPeak_sample_idr}
	
	ch_narrowPeak_branched.samples
		.combine(ch_narrowPeak_branched.samples, by: 0)
		//.filter{group, meta, peaks1, meta2, peaks2 -> meta.sample_id != meta2.sample_id}
		.view()
	
	

	Channel.empty()
		.mix(ch_narrowPeak_sample_idr)
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