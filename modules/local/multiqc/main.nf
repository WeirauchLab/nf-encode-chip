process MULTIQC {
	tag "multiqc_report"

	conda "${moduleDir}/environment.yml"
	container "community.wave.seqera.io/library/multiqc:1.22.1--4886de6095538010"

	input:
	path multiqc_config
	path "data/fastqc/raw/*"
	path "data/fastp/*"
	path "data/fastqc/trimmed/*"
	path "data/bowtie2_align/*"
	path "data/picard_markduplicates/*"
	path "data/spp/*"
	path "data/sourmash/gather/*"

	output:
	path "multiqc_report.html", optional: false, emit: html
    path "*_plots"            , optional:true  , emit: plots
	path "*_data"             , optional:true  , emit: data

	script:
	def args = task.ext.args ?: ""
	"""
	multiqc -f -o . -n multiqc_report "data/"
	"""
}