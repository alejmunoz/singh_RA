# =============================================================================
# In-sample R2 for log(CAEVFCF), log(CAPE), tbl, lty, tms, and eqis
# from 1938 onwards, replicating Table 1 of Marin and Singh (2026).
# - Inputs:  comparison_data.csv
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
df = read_csv(file.path(derived_dir, "comparison_data.csv"))
colnames(df)[1] = "yyyy"

colnames(df)[colnames(df) == "i/k"] = "i_k"
colnames(df)[colnames(df) == "e/p"] = "e_p"


# -----------------------------------------------------------------------------
# In-sample R2, 1938 onwards
# -----------------------------------------------------------------------------
df_1938 = df[df$yyyy >= 1938, ]

predictors = c("log_CAEVFCF", "log_CAPE", "tbl", "lty", "tms", "eqis", "e_p")
horizons   = c(1, 5, 10)

results_table = data.frame()

for (pred in predictors) {
  
  row = data.frame(Predictor = pred)
  
  for (h in horizons) {
    outcome = paste0("fwd_return_", h, "yr")
    data    = df_1938[!is.na(df_1938[[pred]]) & !is.na(df_1938[[outcome]]), ]
    fit     = lm(as.formula(paste(outcome, "~", pred)), data = data)
    r2      = round(summary(fit)$r.squared, 4)
    n       = nobs(fit)
    row[[paste0("R2_h", h)]] = r2
    row[[paste0("N_h",  h)]] = n
  }
  
  results_table = rbind(results_table, row)
}

colnames(results_table) = c("Predictor", 
                            "R2 h=1", "N h=1", "R2 h=5", "N h=5", "R2 h=10", "N h=10")
print(knitr::kable(results_table, format = "simple", align = "c"))

