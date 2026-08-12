# Replication of Marin and Singh (2026): Macroeconomic Free Cash Flow Yield as a Return Predictor

This repository contains the data pipeline and econometric analysis scripts for replicating the empirical results in **Marin and Singh (2026)**, *"Macroeconomic Free Cash Flow Yield as a Return Predictor"*.

The codebase constructs **CAEVFCF** (Cyclically Adjusted Enterprise Value to Free Cash Flow ratio) using U.S. Integrated Macroeconomic Accounts (IMA) and NIPA data, and evaluates its in-sample and out-of-sample forecasting performance for long-horizon real S&P 500 returns against Shiller's CAPE and Goyal et al. (2024) predictors.

---

## 1. Directory Structure

```text
.
├── Data/                             # Raw source datasets
│   ├── CleandataMarch2026extra.xlsx  # Raw macro data (IMA/NIPA); manually processed into caevfcf_data1.xlsx
│   ├── goyal_Data2024.xlsx           # Goyal et al. (2024) annual predictors
│   └── ie_data.xlsx                  # Shiller's online dataset (P, D, CPI, CAPE)
├── Derived/                          # Intermediate & final constructed datasets
│   ├── caevfcf_data1.xlsx            # Manually extracted subset from CleandataMarch2026extra.xlsx
│   ├── caevfcf_data2.xlsx            # Appended CPI; real FCF, real V, 10-year trailing average real FCF, CAEVFCF
│   ├── caevfcf_data3.xlsx            # Appended forward log real total returns (h = 1, 5, 10)
│   ├── caevfcf_final.csv             # Final dataset with log transforms for R analysis
│   ├── goyal_subset.csv              # Processed Goyal predictors subset
│   └── comparison_data.csv           # Merged dataset for Goyal predictor comparisons
├── Figures/                          # Generated plots and time series visuals
│   ├── caevfcf_timeseries.png        # Time-series plot of constructed CAEVFCF
│   └── log_caevfcf_vs_log_cape.png   # Comparison plot: log(CAEVFCF) vs. log(CAPE), 1938-2024
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

## 2. Execution Order & Pipeline Walkthrough

To reproduce the empirical pipeline from raw data to table estimation, run the scripts in the following sequence:

### Sequence A: Marin & Singh (2026) Core Pipeline

#### 1. `construct_caevfcf.py`
* **Description:** Constructs CAEVFCF following Equation (6) from Marin and Singh (2026). Appends December CPI from Shiller (`ie_data.xlsx`) to the manually extracted dataset (`caevfcf_data1.xlsx`), then computes real FCF, real $V$, the 10-year trailing average of real FCF, and CAEVFCF. Also generates a time series plot of CAEVFCF.
* **Inputs:** `Derived/caevfcf_data1.xlsx`, `Data/ie_data.xlsx`
* **Outputs:** `Derived/caevfcf_data2.xlsx`, `Figures/caevfcf_timeseries.png`

#### 2. `construct_returns.py`
* **Description:** Constructs annualized $h$-year forward log real total returns on the S&P 500 for $h = 1, 5, 10$ following Marin and Singh (2026). Real total returns include reinvested dividends and are deflated by December-to-December CPI growth.
* **Inputs:** `Data/ie_data.xlsx`, `Derived/caevfcf_data2.xlsx`
* **Outputs:** `Derived/caevfcf_data3.xlsx`

#### 3. `construct_final.py`
* **Description:** Appends CAPE from Shiller, takes natural logs of valuation ratios ($\log(CAEVFCF)$, $\log(CAPE)$), filters sample to 1929–2024, and saves the final dataset for R regression analysis. Also generates a time series comparison plot of $\log(CAEVFCF)$ vs. $\log(CAPE)$ from 1938–2024.
* **Inputs:** `Derived/caevfcf_data3.xlsx`, `Data/ie_data.xlsx`
* **Outputs:** `Derived/caevfcf_final.csv`, `Figures/log_caevfcf_vs_log_cape.png`

#### 4. `reg_table2.R`
* **Description:** Replicates Table 2 of Marin and Singh (2026). **Panel A** estimates OLS predictive regressions of annualized 10-year forward log real S&P 500 returns on $\log(CAEVFCF)$ and $\log(CAPE)$, for two sample periods: 1938 onwards and post-1954. Reports $R^2$ and $N$. **Panel B** computes expanding-window OOS $R^2$ (Goyal-Welch, 2008) for $\log(CAEVFCF)$ and $\log(CAPE)$ at $h=10$, with evaluation windows starting 1960, 1970, and 1980.
* **Inputs:** `Derived/caevfcf_final.csv`
* **Outputs:** Console output

#### 5. `reg_table6.R`
* **Description:** Replicates Table 6 of Marin and Singh (2026). Computes expanding-window OOS $R^2$ and Campbell-Thompson (2008) sign-constrained OOS $R^2$ for $\log(CAEVFCF)$ and $\log(CAPE)$ across horizons $h = 1, 5, 10$, with evaluation windows starting 1960, 1970, and 1980. Results are reported both with and without a fixed end date of 2015 ($N = 56, 46, 36$).
* **Inputs:** `Derived/caevfcf_final.csv`
* **Outputs:** Console output

---

### Sequence B: Goyal et al. (2024) Comparison Pipeline

#### 1. `construct_goyal.py`
* **Description:** Subsets Goyal et al. (2024) annual predictors to the following variables: `tchi`, `shtint`, `tbl`, `lty`, `tms`, `pce`, `crdstd`, `i/k`, `accrul`, `gpce`, `eqis`, `e/p`, `cay`, `skew`.
* **Inputs:** `Data/goyal_Data2024.xlsx`
* **Outputs:** `Derived/goyal_subset.csv`

#### 2. `construct_comparison.py`
* **Description:** Merges $\log(CAEVFCF)$, $\log(CAPE)$, and forward returns ($h = 1, 5, 10$) from `caevfcf_final.csv` with Goyal et al. (2024) predictors from `goyal_subset.csv` on matching years. Inner join on year index; Goyal data filtered to 1938 onwards.
* **Inputs:** `Derived/caevfcf_final.csv`, `Derived/goyal_subset.csv`
* **Outputs:** `Derived/comparison_data.csv`

#### 3. `reg_comparison.R`
* **Description:** Evaluates in-sample $R^2$ and OOS $R^2$ for $\log(CAEVFCF)$ and $\log(CAPE)$ against Goyal et al. (2024) predictors across $h = 1, 5, 10$ horizons. Structured in four parts:
  1. **In-sample $R^2$, 1938 onwards** for full-history predictors: `log_CAEVFCF`, `log_CAPE`, `tbl`, `lty`, `tms`, `eqis`, `e_p`
  2. **OOS $R^2$** for the same full-history predictors, with evaluation windows starting 1960, 1970, and 1980 — both with and without fixed end date of 2015
  3. **In-sample $R^2$** for shorter-history predictors (`tchi`, `shtint`, `pce`, `crdstd`, `i_k`, `accrul`, `gpce`, `cay`, `skew`), each estimated over its own available sample, alongside $\log(CAEVFCF)$ and $\log(CAPE)$ over the same period for comparison
  4. **OOS $R^2$** for shorter-history predictors with predictor-specific evaluation start years: `i_k` and `gpce` from 1960/1970/1980; `tchi` and `pce` from 1970/1980; `accrul` from 1980; `shtint` from 1988; `cay` from 1960/1970/1980; `skew` from 1970/1980. `crdstd` excluded due to insufficient observations.
* **Inputs:** `Derived/comparison_data.csv`
* **Outputs:** Console output

---

## 3. Key Methodological Formulas

* **Corporate Free Cash Flow ($FCF_t$):**
$$FCF_t = GVA_t - \text{Compensation}_t - \text{Taxes}_t - \text{Gross Investment}_t$$

* **Enterprise Value ($V_t$):**
$$V_t = \text{Market Value of Equity}_t + \text{Total Liabilities}_t - \text{Total Financial Assets}_t$$

* **Cyclically Adjusted EV/FCF ($CAEVFCF_t$):**
$$CAEVFCF_t = \frac{V_t / CPI_t}{\frac{1}{10}\sum_{j=0}^{9} FCF_{t-j} / CPI_{t-j}}$$

* **Real Total Return ($R^{real}_t$):**
$$
R^{real}_t = \frac{P^{Dec}_t + D_t}{P^{Dec}_{t-1}} \cdot \frac{CPI^{Dec}_{t-1}}{CPI^{Dec}_t}
$$

* **Forward Log Real Total Return ($r_{t \to t+h}$):**
$$r_{t \to t+h} = \frac{1}{h}\sum_{j=1}^{h} \log\left(1 + R^{real}_{t+j}\right)$$

* **Out-of-Sample $R^2$ (Goyal and Welch, 2008):**
$$R^2_{OOS} = 1 - \frac{\sum_t (r_t - \hat{r}_t)^2}{\sum_t (r_t - \bar{r}_{t-1})^2}$$

  where $\bar{r}_{t-1}$ is the expanding prevailing mean of returns up to $t-1$.

* **Campbell-Thompson (2008) Restriction:** When the expanding-window slope estimate $\hat{\beta}_t$ has the wrong sign ($\hat{\beta}_t > 0$), it is set to zero and the forecast collapses to the intercept only.

---

## 4. Environment & Coding Conventions

* **Python Dependencies:** `pandas`, `numpy`, `openpyxl`, `matplotlib`
* **R Dependencies:** `readr`, `knitr`
* **R Syntax Rules & Guidelines:**
  * Assignment operator: `=` (not `<-`)
  * Directory paths: `file.path(base_dir, "Derived", "caevfcf_final.csv")`
  * Script structure: organized into distinct section comment blocks (`# ============`)
* **Python Syntax Rules & Guidelines:**
  * Assignment operator: `=`
  * Directory paths: `os.path.join(base_dir, "Derived", "caevfcf_final.csv")`
  * Script structure: organized into distinct section comment blocks (`''' ... '''`)
  * Index columns set explicitly with `.set_index()` after loading
  * All derived files saved to `Derived/` and figures to `Figures/`
