#!/bin/bash
# Script for pulling ENCODE data from https://www.encodeproject.org/experiments/ENCSR785RQR/
# The raw_data folder will be gitignored, so this script could generate that if needed. 

#SBATCH --account=b1042	   ## Allocation: use b1042 for genomics cluster
#SBATCH --partition=genomicsguest  ## Genomics guest clusters: genomicsguest, genomicsguestex, genomicsguest-himem, genomicsguest-gpu
#SBATCH --time=<01:00:00>          ## Required: How long will the job need to run?  Limits vary by partition
#SBATCH --nodes=1                  ## 1 node
#SBATCH --ntasks=1                 ## How many CPUs or processors do you need? (default value 1)
#SBATCH --mem=1G                   ## How much RAM do you need per computer/node? G = gigabytes
#SBATCH --job-name=ENCODE_data_download

# Modules
#module purge all # optional
#module load mamba/24.3.0

# Directories
cd ~/chipseq
mkdir raw_data
cd raw_data

# Commands
wget https://www.encodeproject.org/files/ENCFF861BMZ/@@download/ENCFF861BMZ.fastq.gz
wget https://www.encodeproject.org/files/ENCFF919EHZ/@@download/ENCFF919EHZ.fastq.gz

# Completion indicator
echo Success
