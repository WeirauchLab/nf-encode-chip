process DEEPTOOLS_BAMCOVERAGE {
	tag "${meta.id}"

	conda "${moduleDir}/environment.yml"
	container "community.wave.seqera.io/library/deeptools:3.5.5--0929777992a8c4c6"

	input:
	tuple val(meta), path(bam), path(bai)
	val args

	output:
	tuple val(meta), path("*.bw"), optional: true, emit: bigwig

	script:
	def prefix = task.ext.prefix ?: "${meta.id}_normalized"
	"""
	bamCoverage \\
		--bam ${bam} \\
		--outFileName ${prefix}.bw \\
		--outFileFormat bigwig \\
		--numberOfProcessors ${task.cpus} \\
		${args}
	"""
}