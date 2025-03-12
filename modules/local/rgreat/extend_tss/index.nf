process EXTEND_TSS {
	tag "${meta.id}"

	cpus { 1 * task.attempt }
	memory { 16.GB * task.attempt }
	time { 2.h * task.attempt }

	container "community.wave.seqera.io/library/bioconductor-plyranges_bioconductor-rgreat_bioconductor-rtracklayer_r-argparse_r-tidyverse:c018eae7915254a1"
	conda "${moduleDir}/environment.yaml"

	input:
	tuple val(meta), path(gtf)
	tuple val(meta2), path(fai)

	output:
	tuple val(meta), path("*.rds"), emit: rds

	script:
	def prefix = task.ext.prefix ?: "${meta.id}"
	def args = task.ext.args ?: ""
	"""
	extend_tss.R \\
		--gtf ${gtf} \\
		--fai ${fai} \\
		--prefix ${prefix} \\
		${args}
	"""

	stub:
	def prefix = task.ext.prefix ?: "${meta.id}"
	"""
	touch ${prefix}.rds
	"""
}
