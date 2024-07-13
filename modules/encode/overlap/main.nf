process OVERLAP_PEAKS {
	tag "${meta.id}"
	cpus   = {1 * task.attempt}
	memory = {16.GB * task.attempt}
	time   = {2.h * task.attempt}

	conda "${moduleDir}/environment.yml"
	container "community.wave.seqera.io/library/bedtools:2.31.1--8fd0e3802b0dc02e"

	input:
	tuple val(meta), path(peak1), path(peak2), path(peak3)

	output:
	tuple val(meta), path("*.overlap.narrowPeak")  , optional: true, emit: narrowPeak
	tuple val(task.process), val("bedtools")        , eval("bedtools --version | sed 's/bedtools v//'")                                  , topic: versions

	script:
	def prefix = task.ext.prefix ?: "${meta.id}"
	"""	
	bedtools intersect \\
		-a <(bedtools sort -i $peak1) \\
		-b <(bedtools sort -i $peak2) \\
		-u -f 0.5 -r | \\
	bedtools intersect \\
		-a - \\
		-b <(bedtools sort -i $peak3) \\
		-u -f 0.5 -r \\
		> ${prefix}.overlap.narrowPeak

	"""
}