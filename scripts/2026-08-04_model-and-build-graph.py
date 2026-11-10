#!/usr/bin/env python
# coding: utf-8

# ### **Graph incorporating many TFs and distance filter model**
# Uses like 50 TFs, ? genes\
# Run file with sbatch using sh files
# 

# Pipeline: ChIP-seq narrowPeak files -> TF-gene regulatory networkx graph.
# 
# Expects:
#   - one narrowPeak file per TF, named like "<TFNAME>.narrowPeak"
#   - a TSS bed file: chrom, tss_start, tss_end, gene_name, score, strand
# 
# Produces:
#   - a networkx DiGraph: TF nodes -> gene nodes, edges weighted by
#     signal strength and annotated with distance-to-TSS.

# In[2]:


import glob
import os
import subprocess
import networkx as nx


# ### **STEP 1: Parse a single narrowPeak file into a list of peak dicts**
# Read a narrowPeak file and return a filtered list of peaks.
# 
# WHY: narrowPeak files (especially raw MACS2 output, not IDR-processed)
# contain many low-confidence peaks. We filter on qValue here so garbage
# peaks don't become garbage edges later. qValue in the file is
# -log10(q), so q < 0.05 corresponds to a threshold of 1.3.

# In[3]:


def parse_narrowpeak(path, qvalue_threshold=1.3, keep_raw_line=False):
    peaks = []
    with open(path) as f:
        for line in f:
            cols = line.rstrip("\n").split("\t")
            chrom, start, end = cols[0], int(cols[1]), int(cols[2])
            signal_value = float(cols[6])
            qvalue = float(cols[8])

            if qvalue < qvalue_threshold:
                continue  # discard: not statistically confident enough

            # summit = absolute genomic position of strongest signal in peak
            # (more precise than using the peak midpoint)
            summit_offset = int(cols[9]) if cols[9] != "-1" else (end - start) // 2
            summit = start + summit_offset

            peak = {
                "chrom": chrom,
                "start": start,
                "end": end,
                "summit": summit,
                "signal_value": signal_value,
                "qvalue": qvalue,
            }
            # keep_raw_line: needed later when we want to re-write a filtered
            # narrowPeak file (Step 6) -- we filter based on computed distance,
            # but need the *original* untouched line to write back out.
            if keep_raw_line:
                peak["raw_line"] = line if line.endswith("\n") else line + "\n"

            peaks.append(peak)
    return peaks


# ### **STEP 2: Load gene TSS reference table**
# Load a TSS bed file into a list of gene dicts, one row per gene.
# 
# WHY: narrowPeak files carry zero gene information. This is the
# independent reference table needed to translate "genomic coordinate"
# into "gene identity". In practice this comes from a GENCODE GTF,
# reduced down to one TSS coordinate per gene (start coord for +
# strand genes, end coord for - strand genes).

# In[4]:


def load_tss(tss_bed_path):
    genes = []
    with open(tss_bed_path) as f:
        for line in f:
            cols = line.rstrip("\n").split("\t")
            genes.append({
                "chrom": cols[0],
                "tss": int(cols[1]),
                "name": cols[3],
                "strand": cols[5],
            })
    return genes


# ### **STEP 3: Assign each peak to its nearest gene TSS**
# For each peak, find the closest gene TSS on the same chromosome.
# 
# WHY: This is the actual "linear-distance regulatory assignment" step
# discussed earlier -- the thing Hi-C would later refine. Doing it here
# in pure Python (rather than shelling out to bedtools) keeps the
# pipeline self-contained and easy to swap out later (e.g. replacing
# this function's internals with a Hi-C-loop-based assignment is a
# drop-in replacement -- same input/output shape).
# 
# NOTE: for large chromosome-scale datasets you'd want this to be sorted
# + a smarter nearest-neighbor search (or just call bedtools closest,
# as shown earlier) rather than an O(n*m) scan. For 30-60 TFs at ChIP-seq
# peak-count scale (thousands of peaks, ~20k genes) this brute-force
# version is still fast enough to just work.

# In[5]:


def assign_nearest_gene(peaks, genes):
    # group genes by chromosome so we don't compare against genes on
    # other chromosomes
    genes_by_chrom = {}
    for g in genes:
        genes_by_chrom.setdefault(g["chrom"], []).append(g)

    assignments = []
    for p in peaks:
        candidates = genes_by_chrom.get(p["chrom"], [])
        if not candidates:
            continue  # no genes annotated on this chromosome, skip peak

        # find gene with minimum distance from peak summit to TSS
        nearest = min(candidates, key=lambda g: abs(g["tss"] - p["summit"]))
        distance = abs(nearest["tss"] - p["summit"])

        assignment = {
            "gene": nearest["name"],
            "signal_value": p["signal_value"],
            "qvalue": p["qvalue"],
            "distance_bp": distance,
        }
        # carry the raw narrowPeak line through if parse_narrowpeak kept it
        # (needed by the ML-filtering step to write filtered peak files)
        if "raw_line" in p:
            assignment["raw_line"] = p["raw_line"]

        assignments.append(assignment)
    return assignments


