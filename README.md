# RNA-seq Analysis Pipeline

A SLURM-based bulk RNA-seq pipeline for paired-end data, covering quality trimming, QC, splice-aware alignment to hg38, and gene-level read counting. Designed for HPC environments running SLURM.

---

## Pipeline Overview

| Step | Script | Tool | Purpose |
|------|--------|------|---------|
| 1 | `rnaseq_01_fastp.sh` | fastp | Adapter trimming and quality filtering |
| 2 | `rnaseq_02_fastqc.sh` | FastQC | Post-trimming quality control |
| 3 | `rnaseq_03_hisat2.sh` | HISAT2 + SAMtools | Splice-aware alignment to hg38 |
| 4 | `rnaseq_04_featurecounts.sh` | featureCounts | Gene-level read counting |

---

## Environment

- **Cluster**: SLURM-based HPC
- **Reference genome**: `Homo_sapiens.GRCh38`
- **Base directory**: `/lustre/srishti.s/bjs/`

---

## Requirements

- `fastp`
- `FastQC`
- `HISAT2`
- `SAMtools`
- `featureCounts` (subread package)

---

## Input Files

| File | Description |
|------|-------------|
| `*_R1_001.fastq-*` / `*_R2_001.fastq-*` | Raw paired-end FASTQ files |
| `Homo_sapiens.GRCh38` | HISAT2 genome index (pre-built) |
| `Homo_sapiens.GRCh38.gtf` | Gene annotation file |

---

## Step 1: Adapter Trimming with fastp

**Script**: `rnaseq_01_fastp.sh` | **SLURM**: 1 node, 40 tasks

**Purpose**: Trims Illumina TruSeq adapter sequences from raw paired-end reads and removes low-quality bases. Generates per-sample HTML and JSON quality reports to confirm trimming performance.

| | |
|---|---|
| **Input** | `*_R1_001.fastq-*` / `*_R2_001.fastq-*` |
| **Output** | `trimmed_files/*_R1_trimmed.fastq`, `*_R2_trimmed.fastq`, `*_fastp.html`, `*_fastp.json` |
| **Adapter R1** | `AGATCGGAAGAGCACACGTCTGAACTCCAGTCA` (TruSeq Read 1) |
| **Adapter R2** | `AGATCGGAAGAGCGTCGTGTAGGGAAAGAGTGT` (TruSeq Read 2) |
| **Threads per sample** | 4 |

> **Important**: The script detects R1/R2 pairs automatically by matching sample base names. Samples with a missing R2 file are skipped with a warning. Review the fastp HTML reports before proceeding to alignment to confirm adapter removal was successful.

---

## Step 2: Quality Control with FastQC

**Script**: `rnaseq_02_fastqc.sh` | **SLURM**: 1 node, 40 tasks

**Purpose**: Runs FastQC on all trimmed FASTQ files to assess read quality metrics including per-base quality scores, GC content, duplication levels, and confirm that adapter sequences have been removed.

| | |
|---|---|
| **Input** | `trimmed_files/*_trimmed.fastq` |
| **Output** | `fastqc_results/*.html`, `fastqc_results/*.zip` (one per file) |
| **Threads** | 4 |

> **Important**: Inspect FastQC HTML reports for any remaining adapter content or quality issues before proceeding. For a cohort-level summary across all samples, run `multiqc fastqc_results/` after this step.

---

## Step 3: Splice-Aware Alignment with HISAT2

**Script**: `rnaseq_03_hisat2.sh` | **SLURM**: 1 node, 8 CPUs

**Purpose**: Aligns trimmed paired-end reads to the hg38 reference genome using HISAT2, which is designed for RNA-seq data and correctly handles reads spanning splice junctions. SAM output is immediately sorted, converted to indexed BAM, and the SAM file is deleted to save storage.

| | |
|---|---|
| **Input** | `trimmed_files/*_R1_trimmed.fastq` / `*_R2_trimmed.fastq` |
| **Output** | `aligned_bam/*.bam` + `*.bam.bai` |
| **Reference index** | `Homo_sapiens.GRCh38` (HISAT2 index) |
| **Strandedness** | `RF` (reverse-forward; typical for dUTP/stranded libraries) |
| **HISAT2 threads** | 8 |
| **SAMtools sort threads** | 4 |

> **Important**: `--rna-strandness RF` is set for reverse-stranded libraries (dUTP protocol). If your library is unstranded or forward-stranded, change this to `--rna-strandness` unstranded (remove the flag) or `FR` respectively. Incorrect strandedness will reduce alignment rates and affect strand-specific counting. The `--dta` flag optimizes output for downstream transcript assemblers and quantification tools.

---

## Step 4: Gene-Level Read Counting with featureCounts

**Script**: `rnaseq_04_featurecounts.sh` | **SLURM**: 1 node, 40 tasks

**Purpose**: Counts the number of reads mapping to each gene across all BAM files simultaneously, producing a single gene × sample count matrix. Uses exon-level features summarized by `gene_id`, which is the standard format for DESeq2 and edgeR differential expression analysis.

| | |
|---|---|
| **Input** | `aligned_bam/*.bam`, `Homo_sapiens.GRCh38.gtf` |
| **Output** | `aligned_bam/counts_matrix.txt` (count matrix), `counts_matrix.txt.summary` (mapping statistics) |
| **Mode** | Paired-end (`-p`), exon-level (`-t exon`), gene_id summarization (`-g gene_id`) |
| **Threads** | 40 |

> **Important**: All BAM files are processed together in a single featureCounts run, which produces one count matrix with all samples as columns — ready for direct import into DESeq2 or edgeR. Review `counts_matrix.txt.summary` to check the proportion of successfully assigned reads per sample. Low assignment rates (<60%) may indicate a strandedness mismatch or annotation mismatch with the reference used for alignment.

---

## Directory Structure

```
bjs/
├── *_R1_001.fastq-* / *_R2_001.fastq-*    # Raw input FASTQ files
├── trimmed_files/                          # Step 1 output
│   ├── *_R1_trimmed.fastq
│   ├── *_R2_trimmed.fastq
│   ├── *_fastp.html
│   └── *_fastp.json
├── fastqc_results/                         # Step 2 output
│   ├── *.html
│   └── *.zip
├── aligned_bam/                            # Steps 3 & 4 output
│   ├── *.bam
│   ├── *.bam.bai
│   ├── counts_matrix.txt
│   └── counts_matrix.txt.summary
```

---

## Output for Downstream Analysis

The final output `counts_matrix.txt` is a tab-separated gene × sample count matrix and can be directly loaded into R for differential expression analysis:

```r
counts <- read.table("counts_matrix.txt", header = TRUE, skip = 1, row.names = 1)
```

Recommended downstream tools: **DESeq2**, **edgeR**, **limma-voom**

---

## Notes

- Strandedness (`--rna-strandness RF`) should be confirmed with your library preparation protocol or by running `RSeQC infer_experiment.py` on a subset BAM.
- The HISAT2 genome index must be pre-built before running Step 3. Build with: `hisat2-build Homo_sapiens.GRCh38.fasta Homo_sapiens.GRCh38`
- For cohort-level QC summary across all FastQC reports, run `multiqc .` in the `fastqc_results/` directory.

---

## References

- [fastp](https://github.com/OpenGene/fastp)
- [FastQC](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/)
- [HISAT2](https://daehwankimlab.github.io/hisat2/)
- [featureCounts / Subread](https://subread.sourceforge.net/)
- [DESeq2](https://bioconductor.org/packages/release/bioc/html/DESeq2.html)
