process POOL_TA {
	tag "${meta.id}"
	cpus   = {1 * task.attempt}
	memory = {16.GB * task.attempt}
	time   = {2.h * task.attempt}

	conda "${moduleDir}/environment.yml"
	//container ""

	input:
	tuple val(meta), path(tagAlign)

	output:
	tuple val(meta), path("*.tagAlign.gz"), optional: false, emit: tagAlign

	script:
	def prefix = task.ext.prefix ?: "${meta.id}"
	def args = task.ext.args ?: ""
	"""
	cat ${tagAlign} > ${prefix}.tagAlign.gz
	"""
}