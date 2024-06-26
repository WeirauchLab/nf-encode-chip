
include { BOWTIE2_ALIGN          } from '../../modules/local/bowtie2/align/main'
include { BAM_TO_TA              } from "../../modules/encode/bam_to_ta/main"
include { CREATE_PSEUDOREPS      } from "../../modules/encode/create_pseudoreplicates/main"
include { RUN_SPP                } from "../../modules/local/phantompeakqualtools/run_spp/main"
include { EXTRACT_XCOR           } from "../../modules/local/phantompeakqualtools/extract_xcor/main"
include { CAT_FILES              } from "../../modules/local/cat_files/main"
include { RM_LOWQ_READS          } from '../../modules/encode/rm_lowq_reads/main'
include { PICARD_MARKDUPLICATES  } from '../../modules/local/picard/markDuplicates/main'
include { RM_DUPLICATES          } from '../../modules/encode/rm_dup/main'
include { MACS2_CALLPEAK         } from '../../modules/encode/macs2/callpeak'
include { MACS2_BDGCMP           } from '../../modules/encode/macs2/bdgcmp'
include { FILTER_PEAKS           } from "../../modules/encode/filter_peaks/main"
include { IDR_PEAKS              } from '../../modules/encode/idr/main'
include { OVERLAP_PEAKS          } from '../../modules/encode/overlap/main'
include { ENCODE_REPRODUCIBILITY } from '../../modules/encode/reproducibility/main'
include { SAMTOOLS_INDEX as INDEX_ALIGNED_BAM } from "../../modules/local/samtools/index/main"
include { SAMTOOLS_INDEX as INDEX_FILT_BAM    } from "../../modules/local/samtools/index/main"

def subset_peak_meta(peak_channel, meta_keys){
	peak_channel.map{meta, peak -> [meta.subMap(meta_keys), peak]}
}

