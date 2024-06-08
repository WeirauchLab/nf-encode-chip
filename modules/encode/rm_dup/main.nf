process RM_DUPLICATES {
	tag "${meta.id}"

	conda "${moduleDir}/environment.yml"
	//container ""

	input:
	tuple val(meta), path(bam)

	output:
	tuple val(meta), path("*.bam"), optional: false, emit: bam

	script:
	def prefix = task.ext.prefix ?: "${meta.id}.nodup"
	def args = task.ext.args ?: ""
	if(meta.single_end){
		"""
		samtools view \\
			-F 1804 \\
			-b ${bam} \\
			> ${prefix}.bam
		"""
	}
	//TODO: add paired-end support
}