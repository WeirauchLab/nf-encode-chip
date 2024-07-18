# NF-ENCODE-CHIP Outputs

This pipeline generates several different files as output.

## QC

The pipeline generates several QC files. The main QC file is the `multiqc_report.html` file. This file contains several different plots and tables that summarize the quality of the data.

## Peak calling

The main output of the pipeline is the peak calls in narrowPeak format. This file contains the genomic coordinates of the peaks, the score, the strand, the p-value, the q-value, and the fold change.

### MACS2

The pipeline uses MACS2 to call peaks. The output of MACS2 is a file in narrowPeak format. The file is named `sampleID_peaks.narrowPeak`.

## Signal tracks

The pipeline generates several different signal tracks. The signal tracks are in bigWig format. The signal tracks are generated for the input, the control, and the treatment. The signal tracks are generated for the raw signal, the normalized signal, and the fold change signal.

### ENCODE's signal tracks
