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
		| awk 'BEGIN{OFS="\\t"}{\$4="N";\$5="1000";print \$0}' \\
		| gzip -c > ${prefix}.tagAlign.gz
		"""
	} else {
		"""
		samtools sort -n ${bam} -o tmp_${prefix}.sorted.bam -T ${prefix}
		bedtools bamtobed -bedpe -mate1 -i tmp_${prefix}.sorted.bam \\
		| awk 'BEGIN{OFS="\\t"}{fmt="%s\\t%s\\t%s\\tN\\t1000\\t%s\\n"; printf fmt, \$1, \$2, \$3, \$9; printf fmt, \$4, \$5, \$6, \$10 }' \\
		| gzip -c > ${prefix}.tagAlign.gz
		"""
	}
}