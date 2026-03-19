# Bacterial Genome Assembly Pipeline

A Snakemake pipeline for de novo assembly of bacterial paired-end short reads.

## Pipeline Steps
1. FastQC — Raw read quality control
2. Trimmomatic — Adapter trimming
3. SPAdes — De novo genome assembly
4. QUAST — Assembly quality evaluation
5. BUSCO — Genome completeness assessment
6. MultiQC — Aggregate QC reports

## Requirements
- conda/mamba
- Snakemake

## Installation
​```bash
mamba create -n genome_assembly python=3.9 -y
conda activate genome_assembly
mamba install -c bioconda -c conda-forge \
    fastqc trimmomatic spades quast busco multiqc snakemake -y
​```

## Usage
​```bash
# Dry run
snakemake -n

# Run pipeline
snakemake --cores 4
​```

## Author
Eric Muthanje
