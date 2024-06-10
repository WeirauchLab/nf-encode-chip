process SOURMASH_SKETCH {
	tag "${meta.id}"

	conda "${moduleDir}/environment.yml"
	container "community.wave.seqera.io/library/sourmash:4.8.8--c9498e42d55d50e1"

	input:
	tuple val(meta), path(fastq1), path(fastq2)
	val sm_param

	output:
	tuple val(meta), path("*.sig.gz"), optional: false, emit: sketch

	script:
	def prefix = task.ext.prefix ?: "${meta.id}"
	def args = task.ext.args ?: ""
	"""
	sourmash sketch dna \\
		-p ${sm_param} \\
		--name ${prefix} \\
		-o ${prefix}.sig.gz \\
		${args} \\
		${fastq1} ${fastq2}
	"""
}