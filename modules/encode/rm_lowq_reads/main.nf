process RM_LOWQ_READS {
	tag "${meta.id}"

	conda "${moduleDir}/environment.yml"
	//container ""

	input:
	tuple val(meta), path(bam)
	val mapq_threshold

	output:
	tuple val(meta), path("*.bam"), optional: false, emit: bam

	script:
	def prefix = task.ext.prefix ?: "${meta.id}.lowq_filt"
	def args = task.ext.args ?: ""
	if(meta.single_end){
		"""
		samtools view \\
			-F 1804 \\
			${mapq_threshold ? "-q ${mapq_threshold}": ""} \\
			-u ${bam} \\
		| samtools sort \\
			/dev/stdin \\
			-o ${prefix}.bam \\
			-T tmp_${prefix}
		"""
	}
	//TODO: add paired-end support
}