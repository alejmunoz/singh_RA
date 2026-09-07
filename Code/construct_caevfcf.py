'''
Constructs CAEVFCF following Equation (6) from Marin and Singh (2026).
- Appends CPI from Shiller (ie_data.xlsx) to derived dataset (caevfcf_data1.xlsx)
- Computes real FCF, real V, and 10-year trailing average of real FCF
- Inputs:  caevfcf_data1.xlsx, ie_data.xlsx
- Outputs: caevfcf_data2.xlsx, caevfcf_timeseries.png
'''

import pandas as pd
import os
import matplotlib.pyplot as plt

base_dir        = " *** BASE DIRECTORY HERE *** "
data_dir        = os.path.join(base_dir, "Data")
derived_dir     = os.path.join(base_dir, "Derived")
figures_dir     = os.path.join(base_dir, "Figures")

'''
Loading datasets
'''

# Shiller data
df_shiller_filepath = os.path.join(data_dir, "ie_data.xlsx")
df_shiller = pd.read_excel(df_shiller_filepath, sheet_name="Data", skiprows=7)

# Own derived dataset
df_caevfcf_filepath = os.path.join(derived_dir, "caevfcf_data1.xlsx")
df_caevfcf = pd.read_excel(df_caevfcf_filepath, sheet_name="CAEVFCF")

'''
Adding CPI from Shiller to derived df
'''

# Filter for December only
df_shiller = df_shiller[df_shiller['Date'].astype(str).str.endswith('.12')]

# Convert index to year only (1929.12 -> 1929)
df_shiller['Date'] = df_shiller['Date'].astype(str).str.split('.').str[0].astype(int)
df_shiller = df_shiller.set_index('Date')

# Filter to start at 1929
df_shiller = df_shiller[df_shiller.index >= 1929]

# Append CPI
df_caevfcf['CPI'] = df_shiller['CPI'].values


'''
Calculating CAEVFCF
'''

# Set Dates as index
df_caevfcf = df_caevfcf.set_index('Dates')

# Real FCF and real V
df_caevfcf['FCF_real'] = df_caevfcf['Free Cash Flow'] / df_caevfcf['CPI']
df_caevfcf['V_real']   = df_caevfcf['Enterprise Value'] / df_caevfcf['CPI']

# 10-year trailing average of real FCF
df_caevfcf['FCF_real_10yr'] = df_caevfcf['FCF_real'].rolling(window=10).mean()

# CAEVFCF
df_caevfcf['CAEVFCF'] = df_caevfcf['V_real'] / df_caevfcf['FCF_real_10yr']

# Saving derived dataset
df_caevfcf.to_excel(os.path.join(derived_dir, "caevfcf_data2.xlsx"), sheet_name="CAEVFCF")

'''
CAEVFCF time series plot
'''

fig, ax = plt.subplots(figsize=(12, 5))
ax.plot(df_caevfcf.index, df_caevfcf['CAEVFCF'])
ax.set_title('CAEVFCF over Time')
ax.set_xlabel('Year')
ax.set_ylabel('CAEVFCF')
plt.tight_layout()
plt.savefig(os.path.join(figures_dir, "caevfcf_timeseries.png"), dpi=300)
plt.show()




