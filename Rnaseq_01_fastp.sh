#!/bin/bash

#SBATCH --job-name=fastp-batch
#SBATCH --output=fastp_batch.out
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=40
#SBATCH --partition=compute

# ==========================================================
# Step 1: Adapter Trimming with fastp
# ==========================================================
# Trims adapter sequences and low-quality bases from raw
# paired-end FASTQ files using fastp.
# Generates per-sample HTML and JSON QC reports.
#
# Input:  *_R1_001.fastq-* / *_R2_001.fastq-*
# Output: trimmed_files/*_R1_trimmed.fastq
#         trimmed_files/*_R2_trimmed.fastq
#         trimmed_files/*_fastp.html / *.json
# ==========================================================

echo "Working Directory = $(pwd)"

cd /lustre/srishti.s/bjs

OUTPUT_DIR="/lustre/srishti.s/bjs/trimmed_files"
mkdir -p "$OUTPUT_DIR"

for r1 in *_R1_001.fastq-*; do

    base=$(echo "$r1" | sed 's/_R1_001\.fastq-.*//')
    r2=$(ls ${base}_R2_001.fastq-* 2>/dev/null)

    if [[ ! -f "$r2" ]]; then
        echo "No matching R2 file found for $r1 — skipping."
        continue
    fi

    out_r1="${OUTPUT_DIR}/${base}_R1_trimmed.fastq"
    out_r2="${OUTPUT_DIR}/${base}_R2_trimmed.fastq"
    html="${OUTPUT_DIR}/${base}_fastp.html"
    json="${OUTPUT_DIR}/${base}_fastp.json"

    echo "Running fastp for $base"

    fastp \
        -i  "$r1" \
        -I  "$r2" \
        -o  "$out_r1" \
        -O  "$out_r2" \
        --adapter_sequence    AGATCGGAAGAGCACACGTCTGAACTCCAGTCA \
        --adapter_sequence_r2 AGATCGGAAGAGCGTCGTGTAGGGAAAGAGTGT \
        --thread 4 \
        --html "$html" \
        --json "$json"

    echo "Done: $base"

done

echo "All samples trimmed."
