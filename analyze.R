# Two-way fixed effects panel regression of log GDP per capita (PPP) on
# one-year lags of a network indicator, an ownership indicator and their
# interaction. Base R only.
#
# Usage:
#   Rscript --vanilla analyze.R --demo        # synthetic data (fixed seed)
#   Rscript --vanilla analyze.R panel.csv     # your own panel
#
# The functions below can also be loaded with source("analyze.R") without
# running the command-line entry point (used by tests/test_analyze.R).

required <- c("country", "year", "gdp_per_capita_ppp", "network", "ownership")
terms <- c("network_lag", "ownership_lag", "network_lag:ownership_lag")

simulate_demo_panel <- function(seed = 42) {
  set.seed(seed)
  panel <- expand.grid(country = paste0("demo_", 1:8), year = 2014:2022)
  panel$network <- runif(nrow(panel), 0, 1)
  panel$ownership <- runif(nrow(panel), 0, 1)
  panel$gdp_per_capita_ppp <- exp(9 + rnorm(nrow(panel), sd = 0.2))
  panel
}

validate_panel <- function(panel) {
  if (!all(required %in% names(panel))) {
    stop("Required columns: ", paste(required, collapse = ", "))
  }
  if (anyNA(panel[c("country", "year")]) || any(!nzchar(trimws(panel$country)))) {
    stop("Country and year must be present.")
  }
  numeric_columns <- setdiff(required, "country")
  if (!all(vapply(panel[numeric_columns], is.numeric, logical(1)))) {
    stop("Year, GDP and connectivity indicators must be numeric.")
  }
  if (any(!is.finite(panel$year) | panel$year != floor(panel$year))) {
    stop("Year must be an integer.")
  }
  if (anyDuplicated(panel[c("country", "year")])) {
    stop("Each country and year pair must be unique.")
  }
  if (any(panel$gdp_per_capita_ppp <= 0, na.rm = TRUE) ||
      any(vapply(panel[numeric_columns], function(x) any(is.infinite(x)), logical(1)))) {
    stop("GDP must be positive and non-missing numeric values must be finite.")
  }
  invisible(panel)
}

# Lags are matched on (country, year - 1), so they never cross countries and
# do not depend on row order. A missing previous year gives NA.
add_lags <- function(panel) {
  previous <- match(
    paste(panel$country, panel$year - 1L, sep = "\t"),
    paste(panel$country, panel$year, sep = "\t")
  )
  panel$network_lag <- panel$network[previous]
  panel$ownership_lag <- panel$ownership[previous]
  panel
}

estimate_panel <- function(panel) {
  panel <- add_lags(validate_panel(panel))
  usable <- panel[complete.cases(panel[c("gdp_per_capita_ppp", "network_lag", "ownership_lag")]), ]
  if (length(unique(usable$country)) < 2L || length(unique(usable$year)) < 2L) {
    stop("At least two countries and two years with usable lagged data are needed.")
  }

  fit <- lm(
    log(gdp_per_capita_ppp) ~ factor(country) + factor(year) + network_lag * ownership_lag,
    data = usable
  )
  estimates <- coef(fit)[terms]
  if (anyNA(estimates) || df.residual(fit) < 1L) {
    stop("The sample lacks enough independent variation to estimate this model.")
  }
  list(fit = fit, estimates = estimates)
}

main <- function(args = commandArgs(trailingOnly = TRUE)) {
  if (length(args) != 1L) {
    stop("Usage: Rscript --vanilla analyze.R --demo | panel.csv")
  }
  if (args[[1L]] == "--demo") {
    panel <- simulate_demo_panel()
    cat("Synthetic data demonstration\n")
  } else {
    panel <- read.csv(args[[1L]], na.strings = c("", "NA"))
  }
  result <- estimate_panel(panel)
  cat("Observations:", nobs(result$fit), "\n")
  print(result$estimates)
  invisible(result)
}

if (sys.nframe() == 0L) {
  tryCatch(main(), error = function(e) {
    message("Error: ", conditionMessage(e))
    quit(save = "no", status = 1L)
  })
}
