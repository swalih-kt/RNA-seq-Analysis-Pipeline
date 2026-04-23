#!/bin/bash

#SBATCH --job-name=hisat2_align
#SBATCH --output=hisat2_align.out
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --partition=compute

# ==========================================================
# Step 3: Splice-Aware Alignment with HISAT2
# ==========================================================
# Aligns trimmed paired-end reads to the hg38 reference
# genome using HISAT2. SAM output is sorted and converted
# to indexed BAM files. Intermediate SAM files are removed.
#
# Input:  trimmed_files/*_R1_trimmed.fastq / *_R2_trimmed.fastq
# Output: aligned_bam/*.bam + *.bam.bai
# ==========================================================

REF_INDEX="/lustre/srishti.s/refs/Homo_sapiens.GRCh38"
INPUT_DIR="/lustre/srishti.s/bjs/trimmed_files"
OUTPUT_DIR="/lustre/srishti.s/bjs/aligned_bam"

mkdir -p "$OUTPUT_DIR"

cd "$INPUT_DIR" || exit 1

for r1 in *_R1_trimmed.fastq; do

    sample=${r1%%_R1_trimmed.fastq}
    r2="${sample}_R2_trimmed.fastq"

    if [[ ! -f "$r2" ]]; then
        echo "Missing R2 for $sample — skipping."
        continue
    fi

    echo "Aligning $sample ..."

    hisat2 -p 8 \
        -x "$REF_INDEX" \
        --dta \
        --rna-strandness RF \
        -1 "$r1" \
        -2 "$r2" \
        -S "$OUTPUT_DIR/${sample}.sam"

    samtools sort -@ 4 -o "$OUTPUT_DIR/${sample}.bam" "$OUTPUT_DIR/${sample}.sam"
    samtools index "$OUTPUT_DIR/${sample}.bam"

    rm "$OUTPUT_DIR/${sample}.sam"

    echo "Done: $sample"

done

echo "All alignments completed."
