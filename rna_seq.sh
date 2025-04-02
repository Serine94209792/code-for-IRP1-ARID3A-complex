#!/bin/bash
# script for rna-seq
# version:
# FastQC: 0.11.9
# Trim Galore: 0.6.6
# STAR: 2.7.9a
# RSEM: 1.3.3
# DESeq2: 1.34.0

# QC:
fastqc -o /path/to/output/directory -t number_of_threads /path/to/input/files

# Adapter trimming
trim_galore --gzip \
            --path_to_cutadapt /path/to/cutadapt \
            --phred33 \
            --illumina \
            --output_dir /path/to/TrimGalore/output/directory \
            --paired /path/to/forward/reads /path/to/reverse/reads

# Alignment
STAR --runThreadN NumberOfThreads \
     --runMode genomeGenerate \
     --genomeDir /path/to/STAR/genome/directory \
     --genomeFastaFiles /path/to/genome/fasta/file \
     --sjdbGTFfile /path/to/annotation/gtf/file \
     --sjdbOverhang ReadLength-1

STAR --twopassMode Basic \
     --limitBAMsortRAM available_memory_in_bytes \
     --genomeDir /path/to/STAR/genome/directory \
     --outSAMunmapped Within \
     --outFilterType BySJout \
     --outSAMattributes NH HI AS NM MD MC \
     --outFilterMultimapNmax 20 \
     --outFilterMismatchNmax 999 \
     --outFiIterMismatchNoverReadLmax 0.04 \
     --alignlntronMin 20 \
     --alignlntronMax 1000000 \
     --alignMatesGapMax 1000000 \
     --alignSJDBoverhangMin 1 \
     --sjdbScore 1 \
     --readFilesCommand zcat \
     --runThreadN NumberOfThreads \
     --outSAMtype BAM SortedByCoordinate \
     --quantMode TranscriptomeSAM \
     --outSAMheaderHD "@HD VN:1.4 SO:coordinate" \
     --outFileNamePrefix /path/to/STAR-output/directory/ \
     --readFilesIn /path/to/trimmed_forward_reads /path/to/trimmed_reverse_reads

# Quantification
rsem-prepare-reference --gtf /path/to/annotation/gtf/file \
                       /path/to/genome/fasta/file \
                       /path/to/RSEM/genome/directory/RSEM_ref_prefix

rsem-calculate-expression --num-threads NumberOfThreads \
                          --alignments \
                          --bam \
                          --seed 12345 \
                          --estimate-rspd \
                          --no-bam-output \
                          --strandedness reverse \
                          /path/to/*Aligned.toTranscriptome.out.bam \
                          /path/to/RSEM/genome/directory/RSEM_ref_prefix \
                          /path/to/RSEM/output/directory