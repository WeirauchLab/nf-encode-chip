process BOWTIE2_ALIGN {
	tag "${meta.id}"

	conda "${moduleDir}/environment.yml"
	container "community.wave.seqera.io/library/bowtie2_samtools:5ffb83f41ffa0c0e"

	input:
	tuple val(meta) , path(fastq1), path(fastq2)
	tuple val(meta2), path(fasta)
	tuple val(meta3), path(index)
	val bowtie2_args

	output:
	tuple val(meta), path("*.bam")        , optional: false, emit: bam
	tuple val(meta), path("*.bai")        , optional: false, emit: bai
	tuple val(meta), path("*.bowtie2.log"), optional: false, emit: log, topic: bowtie2_align_log
	tuple val(task.process), eval("bowtie2 --version | head -n 1 | sed 's/^.*version/bowtie2: version/'"), emit: version, topic: versions


	script:
	def prefix = task.ext.prefix ?: "${meta.id}"
	def args = task.ext.args ?: ""
	def index_prefix = index[0].toString() - ~/(\.rev)?\.[0-9]+\.bt2$/
	if (meta.single_end) {
		"""
		bowtie2 \\
			--threads ${task.cpus} \\
			-x ${index_prefix} \\
			-U ${fastq1} \\
			${bowtie2_args} \\
			2> >(tee ${prefix}.bowtie2.log >&2) \\
		| samtools view -1 -S /dev/stdin \\
		| samtools sort -@ ${task.cpus} -o ${prefix}.bam
		samtools index ${prefix}.bam
		"""
	}
	// TODO: add paired end statement
}