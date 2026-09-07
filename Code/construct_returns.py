'''
Constructs annualized h-year forward log real total returns on S&P 500
following Marin and Singh (2026).
- Inputs:  ie_data.xlsx, caevfcf_data2.xlsx
- Outputs: caevfcf_data3.xlsx
'''
import pandas as pd
import numpy as np
import os

base_dir    = " *** BASE DIRECTORY HERE *** "
data_dir    = os.path.join(base_dir, "Data")
derived_dir = os.path.join(base_dir, "Derived")

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
df_caevfcf_filepath = os.path.join(derived_dir, "caevfcf_data2.xlsx")
df_caevfcf = pd.read_excel(df_caevfcf_filepath, sheet_name="CAEVFCF")
df_caevfcf = df_caevfcf.set_index('Dates')

'''
Constructing real total returns
'''
# Annual real total return: R_real_t = (P_t + D_t) / P_{t-1} * CPI_{t-1}/CPI_t - 1
df_shiller['R_real'] = (
    (df_shiller['P'] + df_shiller['D']) / df_shiller['P'].shift(1)
    * df_shiller['CPI'].shift(1) / df_shiller['CPI']
    - 1
)

df_shiller['R_real'] = pd.to_numeric(df_shiller['R_real'], errors='coerce')
log1r = np.log(1 + df_shiller['R_real'])

'''
Constructing forward returns for h = 1, 5, 10
'''
for h in [1, 5, 10]:
    df_shiller[f'fwd_return_{h}yr'] = (
        sum(log1r.shift(-j) for j in range(1, h+1)) / h
    )

'''
Appending to df_caevfcf
'''
df_caevfcf['fwd_return_1yr']  = df_shiller['fwd_return_1yr'].values
df_caevfcf['fwd_return_5yr']  = df_shiller['fwd_return_5yr'].values
df_caevfcf['fwd_return_10yr'] = df_shiller['fwd_return_10yr'].values
'''
Saving
'''

df_caevfcf.to_excel(os.path.join(derived_dir, "caevfcf_data3.xlsx"), sheet_name="CAEVFCF")