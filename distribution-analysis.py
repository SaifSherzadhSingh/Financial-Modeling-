import numpy as np
import pandas as pd
import yfinance as yf
import matplotlib.pyplot as plt
from scipy.stats import kstest, norm, cauchy

def download_log_returns(ticker: str, start: str, end: str) -> np.ndarray:
    """Download daily prices and compute log returns."""
    df = yf.download(ticker, start=start, end=end, progress=False)['Close']
    df = df.dropna()
    return np.log(df / df.shift(1)).dropna().values

def plot_cdfs(sample: np.ndarray, dist, dist_name: str):
    """Compute and plot sample EDF vs distribution CDF."""
    x = np.sort(sample)
    edf = np.arange(1, len(x)+1) / len(x)
    cdf = dist.cdf(x)
    plt.plot(x, edf, label='Empirical CDF')
    plt.plot(x, cdf, label=f'{dist_name} CDF')
    plt.title(f'EDF vs {dist_name} CDF')
    plt.legend()
    plt.show()

def test_distribution(sample: np.ndarray, dist_name: str):
    """
    Perform 1-sample Kolmogorov-Smirnov test using SciPy's kstest.
    Supports 'normal' and 'cauchy'.
    """
    if dist_name == 'normal':
        params = (np.mean(sample), np.std(sample, ddof=1))
    elif dist_name == 'cauchy':
        params = (np.median(sample),
                  (np.percentile(sample, 75) - np.percentile(sample, 25)) / 2)
    else:
        raise ValueError("Only 'normal' or 'cauchy' supported.")
    
    res = kstest(sample, dist_name, args=params)
    print(f"{dist_name.title()} fit: D = {res.statistic:.4f}, p = {res.pvalue:.4f}")
    return res

def main():
    ticker = 'TSLA'
    start, end = '2019-10-31', '2022-10-31'

    data = download_log_returns(ticker, start, end)

    for dist_name in ['normal', 'cauchy']:
        test_distribution(data, dist_name)
        dist = norm(* (np.mean(data), np.std(data, ddof=1))) if dist_name == 'normal' \
               else cauchy(np.median(data),
                           (np.percentile(data,75) - np.percentile(data,25)) / 2)
        plot_cdfs(data, dist, dist_name.title())

if __name__ == "__main__":
    main()
