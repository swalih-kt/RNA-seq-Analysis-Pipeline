#!/bin/bash

#SBATCH --job-name=fastqc-trimmed
#SBATCH --output=fastqc_trimmed.out
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=40
#SBATCH --partition=compute

# ==========================================================
# Step 2: Quality Control with FastQC
# ==========================================================
# Runs FastQC on all trimmed FASTQ files to verify adapter
# removal and assess overall read quality before alignment.
#
# Input:  trimmed_files/*_trimmed.fastq
# Output: fastqc_results/*.html / *.zip (per sample)
# ==========================================================

echo "Working Directory = $(pwd)"

INPUT_DIR="/lustre/srishti.s/bjs/trimmed_files"
OUTPUT_DIR="/lustre/srishti.s/bjs/fastqc_results"

mkdir -p "$OUTPUT_DIR"

echo "Running FastQC on trimmed files..."

fastqc "$INPUT_DIR"/*_trimmed.fastq \
    --outdir="$OUTPUT_DIR" \
    --threads 4

echo "FastQC finished. Results saved in $OUTPUT_DIR"
