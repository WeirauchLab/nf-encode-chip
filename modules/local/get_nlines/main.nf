process GET_NLINES {
	tag "${meta.id}"
	cpus   = {1 * task.attempt}
	memory = {16.GB * task.attempt}
	time   = {2.h * task.attempt}

	//conda "${moduleDir}/environment.yml"
	//container ""

	input:
	tuple val(meta), path(tagalign)

	output:
	tuple val(meta), path("*.nlines"), optional: false, emit: nlines

	script:
	def prefix = task.ext.prefix ?: "${meta.id}"
	def args = task.ext.args ?: ""
	"""
	zcat ${tagalign} | wc -l > ${prefix}.nlines
	"""
}