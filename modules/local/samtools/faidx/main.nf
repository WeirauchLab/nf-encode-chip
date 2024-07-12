process SAMTOOLS_FAIDX {
	tag "${meta.id}"
	cpus   = {1 * task.attempt}
	memory = {16.GB * task.attempt}
	time   = {2.h * task.attempt}

	conda "${moduleDir}/environment.yml"
	//container ""

	input:
	tuple val(meta), path(fasta)

	output:
	tuple val(meta), path("*.fai")       , optional: false, emit: fai
	eval "samtools --version | head -n 1", optional: false, emit: version

	script:
	def prefix = task.ext.prefix ?: "${meta.id}"
	def args = task.ext.args ?: ""
	"""
	samtools faidx ${fasta}
	"""
}