process CAT_FILES {
	tag "${meta.id}"

	conda "${moduleDir}/environment.yml"
	//container ""

	input:
	tuple val(meta), path(files)
	val extension

	output:
	tuple val(meta), path("*.$extension"), optional: false, emit: output

	script:
	def prefix = task.ext.prefix ?: "${meta.id}"
	def args = task.ext.args ?: ""
	"""
	cat ${files} > ${prefix}.${extension}
	"""
}