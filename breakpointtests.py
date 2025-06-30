import numpy as np
import pandas as pd
import yfinance as yf
import scipy.stats as sps
from scipy.optimize import minimize
import matplotlib.pyplot as plt

def download_returns(ticker, start, end):
    prices = yf.download(ticker, start, end, progress=False)['Close']
    returns = np.diff(prices.values) / prices.values[:-1]
    returns = np.sort(returns)
    return returns, prices

def fit_johnson_su(returns):
    # Use SciPy's built-in JohnsonSU MLE for stability :contentReference[oaicite:1]{index=1}
    a, b, loc, scale = sps.johnsonsu.fit(returns)
    return a, b, loc, scale

def ks_test(returns, a, b, loc, scale):
    cdf_empirical = np.arange(1, len(returns) + 1) / len(returns)
    cdf_model = sps.johnsonsu.cdf(returns, a, b, loc=loc, scale=scale)
    D = np.max(np.abs(cdf_empirical - cdf_model))
    # Exact KS p-value approximated via asymptotic formula :contentReference[oaicite:2]{index=2}
    p = 1 - sps.kstwobign.cdf(np.sqrt(len(returns)) * D)
    return D, p

def plot_fit(returns, a, b, loc, scale):
    ecdf = np.arange(1, len(returns)+1)/len(returns)
    jcdf = sps.johnsonsu.cdf(returns, a, b, loc=loc, scale=scale)
    plt.plot(returns, ecdf, label='Empirical CDF')
    plt.plot(returns, jcdf, label='Johnson SU CDF')
    plt.title('CDF Comparison')
    plt.legend()
    plt.show()

def simulate_prices(prices_last, a, b, loc, scale, maturity=30, nsim=1000, rf=0.047):
    # Simulate returns via inverse transform :contentReference[oaicite:3]{index=3}
    U = np.random.rand(maturity, nsim)
    sim_returns = sps.johnsonsu.ppf(U, a, b, loc=loc, scale=scale)
    sim_prices = prices_last * np.cumprod(1 + sim_returns, axis=0)
    return sim_prices

def price_barrier_options(sim_prices, strike, barrier_up, barrier_down, rf, maturity):
    maxP, minP = sim_prices.max(axis=0), sim_prices.min(axis=0)
    final = sim_prices[-1, :]
    def disc(payoffs): return np.mean(payoffs) / (1 + rf) ** (maturity / 252)
    up_in = disc(np.where(maxP >= barrier_up, np.maximum(final - strike, 0), 0))
    up_out = disc(np.where(maxP < barrier_up, np.maximum(final - strike, 0), 0))
    down_in = disc(np.where(minP <= barrier_down, np.maximum(strike - final, 0), 0))
    down_out = disc(np.where(minP > barrier_down, np.maximum(strike - final, 0), 0))
    return up_in, up_out, down_in, down_out

def compare_to_market(ticker, strike, expiry):
    opt = yf.Ticker(ticker).option_chain(expiry)
    call_price = float(opt.calls.loc[opt.calls['strike'] == strike, 'lastPrice'])
    put_price = float(opt.puts.loc[opt.puts['strike'] == strike, 'lastPrice'])
    return call_price, put_price

def main():
    returns, prices = download_returns('WMT', '2018-03-13', '2023-03-13')
    a, b, loc, scale = fit_johnson_su(returns)
    
    D, p = ks_test(returns, a, b, loc, scale)
    print(f"KS test: D={D:.4f}, p-value={p:.4f}")
    
    plot_fit(returns, a, b, loc, scale)

    sim_prices = simulate_prices(prices.iloc[-1], a, b, loc, scale)
    plt.plot(sim_prices, alpha=0.3)
    plt.title("Simulated Price Paths")
    plt.show()

    strike, bu, bd, rf, T = 135, 150, 120, 0.047, 30
    ups = price_barrier_options(sim_prices, strike, bu, bd, rf, T)
    for name, val in zip(['Up-In Call', 'Up-Out Call', 'Down-In Put', 'Down-Out Put'], ups):
        print(f"{name} fair value: {val:.2f}")

    market_call, market_put = compare_to_market('WMT', strike, '2023-04-21')
    print(f"Market Call: {market_call}, {('Undervalued' if ups[0]+ups[1]>market_call else 'Overvalued')}")
    print(f"Market Put: {market_put}, {('Undervalued' if ups[2
