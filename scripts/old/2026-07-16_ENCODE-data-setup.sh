#!/bin/bash
# Script for downloading and unzipping ENCODE chipseq data (.fastq files), 
#   and creating bowtie2 hg38 alignment reference thing
# The raw_data folder will be gitignored, so this script could generate that if needed. 
# USAGE: run this once to be able to use the pipeline script for FastQC and bowtie2
#   run with sbatch <path/to/file.sh>

# -------------------------------- SBATCH --------------------------------
#SBATCH --account=b1042				            # Allocation: use b1042 for genomics cluster
#SBATCH --partition=genomicsguest		        ## Genomics guest clusters: genomicsguest, genomicsguestex, genomicsguest-himem, genomicsguest-gpu
#SBATCH --nodes=1				                ## 1 node
#SBATCH --ntasks=1			                    ## How many CPUs or processors do you need? (default value 1)
#SBATCH --mem=32G			                    ## How much RAM do you need per computer/node? G = gigabytes
#SBATCH --time=04:00:00			                            ## Required: How long will the job need to run?  Limits vary by partition
#SBATCH --job-name=chipseq-data-setup                       ## Name

# Email tcb... when script ends or fails
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=tcb6817@ads.northwestern.edu
# Send output files to logs
#SBATCH --output=logs/slurm_%A.out
#SBATCH --error=logs/slurm_%A.error

# -------------------------------- Dir tree --------------------------------
# Make file runnable from anywhere. This doesn't work. Instead just run from chipseq folder
# SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
#   ${BASH_SOURCE[0]} returns the path to the currently executing script (may be relative or absolute)
#   dirname "..." returns the same thing without the filename at the end (will be .../scripts/)
#   "$(cd ... && pwd)" puts a subshell in the scripts folder and returns absolute path (stored as SCRIPT_DIR)
#       Note: $(...) creates a subshell so our real shell did not cd yet. 
# REPO_ROOT="$(dirname "$SCRIPT_DIR")" # gets parent folder of scripts/
# cd "$REPO_ROOT" || exit 1 # moves into the repo root, exits if that fails

# Should definitely have scripts folder, create others if they don't exist
mkdir -p logs raw_data reference_data # -p so there is no error if they do exist

# -------------------------------- Pull data --------------------------------
# ENCODE data from https://www.encodeproject.org/experiments/ENCSR785RQR/
# Commands: wget files and put them in raw_data/ (this also would create raw_data/ if it didn't exist). 
#   Can include -O <filename> to name, but be careful of overwrites. 
wget -P raw_data/ https://www.encodeproject.org/files/ENCFF861BMZ/@@download/ENCFF861BMZ.fastq.gz
wget -P raw_data/ https://www.encodeproject.org/files/ENCFF919EHZ/@@download/ENCFF919EHZ.fastq.gz
echo '1. Download complete'

# -------------------------------- Unzip --------------------------------
# Commands
gunzip ENCFF861BMZ.fastq.gz
gunzip ENCFF919EHZ.fastq.gz
echo '2. Unzip complete'

# -------------------------------- bowtie2-build --------------------------------
# Build files for bowtie2
bowtie2-build /projects/genomicsshare/anno/Homo_sapiens/UCSC/hg38/Sequence/WholeGenomeFasta/genome.fa reference_data/hg38
echo '3. Bowtie hg38 build complete'

