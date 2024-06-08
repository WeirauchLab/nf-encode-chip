process GZIP_GUNZIP {
	tag "${meta.id}"

	conda "${moduleDir}/environment.yml"
	//container ""

	input:
	tuple val(meta), path(archive)

	output:
	tuple val(meta), path("$gunzipped"), optional: false, emit: gunzip
	eval "gunzip --version | head -n 1", emit: version

	script:
	def prefix = task.ext.prefix ?: "${meta.id}"
	def args = task.ext.args ?: ""
	gunzipped = archive.toString() - ~/.gz$/
	"""
	gunzip -c ${archive} > ${gunzipped}
	"""
}