# ### **STEP 4: Build the graph across all TFs**
# Loop over every narrowPeak file in narrowpeak_dir (one per TF),
# assign peaks to genes, and accumulate everything into one
# networkx DiGraph.
# 
# WHY a DiGraph: TF -> gene is directional (regulator -> target).
# We also tag node types ("TF" or "gene") as node attributes so the
# graph can be treated as bipartite/multipartite later even though
# networkx doesn't enforce bipartite-ness structurally.

# In[6]:


def build_graph(narrowpeak_dir, tss_bed_path, qvalue_threshold=1.3):
    genes = load_tss(tss_bed_path)
    G = nx.DiGraph()

    narrowpeak_files = glob.glob(os.path.join(narrowpeak_dir, "*.narrowPeak"))

    for path in narrowpeak_files:
        tf_name = os.path.splitext(os.path.basename(path))[0]

        peaks = parse_narrowpeak(path, qvalue_threshold=qvalue_threshold)
        assignments = assign_nearest_gene(peaks, genes)

        G.add_node(tf_name, node_type="TF")

        for a in assignments:
            gene = a["gene"]
            G.add_node(gene, node_type="gene")

            # WHY: one TF often has multiple peaks near the same gene
            # (e.g. multiple binding sites in a promoter/enhancer cluster).
            # We collapse these into a single edge, keeping the
            # strongest (max signal_value) peak's stats as the edge weight,
            # rather than creating parallel edges. This keeps downstream
            # graph metrics (degree, centrality) clean and interpretable.
            if G.has_edge(tf_name, gene):
                if a["signal_value"] > G[tf_name][gene]["weight"]:
                    G[tf_name][gene]["weight"] = a["signal_value"]
                    G[tf_name][gene]["distance_bp"] = a["distance_bp"]
                    G[tf_name][gene]["qvalue"] = a["qvalue"]
            else:
                G.add_edge(
                    tf_name, gene,
                    weight=a["signal_value"],
                    distance_bp=a["distance_bp"],
                    qvalue=a["qvalue"],
                )

    return G


# ### **<span style="color: red">-----------------------------------Main----------------------------------------</span>**
# ### **STEP 5: Run + check output**

# In[8]:


#Set working directory
#repo_root ="chipseq/"
#os.chdir(repo_root)

narrowpeak_dir = "../raw_data/peaks_unfiltered/" # "../results/macs3/"  # name of folder with narrowpeak files. only those will be used so other stuff can be there too
tss_bed_path="../reference_data/2026-07-31_sorted-gencode-tss-protein-encoding.bed"
# First run: ../reference_data/2026-07-30_sorted-gencode-tss-with-ncRNA.bed
# Second run: ../reference_data/2026-07-31_sorted-gencode-tss-protein-encoding.bed

G = build_graph(
    narrowpeak_dir=narrowpeak_dir,
    tss_bed_path=tss_bed_path, 
    qvalue_threshold=1.3
)

print(f"Nodes: {G.number_of_nodes()}  Edges: {G.number_of_edges()}")

tf_nodes = [n for n, d in G.nodes(data=True) if d["node_type"] == "TF"]
gene_nodes = [n for n, d in G.nodes(data=True) if d["node_type"] == "gene"]
print(f"  TF nodes: {len(tf_nodes)}   Gene nodes: {len(gene_nodes)}")

#print("\nEdges:")
#for u, v, data in G.edges(data=True):
#    print(f"  {u} -> {v}   weight={data['weight']:.2f}  "
#            f"distance={data['distance_bp']}bp  qvalue={data['qvalue']:.2f}")


# In[ ]:


# save for analysis
output_path = "../results/networks/DATE_grn-without-model"
#nx.write_gexf(G, output_path + ".gexf")
nx.write_graphml(G, output_path + ".graphml")
print("\nSaved graph without model")


# ### **Step 5b: Fit the two-state model per TF, compute spurious-binding cutoff, filter peaks**
# 
# For each TF, this:
# 1. Re-parses that TF's narrowPeak file, this time keeping the raw line (needed to write a filtered file back out) and the peak-to-TSS distance already computed by `assign_nearest_gene`.
# 2. Fits the two-state model (`model_fit` from `utils.py`) to that TF's distance distribution, giving `(rb, tau, rs)` -- biological binding scale, decay rate, and spurious/background binding rate, specific to that TF.
# 3. Uses `n_max_true` to compute the distance at which the spurious-to-true binding ratio crosses a chosen threshold (default 0.1, i.e. spurious binding is at most 10% of true binding at that distance). This is the TF-specific cutoff, replacing a single flat distance cutoff for every TF.
# 4. Keeps only peaks within that cutoff, and writes them to a new narrowPeak file in `out_dir` -- same filename, same format, just fewer rows -- so Step 6 (which already expects a `peaks_filtered/` folder) can rebuild the graph from these filtered files with no further changes needed.
# 
# WARNING printed if a TF has too few peaks (<20) passing the qvalue filter -- the curve fit becomes unreliable with very few data points, and the resulting cutoff shouldn't be trusted at face value.

