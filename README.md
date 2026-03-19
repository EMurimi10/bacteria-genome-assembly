# Bacterial Genome Assembly & Annotation Pipeline

A complete Snakemake pipeline for de novo assembly, annotation, and 
antimicrobial resistance (AMR) detection of bacterial paired-end short reads.

---

## Pipeline Overview
```
Raw Reads (FASTQ)
      ↓
   FastQC          → Read quality control
      ↓
   Trimmomatic     → Adapter & quality trimming
      ↓
   SPAdes          → De novo genome assembly
      ↓
   ┌─────────────────────────────────────┐
   │  QUAST      → Assembly statistics   │
   │  BUSCO      → Genome completeness   │
   │  Prokka     → Genome annotation     │
   │  ABRicate   → AMR gene detection    │
   └─────────────────────────────────────┘
      ↓
   MultiQC         → Aggregate QC report
```

---

## Pipeline Steps

| Step | Tool | Purpose | Output |
|------|------|---------|--------|
| 1 | FastQC | Raw read quality check | `qc/fastqc/` |
| 2 | Trimmomatic | Adapter & quality trimming | `trimmed/` |
| 3 | SPAdes | De novo genome assembly | `assembly/` |
| 4 | QUAST | Assembly quality statistics | `evaluation/quast/` |
| 5 | BUSCO | Genome completeness assessment | `evaluation/busco/` |
| 6 | MultiQC | Aggregate all QC reports | `qc/multiqc/` |
| 7 | Prokka | Genome annotation | `annotation/` |
| 8 | ABRicate | AMR gene detection (NCBI/CARD/ResFinder) | `amr/` |
| 9 | ABRicate Summary | AMR summary across all samples | `amr/summary/` |

---

## Requirements

- macOS or Linux
- conda or mamba
- Internet connection (first run only for BUSCO databases)

---

## Installation

### 1. Clone the repository
```bash
git clone https://github.com/EMurimi10/bacteria-genome-assembly.git
cd bacteria-genome-assembly
```

### 2. Create conda environment
```bash
mamba create -n genome_assembly python=3.9 -y
conda activate genome_assembly
```

### 3. Install all tools
```bash
mamba install -c bioconda -c conda-forge \
    fastqc trimmomatic spades quast busco \
    multiqc prokka abricate snakemake -y

pip install InSilicoSeq
```

---

## Usage

### 1. Add your samples to config.yaml
```yaml
samples:
  - sample1
  - sample2
  - sample3
```

### 2. Place your reads in the reads/ folder
```
reads/
├── sample1_R1.fastq.gz
├── sample1_R2.fastq.gz
├── sample2_R1.fastq.gz
└── sample2_R2.fastq.gz
```

### 3. Dry run to check pipeline
```bash
snakemake -n
```

### 4. Run the pipeline
```bash
snakemake --cores 4
```

### 5. Run on HPC/SLURM cluster
```bash
snakemake --cores 100 \
    --cluster "sbatch --cpus-per-task={threads} --mem=8G" \
    --jobs 20
```

---

## Project Structure
```
bacteria-genome-assembly/
├── Snakefile              # Pipeline rules (9 steps)
├── config.yaml            # Parameters and sample names
├── README.md              # This file
├── .gitignore             # Files excluded from git
├── reads/                 # Input FASTQ files (not tracked)
├── trimmed/               # Trimmed reads (not tracked)
├── assembly/              # SPAdes assemblies (not tracked)
├── evaluation/
│   ├── quast/             # QUAST reports
│   └── busco/             # BUSCO reports
├── annotation/            # Prokka annotation files
├── amr/                   # ABRicate AMR results
│   └── summary/           # AMR summary table
├── qc/
│   ├── fastqc/            # FastQC reports
│   └── multiqc/           # MultiQC aggregate report
└── logs/                  # Log files per rule per sample
```

---

## Output Files

### Assembly
| File | Description |
|------|-------------|
| `assembly/{sample}/contigs.fasta` | Final assembled contigs |
| `assembly/{sample}/scaffolds.fasta` | Scaffolded sequences |

### Annotation (Prokka)
| File | Description |
|------|-------------|
| `.gff` | Genome annotation in GFF3 format |
| `.gbk` | GenBank format annotation |
| `.faa` | Protein sequences |
| `.ffn` | Nucleotide gene sequences |
| `.txt` | Annotation summary statistics |
| `.tsv` | Tab-separated gene table |

### AMR Detection (ABRicate)
| File | Description |
|------|-------------|
| `amr/{sample}/{sample}_ncbi.tsv` | NCBI resistance genes |
| `amr/{sample}/{sample}_card.tsv` | CARD resistance genes |
| `amr/{sample}/{sample}_resfinder.tsv` | ResFinder resistance genes |
| `amr/summary/amr_summary.tsv` | Summary across all samples |

---

## Configuration

All parameters are set in `config.yaml`:
```yaml
# Samples
samples:
  - sample1

# Trimmomatic
trimmomatic:
  sliding_window: "4:20"
  min_len: 50
  leading: 3
  trailing: 3

# SPAdes
spades:
  threads: 4
  memory: 8        # GB

# BUSCO
busco:
  lineage: "bacteria_odb10"

# ABRicate
abricate:
  databases: [ncbi, card, resfinder]
  min_coverage: 80
  min_identity: 90
```

---

## Interpreting Results

### QUAST — Assembly Quality
| Metric | Good Value |
|--------|-----------|
| N50 | > 100 kbp |
| Total length | Close to expected genome size |
| Number of contigs | As few as possible |
| Largest contig | > 500 kbp |

### BUSCO — Genome Completeness
| Result | Meaning |
|--------|---------|
| C > 95% | Excellent assembly |
| C 90-95% | Good assembly |
| C < 90% | May need improvement |

### AMR — Resistance Genes
| Column | Meaning |
|--------|---------|
| GENE | Resistance gene name |
| PRODUCT | Gene function |
| RESISTANCE | Antibiotic class |
| %COVERAGE | Gene coverage |
| %IDENTITY | Sequence identity |

---

## Author

**Eric Muthanje**
- GitHub: [EMurimi10](https://github.com/EMurimi10)
- Email: emurimi10@gmail.com

---

## Citation

If you use this pipeline please cite the individual tools:
- SPAdes: Bankevich et al., 2012
- Prokka: Seemann, 2014
- ABRicate: Seemann, 2020
- BUSCO: Simão et al., 2015
- QUAST: Gurevich et al., 2013
