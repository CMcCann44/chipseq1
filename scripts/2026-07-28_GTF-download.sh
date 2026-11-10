#!/bin/bash
# Script for downloading human comprehensive GTF file from GENCODE
# USAGE: Run this from repo root

# -------------------------------- SBATCH --------------------------------
#SBATCH --job-name=human-GTF	## Name
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

# Dir structure
mkdir -p reference_data/

# -------------------------------- Commands --------------------------------
#module load bedtools/2.31.1

# Download
wget -P reference_data/2026-07-28_GTK-human-release-50.gtf.gz https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_50/gencode.v50.annotation.gtf.gz
echo '1. Download complete'
sleep 1

# Get rid of parent folder
mv reference_data/2026-07-28_GTK-human-release-50.gtf.gz/gencode.v50.annotation.gtf.gz reference_data/gencode.v50.annotation.gtf.gz
rm -r reference_data/2026-07-28_GTK-human-release-50.gtf.gz/

# Unzip
gunzip reference_data/*.gtf.gz
echo '2. Unzip complete'