# In[ ]:


import pandas as pd
from utils import model, model_fit, model_true, n_max_true


def fit_thresholds_and_filter(narrowpeak_dir, tss_bed_path, out_dir,
                               qvalue_threshold=1.3, spurious_ratio_threshold=0.1):
    genes = load_tss(tss_bed_path)
    os.makedirs(out_dir, exist_ok=True)

    narrowpeak_files = glob.glob(os.path.join(narrowpeak_dir, "*.narrowPeak"))
    fit_summary = []

    for path in narrowpeak_files:
        tf_name = os.path.splitext(os.path.basename(path))[0]

        # keep_raw_line=True: we need the untouched original line later to
        # write the filtered file back out in the same format
        peaks = parse_narrowpeak(path, qvalue_threshold=qvalue_threshold, keep_raw_line=True)
        assignments = assign_nearest_gene(peaks, genes)

        df = pd.DataFrame(assignments)
        if df.empty:
            print(f"WARNING: {tf_name} had 0 peaks pass filtering/assignment -- skipping")
            continue
        # utils.py's model_fit()/model()/n_max_true() expect a column
        # literally named "min_dist" -- rename to match, since our own
        # pipeline calls the same thing "distance_bp"
        df["min_dist"] = df["distance_bp"]

        if len(df) < 20:
            print(f"WARNING: {tf_name} has only {len(df)} peaks passing qvalue "
                  f"filter -- model fit may be unreliable, inspect this TF's cutoff carefully.")

        # fit the two-state model to this TF's peak-distance distribution
        rb, tau, rs = model_fit(df)

        # distance at which spurious/true binding ratio crosses the chosen threshold
        cutoff = n_max_true(rb, tau, rs, [spurious_ratio_threshold]).Distance.iloc[0]

        kept = df[df.distance_bp <= cutoff]

        # write filtered peaks back out as a normal narrowPeak file, so Step 6
        # can read it exactly like any other narrowPeak file
        out_path = os.path.join(out_dir, tf_name + ".narrowPeak")
        with open(out_path, "w") as f_out:
            for line in kept["raw_line"]:
                f_out.write(line)

        fit_summary.append({
            "TF": tf_name,
            "rb": rb, "tau": tau, "rs": rs,
            "cutoff_bp": cutoff,
            "n_peaks_total": len(df),
            "n_peaks_kept": len(kept),
        })

        print(f"{tf_name}: rb={rb:.2f} tau={tau:.1f} rs={rs:.4f} -> "
              f"cutoff={cutoff:.0f}bp, kept {len(kept)}/{len(df)} peaks")

    return pd.DataFrame(fit_summary)


# ### **Run the fit + filter step**
# 
# Reads from the same `narrowpeak_dir` used in Step 5, writes filtered peaks to `../results/peaks_filtered/` (the folder Step 6 already expects).

# In[ ]:


fit_summary = fit_thresholds_and_filter(
    narrowpeak_dir=narrowpeak_dir,          # same input folder as Step 5
    tss_bed_path=tss_bed_path,              # same TSS reference as Step 5
    out_dir="../results/peaks_filtered/",   # matches Step 6's expected input
    qvalue_threshold=1.3,
    spurious_ratio_threshold=0.1,           # keep binding until spurious <= 10% of true
)

fit_summary


# ### **Step 6. Make graph again after filtering with ML model**
# 

# In[ ]:


G = build_graph(
    narrowpeak_dir="../results/peaks_filtered/", # folder with narrowpeak files
    tss_bed_path=tss_bed_path,
    qvalue_threshold=1.3 # needed?
)

print(f"Nodes: {G.number_of_nodes()}  Edges: {G.number_of_edges()}")

tf_nodes = [n for n, d in G.nodes(data=True) if d["node_type"] == "TF"]
gene_nodes = [n for n, d in G.nodes(data=True) if d["node_type"] == "gene"]
print(f"  TF nodes: {len(tf_nodes)}   Gene nodes: {len(gene_nodes)}")


# In[ ]:


# save for analysis
output_path_2 = "../results/networks/DATE-grn-with-model"
#nx.write_gexf(G, output_path + ".gexf")
nx.write_graphml(G, output_path_2 + ".graphml")
print("\nSaved graph with model")

