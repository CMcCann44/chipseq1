#!/bin/bash
# Script for running MACS
# USAGE: Run this from repo root

# -------------------------------- SBATCH --------------------------------
#SBATCH --job-name=ENCFF-control-download	## Name
#SBATCH --cpus-per-task=2  ## CPUs
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

# Dir structure
#mkdir -p raw_data/

# -------------------------------- Pull data --------------------------------
# ENCODE data from https://www.encodeproject.org/experiments/ENCSR785RQR/
# Get links by right-clicking little download icon and copying link address
# Commands: wget files and put them in raw_data/ (this also would create raw_data/ if it didn't exist). 
#   Can include -O <filename> to name, but be careful of overwrites. 
wget -P raw_data/ https://www.encodeproject.org/files/ENCFF260LDK/@@download/ENCFF260LDK.fastq.gz
wget -P raw_data/ https://www.encodeproject.org/files/ENCFF977HJB/@@download/ENCFF977HJB.fastq.gz
echo '1. Download complete'

sleep 10

# -------------------------------- Unzip --------------------------------
# Commands
gunzip raw_data/*.fastq.gz
echo '2. Unzip complete'
