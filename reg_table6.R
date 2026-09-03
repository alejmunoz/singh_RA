# =============================================================================
# Out-of-sample R2 and Campbell-Thompson (2008) constrained R2 for log(CAEVFCF) 
# and log(CAPE) at h = 1, 5, 10 year horizons, replicating Table 6 of Marin and Singh (2026).
# - Inputs:  caevfcf_final.csv
# - Outputs: TBD
# =============================================================================

library(readr)
library(knitr)

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
# OOS R2 function (no fixed end date)
# -----------------------------------------------------------------------------
oos_r2 = function(data, predictor, outcome, start_year, ct = FALSE) {
  
  data = data[!is.na(data[[predictor]]) & !is.na(data[[outcome]]), ]
  data = data[order(data$Dates), ]
  
  n         = nrow(data)
  sse_model = 0
  sse_bench = 0
  
  start_idx = which(data$Dates == start_year)
  
  for (t in start_idx:n) {
    
    # Training data: all observations before t
    train = data[1:(t-1), ]
    
    # Model fit
    fit  = lm(as.formula(paste(outcome, "~", predictor)), data = train)
    beta = coef(fit)[predictor]
    
    # CT restriction: set beta to zero if wrong sign
    if (ct & beta > 0) {
      yhat = coef(fit)["(Intercept)"]
    } else {
      yhat = predict(fit, newdata = data[t, ])
    }
    
    # Benchmark: prevailing mean
    ybar = mean(train[[outcome]])
    
    # Actual value
    y = data[[outcome]][t]
    
    sse_model = sse_model + (y - yhat)^2
    sse_bench = sse_bench + (y - ybar)^2
  }
  
  r2_oos = 1 - sse_model / sse_bench
  n_oos  = n - start_idx + 1
  return(list(r2_oos = round(as.numeric(r2_oos), 4), n = as.integer(n_oos)))
}

# -----------------------------------------------------------------------------
# OOS R2 function (fixed end date)
# -----------------------------------------------------------------------------
oos_r2_fixed = function(data, predictor, outcome, start_year, end_year, ct = FALSE) {
  
  data = data[!is.na(data[[predictor]]) & !is.na(data[[outcome]]), ]
  data = data[order(data$Dates), ]
  data = data[data$Dates <= end_year, ]
  
  n         = nrow(data)
  sse_model = 0
  sse_bench = 0
  
  start_idx = which(data$Dates == start_year)
  
  for (t in start_idx:n) {
    
    # Training data: all observations before t
    train = data[1:(t-1), ]
    
    # Model fit
    fit  = lm(as.formula(paste(outcome, "~", predictor)), data = train)
    beta = coef(fit)[predictor]
    
    # CT restriction: set beta to zero if wrong sign
    if (ct & beta > 0) {
      yhat = coef(fit)["(Intercept)"]
    } else {
      yhat = predict(fit, newdata = data[t, ])
    }
    
    # Benchmark: prevailing mean
    ybar = mean(train[[outcome]])
    
    # Actual value
    y = data[[outcome]][t]
    
    sse_model = sse_model + (y - yhat)^2
    sse_bench = sse_bench + (y - ybar)^2
  }
  
  r2_oos = 1 - sse_model / sse_bench
  n_oos  = n - start_idx + 1
  return(list(r2_oos = round(as.numeric(r2_oos), 4), n = as.integer(n_oos)))
}

# -----------------------------------------------------------------------------
# Results: no fixed end date
# -----------------------------------------------------------------------------
horizons    = c(1, 5, 10)
start_years = c(1960, 1970, 1980)
predictors  = c("log_CAEVFCF", "log_CAPE")

for (h in horizons) {
  outcome = paste0("fwd_return_", h, "yr")
  cat("== Horizon h =", h, "==\n")
  for (yr in start_years) {
    cat("  Start year:", yr, "\n")
    for (pred in predictors) {
      res    = oos_r2(df, pred, outcome, yr, ct = FALSE)
      res_ct = oos_r2(df, pred, outcome, yr, ct = TRUE)
      cat("   ", pred, "| OOS R2:", res$r2_oos, "| CT R2:", res_ct$r2_oos, "| N:", res$n, "\n")
    }
  }
}

# -----------------------------------------------------------------------------
# Results: fixed end date (end_year = 2015, N = 56, 46, 36)
# -----------------------------------------------------------------------------
end_year = 2015

