process CHR_SIZES {
	tag "${meta.id}"

	conda "${moduleDir}/environment.yml"
	//container ""

	input:
	tuple val(meta), path(fai)

	output:
	tuple val(meta), path("*.chrsizes"), optional: false, emit: chr_sizes
	eval "awk --version | head -n 1", optional: false, emit: version
	val "$task.cpus", emit: task_name

	script:
	def prefix = task.ext.prefix ?: "${meta.id}"
	def args = task.ext.args ?: ""
	"""

	awk '{print \$1"\\t"\$2}' ${fai} > ${prefix}.chrsizes

	"""
}