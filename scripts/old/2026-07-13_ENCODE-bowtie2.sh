#!/bin/bash
# Script for running bowtie2 for alignment
# Run this from chipseq folder with: sbatch scripts/name.sh

# -------------------------------- SBATCH --------------------------------
#SBATCH --account=b1042				## Allocation: use b1042 for genomics cluster
#SBATCH --partition=genomicsguest		## Genomics guest clusters: genomicsguest, genomicsguestex, genomicsguest-himem, genomicsguest-gpu
#SBATCH --time=48:00:00			## Required: How long will the job need to run?  Limits vary by partition
#SBATCH --nodes=1				## 1 node
#SBATCH --ntasks=1			## How many CPUs or processors do you need? (default value 1)
#SBATCH --mem=48G			## How much RAM do you need per computer/node? G = gigabytes

#SBATCH --cpus-per-task=10
#SBATCH --job-name=hg38_bowtie2	## Name

#SBATCH --mail-type=END,FAIL			## Email if
#SBATCH --mail-user=tcb6817@ads.northwestern.edu	## Email address

# Send output files to logs
#SBATCH --output=logs/slurm_%A.out
#SBATCH --error=logs/slurm_%A.error


# If script is not run from repo root, throw error. 
if [ ! -d "scripts" ] || [ ! -d "logs" ]; then
    echo "ERROR: This script must be submitted from the chipseq/ repo root." >&2
    exit 1
fi

# -------------------------------- Modules --------------------------------
module load bowtie2/2.5.4 # maybe loads gcc idek

# -------------------------------- Commands --------------------------------

# Alignment
bowtie2 -p 8 -q --local \
-x reference_data/hg38 \
-1 raw_data/ENCFF861BMZ.fastq \
-2 raw_data/ENCFF919EHZ.fastq \
-S results/bowtie2/2026-07-16_ENCODE-bowtie2-unsorted.sam \
2> logs/2026-07-16_ENCODE-bowtie2.log \
&& mv results/bowtie2/2026-07-16_ENCODE-bowtie2-unsorted.sam.tmp \
       results/bowtie2/2026-07-16_ENCODE-bowtie2-unsorted.sam
# 2>  # puts alignment summary in logs
# && mv gets rid of '.tmp' on output files but only if the bowtie2 command finished. 

# Completion indicator
echo Success

