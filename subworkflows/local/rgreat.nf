include { EXTEND_TSS } from '../../modules/local/rgreat/extend_tss/index'
include { RGREAT_GREAT } from '../../modules/local/rgreat/great/index'
include { RGREAT_SUMMARIZE } from '../../modules/local/rgreat/summarize/index'

workflow RGREAT {
	take:
	ch_bed // channel [ val(meta), path(bed) ]
	term_libraries // channel [ [id:], file(gmt) ]
	ch_gtf // channel [ val(meta), path(gtf) ]
	ch_fai // channel [ val(meta), path(chrsizes) ]

	main:

	// Create an extended TSS file to use for the next steps
	EXTEND_TSS(ch_gtf, ch_fai)

	ch_bed
		.combine(term_libraries)
		.map { meta_bed, bed, meta_term, term ->
			def new_meta = meta_term + meta_bed
			new_meta.id = [meta_bed.id, meta_term.id].join("_")
			[new_meta, bed, term]
		}
		.set { ch_great_inputs }

	RGREAT_GREAT(ch_great_inputs, EXTEND_TSS.out.rds)
	RGREAT_GREAT.out.csv
		.map { meta, csv ->
			def new_meta = meta.subMap("id", "group", "reproducibility_mode", "reproducibility_class")
			new_meta.id = [meta.group, meta.reproducibility_mode, meta.reproducibility_class, "great"].join("_")
			[new_meta, csv]
		}
		.groupTuple(by: 0)
		.set { ch_summary_input }

	RGREAT_SUMMARIZE(ch_summary_input)

	emit:
	ext_tss = EXTEND_TSS.out.rds
	csv = RGREAT_GREAT.out.csv
	summary_xlsx = RGREAT_SUMMARIZE.out.xlsx
}
