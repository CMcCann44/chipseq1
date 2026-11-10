## README ##
# chipseq
Working with ChIP-seq data for NITMB SURP REU\
Amaral Lab

Run shell scripts from repo root\
Don't run python scripts or notebooks directly, use runner shell scripts

Dir Structure\
logs/ 		    - for console/job output\
meta/		    - metadata (empty as of 8/3)\
raw\_data/	    - full data files (gitignored. scripts to download these will be in scripts/.)\
reference\_data/- for datasets of full genome for sequence algning (gitignored)\
results/	    - fastqc quality files (html and zip), bowtie2 alignment files (SAM/BAM), etc.\
scripts/	    - shell scripts to be run with sbatch on Northwestern QUEST GCC

File Naming\
YYYY-MM-DD\_file-name.txt

Datasets used\
ENCODE TF experiments, GENCODE gtf annotation\
See scripts for download commands

