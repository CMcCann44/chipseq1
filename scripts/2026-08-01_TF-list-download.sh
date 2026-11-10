#!/bin/bash
# Script for downloading many TF BED or narrowPeaks files from ENCODE
# USAGE: Run this from repo root

# -------------------------------- SBATCH --------------------------------
#SBATCH --job-name=TF-list-download	## Name
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
#module load _

# Download
# -n 1 means use at most 1 args per command line
# -O means to save using the filename as it appears on the website
# -L means to follow redirects
cd raw_data/peaks_unfiltered/
xargs -n 1 curl -O -L < files.txt
echo '1. Download complete'
sleep 1

# Get metadata.csv
