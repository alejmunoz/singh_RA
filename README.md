# Replication of Marin and Singh (2026): Macroeconomic Free Cash Flow Yield as a Return Predictor

This repository replicates the empirical results in **Marin and Singh (2026)**, *"Macroeconomic Free Cash Flow Yield as a Return Predictor"*. The codebase constructs **CAEVFCF** (Cyclically Adjusted Enterprise Value to Free Cash Flow ratio) using BEA National Income and Product Accounts (NIPA), BEA Fixed Assets Accounts (FA), Fed Financial Accounts of the US, Statistics of Income 1945, CRSP Market Cap, and Shiller's CAPE data, and evaluates its in-sample and out-of-sample forecasting performance for long-horizon real S&P 500 returns against Shiller's CAPE and Goyal et al. (2024) predictors.

---

## 1. Directory Structure

```text
.
├── Data/                             # Raw source datasets
│   ├── CleandataMarch2026extra.xlsx  # Raw macro data (NIPA/FA/Statistics of Income 1945/CRSP Market Cap/Fed Financial Accounts)
│   ├── goyal_Data2024.xlsx           # Goyal et al. (2024) annual predictors
│   └── ie_data.xlsx                  # Shiller's online dataset (P, D, CPI, CAPE)
├── Derived/                          # Intermediate & final constructed datasets
│   ├── caevfcf_data1.xlsx            # Manually extracted subset from CleandataMarch2026extra.xlsx
│   ├── caevfcf_data2.xlsx            # Real FCF, real V, 10-year trailing average real FCF, CAEVFCF
│   ├── caevfcf_data3.xlsx            # Forward log real total returns (h = 1, 5, 10)
│   ├── caevfcf_final.csv             # Final dataset for R analysis
│   ├── goyal_subset.csv              # Processed Goyal predictors subset
│   └── comparison_data.csv           # Merged dataset for predictor comparisons
├── Figures/                          
│   ├── caevfcf_timeseries.png        
│   └── log_caevfcf_vs_log_cape.png   
├── Code/
│   ├── construct_caevfcf.py
│   ├── construct_returns.py
│   ├── construct_final.py
│   ├── construct_goyal.py
│   ├── construct_comparison.py
│   ├── reg_table2.R
│   ├── reg_table6.R
│   └── reg_comparison.R
```

---

## 2. Execution Order

### Sequence A: Marin & Singh (2026) Core Pipeline

| Step | Script | Description | Inputs | Outputs |
|------|--------|-------------|--------|---------|
| 1 | `construct_caevfcf.py` | Constructs CAEVFCF following Equation (6) | `caevfcf_data1.xlsx`, `ie_data.xlsx` | `caevfcf_data2.xlsx` |
| 2 | `construct_returns.py` | Constructs annualized forward log real total returns ($h = 1, 5, 10$) | `ie_data.xlsx`, `caevfcf_data2.xlsx` | `caevfcf_data3.xlsx` |
| 3 | `construct_final.py` | Appends CAPE, takes logs, saves final dataset | `caevfcf_data3.xlsx`, `ie_data.xlsx` | `caevfcf_final.csv` |
| 4 | `reg_table2.R` | Replicates Table 2: in-sample $R^2$ (Panel A) and OOS $R^2$ at $h=10$ (Panel B) | `caevfcf_final.csv` | — |
| 5 | `reg_table6.R` | Replicates Table 6: OOS $R^2$ and CT-constrained OOS $R^2$ at $h = 1, 5, 10$ | `caevfcf_final.csv` | — |

### Sequence B: Goyal et al. (2024) Comparison Pipeline

| Step | Script | Description | Inputs | Outputs |
|------|--------|-------------|--------|---------|
| 1 | `construct_goyal.py` | Subsets Goyal et al. (2024) annual predictors | `goyal_Data2024.xlsx` | `goyal_subset.csv` |
| 2 | `construct_comparison.py` | Merges CAEVFCF/CAPE predictors with Goyal predictors | `caevfcf_final.csv`, `goyal_subset.csv` | `comparison_data.csv` |
| 3 | `reg_comparison.R` | In-sample $R^2$ and OOS $R^2$ for CAEVFCF, CAPE, and Goyal predictors | `comparison_data.csv` | — |

---

## 3. Key Methodological Formulas

* **Corporate Free Cash Flow ($FCF_t$):**

$$
FCF_t = GVA_t - \text{Compensation}_t - \text{Taxes}_t - \text{Gross Investment}_t
$$

* **Cyclically Adjusted EV/FCF ($CAEVFCF_t$):**

$$
CAEVFCF_t = \frac{V_t / CPI_t}{\frac{1}{10}\sum_{j=0}^{9} FCF_{t-j} / CPI_{t-j}}
$$

* **Real Total Return ($R^{real}_t$):**

$$
R^{real}_t = \frac{P_t + D_t}{P_{t-1}} \cdot \frac{CPI_{t-1}}{CPI_t}
$$

* **Forward Log Real Total Return ($r_{t \to t+h}$):**

$$
r_{t \to t+h} = \frac{1}{h}\sum_{j=1}^{h} \log\left(1 + R^{real}_{t+j}\right)
$$

* **Out-of-Sample $R^2$ (Goyal and Welch, 2008):**

$$
R^2_{OOS} = 1 - \frac{\sum_t (r_t - \hat{r}_t)^2}{\sum_t (r_t - \bar{r}_{t-1})^2}
$$

where $\bar{r}_{t-1}$ is the expanding prevailing mean of returns up to $t-1$.

* **Campbell-Thompson (2008) Restriction:** When the expanding-window slope estimate $\hat{\beta}_t$ has the wrong sign ($\hat{\beta}_t > 0$), it is set to zero and the forecast collapses to the intercept only.
