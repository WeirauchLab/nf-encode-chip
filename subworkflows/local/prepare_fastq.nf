
include { CAT_FASTQ } from "../../modules/local/cat_fastq/main"
include { GAWK_READLENGTHS } from '../../modules/local/gawk/readlengths/main'

workflow PREPARE_FASTQ {
	take:
	ch_fastq // [ [meta], fastq1, fastq2 ]
	read_length_reads // int or []

	main:
	
	ch_fastq
		.groupTuple(by: 0)
		.map{meta, fastq1, fastq2 ->
			meta.single_end = fastq2.flatten() ? false : true
			[meta, fastq1.flatten(), fastq2.flatten()]
		}
		.branch{meta, fastq1, fastq2 ->
			multiple: fastq1.size() > 1 || fastq2.size() > 1
			single: true
		}
		.set {ch_fastq_branched}
	
	
	CAT_FASTQ(ch_fastq_branched.multiple)

	CAT_FASTQ.out.fastq1
		.join(CAT_FASTQ.out.fastq2, by: 0,remainder: true)
		.mix(ch_fastq_branched.single)
		.set {ch_fastq_concat}
	
	GAWK_READLENGTHS(
		ch_fastq_concat.map{meta, fq1, fq2 -> [meta, fq1]},
		read_length_reads
	)
	GAWK_READLENGTHS.out.txt
		.join(ch_fastq_concat, by: 0)
		.map{ meta, readlengths, fq1, fq2 ->
			[meta + [read_length: readlengths.readLines()[0]], fq1, fq2 ]
		}
		.set {ch_fastq_concat}
	
	// TODO: add trimming
	ch_fastq_trimmed = Channel.empty()

	emit:
	fastq = ch_fastq_concat
	fastq_trimmed = ch_fastq_trimmed 

}