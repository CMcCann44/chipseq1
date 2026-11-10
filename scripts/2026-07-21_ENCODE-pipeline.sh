#!/bin/bash
# Script for running quality check (fastqc) on a fastq file, and aligning to human genome hg38 with bowtie2. 
# USAGE: You could run this on one file (run from repo root):
#   sh scripts/2026-07-16_ENCODE-pipeline.sh <path-to-fastq-file.fastq> <path-to-paired-file.fastq>
#   Note: you can leave second argument blank. Paths must have no spaces. 
# Or run on multiple with the runner file

# -------------------------------- SBATCH --------------------------------
#SBATCH --job-name=hg38_fastqc-bowtie2-alignment	## Name
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
mkdir -p results/fastqc results/bowtie2/intermediate_bams

# Variables
fq1=$1
fq2=$2
# If first argument is missing, exit
if [ -z "$fq1" ]; then
    echo "Usage: $0 <R1.fastq.gz> [R2.fastq.gz]"
    exit 1
fi

# How many threads to use (should be total_cores / #parallel_jobs). Default is 1
THREADS=${3:-1}

# grab base of filename for naming outputs
base=`basename $fq1 .fastq`
echo "Sample name is $base"

# directory with bowtie genome index
genome=reference_data/hg38

# set up output filenames and locations
fastqc_out=results/fastqc/

## set up file names
align_sam=results/bowtie2/${base}-unsorted.sam
align_bam=results/bowtie2/${base}-unsorted.bam
align_sorted=results/bowtie2/${base}-sorted.bam
align_filtered=results/bowtie2/${base}-aln.bam

# set up the software environment
module load fastqc/0.12.0 # also loads java
module load bowtie2/2.5.4 # maybe loads gcc idk
module load samtools/1.16.1-gcc-10.4.0
module load sambamba/0.8.2 # not sambama

echo "1. Processing file $fq1 and $fq2"

# -------------------------------- FastQC --------------------------------
# Commands
fastqc $fq1
if [ -n "$fq2" ]; then
	fastqc $fq2
fi
mv raw_data/*_fastqc.* results/fastqc/
echo '2. Ran FastQC'

# Run bowtie2
# Note: bowtie2-build /projects/genomicsshare/anno/Homo_sapiens/UCSC/hg38/Sequence/WholeGenomeFasta/genome.fa reference_data/hg38
#   is needed, unless already done
# If second argument is non-empty, use paired bowtie2, otherwise just use single
if [ -n "$fq2" ]; then
    bowtie2 -p 8 -q --local -x $genome -1 $fq1 -2 $fq2 -S $align_sam
else
    echo "Single-end mode: $fq1"
    bowtie2 -p 8 -q --local -x $genome -U $fq1 -S $align_sam
fi
echo '3. Ran bowtie'

# Create BAM from SAM
samtools view -h -S -b -@ "$THREADS" -o $align_bam $align_sam
echo '4. Created BAM'

# Sort BAM file by genomic coordinates
sambamba sort -t "$THREADS" -o $align_sorted $align_bam
echo '5. Sorted BAM'

# Filter out duplicates
sambamba view -h -t "$THREADS" -f bam -F "[XS] == null and not unmapped " $align_sorted > $align_filtered # '  and not duplicate'?
echo '6. Filtered duplicates'

# Create indices for all the bam files for visualization and QC
samtools index $align_filtered
echo '7. Indexed BAM'

# Move intermediate files out of the bowtie2 directory
mv results/bowtie2/${base}*sorted* results/bowtie2/intermediate_bams
echo '8. Moved intermediate files'
echo '9. End'

