
include { CAT_FASTQ                       } from "../../modules/local/cat_fastq/main"
include { GAWK_READLENGTHS                } from '../../modules/local/gawk/readlengths/main'
include { FASTQC_FASTQC as FASTQC_RAW     } from '../../modules/local/fastqc/main'
include { FASTQC_FASTQC as FASTQC_TRIMMED } from '../../modules/local/fastqc/main'
include { FASTP_FASTP                     } from '../../modules/local/fastp/fastp/main'

workflow PREPARE_FASTQ {
	take:
	ch_fastq              // [ [meta], fastq1, fastq2 ]
	read_length_reads     // int or []
	fastp_extra_args      // string
	skip_adapter_trimming // boolean

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
	
	FASTQC_RAW(ch_fastq_concat)
	
	if(skip_adapter_trimming) {
		ch_fastq_trimmed      = ch_fastq_concat
		ch_fastp_json         = Channel.empty()
		ch_fastp_html         = Channel.empty()
		ch_fastqc_trimmed     = Channel.empty()
		ch_fastqc_trimmed_zip = Channel.empty()
	} else {
		FASTP_FASTP(
			ch_fastq_concat,
			fastp_extra_args ?: []
		)
		ch_fastp_json = FASTP_FASTP.out.json
		ch_fastp_html = FASTP_FASTP.out.html
		FASTP_FASTP.out.fastq
			.map{meta, fastq ->
				if(meta.single_end) {
					[meta, fastq, []]
				} else {
					[meta, fastq[0], fastq[1]]
				}
			}
			.set {ch_fastq_trimmed}
		FASTQC_TRIMMED(ch_fastq_trimmed)
		ch_fastqc_trimmed     = FASTQC_TRIMMED.out
		ch_fastqc_trimmed_zip = FASTQC_TRIMMED.out.zip
	}
	


	publish:
	FASTQC_RAW.out       >> "fastqc/raw"
	ch_fastqc_trimmed    >> "fastqc/trimmed"
	ch_fastp_json        >> "fastp"
	ch_fastp_html        >> "fastp"

	emit:
	fastq              = ch_fastq_concat
	fastq_trimmed      = ch_fastq_trimmed
	fastqc_raw_zip     = FASTQC_RAW.out.zip
	fastqc_trimmed_zip = ch_fastqc_trimmed_zip
	fastp_json         = ch_fastp_json
	fastp_html         = ch_fastp_html

}