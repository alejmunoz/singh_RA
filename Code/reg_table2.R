# =============================================================================
# OLS predictive regressions of annualized 10-year forward log real S&P 500
# returns on lagged valuation ratios, replicating Table 2 of Marin and Singh (2026).
# - Inputs:  caevfcf_final.csv
# - Outputs: TBD
# =============================================================================

library(readr)

# -----------------------------------------------------------------------------
# Directories
# -----------------------------------------------------------------------------
base_dir    = " *** BASE DIRECTORY HERE *** "
data_dir    = file.path(base_dir, "Data")
derived_dir = file.path(base_dir, "Derived")
figures_dir = file.path(base_dir, "Figures")

# -----------------------------------------------------------------------------
# Load data
# -----------------------------------------------------------------------------
df = read_csv(file.path(derived_dir, "caevfcf_final.csv"))

# -----------------------------------------------------------------------------
# Panel A: OLS predictive regressions, 1938 onwards
# -----------------------------------------------------------------------------
df_1938 = df[df$Dates >= 1938, ]

# log(CAPE)
reg_cape = lm(fwd_return_10yr ~ log_CAPE, data = df_1938)
summary_cape = summary(reg_cape)
summary_cape

# log(CAEVFCF)
reg_caevfcf = lm(fwd_return_10yr ~ log_CAEVFCF, data = df_1938)
summary_caevfcf = summary(reg_caevfcf)
summary_caevfcf

# Print R-squared and N
cat("log(CAPE)    R2:", round(summary_cape$r.squared, 4), "| N:", nobs(reg_cape), "\n")
cat("log(CAEVFCF) R2:", round(summary_caevfcf$r.squared, 4), "| N:", nobs(reg_caevfcf), "\n")

# -----------------------------------------------------------------------------
# Panel A: OLS predictive regressions, post-1954
# -----------------------------------------------------------------------------
df_post1954 = df[df$Dates >= 1954, ]

# log(CAPE)
reg_cape_post1954 = lm(fwd_return_10yr ~ log_CAPE, data = df_post1954)
summary_cape_post1954 = summary(reg_cape_post1954)
summary_cape_post1954

# log(CAEVFCF)
reg_caevfcf_post1954 = lm(fwd_return_10yr ~ log_CAEVFCF, data = df_post1954)
summary_caevfcf_post1954 = summary(reg_caevfcf_post1954)
summary_caevfcf_post1954

# Print R-squared and N
cat("log(CAPE)    R2 post-1954:", round(summary_cape_post1954$r.squared, 4), 
    "| N:", nobs(reg_cape_post1954), "\n")
cat("log(CAEVFCF) R2 post-1954:", round(summary_caevfcf_post1954$r.squared, 4), 
    "| N:", nobs(reg_caevfcf_post1954), "\n")

# -----------------------------------------------------------------------------
# Panel B: Out-of-sample R2, expanding window
# -----------------------------------------------------------------------------

oos_r2 = function(data, predictor, start_year) {
  
  data = data[!is.na(data[[predictor]]) & !is.na(data$fwd_return_10yr), ]
  data = data[order(data$Dates), ]
  
  n = nrow(data)
  sse_model = 0
  sse_bench = 0
  
  start_idx = which(data$Dates == start_year)
  
  for (t in start_idx:n) {
    
    # Training data: all observations before t
    train = data[1:(t-1), ]
    
    # Model forecast
    fit   = lm(as.formula(paste("fwd_return_10yr ~", predictor)), data = train)
    yhat  = predict(fit, newdata = data[t, ])
    
    # Benchmark forecast: prevailing mean
    ybar  = mean(train$fwd_return_10yr)
    
    # Actual value
    y     = data$fwd_return_10yr[t]
    
    sse_model = sse_model + (y - yhat)^2
    sse_bench = sse_bench + (y - ybar)^2
  }
  
  r2_oos = 1 - sse_model / sse_bench
  n_oos  = n - start_idx + 1
  return(list(r2_oos = round(as.numeric(r2_oos), 4), n = as.integer(n_oos)))
}

# -----------------------------------------------------------------------------
# Panel B: Results
# -----------------------------------------------------------------------------
start_years = c(1960, 1970, 1980)

for (yr in start_years) {
  cape_res    = oos_r2(df, "log_CAPE",    yr)
  caevfcf_res = oos_r2(df, "log_CAEVFCF", yr)
  cat("Start year:", yr, "\n")
  cat("  log(CAPE)    OOS R2:", cape_res$r2_oos,    "| N:", cape_res$n,    "\n")
  cat("  log(CAEVFCF) OOS R2:", caevfcf_res$r2_oos, "| N:", caevfcf_res$n, "\n")
}