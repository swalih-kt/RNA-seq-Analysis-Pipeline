#!/bin/bash

#SBATCH --job-name=count_ariz_imd
#SBATCH --output=count_ariz_imd.out
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=40
#SBATCH --partition=compute

# ==========================================================
# Step 4: Read Counting with featureCounts
# ==========================================================
# Counts reads mapping to each gene across all BAM files
# simultaneously. Uses exon-level summarization by gene_id
# for compatibility with DESeq2 / edgeR downstream.
#
# Input:  aligned_bam/*.bam
#         Homo_sapiens.GRCh38.gtf
# Output: counts_matrix.txt (gene x sample count matrix)
#         counts_matrix.txt.summary (mapping statistics)
# ==========================================================

echo "Working Directory = $(pwd)"

cd /lustre/srishti.s/bjs/aligned_bam

featureCounts \
    -T 40 \
    -p \
    -t exon \
    -g gene_id \
    -a /lustre/srishti.s/refs/Homo_sapiens.GRCh38.gtf \
    -o counts_matrix.txt \
    *.bam

echo "featureCounts completed. Output: counts_matrix.txt"
