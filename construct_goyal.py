'''
Subsets Goyal et al (2024) annual predictors for comparison against
CAEVFCF and CAPE.
- Inputs:  goyal_Data2024.xlsx
- Outputs: goyal_subset.csv
'''

import pandas as pd
import os

base_dir    = " *** BASE DIRECTORY HERE *** "
data_dir    = os.path.join(base_dir, "Data")
derived_dir = os.path.join(base_dir, "Derived")

'''
Loading Goyal et al (2024) annual data
'''
goyal_filepath = os.path.join(data_dir, "goyal_Data2024.xlsx")
df_goyal = pd.read_excel(goyal_filepath, sheet_name="Annual")

'''
Subsetting to relevant predictors
'''
cols = ["yyyy", "tchi", "shtint", "tbl", "lty", "tms", "pce", 
        "crdstd", "i/k", "accrul", "gpce", "eqis", "e/p", "cay", "skew"]
df_goyal = df_goyal[cols]
df_goyal = df_goyal.set_index("yyyy")

'''
Saving
'''
df_goyal.to_csv(os.path.join(derived_dir, "goyal_subset.csv"))