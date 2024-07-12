process FASTP_FASTP {
	tag "${meta.id}"
	cpus   = {1 * task.attempt}
	memory = {16.GB * task.attempt}
	time   = {2.h * task.attempt}

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
		if [ "${fastq1}" != "${prefix}.fastq.gz" ]; then
			mv ${fastq1} ${prefix}.fastq.gz
		fi

		fastp \\
			--in1 ${prefix}.fastq.gz \\
			--out1 ${prefix}.fastp.fastq.gz \\
			--json ${prefix}.fastp.json \\
			--html ${prefix}.fastp.html \\
			--thread ${task.cpus} \\
			${args}
		"""
	} else {
		"""
		if [ "${fastq1}" != "${prefix}_1.fastq.gz" ]; then
			mv ${fastq1} ${prefix}_1.fastq.gz
		fi
		if [ "${fastq2}" != "${prefix}_2.fastq.gz" ]; then
			mv ${fastq2} ${prefix}_2.fastq.gz
		fi

		fastp \\
			--in1 ${prefix}_1.fastq.gz \\
			--out1 ${prefix}_1.fastp.fastq.gz \\
			--in2 ${prefix}_2.fastq.gz \\
			--out2 ${prefix}_2.fastp.fastq.gz \\
			--json ${prefix}.fastp.json \\
			--html ${prefix}.fastp.html \\
			--thread ${task.cpus} \\
			${args}
		"""
	}
	
}