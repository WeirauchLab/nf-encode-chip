include { UCSC_BEDTOBIGBED       } from '../../modules/local/ucsc/bedtoBigBed/main.nf'
include { UCSC_TRACKDB           } from '../../modules/local/ucsc_trackhub/main.nf'

workflow UCSC_TRACKHUB {
	take:
	ch_bed // channel: [val(meta), path(bed)]
	ch_fai // channel: [val(meta), path(fai)]
	ch_bigwig // channel: [val(meta), path(bigwig)]

	main:

	UCSC_BEDTOBIGBED(ch_bed, ch_fai)
	UCSC_TRACKDB(
		UCSC_BEDTOBIGBED.out.bigbed.collect{it[1]}.ifEmpty{[]},
		ch_bigwig.collect{it[1]}.ifEmpty{[]}
	)

	publish:
	UCSC_TRACKDB.out.data >> "trackhubs/ucsc"
	UCSC_TRACKDB.out.hub  >> "trackhubs/ucsc"
}