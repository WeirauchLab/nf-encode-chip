process UCSC_TRACKDB {
	tag "UCSC Trackhub"
	cache false

	cpus   = {1 * task.attempt}
	memory = {16.GB * task.attempt}
	time   = {2.h * task.attempt}

	conda "${moduleDir}/environment.yml"
	container "community.wave.seqera.io/library/pydantic_python:ef418a61c42ac2fb"

	input:
	path "data/bigbed/*"
	path "data/bigwig/*"

	output:
	//TODO: set up output
	path("data")   , includeInputs: true, optional: true, emit: data
	path("hub.txt"), optional: true, emit: hub

	// version strings
	//TODO: add version outputs
	//tuple val(task.process), val("tool") , eval("tool --version"), topic: versions

	script:
	def args = task.ext.args ?: ""
	"""
	trackdb.py --dt_bigwig data/bigwig/* --encode_bigbed data/bigbed/* ${args}
	"""
}