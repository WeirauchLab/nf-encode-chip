process MULTIQC {
    tag "multiqc_report"
    cache false

    conda "${moduleDir}/environment.yml"
    container "community.wave.seqera.io/library/multiqc:1.22.1--4886de6095538010"

    input:
    path multiqc_config
    path "data/fastqc/raw/*"
    path "data/fastp/*"
    path "data/fastqc/trimmed/*"
    path "data/bowtie2_align/*"
    path "data/picard_markduplicates/*"
    path "data/spp/*"
    path "data/sourmash/gather/*"
    path "data/spp_xcor/*"
    path "data/encode_reproducibility_stats/idr/*"
    path "data/encode_reproducibility_stats/overlap/*"
    path "data/deeptools/plotFingerprint/qc_metrics/*"
    path "data/deeptools/plotFingerprint/raw_counts/*"

    output:
    path "multiqc_report.html", optional: false, emit: html
    path "*_plots"            , optional:true  , emit: plots
    path "*_data"             , optional:true  , emit: data

    script:
    def args = task.ext.args ?: ""
    """
    run_multiqc.py --config ${multiqc_config}
    """
}