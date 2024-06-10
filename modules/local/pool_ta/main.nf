process POOL_TA {
	tag "${meta.id}"

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