# Modified from "A Principled Approach to the Identification of Functional Targets of Transcription Factor Binding Sites"
# By Maalavika Pillai and Luis A. Nunes Amaral
# https://github.com/amarallab/TF_Positional_Distribution_Model

# Load required modules
import os
import pandas as pd
import urllib.request
import subprocess

# Set working directory
# Assumes this script is run from chipseq/scripts/
working_dir = "../raw_data/peaks_unfiltered/"
os.chdir(working_dir)

# Read ENCODE metadata
df = pd.read_table("metadata.tsv")

# Simplify Experiment target names
# e.g. CTCF-human -> CTCF
df["Experiment target"] = [
    str(i).split("-")[0] for i in df["Experiment target"]
]

# Select GRCh38 IDR thresholded TF ChIP-seq narrowPeak files
# Includes bed narrowPeak - skips bigBed narrowPeak for now
df_sub = df.loc[
    df["Output type"].str.contains(
        "conservative IDR thresholded peaks", case=False, na=False   # conservative only - for network
    ) &
    (df["Assay"] == "TF ChIP-seq") &
    (df["File assembly"] == "GRCh38") &
    (df["File format type"] == "narrowPeak") &
    (df["File format"] == "bed narrowPeak")
    #(df["File format"].isin(["bed narrowPeak", "bigBed narrowPeak"]))
].copy()

# Identify duplicate BED/bigBed representations
# BED narrowPeak is preferred over bigBed narrowPeak
duplicate_columns = [
    "Experiment accession",
    "Experiment target",
    "Biosample term name",
    "Output type",
    "File assembly",
    "Biological replicate(s)"
]

df_sub["format_priority"] = df_sub["File format"].map({
    "bed narrowPeak": 1,
    "bigBed narrowPeak": 2
})

duplicates = df_sub[
    df_sub.duplicated(subset=duplicate_columns, keep=False)
]

if len(duplicates) > 0:
    print("\nDuplicate BED/bigBed representations found:")
    print(
        duplicates[
            duplicate_columns + ["File accession", "File format"]
        ].to_string(index=False)
    )
    print("\nBED narrowPeak will be preferred.\n")

# Keep one representation of each peak set
df_sub = df_sub.sort_values(
    duplicate_columns + ["format_priority"]
).drop_duplicates(
    subset=duplicate_columns,
    keep="first"
).drop(columns=["format_priority"])

# Print summary
print("========================================")
print("ENCODE ChIP-seq peak download")
print("========================================")
print(f"Total metadata rows: {len(df)}")
print(f"Selected peak files: {len(df_sub)}")
print(f"Unique TFs: {df_sub['Experiment target'].nunique()}")

print("\nTFs selected:")
for target in sorted(df_sub["Experiment target"].unique()):
    print(f"  {target}")

print("\nSelected file formats:")
print(df_sub["File format"].value_counts())

# Download selected files
for _, line in df_sub.iterrows():
    target = line["Experiment target"]
    accession = line["File accession"]
    file_format = line["File format"]

    # Create TF directory
    os.makedirs(target, exist_ok=True)

    if file_format == "bed narrowPeak":
        url = (
            f"https://www.encodeproject.org/files/"
            f"{accession}/@@download/{accession}.bed.gz"
        )

        savefile = os.path.join(
            target,
            f"{accession}_{target}.narrowPeak.gz"
        )

        if not os.path.exists(savefile):
            print(f"Downloading {accession} ({target})...")
            urllib.request.urlretrieve(url, savefile)
        else:
            print(f"Already exists: {savefile}")

    elif file_format == "bigBed narrowPeak":
        bigbed_file = os.path.join(
            target,
            f"{accession}_{target}.bigBed"
        )

        narrowpeak_file = os.path.join(
            target,
            f"{accession}_{target}.narrowPeak"
        )

        # Download bigBed if necessary
        if not os.path.exists(bigbed_file) and not os.path.exists(narrowpeak_file):
            url = (
                f"https://www.encodeproject.org/files/"
                f"{accession}/@@download/{accession}.bigBed"
            )
            print(f"Downloading bigBed {accession} ({target})...")
            urllib.request.urlretrieve(url, bigbed_file)

        # Convert bigBed to narrowPeak
        if not os.path.exists(narrowpeak_file):
            print(f"Converting {accession} to narrowPeak...")
            subprocess.run(
                ["bigBedToBed", bigbed_file, narrowpeak_file],
                check=True
            )
            os.remove(bigbed_file)
        else:
            print(f"Already exists: {narrowpeak_file}")

print("\nDownload and conversion complete.")
