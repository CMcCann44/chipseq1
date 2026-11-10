#!/bin/bash
# Script for running fast qc on two ENCODE data files
# Will use one CPU for each (2)

#SBATCH --account=b1042				## Allocation: use b1042 for genomics cluster
#SBATCH --partition=genomicsguest		## Genomics guest clusters: genomicsguest, genomicsguestex, genomicsguest-himem, genomicsguest-gpu
#SBATCH --time=01:30:00			## Required: How long will the job need to run?  Limits vary by partition
#SBATCH --nodes=1				## 1 node
#SBATCH --ntasks=2			## How many CPUs or processors do you need? (default value 1)
#SBATCH --mem=16G			## How much RAM do you need per computer/node? G = gigabytes
#SBATCH --job-name=ENCODE_data_fastqc	## Name
#SBATCH --mail-type=END,FAIL			## Email if
#SBATCH --mail-user=tcb6817@northwestern.edu		## Email address
#SBATCH --output=/projects/b1042/AmaralLab/colin/chipseq/logs/slurm_%A.out
#SBATCH --error=/projects/b1042/AmaralLab/colin/chipseq/logs/slurm_%A.error


# Modules
module purge all # optional
module load fastqc/0.12.0

# Directories
cd /projects/b1042/AmaralLab/colin/chipseq/raw_data

# Commands
fastqc -t 2 *.fastq  # -t 2 means to run on two cores

# Completion indicator
echo Success

