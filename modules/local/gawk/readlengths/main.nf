process GAWK_READLENGTHS {
	tag "${meta.id}"

	conda "${moduleDir}/environment.yml"
	container "community.wave.seqera.io/library/gawk:5.3.0--fee4ad759a5f7c5f"

	input:
	tuple val(meta), path(fastq)
	val n_reads

	output:
	tuple val(meta), path("*.readlengths.txt"), optional: false, emit: txt

	script:
	def prefix = task.ext.prefix ?: "${meta.id}"
	def args = task.ext.args ?: ""
	def total_lines = n_reads ? "&& NR<=${n_reads * 4}" : ""
	"""
	zcat ${fastq} | awk 'NR%4==2 ${total_lines} {if (length(\$0) > max) max = length(\$0)} END {print max}' > ${prefix}.readlengths.txt
	"""
}