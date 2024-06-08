nextflow.preview.output = true

include { CHIPSEQ } from './workflows/chipseq'

workflow {
	CHIPSEQ()
}

output {
    directory "$params.outdir"
}