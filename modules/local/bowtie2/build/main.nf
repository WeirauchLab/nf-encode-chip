process BOWTIE2_BUILD {
	tag "${meta.id}"

	conda "${moduleDir}/environment.yml"
	//container ""

	input:
	tuple val(meta), path(fasta)

	output:
	tuple val(meta), path("*.bt2"), optional: false, emit: index

	script:
	def prefix = task.ext.prefix ?: "${meta.id}"
	def args = task.ext.args ?: ""
	"""
	bowtie2-build ${fasta} ${prefix}
	"""
}