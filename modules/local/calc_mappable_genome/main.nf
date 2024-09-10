process CALC_MAPPABLE_GENOME {
	tag "${meta.id}"
	cpus   = {1 * task.attempt}
	memory = {4.GB * task.attempt}
	time   = {1.h * task.attempt}

	conda "${moduleDir}/environment.yml"
	container "community.wave.seqera.io/library/gawk:5.3.0--fee4ad759a5f7c5f"

	input:
	tuple val(meta), path(fai)

	output:
	path "mappable_sum.txt", optional: false, emit: txt
	eval "cat mappable_sum.txt", optional: false, emit: value
	tuple val(task.process), val("awk")  , eval("awk -Wversion | sed '1!d; s/.*Awk //; s/,.*//'")      , topic: versions

	script:
	
	"""
	awk '{sum += \$2} END {print sum}' ${fai} > mappable_sum.txt
	"""
}