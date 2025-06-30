from datetime import datetime, timedelta  # correct import
import numpy as np
import matplotlib.pyplot as plt
import pandas as pd
from pandas_datareader import data as pdr
from scipy.stats import norm


# --- Data Retrieval ---
def get_data(stocks, start, end):
    stock_data = pdr.get_data_yahoo(stocks, start, end)['Close']
    returns = stock_data.pct_change()
    mean_returns = returns.mean()
    cov_matrix = returns.cov()
    return mean_returns, cov_matrix


# --- Define Stocks and Timeframe ---
stock_list = ['CBA', 'BHP', 'TLS', 'NAB', 'WBC', 'STO']
stocks = [stock + '.AX' for stock in stock_list]
end_date = datetime.now()
start_date = end_date - timedelta(days=300)

mean_returns, cov_matrix = get_data(stocks, start_date, end_date)

# --- Portfolio Weights ---
weights = np.random.random(len(mean_returns))
weights /= np.sum(weights)

# --- Monte Carlo Simulation ---
mc_sims = 400  # number of simulations
T = 100        # timeframe in days
initial_portfolio = 10000

mean_matrix = np.full(shape=(T, len(weights)), fill_value=mean_returns).T
portfolio_sims = np.zeros((T, mc_sims))

for m in range(mc_sims):
    Z = np.random.normal(size=(T, len(weights)))  # uncorrelated random variables
    L = np.linalg.cholesky(cov_matrix)            # Cholesky decomposition
    daily_returns = mean_matrix + np.inner(L, Z)  # correlated returns
    portfolio_sims[:, m] = np.cumprod(np.inner(weights, daily_returns.T) + 1) * initial_portfolio

# --- Plotting Results ---
plt.figure(figsize=(10, 6))
plt.plot(portfolio_sims)
plt.ylabel('Portfolio Value ($)')
plt.xlabel('Days')
plt.title('Monte Carlo Simulation of Stock Portfolio')
plt.grid(True)
plt.tight_layout()
plt.show()


# --- Value at Risk (VaR) and Conditional VaR ---
def mcVaR(returns, alpha=5):
    if isinstance(returns, pd.Series):
        return np.percentile(returns, alpha)
    raise TypeError("Expected a pandas Series.")


def mcCVaR(returns, alpha=5):
    if isinstance(returns, pd.Series):
        return returns[returns <= mcVaR(returns, alpha)].mean()
    raise TypeError("Expected a pandas Series.")


port_results = pd.Series(portfolio_sims[-1, :])

VaR = initial_portfolio - mcVaR(port_results, alpha=5)
CVaR = initial_portfolio - mcCVaR(port_results, alpha=5)

print(f'VaR_5 = ${round(VaR, 2)}')
print(f'CVaR_5 = ${round(CVaR, 2)}')