workflow ENCODE_CHIP {
	take:
	ch_fastq
	ch_fasta
	ch_fai
	ch_gensz
	ch_bowtie2_index
	ch_bowtie2_mito_index
	multimapping
	local_mode
	mapq_threshold
	ch_chr_filter
	pseudorep_seed
	ch_blacklist_peaks
	ch_idr_threshold_col
	ch_idr_threshold
	ch_mito_chr_name
	ch_chip_mode

	main:

	// TASK align
	ch_bam_aligned = Channel.empty()
	BOWTIE2_ALIGN(
		ch_fastq,
		ch_fasta,
		ch_bowtie2_index,
		[
			multimapping ? "--mm ${multimapping}" : "",
			local_mode ? "--local" : ""
		].join(" ")
	)
	ch_bam_aligned = BOWTIE2_ALIGN.out.bam
	ch_bowtie2_log = BOWTIE2_ALIGN.out.log
	INDEX_ALIGNED_BAM(ch_bam_aligned)
	ch_bam_aligned_index   = INDEX_ALIGNED_BAM.out.bai

	// TASK filter

	ch_lowq_filtered = Channel.empty()
	ch_bam_markdup   = Channel.empty()
	ch_bam_filtered  = Channel.empty()
	
	RM_LOWQ_READS(
		ch_bam_aligned,
		mapq_threshold
	)
	ch_lowq_filtered = RM_LOWQ_READS.out.bam

	PICARD_MARKDUPLICATES(
		ch_lowq_filtered
	)
	ch_bam_markdup = PICARD_MARKDUPLICATES.out.bam

	RM_DUPLICATES(
		ch_bam_markdup
	)
	ch_bam_filtered = RM_DUPLICATES.out.bam
	
	INDEX_FILT_BAM(
		ch_bam_filtered
	)
	ch_bam_filtered_index = INDEX_FILT_BAM.out.bai

	// TASK bam2ta

	BAM_TO_TA(
		ch_bam_filtered
	)
	ch_tagalign = BAM_TO_TA.out.tagAlign

	// TASK generate pseudoreps

	CREATE_PSEUDOREPS(
		ch_tagalign,
		pseudorep_seed
	)

	CREATE_PSEUDOREPS.out.tagAlign
		.transpose()
		.map { meta, ta ->
			def new_meta = meta.clone()
			new_meta.sample_type = "pr"
			def (pr_full, pr_rep) = (ta.toString() =~ /.*pr(\d+)\.tagAlign\.gz$/)[0]
			new_meta.pr_rep = pr_rep.toInteger()
			new_meta.id = "${new_meta.sample_id}_pr${new_meta.pr_rep}"
			[ new_meta, ta ]
		}
		.set { ch_pr_ta }
	
	ch_tagalign = ch_tagalign.mix(ch_pr_ta)

	// TASK pool tagAlign

	ch_tagalign
		.map{ meta, ta ->
			def new_meta = [:]
			if(meta.pr_rep){
				new_meta = [
					id: "${meta.group}_${meta.sample_type}${meta.pr_rep}",
					group: meta.group,
					single_end: meta.single_end,
					sample_type: "pooled_pr",
					pr_rep: meta.pr_rep
				]
			} else {
				new_meta = [
					id: "${meta.group}_${meta.sample_type}",
					group: meta.group,
					single_end: meta.single_end,
					sample_type: "pooled"
				]
			}
			[ new_meta, ta ]
		}
		.groupTuple(by: 0)
		.map{meta, ta_list -> [meta, ta_list.sort()]}
		.filter{meta, ta_list -> ta_list.size() > 1}
		.set{ch_pooled_ta_input}

	CAT_FILES(ch_pooled_ta_input,"tagAlign.gz")
	ch_tagalign = ch_tagalign.mix(CAT_FILES.out.output)

	// TASK spp fragment estimation
	RUN_SPP(
		ch_tagalign,
		ch_chip_mode,
		ch_mito_chr_name
	)
	EXTRACT_XCOR(RUN_SPP.out.rdata)
	ch_spp      = RUN_SPP.out
	ch_xcor_csv = EXTRACT_XCOR.out

	RUN_SPP.out.spp
		.join(ch_tagalign, by: 0)
		.map{meta, spp, ta ->
			def new_meta = meta.clone()
			// frag_len calculated by parsing spp's output. 3rd column, first entry.
			new_meta.frag_len = spp.readLines()[0].split("\t")[2] - ~/,.*/
			[ new_meta, ta ]
		}
		.set { ch_processed_tagalign }

	// TASK macs2

	ch_processed_tagalign
		.collect{meta, ta -> [ [meta.id,ta] ]}
		.set{list_tagalign}
	ch_processed_tagalign
		.map{meta, ta -> 
			if(meta.control_id){
				def control_entry = list_tagalign.findAll{it[0].id == meta.control_id}
				if(control_entry) {
					[meta, ta, control_entry[1]]
				}
			} else {
				[meta, ta, []]
			}
		}
		.set {ch_macs2_input}

	MACS2_CALLPEAK(
		ch_macs2_input,
		ch_fai,
		ch_gensz,
		0,
		[
			"-f BED",
			"-p 0.05",
			"--nomodel",
			"--shift 0",
			"--keep-dup all",
			"-B",
			"--SPMR"
		].join(" ")
	)
	
	ch_narrowPeak = MACS2_CALLPEAK.out.narrowPeak

	MACS2_CALLPEAK.out.treat_pileup
		.join(MACS2_CALLPEAK.out.control_lambda, by: 0)
		.join(ch_processed_tagalign, by: 0)
		.map {meta, treat, control, ta ->
			def new_meta = meta.clone()
			new_meta.nreads = ta.countLines()
			new_meta.rpm_scale = new_meta.nreads / 1000000
			[new_meta, treat, control, ta, new_meta.rpm_scale]
		}
		.set{ch_bdgcmp_input}


	MACS2_BDGCMP(
		ch_bdgcmp_input,
		ch_fai
	)
	ch_macs2_fc_bigwig   = MACS2_BDGCMP.out.fc_bigwig
	ch_macs2_pval_bigwig = MACS2_BDGCMP.out.pval_bigwig

	// TASK postproc_peaks

	FILTER_PEAKS(
		ch_narrowPeak,
		ch_blacklist_peaks,
		ch_chr_filter
	)
	ch_peaks_filtered = FILTER_PEAKS.out.narrowPeak

	// Intermediate: create peak comparison groups
	ch_peaks_filtered
		.branch { meta, peak ->
			sample:    meta.sample_type == "sample"
			pooled:    meta.sample_type == "pooled"
			pr1:       meta.sample_type == "pr" && meta.pr_rep == 1
			pr2:       meta.sample_type == "pr" && meta.pr_rep == 2
			pooled_pr1: meta.sample_type == "pooled_pr" && meta.pr_rep == 1
			pooled_pr2: meta.sample_type == "pooled_pr" && meta.pr_rep == 2
		}
		.set{ch_peaks_branched}

	subset_peak_meta(ch_peaks_branched.sample, ["sample_id","group","single_end"])
		.join(subset_peak_meta(ch_peaks_branched.pr1, ["sample_id","group","single_end"]), by:0)
		.join(subset_peak_meta(ch_peaks_branched.pr2, ["sample_id","group","single_end"]), by:0)
		.map{meta, peak1, peak2, peak3 ->
			def new_meta = [id: "${meta.sample_id}_pr1-vs-pr2", peak_comparison_group: "sample"] + meta 
			[ new_meta, peak1, peak2, peak3 ]
		}
		.set{ch_peak_sample_pr1_v_pr2}

	subset_peak_meta(ch_peaks_branched.pooled, ["sample_id","group","single_end"])
		.join(subset_peak_meta(ch_peaks_branched.pooled_pr1, ["sample_id","group","single_end"]), by:0)
		.join(subset_peak_meta(ch_peaks_branched.pooled_pr2, ["sample_id","group","single_end"]), by:0)
		.map{meta, peak1, peak2, peak3 ->
			def new_meta = [id: "${meta.group}_pooled_pr1-vs-pr2", peak_comparison_group: "np"] + meta 
			[ new_meta, peak1, peak2, peak3 ]
		}
		.set{ch_peak_pooled_pr1_v_pr2}


	subset_peak_meta(ch_peaks_branched.pooled,["group","single_end"])
		.combine(
			ch_peaks_branched.sample
				.map{meta, peak ->
					def new_meta = meta.subMap("group","single_end")
					[ new_meta, [meta.sample_id, peak ] ]
				}
			, by: 0
		)
		.combine(
			ch_peaks_branched.sample
				.map{meta, peak ->
					def new_meta = meta.subMap("group","single_end")
					[ new_meta, [meta.sample_id, peak ] ]
				}
			, by: 0
		)
		.filter{meta,peak,peak2,peak3 -> peak2[0] != peak3[0]}
		.map{meta,peak,peak2,peak3 ->
			[meta,peak,[peak2,peak3].sort{a,b -> a[0] <=> b[0]}]
		}
		.unique()
		.map{meta,peak,peak_pair ->
			def peak1 = peak_pair[0][0]
			def peak2 = peak_pair[1][0]
			def new_meta = [id: "${meta.group}_${peak1}-vs-${peak2}", peak1: peak1, peak2: peak2, peak_comparison_group: "nt"] + meta
			[new_meta, peak, peak_pair[0][1], peak_pair[1][1]]
		}
		.set{ch_peak_pooled_v_sample}
		
		Channel.empty()
			.mix(ch_peak_sample_pr1_v_pr2)
			.mix(ch_peak_pooled_pr1_v_pr2)
			.mix(ch_peak_pooled_v_sample)
			.set{ch_peak_combos}
		
		// TASK reproducibility
		ch_reproducibility_peaks = Channel.empty()
		ch_peak_combos
			.map{meta, peak1, peak2, peak3 ->
				[meta + [mode: "idr"], peak1, peak2, peak3]
			}
			.set{ch_idr_input}
		ch_peak_combos
			.map{meta, peak1, peak2, peak3 ->
				[meta + [mode: "overlap"], peak1, peak2, peak3]
			}
			.set{ch_overlap_input}
		// SUBTASK idr

		IDR_PEAKS(
			ch_idr_input,
			ch_idr_threshold_col,
			ch_idr_threshold
		)
		IDR_PEAKS.out.narrowPeak
			.map{meta, peak ->
				def new_meta = meta.clone()
				new_meta.n_peaks = peak.countLines()
				[new_meta, peak]
			}
			.set {ch_idr_peaks}
		ch_reproducibility_peaks = ch_reproducibility_peaks.mix(ch_idr_peaks)
		
		OVERLAP_PEAKS(ch_overlap_input)
		OVERLAP_PEAKS.out.narrowPeak
			.map{meta, peak ->
				def new_meta = meta.clone()
				new_meta.n_peaks = peak.countLines()
				[new_meta, peak]
			}
			.set {ch_overlap_peaks}
		ch_reproducibility_peaks = ch_reproducibility_peaks.mix(ch_overlap_peaks)

		ch_reproducibility_peaks
			.map{meta,peaks ->
				def new_meta = meta.subMap("group","mode")
				[new_meta, [meta.peak_comparison_group, peaks]]
			}
			.groupTuple(by: 0)
			.map{meta, peaks ->
				def nt_peaks = peaks.findAll{it[0] == "nt"}.collect{it[1]}
				def np_peaks = peaks.findAll{it[0] == "np"}.collect{it[1]}
				def sample_peaks = peaks.findAll{it[0] == "sample"}.collect{it[1]}
				[meta, nt_peaks, np_peaks, sample_peaks]
			}
		.set{ch_reproducibility_input}
		ENCODE_REPRODUCIBILITY(ch_reproducibility_input)


	publish:
	ch_bam_aligned             >> "encode/alignments/raw"
	ch_bam_aligned_index       >> "encode/alignments/raw"
	ch_bam_filtered            >> "encode/alignments/filtered"
	ch_bam_filtered_index      >> "encode/alignments/filtered"
	ch_processed_tagalign      >> "encode/tagAlign"
	ch_narrowPeak		       >> "encode/macs2/raw"
	ch_peaks_filtered	       >> "encode/macs2/filtered"
	ch_idr_peaks		       >> "encode/macs2/idr"
	ch_macs2_fc_bigwig         >> "encode/macs2/signal"
	ch_macs2_pval_bigwig       >> "encode/macs2/signal"
	ch_spp                     >> "encode/qc/spp"     
	ch_xcor_csv                >> "encode/qc/spp"
	ENCODE_REPRODUCIBILITY.out >> "encode/reproducibility"


	emit:
	bam_aligned        = ch_bam_aligned
	bam_aligned_index  = ch_bam_aligned_index
	bowtie2_log        = ch_bowtie2_log
	bam_filtered       = ch_bam_filtered
	bam_filtered_index = ch_bam_filtered_index
	processed_tagalign = ch_processed_tagalign
	narrowPeak         = ch_narrowPeak
	peaks_filtered     = ch_peaks_filtered
	macs2_fc_bigwig    = ch_macs2_fc_bigwig
	macs2_pval_bigwig  = ch_macs2_pval_bigwig

}