include { SOURMASH_CLASSIFIER } from "./sourmash_classifier"

workflow METAGENOMICS {
	take:
	ch_fastq       // channel: [ val(meta), path(fastq1), path(fastq2) ]
	sourmash_db    // file or []
	skip_sourmash  // boolean

	main:

	//----------------------------------------------------------//
	// sourmash classifier
	//----------------------------------------------------------//

	ch_sourmash_sketch     = Channel.empty()
	ch_sourmash_gather_csv = Channel.empty()
	if(!skip_sourmash && sourmash_db){
		SOURMASH_CLASSIFIER(
			ch_fastq,
			sourmash_db
		)
		ch_sourmash_sketch     = SOURMASH_CLASSIFIER.out.sketch
		ch_sourmash_gather_csv = SOURMASH_CLASSIFIER.out.csv
	}

	emit:
	sourmash_sketch     = ch_sourmash_sketch
	sourmash_gather_csv = ch_sourmash_gather_csv

}