for (h in horizons) {
  outcome = paste0("fwd_return_", h, "yr")
  cat("== Horizon h =", h, "==\n")
  for (yr in start_years) {
    cat("  Start year:", yr, "\n")
    for (pred in predictors) {
      res    = oos_r2_fixed(df, pred, outcome, yr, end_year, ct = FALSE)
      res_ct = oos_r2_fixed(df, pred, outcome, yr, end_year, ct = TRUE)
      cat("   ", pred, "| OOS R2:", res$r2_oos, "| CT R2:", res_ct$r2_oos, "| N:", res$n, "\n")
    }
  }
}

# -----------------------------------------------------------------------------
# Table 6: fixed end date results
# -----------------------------------------------------------------------------
results_table = data.frame()

for (yr in start_years) {
  
  # Header row for start year
  header = data.frame(
    Label     = paste0("OOS from ", yr),
    R2_h1     = "-", R2_h5  = "-", R2_h10   = "-",
    CT_R2_h1  = "-", CT_R2_h5 = "-", CT_R2_h10 = "-"
  )
  results_table = rbind(results_table, header)
  
  for (pred in predictors) {
    
    r2_h1  = oos_r2_fixed(df, pred, "fwd_return_1yr",  yr, end_year, ct = FALSE)$r2_oos
    r2_h5  = oos_r2_fixed(df, pred, "fwd_return_5yr",  yr, end_year, ct = FALSE)$r2_oos
    r2_h10 = oos_r2_fixed(df, pred, "fwd_return_10yr", yr, end_year, ct = FALSE)$r2_oos
    ct_h1  = oos_r2_fixed(df, pred, "fwd_return_1yr",  yr, end_year, ct = TRUE)$r2_oos
    ct_h5  = oos_r2_fixed(df, pred, "fwd_return_5yr",  yr, end_year, ct = TRUE)$r2_oos
    ct_h10 = oos_r2_fixed(df, pred, "fwd_return_10yr", yr, end_year, ct = TRUE)$r2_oos
    
    row = data.frame(
      Label     = pred,
      R2_h1     = r2_h1,  R2_h5  = r2_h5,  R2_h10   = r2_h10,
      CT_R2_h1  = ct_h1,  CT_R2_h5 = ct_h5,  CT_R2_h10 = ct_h10
    )
    results_table = rbind(results_table, row)
  }
}

colnames(results_table) = c("", "h=1", "h=5", "h=10", "CT h=1", "CT h=5", "CT h=10")
print(knitr::kable(results_table, format = "simple", align = "c", na = ""))

# -----------------------------------------------------------------------------
# Table 6: no fixed end date results
# -----------------------------------------------------------------------------
results_table = data.frame()

for (yr in start_years) {
  
  # Header row for start year
  header = data.frame(
    Label     = paste0("OOS from ", yr),
    R2_h1     = "-", R2_h5  = "-", R2_h10   = "-",
    CT_R2_h1  = "-", CT_R2_h5 = "-", CT_R2_h10 = "-"
  )
  results_table = rbind(results_table, header)
  
  for (pred in predictors) {
    
    r2_h1  = oos_r2(df, pred, "fwd_return_1yr",  yr, ct = FALSE)$r2_oos
    r2_h5  = oos_r2(df, pred, "fwd_return_5yr",  yr, ct = FALSE)$r2_oos
    r2_h10 = oos_r2(df, pred, "fwd_return_10yr", yr, ct = FALSE)$r2_oos
    ct_h1  = oos_r2(df, pred, "fwd_return_1yr",  yr, ct = TRUE)$r2_oos
    ct_h5  = oos_r2(df, pred, "fwd_return_5yr",  yr, ct = TRUE)$r2_oos
    ct_h10 = oos_r2(df, pred, "fwd_return_10yr", yr, ct = TRUE)$r2_oos
    
    row = data.frame(
      Label     = pred,
      R2_h1     = r2_h1,  R2_h5  = r2_h5,  R2_h10   = r2_h10,
      CT_R2_h1  = ct_h1,  CT_R2_h5 = ct_h5,  CT_R2_h10 = ct_h10
    )
    results_table = rbind(results_table, row)
  }
}

colnames(results_table) = c("", "h=1", "h=5", "h=10", "CT h=1", "CT h=5", "CT h=10")
print(knitr::kable(results_table, format = "simple", align = "c", na = ""))
