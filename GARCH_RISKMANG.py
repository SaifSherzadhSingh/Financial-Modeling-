import numpy as np
import pandas as pd
import yfinance as yf
import matplotlib.pyplot as plt
import scipy.optimize as spop
import logging

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(levelname)s:%(message)s')

def download_price_series(ticker: str, start: str, end: str) -> pd.Series:
    """
    Download adjusted closing prices for a given ticker.

    Args:
        ticker: e.g. '^GSPC'
        start: e.g. '2015-12-31'
        end: e.g. '2021-06-25'

    Returns:
        pandas Series of daily closing prices.
    """
    data = yf.download(ticker, start=start, end=end, progress=False)
    if 'Close' not in data:
        raise ValueError(f"No 'Close' column in downloaded data for {ticker}")
    logging.info(f"Downloaded {len(data)} rows for {ticker}")
    return data['Close']


def compute_returns(prices: pd.Series) -> np.ndarray:
    """
    Compute daily log returns to stabilize variance.
    """
    return np.log(prices / prices.shift(1)).dropna().to_numpy()


def garch_log_likelihood(params: np.ndarray, returns: np.ndarray) -> float:
    """
    Negative log-likelihood for a GARCH(1,1) model.

    params: [mu, omega, alpha, beta]
    returns: array of log returns
    """
    mu, omega, alpha, beta = params

    # Enforce parameter constraints to prevent invalid model
    if omega <= 0 or alpha < 0 or beta < 0 or alpha + beta >= 1:
        return np.inf

    # Initialize variance series
    T = len(returns)
    resid = returns - mu
    sigma2 = np.empty(T)
    sigma2[0] = omega / (1 - alpha - beta)

    for t in range(1, T):
        sigma2[t] = omega + alpha * resid[t - 1] ** 2 + beta * sigma2[t - 1]

    # Compute log-likelihood assuming normal residuals
    ll = -0.5 * (np.log(2 * np.pi) + np.log(sigma2) + resid**2 / sigma2)
    return -np.sum(ll)


def fit_garch(returns: np.ndarray) -> dict:
    """
    Fit GARCH(1,1) via MLE, return parameter estimates and likelihood.
    """
    # Initial guess: mu = sample mean, others small
    mu0 = np.mean(returns)
    omega0 = np.var(returns) * 0.1
    alpha0, beta0 = 0.05, 0.9

    bounds = [(-np.inf, np.inf), (1e-8, None), (0, 1), (0, 1)]
    result = spop.minimize(
        fun=garch_log_likelihood,
        x0=[mu0, omega0, alpha0, beta0],
        args=(returns,),
        bounds=bounds,
        method='L-BFGS-B'
    )

    if not result.success:
        logging.warning("Optimization did not converge: " + result.message)

    params = result.x
    return {
        'mu': params[0],
        'omega': params[1],
        'alpha': params[2],
        'beta': params[3],
        'loglike': -result.fun
    }


def calculate_volatility(returns: np.ndarray, mu: float, omega: float, alpha: float, beta: float) -> np.ndarray:
    """
    Compute conditional volatility series (standard deviation).
    """
    resid = returns - mu
    T = len(returns)
    sigma2 = np.empty(T)
    sigma2[0] = omega / (1 - alpha - beta)

    for t in range(1, T):
        sigma2[t] = omega + alpha * resid[t - 1]**2 + beta * sigma2[t - 1]
    return np.sqrt(sigma2)


def main():
    ticker = '^GSPC'
    start_date = '2015-12-31'
    end_date = '2021-06-25'

    prices = download_price_series(ticker, start_date, end_date)
    returns = compute_returns(prices)

    results = fit_garch(returns)
    logging.info("Fitted GARCH(1,1) parameters: %r", results)

    volatility = calculate_volatility(returns, results['mu'], results['omega'], results['alpha'], results['beta'])
    dates = prices.index[1:]

    # Plot realized vs conditional volatility
    plt.figure(figsize=(12, 6))
    plt.plot(dates, np.abs(returns), label='Absolute Returns', alpha=0.5)
    plt.plot(dates, volatility, label='GARCH(1,1) Volatility', linewidth=1.5)
    plt.title('GARCH Estimated Conditional Volatility vs Returns')
    plt.xlabel('Date')
    plt.ylabel('Volatility')
    plt.legend(loc='upper right')
    plt.tight_layout()
    plt.show()


if __name__ == '__main__':
    main()
