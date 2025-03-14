process RGREAT_SUMMARIZE {
	tag "${meta.id}"

	cpus { 1 * task.attempt }
	memory { 16.GB * task.attempt }
	time { 2.h * task.attempt }

	container "community.wave.seqera.io/library/r-argparse_r-openxlsx_r-tidyverse:876b48b27e5aac62"
	conda "${moduleDir}/environment.yaml"

	input:
	tuple val(meta), path(results)

	output:
	tuple val(meta), path("*.xlsx"), emit: xlsx

	script:
	def prefix = task.ext.prefix ?: "${meta.id}"
	def args = task.ext.args ?: ""
	"""
	rgreat_summarize.R \\
		--prefix ${prefix} \\
		${args} \\
		${results}
	
	"""

	stub:
	def prefix = task.ext.prefix ?: "${meta.id}"
	"""
	touch ${prefix}.xlsx
	"""
}
