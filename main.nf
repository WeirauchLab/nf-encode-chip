nextflow.preview.output = true
nextflow.preview.topic = true

include { CHIPSEQ } from './workflows/chipseq'

workflow {
	main:
	CHIPSEQ()

	publish:
	CHIPSEQ.out.rgreat_ext_tss >> "great"
	CHIPSEQ.out.rgreat_csv >> "great"
	CHIPSEQ.out.rgreat_summary_xlsx >> "great"
}

output {
	'encode/tagAlign' {
		index {
			path 'tagAlign_index.csv'
		}
	}
	'encode/alignments/raw' {
		index {
			path 'alignments_raw_index.csv'
		}
	}
	'encode/alignments/filtered' {
		index {
			path 'alignments_filtered_index.csv'
		}
	}
	'encode/peaks/macs2/raw' {
		index {
			path 'macs2_raw_index.csv'
		}
	}
	'encode/peaks/macs2/filtered' {
		index {
			path 'macs2_filtered_index.csv'
		}
	}
	'encode/macs2/signal' {
		index {
			path 'macs2_signal_index.csv'
		}
	}
	'encode/macs2/idr' {
		index {
			path 'macs2_idr_index.csv'
		}
	}
	'great' {
		index {
			path 'great_index.json'
			mapper { meta, path ->
				def output = meta.clone()
				output.mode = params.great_mode ?: null
				output.extension = params.great_extension ?: null
				output.basal_upstream = params.great_basal_upstream ?: null
				output.basal_downstream = params.great_basal_downstream ?: null
				output.ext_args = params.extend_tss_ext_args ?: null
				[output, path]
			}
		}
	}
}
