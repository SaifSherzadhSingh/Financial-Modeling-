
required_packages <- c("copula", "rmgarch", "quantmod", "PerformanceAnalytics", "rugarch", "xts", "zoo", "tidyverse")
install_if_missing <- function(p) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p)
  }
  library(p, character.only = TRUE)
}
invisible(sapply(required_packages, install_if_missing))
set.seed(123)

# Number of obligors
n_obligors <- 100

PDs <- runif(n_obligors, min = 0.01, max = 0.2)


LGDs <- runif(n_obligors, min = 0.2, max = 0.6)

EADs <- runif(n_obligors, min = 1e6, max = 10e6)
# Define a Gaussian copula with a specified correlation matrix
rho <- 0.2  # Assumed average correlation between obligors
cor_matrix <- matrix(rho, nrow = n_obligors, ncol = n_obligors)
diag(cor_matrix) <- 1  # Set diagonal to 1

# Create a normal copula object
copula_model <- normalCopula(param = rho, dim = n_obligors, dispstr = "ex")

n_scenarios <- 10000

u_matrix <- rCopula(n_scenarios, copula_model)

default_matrix <- sweep(u_matrix, 2, PDs, "<")

# Calculate losses for each scenario
losses <- default_matrix %*% (EADs * LGDs)

# Analyze the loss distribution
losses_vector <- as.vector(losses)
hist(losses_vector, breaks = 50, main = "Portfolio Loss Distribution", xlab = "Loss Amount")

symbols <- c("DGS10", "CPIAUCNS", "WTI")  # 10-Year Treasury Rate, CPI, and WTI Crude Oil

# Fetch data from FRED (Federal Reserve Economic Data)
getSymbols(symbols, src = "FRED")

data_combined <- na.omit(merge(DGS10, CPIAUCNS, WTI))
colnames(data_combined) <- c("InterestRate", "Inflation", "OilPrice")

log_returns <- diff(log(data_combined))[-1, ]
# Specify univariate GARCH(1,1) model
garch_spec <- ugarchspec(variance.model = list(model = "sGARCH", garchOrder = c(1,1)),
                         mean.model = list(armaOrder = c(1,0), include.mean = TRUE),
                         distribution.model = "norm")

# Create a list of univariate GARCH specifications for each series
uspec_list <- multispec(replicate(3, garch_spec))
# Specify DCC-GARCH(1,1) model
dcc_spec <- dccspec(uspec = uspec_list, dccOrder = c(1,1), distribution = "mvnorm")

# Fit the DCC-GARCH model to the log returns
dcc_fit <- dccfit(dcc_spec, data = log_returns)
# Extract dynamic conditional correlations
dcc_correlations <- rcor(dcc_fit)

# Plot the dynamic correlation between Interest Rate and Oil Price
plot(dcc_correlations[1,3,], type = "l", col = "blue",
     main = "Dynamic Conditional Correlation: Interest Rate & Oil Price",
     xlab = "Time", ylab = "Correlation")
