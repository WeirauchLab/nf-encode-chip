nextflow.preview.output = true
nextflow.preview.topic  = true

include { CHIPSEQ } from './workflows/chipseq'

workflow {
	CHIPSEQ()

	ch_versions = channel
		.topic("versions")
		.unique()

	publish:
	ch_versions >> 'versions/'
}

output {
    directory "$params.outdir"


}