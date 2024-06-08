process SAMTOOLS_FAIDX_CHR {
	tag "${meta.id}"

	conda "${moduleDir}/environment.yml"
	//container ""

	input:
	tuple val(meta), path(fasta)
	val chr

	output:
	tuple val(meta), path("*.fasta")     , optional: false, emit: fasta
	eval "samtools --version | head -n 1", optional: false, emit: version

	script:
	def prefix = task.ext.prefix ?: "${meta.id}"
	def args = task.ext.args ?: ""
	"""
	samtools faidx ${fasta} ${chr} > ${prefix}.fasta
	"""
}