include {FILTER_PEAKS} from "../../modules/encode/filter_peaks/main"

workflow TASK_POSTPROC_PEAKS {
	take:
	ch_narrowPeak
	ch_blacklist
	ch_chr_filter

	main:

	FILTER_PEAKS(
		ch_narrowPeak,
		ch_blacklist,
		ch_chr_filter
	)

	publish:
	FILTER_PEAKS.out.narrowPeak >> "encode/peaks"

	emit:
	narrowPeak = FILTER_PEAKS.out.narrowPeak

}