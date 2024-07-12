process FILTER_PEAKS {
	tag "${meta.id}"
	cpus   = {1 * task.attempt}
	memory = {16.GB * task.attempt}
	time   = {2.h * task.attempt}

	conda "${moduleDir}/environment.yml"
	container "community.wave.seqera.io/library/bedtools:2.31.1--8fd0e3802b0dc02e"

	input:
	tuple val(meta), path(narrowPeak)
	tuple val(meta2), path(bl_peaks)
	val filter_pattern

	output:
	tuple val(meta), path("*.narrowPeak"), optional: false, emit: narrowPeak

	script:
	def prefix = task.ext.prefix ?: "${meta.id}.bl_filt"
	def args = task.ext.args ?: ""
	"""
	bedtools intersect -a ${narrowPeak} -b ${bl_peaks} -v > ${prefix}.narrowPeak

	if [[ -n '$filter_pattern' ]]; then
		echo "Retaining peaks matching pattern '${filter_pattern}'"
		grep -E '${filter_pattern}' ${prefix}.narrowPeak > tmp.narrowPeak
		mv tmp.narrowPeak ${prefix}.narrowPeak
	fi

	"""
}