#!/bin/bash
# Script for running MACS
# USAGE: Run this from repo root

# -------------------------------- SBATCH --------------------------------
#SBATCH --job-name=hg38_macs	## Name
#SBATCH --cpus-per-task=10  ## CPUs
#SBATCH --mem=48G			## How much RAM do you need per computer/node? G = gigabytes
#SBATCH --ntasks=1			## How many CPUs or processors do you need? (default value 1)
#SBATCH --time=48:00:00			        ## Required: How long will the job need to run?  Limits vary by partition
#SBATCH --nodes=1				        ## 1 node
#SBATCH --account=b1042				    ## Allocation: use b1042 for genomics cluster
#SBATCH --partition=genomicsguest		## Genomics guest clusters: genomicsguest, genomicsguestex, genomicsguest-himem, genomicsguest-gpu
# Email
#SBATCH --mail-type=END,FAIL			            ## Email if
#SBATCH --mail-user=tcb6817@ads.northwestern.edu	## Email address
# Send output files to logs
#SBATCH --output=logs/slurm_%A.out
#SBATCH --error=logs/slurm_%A.error


# -------------------------------- Setup --------------------------------
# If script is not run from repo root, throw error. 
if [ ! -d "scripts" ] || [ ! -d "logs" ]; then
    echo "ERROR: This script must be submitted from the chipseq/ repo root." >&2
    exit 1
fi

# Directory structure: should have scripts, raw_data, reference_data, logs
mkdir -p results/macs3/

# -------------------------------- Commands --------------------------------
#module load python/3.13.0-gcc-8.5.0 # workshop used python/2.7.12 and gcc/6.2.0   They are up to gcc/12.3
module load MACS3/3.0.2 # there is also MACS2/2/1/0 (Default) and 2.2.9.1

# MACS3
# Input flags:  -t: the input data file (required). -c: control file. 
#               -f: input file format (default is auto). -g: mappable genome size
# Output flags: --outdir: where files will be saved. -n: prefix string for output
#               -B or .--bdg: stores fragment pileup, control lambda, -log10pvalue and -log10qvalue scores in bedGraph files
# Others: -s, --bw, --mfold, -q (q value), -p (p value), --nolambda, --broad
# 'hs' means human genome (~2.7e9). Could also use ~2.9e9
macs3 callpeak \
	-t results/bowtie2/2026-07-16_ENCODE-bowtie2-aln.bam \
    -c results/bowtie2/control-strand1-ENCFF260LDK-aln.bam \
 	-f BAM -g hs \
	-n 2026-07-24_ENCODE-hg38 \
	--outdir results/macs3/ \
	2> results/macs3/2026-07-24_macs3-paired-end-mode.log

sleep 1
mv results/macs3/*.log logs/

echo Success

