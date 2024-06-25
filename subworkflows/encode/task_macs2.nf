include { MACS2_CALLPEAK } from '../../modules/encode/macs2/callpeak'
include { MACS2_BDGCMP } from '../../modules/encode/macs2/bdgcmp'

workflow TASK_MACS2 {
	take:
	ch_tagalign
	ch_fai
	ch_gensz

	main:

	ch_tagalign.collect{meta, ta -> [ [meta.id,ta] ]}.set{list_tagalign}

	ch_tagalign
		.map{meta, ta -> 
			if(meta.control_id){
				def control_entry = list_tagalign.findAll{it[0].id == meta.control_id}
				if(control_entry) {
					[meta, ta, control_entry[1]]
				}
			} else {
				[meta, ta, []]
			}
		}
		.set {ch_macs2_input}

	MACS2_CALLPEAK(
		ch_macs2_input,
		ch_fai,
		ch_gensz,
		0,
		[
			"-f BED",
			"-p 0.05",
			"--nomodel",
			"--shift 0",
			"--keep-dup all",
			"-B",
			"--SPMR"
		].join(" ")
	)

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
		ch_fai
	)

	publish:
		MACS2_CALLPEAK.out.narrowPeak >> "encode/peaks/raw"
		MACS2_BDGCMP.out              >> "encode/macs2/signal"
	
	emit:
		narrowPeak = MACS2_CALLPEAK.out.narrowPeak
}