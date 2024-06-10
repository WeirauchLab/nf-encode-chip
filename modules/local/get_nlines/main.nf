process GET_NLINES {
	tag "${meta.id}"

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