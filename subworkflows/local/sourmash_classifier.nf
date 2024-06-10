include { SOURMASH_SKETCH } from '../../modules/local/sourmash/sketch/main'
include { SOURMASH_GATHER } from '../../modules/local/sourmash/gather/main'

workflow SOURMASH_CLASSIFIER {
	take:
	ch_fastq
	ch_db
	ch_param

	main:

	SOURMASH_SKETCH(ch_fastq, ch_param)
	SOURMASH_GATHER(SOURMASH_SKETCH.out.sketch, ch_db)


}