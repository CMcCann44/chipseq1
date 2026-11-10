# From "A Principled Approach to the Identification of Functional Targets of Transcription Factor Binding Sites"
# By Maalavika Pillai and Luis A. Nunes Amaral
# https://github.com/amarallab/TF_Positional_Distribution_Model

#Load required modules
import os
import pandas as pd 
import urllib.request 
import numpy as np

#Set working directory
working_dir ="TF_Positional_Distribution_Model/data/ENCODE/"
os.chdir(working_dir)

#15 TFs used for the analyses
tfs = ['CEBPB', 'CTCF', 'ELK1', 'EP300', 'ESRRA', 'HDAC2', 'MAFK', 'MAX',
       'MAZ', 'MYC', 'RAD21', 'RCOR1', 'REST', 'RFX5', 'SIN3A']

#Select files corresponding to IDR thresholded peaks
df = pd.read_table('metadata.tsv')
targets = [str(i).split('-')[0] for i in df['Experiment target'] ]
df['Experiment target'] = targets


### TF ChIP-seq
df_sub = df.loc[(df['Output type'] == 'IDR thresholded peaks') & 
                (df.Assay == 'TF ChIP-seq') &
                (df['Experiment target'].isin(tfs)) &
                (df['File assembly'] == 'GRCh38')&
                ([',' not in str(i) for i in df['Biological replicate(s)']])]


#Create directories to organize ChIP-seq files if they don't exist
for idx, line in df_sub.iterrows():
    cl = line['Biosample term name']
    if not os.path.exists(cl):
        os.mkdir(cl)
        os.mkdir(cl+ '/ChIP-seq')
    
    file = 'https://www.encodeproject.org/files/' + line['File accession']+ '/@@download/' + line['File accession']+ '.bed.gz'
    if type(line['Experiment target']) == str:
        savefile = cl + '/ChIP-seq' +'/'+ line['File accession'] + '_' + line['Experiment target'].split('-')[0] + '.bed.gz'
    else: 
        savefile = cl + '/ChIP-seq' + '/'+ line['File accession'] + '.bed.gz'
    if not os.path.exists(savefile):   
        urllib.request.urlretrieve(file, savefile)   

### ATAC-seq
df_sub = df.loc[(df['Output type'] == 'IDR thresholded peaks') & 
                (df.Assay == 'ATAC-seq') &
                (df['File assembly'] == 'GRCh38')&
                ([',' not in str(i) for i in df['Biological replicate(s)']])]

#Create directories to organize ATAC-seq files if they don't exist
for idx, line in df_sub.iterrows():
    cl = line['Biosample term name']
    if not os.path.exists(cl + '/ATAC-seq'):
        os.mkdir(cl+ '/ATAC-seq')
    
    file = 'https://www.encodeproject.org/files/' + line['File accession']+ '/@@download/' + line['File accession']+ '.bed.gz'
    savefile = cl + '/ATAC-seq' + '/'+ line['File accession'] + '.bed.gz'
    if not os.path.exists(savefile):   
        urllib.request.urlretrieve(file, savefile)   
