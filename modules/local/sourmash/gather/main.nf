process SOURMASH_GATHER {
	tag "${meta.id}"

	conda "${moduleDir}/environment.yml"
	container "community.wave.seqera.io/library/sourmash:4.8.8--c9498e42d55d50e1"

	input:
	tuple val(meta), path(sketch)
	path db

	output:
	tuple val(meta), path("*.csv"), optional: true, emit: csv, topic: sourmash_gather_csv

	script:
	def prefix = task.ext.prefix ?: "${meta.id}"
	def args = task.ext.args ?: ""
	"""
	sourmash gather ${sketch} ${db} \\
		--output ${prefix}_matches.csv \\
		${args}
		#--save-matches ${prefix}_matches.zip
	"""
}