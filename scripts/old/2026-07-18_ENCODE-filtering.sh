#!/bin/bash
# Script for running filtering after bowtie2 stuff
# Run this from chipseq folder with: sbatch scripts/name.sh

# -------------------------------- SBATCH --------------------------------
#SBATCH --account=b1042				## Allocation: use b1042 for genomics cluster
#SBATCH --partition=genomicsguest		## Genomics guest clusters: genomicsguest, genomicsguestex, genomicsguest-himem, genomicsguest-gpu
#SBATCH --time=48:00:00			## Required: How long will the job need to run?  Limits vary by partition
#SBATCH --nodes=1				## 1 node
#SBATCH --ntasks=1			## How many CPUs or processors do you need? (default value 1)
#SBATCH --mem=48G			## How much RAM do you need per computer/node? G = gigabytes

#SBATCH --cpus-per-task=10
#SBATCH --job-name=hg38_filtering	 ## Name

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
module load samtools/1.16.1-gcc-10.4.0
module load sambamba/0.8.2

# -------------------------------- Commands --------------------------------

# Alignment
cd results/bowtie2/
# Convert SAM to BAM
#samtools view -h -S -b -o 2026-07-16_ENCODE-bowtie2-unsorted.bam 2026-07-16_ENCODE-bowtie2-unsorted.sam

# Sort BAM
sambamba sort -t 2 -o 2026-07-16_ENCODE-bowtie2-sorted.bam 2026-07-16_ENCODE-bowtie2-unsorted.bam
# Filter by uniquely mapped reads
sambamba view -h -t 2 -f bam -F "[XS] == null and not unmapped  and not duplicate" 2026-07-16_ENCODE-bowtie2-sorted.bam > 2026-07-16_ENCODE-bowtie2-aln.bam

# Completion indicator
echo Success

