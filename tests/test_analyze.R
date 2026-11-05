# Sanity checks for analyze.R. Run from the repository root:
#   Rscript --vanilla tests/test_analyze.R

source("analyze.R")

# 1. Demo data: fixed seed, 8 countries x 9 years, 64 observations after lags.
demo_a <- simulate_demo_panel()
demo_b <- simulate_demo_panel()
stopifnot(identical(demo_a, demo_b))
stopifnot(nrow(demo_a) == 72L)
demo <- estimate_panel(demo_a)
stopifnot(nobs(demo$fit) == 64L)
stopifnot(identical(names(demo$estimates), terms))
stopifnot(all(is.finite(demo$estimates)))

# 2. Lags are taken within country from year - 1, independent of row order,
#    and are NA when the previous year is missing.
toy <- data.frame(
  country = c("B", "A", "A", "B", "A", "B"),
  year = c(2001, 2002, 2000, 2000, 2001, 2003),
  network = c(21, 12, 10, 20, 11, 23),
  ownership = c(0.21, 0.12, 0.10, 0.20, 0.11, 0.23),
  gdp_per_capita_ppp = 1
)
lagged <- add_lags(toy)
stopifnot(identical(lagged$network_lag, c(20, 11, NA, NA, 10, NA)))
stopifnot(identical(lagged$ownership_lag, c(0.20, 0.11, NA, NA, 0.10, NA)))

# 3. With a known data-generating process (country and year effects plus the
#    lagged terms), the model recovers the coefficients, also on shuffled rows.
set.seed(1)
sim <- expand.grid(country = paste0("c", 1:10), year = 2010:2020)
sim$network <- runif(nrow(sim))
sim$ownership <- runif(nrow(sim))
sim <- add_lags(sim)
country_effect <- setNames(rnorm(10), paste0("c", 1:10))
year_effect <- setNames(rnorm(11, sd = 0.1), 2010:2020)
truth <- c(network_lag = 0.5, ownership_lag = 0.3, `network_lag:ownership_lag` = 0.2)
log_gdp <- 9 + country_effect[as.character(sim$country)] +
  year_effect[as.character(sim$year)] +
  truth[[1]] * sim$network_lag + truth[[2]] * sim$ownership_lag +
  truth[[3]] * sim$network_lag * sim$ownership_lag +
  rnorm(nrow(sim), sd = 0.01)
sim$gdp_per_capita_ppp <- ifelse(is.na(log_gdp), exp(9), exp(log_gdp))
sim <- sim[c("country", "year", "network", "ownership", "gdp_per_capita_ppp")]
recovered <- estimate_panel(sim)$estimates
stopifnot(max(abs(recovered - truth)) < 0.05)
shuffled <- estimate_panel(sim[sample(nrow(sim)), ])$estimates
stopifnot(isTRUE(all.equal(shuffled, recovered)))

# 4. Invalid input stops with an error.
fails <- function(expr) inherits(try(expr, silent = TRUE), "try-error")
stopifnot(fails(estimate_panel(demo_a[setdiff(names(demo_a), "network")])))
stopifnot(fails(estimate_panel(rbind(demo_a, demo_a[1, ]))))
bad_gdp <- demo_a
bad_gdp$gdp_per_capita_ppp[1] <- 0
stopifnot(fails(estimate_panel(bad_gdp)))
bad_year <- demo_a
bad_year$year[1] <- 2014.5
stopifnot(fails(estimate_panel(bad_year)))

cat("All checks passed.\n")