# -----------------------------------------------------------------------------
# OOS R2 function (no fixed end date)
# -----------------------------------------------------------------------------
oos_r2 = function(data, predictor, outcome, start_year, ct = FALSE) {
  
  data = data[!is.na(data[[predictor]]) & !is.na(data[[outcome]]), ]
  data = data[order(data$yyyy), ]
  
  n         = nrow(data)
  sse_model = 0
  sse_bench = 0
  
  start_idx = which(data$yyyy == start_year)
  
  for (t in start_idx:n) {
    train = data[1:(t-1), ]
    fit   = lm(as.formula(paste(outcome, "~", predictor)), data = train)
    beta  = coef(fit)[predictor]
    if (ct & beta > 0) {
      yhat = coef(fit)["(Intercept)"]
    } else {
      yhat = predict(fit, newdata = data[t, ])
    }
    ybar      = mean(train[[outcome]])
    y         = data[[outcome]][t]
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
  data = data[order(data$yyyy), ]
  data = data[data$yyyy <= end_year, ]
  
  n         = nrow(data)
  sse_model = 0
  sse_bench = 0
  
  start_idx = which(data$yyyy == start_year)
  
  for (t in start_idx:n) {
    train = data[1:(t-1), ]
    fit   = lm(as.formula(paste(outcome, "~", predictor)), data = train)
    beta  = coef(fit)[predictor]
    if (ct & beta > 0) {
      yhat = coef(fit)["(Intercept)"]
    } else {
      yhat = predict(fit, newdata = data[t, ])
    }
    ybar      = mean(train[[outcome]])
    y         = data[[outcome]][t]
    sse_model = sse_model + (y - yhat)^2
    sse_bench = sse_bench + (y - ybar)^2
  }
  
  r2_oos = 1 - sse_model / sse_bench
  n_oos  = n - start_idx + 1
  return(list(r2_oos = round(as.numeric(r2_oos), 4), n = as.integer(n_oos)))
}

# -----------------------------------------------------------------------------
# Table function
# -----------------------------------------------------------------------------
build_table = function(data, predictors, start_years, end_year = NULL) {
  
  results_table = data.frame()
  
  for (yr in start_years) {
    
    header = data.frame(
      Label  = paste0("OOS from ", yr),
      R2_h1  = "-", R2_h5 = "-", R2_h10 = "-"
    )
    results_table = rbind(results_table, header)
    
    for (pred in predictors) {
      
      if (is.null(end_year)) {
        r2_h1  = oos_r2(data, pred, "fwd_return_1yr",  yr, ct = FALSE)$r2_oos
        r2_h5  = oos_r2(data, pred, "fwd_return_5yr",  yr, ct = FALSE)$r2_oos
        r2_h10 = oos_r2(data, pred, "fwd_return_10yr", yr, ct = FALSE)$r2_oos
      } else {
        r2_h1  = oos_r2_fixed(data, pred, "fwd_return_1yr",  yr, end_year, ct = FALSE)$r2_oos
        r2_h5  = oos_r2_fixed(data, pred, "fwd_return_5yr",  yr, end_year, ct = FALSE)$r2_oos
        r2_h10 = oos_r2_fixed(data, pred, "fwd_return_10yr", yr, end_year, ct = FALSE)$r2_oos
      }
      
      row = data.frame(
        Label  = pred,
        R2_h1  = as.character(r2_h1),
        R2_h5  = as.character(r2_h5),
        R2_h10 = as.character(r2_h10)
      )
      results_table = rbind(results_table, row)
    }
  }
  
  colnames(results_table) = c("", "h=1", "h=5", "h=10")
  return(results_table)
}

# -----------------------------------------------------------------------------
# OOS R^2 Results
# -----------------------------------------------------------------------------
predictors  = c("log_CAEVFCF", "log_CAPE", "tbl", "lty", "tms", "eqis", "e_p")
start_years = c(1960, 1970, 1980)
end_year    = 2015

cat("=== No fixed end date ===\n")
tbl_nofixed = build_table(df, predictors, start_years)
print(knitr::kable(tbl_nofixed, format = "simple", align = "c"))

cat("\n=== Fixed end date: 2015 ===\n")
tbl_fixed = build_table(df, predictors, start_years, end_year)
print(knitr::kable(tbl_fixed, format = "simple", align = "c"))

# -----------------------------------------------------------------------------
# In-sample R2: log(CAEVFCF) and log(CAPE) vs Goyal predictors each predictor 
# uses its own available sample
# -----------------------------------------------------------------------------
get_start_year = function(data, predictor) {
  data = data[!is.na(data[[predictor]]), ]
  return(min(data$yyyy))
}

goyal_predictors = c("tchi", "shtint", "pce", "crdstd", "i_k", "accrul", 
                     "gpce", "cay", "skew")
horizons         = c(1, 5, 10)

results_table2 = data.frame()

for (pred in goyal_predictors) {
  
  start_yr = get_start_year(df, pred)
  df_sub   = df[df$yyyy >= start_yr, ]
  
  row = data.frame(Predictor = paste0(pred, " (from ", start_yr, ")"))
  
  for (h in horizons) {
    outcome  = paste0("fwd_return_", h, "yr")
    
    # Predictor R2
    data_pred = df_sub[!is.na(df_sub[[pred]]) & !is.na(df_sub[[outcome]]), ]
    fit_pred  = lm(as.formula(paste(outcome, "~", pred)), data = data_pred)
    r2_pred   = round(summary(fit_pred)$r.squared, 4)
    
    # log(CAEVFCF) R2 over same sample
    data_caevfcf = df_sub[!is.na(df_sub[["log_CAEVFCF"]]) & !is.na(df_sub[[outcome]]), ]
    fit_caevfcf  = lm(as.formula(paste(outcome, "~ log_CAEVFCF")), data = data_caevfcf)
    r2_caevfcf   = round(summary(fit_caevfcf)$r.squared, 4)
    
    # log(CAPE) R2 over same sample
    data_cape = df_sub[!is.na(df_sub[["log_CAPE"]]) & !is.na(df_sub[[outcome]]), ]
    fit_cape  = lm(as.formula(paste(outcome, "~ log_CAPE")), data = data_cape)
    r2_cape   = round(summary(fit_cape)$r.squared, 4)
    
    row[[paste0("R2_pred_h",     h)]] = r2_pred
    row[[paste0("R2_caevfcf_h", h)]] = r2_caevfcf
    row[[paste0("R2_cape_h",    h)]] = r2_cape
  }
  
  results_table2 = rbind(results_table2, row)
}

colnames(results_table2) = c(
  "Predictor",
  "Pred h=1", "CAEVFCF h=1", "CAPE h=1",
  "Pred h=5", "CAEVFCF h=5", "CAPE h=5",
  "Pred h=10", "CAEVFCF h=10", "CAPE h=10"
)
print(knitr::kable(results_table2, format = "simple", align = "c"))

# -----------------------------------------------------------------------------
# OOS R2: log(CAEVFCF) and log(CAPE) vs Goyal predictors
# each predictor uses its own OOS start years
# -----------------------------------------------------------------------------

predictor_start_years = list(
  "i_k"    = c(1960, 1970, 1980),
  "gpce"   = c(1960, 1970, 1980),
  "tchi"   = c(1970, 1980),
  "pce"    = c(1970, 1980),
  "accrul" = c(1980),
  "shtint" = c(1988),
  "cay"    = c(1960, 1970, 1980),
  "skew"   = c(1970, 1980)
)

results_table3 = data.frame()

for (pred in names(predictor_start_years)) {
  
  start_years_pred = predictor_start_years[[pred]]
  
  for (yr in start_years_pred) {
    
    header = data.frame(
      Label  = paste0(pred, " — OOS from ", yr),
      R2_h1  = "-", R2_h5 = "-", R2_h10 = "-"
    )
    results_table3 = rbind(results_table3, header)
    
    for (comp in c(pred, "log_CAEVFCF", "log_CAPE")) {
      
      r2_h1  = oos_r2(df, comp, "fwd_return_1yr",  yr, ct = FALSE)$r2_oos
      r2_h5  = oos_r2(df, comp, "fwd_return_5yr",  yr, ct = FALSE)$r2_oos
      r2_h10 = oos_r2(df, comp, "fwd_return_10yr", yr, ct = FALSE)$r2_oos
      
      row = data.frame(
        Label  = comp,
        R2_h1  = as.character(r2_h1),
        R2_h5  = as.character(r2_h5),
        R2_h10 = as.character(r2_h10)
      )
      results_table3 = rbind(results_table3, row)
    }
  }
}

colnames(results_table3) = c("", "h=1", "h=5", "h=10")
print(knitr::kable(results_table3, format = "simple", align = "c"))