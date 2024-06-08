process CAT_FASTQ {
	tag "${meta.id}"

	conda "${moduleDir}/environment.yml"
	//container ""

	input:
	tuple val(meta), path(fastq1), path(fastq2)

	output:
	tuple val(meta), path("*_r1.fastq.gz"), optional: false, emit: fastq1
	tuple val(meta), path("*_r2.fastq.gz"), optional: true , emit: fastq2

	script:
	def prefix = task.ext.prefix ?: "${meta.id}"
	def args = task.ext.args ?: ""
	"""
	cat ${fastq1} > ${prefix}_r1.fastq.gz
	${fastq2 ? "cat ${fastq2} > ${prefix}_r2.fastq.gz" : ""}
	"""
}