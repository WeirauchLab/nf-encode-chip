process CREATE_PSEUDOREPS {
	tag "${meta.id}"

	// TODO: add container and conda
	//conda "${moduleDir}/environment.yml"
	//container ""

	input:
	tuple val(meta), path(tagAlign)
	val pseudorep_seed

	output:
	tuple val(meta), path("*.tagAlign.gz"), optional: false, emit: tagAlign
	tuple val(meta), path("*pr1.tagAlign.gz"), optional: false, emit: pr1
	tuple val(meta), path("*pr2.tagAlign.gz"), optional: false, emit: pr2

	script:
	def prefix = task.ext.prefix ?: "${meta.id}"
	def args = task.ext.args ?: ""
	if(meta.single_end){
		"""
		nlines=\$(zcat ${tagAlign} | wc -l)
		zcat ${tagAlign} \\
			| shuf --random-source=<(openssl enc -aes-256-ctr -pass pass:${pseudorep_seed} -nosalt </dev/zero 2>/dev/null) \\
			| split -d -l \$(( (nlines + 1) /2 )) - ${prefix}.
		gzip -nc ${prefix}.00 > ${prefix}_pr1.tagAlign.gz
		gzip -nc ${prefix}.01 > ${prefix}_pr2.tagAlign.gz
		rm -f ${prefix}.00 ${prefix}.01
		"""
	} else {
		// TODO: paired-end
		"""
		"""
	}
}