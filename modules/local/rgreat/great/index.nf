process RGREAT_GREAT {
	tag "${meta.id}"

	cpus { 1 * task.attempt }
	memory { 16.GB * task.attempt }
	time { 2.h * task.attempt }

	container "community.wave.seqera.io/library/bioconductor-plyranges_bioconductor-rgreat_bioconductor-rtracklayer_r-argparse_r-tidyverse:c018eae7915254a1"
	conda "${moduleDir}/environment.yaml"

	input:
	tuple val(meta), path(peak), path(term_lib)
	tuple val(meta2), path(tss)

	output:
	tuple val(meta), path("*.csv"), emit: csv

	script:
	def prefix = task.ext.prefix ?: "${meta.id}"
	def args = task.ext.args ?: ""
	"""
	rgreat_great.R \\
		--bed ${peak} \\
		--tss ${tss} \\
		--gmt ${term_lib} \\
		--prefix ${prefix} \\
		${args}
	"""

	stub:
	def prefix = task.ext.prefix ?: "${meta.id}"
	"""
	touch ${prefix}.csv
	"""
}
