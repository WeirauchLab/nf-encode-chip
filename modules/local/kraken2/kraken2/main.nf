process KRAKEN2_KRAKEN2 {
	tag "${meta.id}"

	conda "${moduleDir}/environment.yml"
	container "community.wave.seqera.io/library/kraken2:2.1.3--517e0e9dce07cd35"

	input:
	tuple val(meta), path(fastq1), path(fastq2)
	tuple val(meta2), path(db)

	output:
	tuple val(meta), path("*.kraken2.report"), optional: true, emit: report

	script:
	def prefix = task.ext.prefix ?: "${meta.id}"
	def args = task.ext.args ?: ""
	"""
	kraken2 \\
		--db ${db} \\
		--threads ${task.cpus} \\
		--report ${prefix}.kraken2.report \\
		${!meta.single_end ? "--paired" : ""} \\
		${args} \\
		${fastq1} ${fastq2}
	"""
}