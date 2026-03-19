# ─────────────────────────────────────────
# Bacterial Genome Assembly Pipeline
# Author: Eric Muthanje
# ─────────────────────────────────────────

configfile: "config.yaml"

SAMPLES = config["samples"]
READS   = config["reads_dir"]

# ─────────────────────────────────────────
# RULE ALL — Final outputs
# ─────────────────────────────────────────
rule all:
    input:
        expand("qc/fastqc/{sample}_{read}_fastqc.html",
               sample=SAMPLES, read=["R1","R2"]),
        "qc/multiqc/multiqc_report.html",
        expand("assembly/{sample}/contigs.fasta", sample=SAMPLES),
        expand("evaluation/quast/{sample}/report.html", sample=SAMPLES),
        expand("evaluation/busco/{sample}/short_summary.txt", sample=SAMPLES)

# ─────────────────────────────────────────
# STEP 1: FastQC
# ─────────────────────────────────────────
rule fastqc:
    input:
        r1 = READS + "/{sample}_R1.fastq.gz",
        r2 = READS + "/{sample}_R2.fastq.gz"
    output:
        html_r1 = "qc/fastqc/{sample}_R1_fastqc.html",
        html_r2 = "qc/fastqc/{sample}_R2_fastqc.html",
        zip_r1  = "qc/fastqc/{sample}_R1_fastqc.zip",
        zip_r2  = "qc/fastqc/{sample}_R2_fastqc.zip"
    threads: 2
    log:
        "logs/fastqc/{sample}.log"
    shell:
        """
        fastqc {input.r1} {input.r2} \
            --outdir qc/fastqc/ \
            --threads {threads} \
            2> {log}
        """

# ─────────────────────────────────────────
# STEP 2: Trimmomatic
# ─────────────────────────────────────────
rule trim:
    input:
        r1 = READS + "/{sample}_R1.fastq.gz",
        r2 = READS + "/{sample}_R2.fastq.gz"
    output:
        r1          = "trimmed/{sample}_R1_paired.fastq.gz",
        r2          = "trimmed/{sample}_R2_paired.fastq.gz",
        r1_unpaired = "trimmed/{sample}_R1_unpaired.fastq.gz",
        r2_unpaired = "trimmed/{sample}_R2_unpaired.fastq.gz"
    params:
        sw       = config["trimmomatic"]["sliding_window"],
        minlen   = config["trimmomatic"]["min_len"],
        leading  = config["trimmomatic"]["leading"],
        trailing = config["trimmomatic"]["trailing"]
    threads: 4
    log:
        "logs/trim/{sample}.log"
    shell:
        """
        trimmomatic PE \
            -threads {threads} \
            {input.r1} {input.r2} \
            {output.r1} {output.r1_unpaired} \
            {output.r2} {output.r2_unpaired} \
            LEADING:{params.leading} \
            TRAILING:{params.trailing} \
            SLIDINGWINDOW:{params.sw} \
            MINLEN:{params.minlen} \
            2> {log}
        """

# ─────────────────────────────────────────
# STEP 3: SPAdes Assembly
# ─────────────────────────────────────────
rule spades:
    input:
        r1 = "trimmed/{sample}_R1_paired.fastq.gz",
        r2 = "trimmed/{sample}_R2_paired.fastq.gz"
    output:
        contigs   = "assembly/{sample}/contigs.fasta",
        scaffolds = "assembly/{sample}/scaffolds.fasta"
    params:
        outdir = "assembly/{sample}",
        memory = config["spades"]["memory"]
    threads: config["spades"]["threads"]
    log:
        "logs/assembly/{sample}.log"
    shell:
        """
        spades.py \
            -1 {input.r1} \
            -2 {input.r2} \
            -o {params.outdir} \
            --threads {threads} \
            --memory {params.memory} \
            2> {log}
        """

# ─────────────────────────────────────────
# STEP 4: QUAST
# ─────────────────────────────────────────
rule quast:
    input:
        "assembly/{sample}/contigs.fasta"
    output:
        "evaluation/quast/{sample}/report.html"
    params:
        outdir     = "evaluation/quast/{sample}",
        min_contig = config["quast"]["min_contig"]
    threads: config["quast"]["threads"]
    log:
        "logs/quast/{sample}.log"
    shell:
        """
        quast.py {input} \
            -o {params.outdir} \
            --min-contig {params.min_contig} \
            --threads {threads} \
            2> {log}
        """

# ─────────────────────────────────────────
# STEP 5: BUSCO
# ─────────────────────────────────────────
rule busco:
    input:
        "assembly/{sample}/contigs.fasta"
    output:
        "evaluation/busco/{sample}/short_summary.txt"
    params:
        lineage = config["busco"]["lineage"],
        outdir  = "evaluation/busco/{sample}"
    threads: config["busco"]["threads"]
    log:
        "logs/busco/{sample}.log"
    shell:
        """
        busco \
            -i {input} \
            -o {params.outdir} \
            -l {params.lineage} \
            -m genome \
            --cpu {threads} \
            --force \
            2> {log}
        """

# ─────────────────────────────────────────
# STEP 6: MultiQC
# ─────────────────────────────────────────
rule multiqc:
    input:
        expand("qc/fastqc/{sample}_{read}_fastqc.zip",
               sample=SAMPLES, read=["R1","R2"])
    output:
        "qc/multiqc/multiqc_report.html"
    log:
        "logs/multiqc/multiqc.log"
    shell:
        """
        multiqc qc/fastqc/ \
            -o qc/multiqc/ \
            2> {log}
        """
