process RUN_SPP {
	tag "${meta.id}"

	conda "${moduleDir}/environment.yml"
	container "community.wave.seqera.io/library/phantompeakqualtools:1.2.2--f8026fe2526a5e18"

	input:
	tuple val(meta), path(ta)
	val seq_type
	val mito_chr_name

	output:
	tuple val(meta), path("*.spp.out")  , optional: false, emit: spp, topic: spp_log
	tuple val(meta), path("*.spp.pdf")  , optional: false, emit: pdf
	tuple val(meta), path("*.spp.Rdata"), optional: false, emit: rdata

	script:
	def prefix = task.ext.prefix ?: "${meta.id}"
	def args = task.ext.args ?: ""
	"""
	readlen=\$(zcat ${ta} \\
		| head -n 100 \\
		| awk 'function abs(v) {return v < 0 ? -v : v} BEGIN{sum=0} {sum+=abs(\$3-\$2)} END{print int(sum/NR)}')
	
	if [ "$seq_type" == "tf" ]; then
		max=\$((readlen + 10 > 50 ? readlen + 10 : 50))
	elif [ "$seq_type" == "histone" ]; then
		max=\$((readlen + 10 > 100 ? readlen + 10 : 100))
	fi

	Rscript \\
		--max-ppsize=500000 \\
		\$(which run_spp.R) \\
		-rf \\
		-c=${ta} \\
		-p=${task.cpus} \\
		-filtchr="${mito_chr_name}" \\
		-savp=${prefix}.spp.pdf \\
		-out=${prefix}.spp.out \\
		-savd="${prefix}.spp.Rdata" \\
		-x=0:\$max

	"""
}