'''
Merges all constructed variables, takes logs, and saves final dataset for R.
- Inputs:  caevfcf_data3.xlsx, ie_data.xlsx
- Outputs: caevfcf_final.csv, log_caevfcf_vs_log_cape.png
'''
import pandas as pd
import numpy as np
import os
import matplotlib.pyplot as plt


base_dir    = " *** BASE DIRECTORY HERE *** "
data_dir    = os.path.join(base_dir, "Data")
derived_dir = os.path.join(base_dir, "Derived")
figures_dir = os.path.join(base_dir, "Figures")

'''
Loading datasets
'''
# Shiller data
df_shiller_filepath = os.path.join(data_dir, "ie_data.xlsx")
df_shiller = pd.read_excel(df_shiller_filepath, sheet_name="Data", skiprows=7)

# Filter December, convert to year
df_shiller = df_shiller[df_shiller['Date'].astype(str).str.endswith('.12')]
df_shiller['Date'] = df_shiller['Date'].astype(str).str.split('.').str[0].astype(int)
df_shiller = df_shiller.set_index('Date')
df_shiller = df_shiller[df_shiller.index >= 1929]

# Derived dataset
df_caevfcf_filepath = os.path.join(derived_dir, "caevfcf_data3.xlsx")
df_caevfcf = pd.read_excel(df_caevfcf_filepath, sheet_name="CAEVFCF")
df_caevfcf = df_caevfcf.set_index('Dates')


'''
Appending CAPE from Shiller
'''
df_caevfcf['CAPE'] = df_shiller['CAPE'].values

'''
Log transforms
'''
df_caevfcf['log_CAEVFCF'] = np.log(df_caevfcf['CAEVFCF'])
df_caevfcf['log_CAPE']    = np.log(df_caevfcf['CAPE'])

# Remove 2025
df_caevfcf = df_caevfcf[df_caevfcf.index <= 2024]

'''
log(CAEVFCF) and log(CAPE) time series plot
'''

fig, ax = plt.subplots(figsize=(12, 5))
df_plot = df_caevfcf.loc[1938:2024]
ax.plot(df_plot.index, df_plot['log_CAEVFCF'], label='log(CAEVFCF)', color='steelblue')
ax.plot(df_plot.index, df_plot['log_CAPE'],    label='log(CAPE)',    color='firebrick', linestyle='--')
ax.set_title('log(CAEVFCF) vs log(CAPE), 1938-2024')
ax.set_xlabel('Year')
ax.set_ylabel('Log Valuation Ratio')
ax.legend()
plt.tight_layout()
plt.savefig(os.path.join(figures_dir, "log_caevfcf_vs_log_cape.png"), dpi=300)
plt.show()

'''
Saving final dataset for R
'''
df_caevfcf.to_csv(os.path.join(derived_dir, "caevfcf_final.csv"))