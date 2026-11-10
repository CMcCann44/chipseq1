# Functions for building an ML model to determine biologically relevant binding of TFs
# From "A Principled Approach to the Identification of Functional Targets of Transcription Factor Binding Sites"
# By Maalavika Pillai and Luis A. Nunes Amaral
# https://github.com/amarallab/TF_Positional_Distribution_Model

###############################################
#This file contains a set of functions that are 
#commonly used throughout the analysis done in
#this paper.
###############################################


#Load required packages
import numpy as np
import os
import pandas as pd
from scipy.optimize import curve_fit

def model(x,rb,tau,rs):

    '''
    
    This function defines the cumulative positional distribution of TF binding
    events in a genome as defined by the two-state model. The total number of
    binding events occuring within a distance (x) of TSS is a sum of biologically
    relevant binding and spurious binding. 
    
    INPUT: 
    rb: Scaling factor for biologically relevant binding for a TF.
    tau: Exponential decay rate of biologically relvant binding with distance from
    TSS for a TF.
    rs: Spurious binding rate for a TF.
    
    OUTPUT: 
    float64, correponding to total number of binding events expected at distance x
    from TSS.


    '''
    
    return rb*(1-np.exp(-(x+1)/tau))/(1-np.exp(-(1/tau))) + rs*x

def model_fit(df):

    '''
    
    This function calculates the cumulative TF binding events in a dataset and
    fits the two-state model to the data. 
    
    INPUT: 
    df: pandas.DataFrame() contains a columns "min_dist" corresponding to distance
    between a gene's TSS and the closest TF binding event. 
    
    OUTPUT: 
    np.array(), parameters for the two state model (rb,tau,rs) after fitting(minimizing
    sum of squares between expected fit and observed values). 


    '''
     
    #Summarize data amd calculate cumulative number of peaks for each distance
    summary = [[i, sum(df.min_dist <= i)] for i in range(0,10000, 100)]
    summary = pd.DataFrame(summary, columns =['interval','cumulative'])
    xdata = summary.interval.values
    y = summary.cumulative.values
    
    #Fit data
    popt1, pcov1 = curve_fit(model, xdata, y, p0 =[100,2000,0], maxfev = 4000)

    
    return pd.Series(popt1)


def model_true(x,rb,tau,rs):

    '''
    
    This function defines the cumulative positional distribution of biologically
    relevant TF binding events in a genome as defined by the two-state model.
    
    INPUT: 
    rb: Scaling factor for biologically relevant binding for a TF.
    tau: Exponential decay rate of biologically relvant binding with distance from
    TSS for a TF.
    rs: Spurious binding rate for a TF.
    
    OUTPUT: 
    float64, correponding to number of biologically relevant binding events expected
    at distance x from TSS.


    '''
    
    return rb*(1-np.exp(-(x+1)/tau))/(1-np.exp(-(1/tau))) 

def true_spur_ratio(x,rb,tau,rs):

    '''
    
    This function defines the ratio of spurious binding events to biologically
    relevant TF binding events in a genome observed upto a distance (x) of the TSS.
    
    INPUT: 
    rb: Scaling factor for biologically relevant binding for a TF.
    tau: Exponential decay rate of biologically relvant binding with distance from
    TSS for a TF.
    rs: Spurious binding rate for a TF.
    
    OUTPUT: 
    float64, correponding to number of biologically relevant binding events expected
    at distance x from TSS.


    '''
    return rs*x/(rb*(1-np.exp(-(x+1)/tau))/(1-np.exp(-(1/tau))))







def n_max_true(rb,tau,rs, thresholds):
    
    '''
    
    This function estimates the distance from TSS at which the ratio of 
    spurious binding events to biologically relevant TF binding events in a genome 
    is equal to a specific threshold level.
    
    INPUT: 
    rb: Scaling factor for biologically relevant binding for a TF.
    tau: Exponential decay rate of biologically relvant binding with distance from
    TSS for a TF.
    rs: Spurious binding rate for a TF.
    threshold: list of threshold values for ratio of spurious to biologically relevant
    binding events
    
    OUTPUT: 
    pd.DataFrame(), correponding to  distance from TSS at which the ratio of 
    spurious binding events to biologically relevant TF binding events in a genome 
    is equal to a specific threshold (alpha) level.



    '''

    values = []
    for threshold in thresholds:
        y = [true_spur_ratio(i,rb,tau,rs) for i in np.linspace(1,10000,10000)]
        y_thresh = [idx+1 for idx,i in enumerate(y) if i <= threshold]
        if y_thresh:
            values.append([max(y_thresh), y[max(y_thresh)-1]])
        else:
            values.append([np.argmin(y)+1,min(y)])

    return pd.DataFrame(values, columns =['Distance','Alpha'])
