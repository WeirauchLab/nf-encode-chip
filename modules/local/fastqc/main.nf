process FASTQC_FASTQC {
	tag "${meta.id}"

	conda "${moduleDir}/environment.yml"
	container "community.wave.seqera.io/library/fastqc:0.12.1--5cfd0f3cb6760c42"

	input:
	tuple val(meta), path(fastq1), path(fastq2)

	output:
	tuple val(meta), path("*.html"), optional: true, emit: html
	tuple val(meta), path("*.zip") , optional: true, emit: zip

	script:
	def prefix = task.ext.prefix ?: "${meta.id}"
	def args = task.ext.args ?: ""
	if (meta.single_end) {
		"""
		ln -s ${fastq1} ${prefix}_1.fastq.gz
		fastqc \\
			--threads ${task.cpus} \\
			${fastq1}
		"""
	} else {
		"""
		ln -s ${fastq1} ${prefix}_1.fastq.gz
		ln -s ${fastq2} ${prefix}_2.fastq.gz
		fastqc \\
			--threads ${task.cpus} \\
			${fastq1} ${fastq2}
		"""
	}
	
}