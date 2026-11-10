#!/bin/bash
# Script to run pipeline on all fastq files in raw_data (submitted in parallel via sbatch)
# Handles both single-end files and paired-end files.
# Paired-end files must contain 'strand1' and 'strand2' in their names
# (e.g. sample1_strand1.fastq / sample1_strand2.fastq); everything else
# is treated as single-end.

THREADS=6   # should match -n below

# -------------------------------- Paired-end files --------------------------------
# Loop over every "strand1" file and find its "strand2" partner
for fq1 in raw_data/*strand1*.fastq
do
    # skip if no strand1 files exist (avoids literal glob string when no matches)
    [ -e "$fq1" ] || continue

    fq2="${fq1/strand1/strand2}"

    if [ -e "$fq2" ]; then
        echo "Submitting paired-end job for $fq1 and $fq2"
        sbatch -n $THREADS --job-name chipseq-analysis -o logs/%j.out -e logs/%j.err \
            --wrap="sh scripts/2026-07-16_ENCODE-pipeline.sh \"$fq1\" \"$fq2\" $THREADS"
    else
        echo "WARNING: no matching strand2 file found for $fq1 -- skipping" >&2
    fi

    sleep 1    # wait 1 second between each job submission
done

# -------------------------------- Single-end files --------------------------------
# Every fastq file that is NOT part of a strand1/strand2 pair is run single-end
for fq in raw_data/*.fastq
do
    [ -e "$fq" ] || continue

    case "$fq" in
        *strand1*|*strand2*
            continue    # already handled above
            ;;
    esac

    echo "Submitting single-end job for $fq"
    sbatch -n $THREADS --job-name chipseq-analysis -o logs/%j.out -e logs/%j.err \
        --wrap="sh scripts/2026-07-16_ENCODE-pipeline.sh \"$fq\" '' $THREADS"

    sleep 1    # wait 1 second between each job submission
done
