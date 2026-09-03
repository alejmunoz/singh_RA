'''
Merges CAEVFCF/CAPE predictors and forward returns from caevfcf_final.csv
with Goyal et al (2024) predictors from goyal_subset.csv for comparison.
- Inputs:  caevfcf_final.csv, goyal_subset.csv
- Outputs: comparison_data.csv
'''

import pandas as pd
import os

base_dir    = " *** BASE DIRECTORY HERE *** "
data_dir    = os.path.join(base_dir, "Data")
derived_dir = os.path.join(base_dir, "Derived")

'''
Loading datasets
'''
# CAEVFCF final dataset
df_caevfcf = pd.read_csv(os.path.join(derived_dir, "caevfcf_final.csv"))
df_caevfcf = df_caevfcf.set_index('Dates')

# Goyal subset
df_goyal = pd.read_csv(os.path.join(derived_dir, "goyal_subset.csv"))
df_goyal = df_goyal.set_index('yyyy')
df_goyal = df_goyal[df_goyal.index >= 1938]

'''
Subsetting caevfcf to relevant columns
'''
cols_caevfcf = ['log_CAEVFCF', 'log_CAPE', 'fwd_return_1yr', 
                'fwd_return_5yr', 'fwd_return_10yr']
df_caevfcf = df_caevfcf[cols_caevfcf]

'''
Merging on year index
'''
df_comparison = df_caevfcf.join(df_goyal, how='inner')

'''
Saving
'''
df_comparison.to_csv(os.path.join(derived_dir, "comparison_data.csv"))