process SAMTOOLS_INDEX {
	tag "${meta.id}"

	conda "${moduleDir}/environment.yml"
	//container ""

	input:
	tuple val(meta), path(bam)

	output:
	tuple val(meta), path("*.bai")       , optional: true, emit: bai
	eval "samtools --version | head -n 1", optional: false, emit: version

	script:
	def prefix = task.ext.prefix ?: "${meta.id}"
	def args = task.ext.args ?: ""
	"""
	samtools index ${bam}
	"""
}