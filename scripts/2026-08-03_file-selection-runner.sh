#!/bin/bash
# Script for downloading many TF BED or narrowPeaks files from ENCODE
# USAGE: Run this from repo root

# -------------------------------- SBATCH --------------------------------
#SBATCH --job-name=file-selection-runner	## Name
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
    echo "ERROR: This script must be submitted from the repo root (chipseq/)." >&2
    exit 1
fi

# Dir structure
mkdir -p raw_data/peaks_unfiltered/

# -------------------------------- Commands --------------------------------
module load python/3.13.0-gcc-8.5.0

# Virtual environment
# Note: ran python -m venv venv
source /projects/b1042/AmaralLab/colin/chipseq/.venv/bin/activate # .venv/bin/activate

# Run script
cd scripts/
python 2026-08-03_file-selection.py
sleep 1
echo 'Download complete'

# Unzip
cd ../raw_data/peaks_unfiltered/
find . -type f -name "*.gz" -exec gunzip {} \;
echo 'Unzip complete'
sleep 1

# Remove folders since names of TF are in filenames
find . -mindepth 2 -type f -name "*.narrowPeak" -exec mv {} . \;
find . -mindepth 1 -type d -empty -delete
echo 'Removed folders'

