process BAM_TO_TA {
	tag "${meta.id}"

	conda "${moduleDir}/environment.yml"
	container "community.wave.seqera.io/library/bedtools_samtools_gawk_gzip:211fa1eea1361c12"

	input:
	tuple val(meta), path(bam)

	output:
	tuple val(meta), path("*.tagAlign.gz"), optional: false, emit: tagAlign

	script:
	def prefix = task.ext.prefix ?: "${meta.id}"
	def args = task.ext.args ?: ""
	if(meta.single_end){
		"""
		bedtools bamtobed -i ${bam} \\
		| awk 'BEGIN{{OFS="\\t"}}{{\$4="N";\$5="1000";print \$0}}' \\
		| gzip -c > ${prefix}.tagAlign.gz
		"""
	}
	// TODO: paired-end
}