process FASTP_FASTP {
	tag "${meta.id}"

	conda "${moduleDir}/environment.yml"
	container "community.wave.seqera.io/library/fastp:0.23.4--4d9e23447c67e79e"

	input:
	tuple val(meta), path(fastq1), path(fastq2)
	val args

	output:
	tuple val(meta), path("*.fastp.fastq.gz"), optional: false, emit: fastq
	tuple val(meta), path("*.json")          , optional: false, emit: json, topic: fastp_json
	tuple val(meta), path("*.html")          , optional: false, emit: html, topic: fastp_html

	script:
	def prefix = task.ext.prefix ?: "${meta.id}"
	def args = task.ext.args ?: ""
	if (meta.single_end){
		"""
		fastp \\
			--in1 ${fastq1} \\
			--out1 ${prefix}.fastp.fastq.gz \\
			--json ${prefix}.fastp.json \\
			--html ${prefix}.fastp.html \\
			--thread ${task.cpus} \\
			${args}
		"""
	} else {
		"""
		fastp \\
			--in1 ${fastq1} \\
			--out1 ${prefix}_R1.fastp.fastq.gz \\
			--in2 ${fastq2} \\
			--out2 ${prefix}_R2.fastp.fastq.gz \\
			--json ${prefix}.fastp.json \\
			--html ${prefix}.fastp.html \\
			--thread ${task.cpus} \\
			${args}
		"""
	}
	
}