#!/bin/bash
# script for atac-seq
# version:
# Trim Galore: 0.6.6
# Bowtie2: 2.4.5
# samtools: 1.16.1
# Picard: 2.27.1
# MACS2: 2.2.0

# QC
trim_galore --cores 30 \
            -q 20 \
            --length 20 \
            --max_n 3 \
            --stringency 3 \
            --fastqc \
            --paired \
            -o ./ \
            ../rawdata/file_1.fastq.gz ../rawdata/file_2.fastq.gz

multiqc *.zip -n qc_trim

# alignment
bowtie2 --very-sensitive \
        -X 2000 \
        -x /path/to/Bowtie2Index \
        -1 ../data/cleandata/file_1_val_1.fq.gz \
        -2 ../data/cleandata/file_2_val_2.fq.gz \
        -p 35 2> file.bowtie2.log | \
samtools sort -@ 35 -O bam -o file.sorted.bam -

# rm mt
samtools view -@ 35 -h file.sorted.bam | grep -v chrM | \
samtools sort -@ 35 -O bam -o file.rmChrM.bam -

# rm duplication
java -XX:ParallelGCThreads=30 \
     -Djava.io.tmpdir=/tmp \
     -jar /path/to/picard.jar MarkDuplicates \
     QUIET=true \
     INPUT=file.rmChrM.bam \
     OUTPUT=file.rmDup.bam \
     METRICS_FILE=file.sorted.metrics \
     REMOVE_DUPLICATES=true \
     CREATE_INDEX=true \
     VALIDATION_STRINGENCY=LENIENT \
     TMP_DIR=/tmp
    
# callpeaks
macs2 callpeak -t file.rmDup.bam \
               -c control.bam \
               -n file_peaks \
               --shift -75 \
               --extsize 150 \
               --nomodel \
               --call-summits \
               --nolambda \
               --keep-dup all \
               -p 0.01