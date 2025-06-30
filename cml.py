import numpy as np
import pandas as pd
import yfinance as yf
import matplotlib.pyplot as plt

def fetch_returns(tickers, start, end):
    """
    Download adjusted close prices and compute annualized returns and covariance.
    """
    data = yf.download(tickers, start=start, end=end, progress=False)['Adj Close']
    if data.isnull().any().any():
        data = data.dropna(how='any')
    log_rets = np.log(data / data.shift(1)).dropna()
    mu = log_rets.mean() * 252
    cov = log_rets.cov() * 252
    return mu.values, cov.values, log_rets.index

def compute_efficient_frontier(mu, cov, n_points=100):
    """
    Return efficient frontier (risk, return) along with MVP and tangency portfolio.
    """
    inv_cov = np.linalg.inv(cov)
    ones = np.ones_like(mu)
    A = ones @ inv_cov @ ones
    B = ones @ inv_cov @ mu
    C = mu @ inv_cov @ mu
    D = A * C - B**2

    mvp = (inv_cov @ ones) / A
    tang = (inv_cov @ mu) / B
    ret_mvp, risk_mvp = B / A, np.sqrt(1 / A)
    ret_tang, risk_tang = C / B, np.sqrt(C) / B

    tgt_rets = np.linspace(ret_mvp, ret_tang, n_points)
    risks = np.array([np.sqrt((A*r**2 - 2*B*r + C) / D) for r in tgt_rets])

    return {
        'rets': tgt_rets,
        'risks': risks,
        'mvp': (risk_mvp, ret_mvp, mvp),
        'tang': (risk_tang, ret_tang, tang)
    }

def get_target_solution(mu, cov, target):
    """
    Solve for portfolio matching a target return via analytical formulas.
    """
    inv_cov = np.linalg.inv(cov)
    ones = np.ones_like(mu)
    A = ones @ inv_cov @ ones
    B = ones @ inv_cov @ mu
    C = mu @ inv_cov @ mu
    D = A * C - B**2
    lmb = (C - B * target) / D
    m = (A * target - B) / D
    weights = lmb * (inv_cov @ ones) + m * (inv_cov @ mu)
    port_ret = weights @ mu
    port_risk = np.sqrt((A*port_ret**2 - 2*B*port_ret + C) / D)
    return port_ret, port_risk, weights

def plot_portfolios(dates, frontier, mvp_data, tang_data, target_solution=None):
    """
    Visualize the efficient frontier, MVP, tangency, and optional target portfolio.
    """
    plt.figure(figsize=(10, 6))
    plt.plot(frontier['risks'], frontier['rets'], 'b-', label='Efficient Frontier')
    plt.scatter(mvp_data[0], mvp_data[1], marker='o', color='green', label='Minimum Variance')
    plt.scatter(tang_data[0], tang_data[1], marker='*', color='red', label='Tangency')
    if target_solution:
        plt.scatter(target_solution[1], target_solution[0], marker='x',
                    color='orange', label=f"Target Return {target_solution[0]:.2f}")
    plt.title('Efficient Frontier & Portfolios')
    plt.xlabel('Annual Risk (Std Dev)')
    plt.ylabel('Annual Return')
    plt.legend()
    plt.grid(True)
    plt.show()

def main():
    tickers = ['BA','CVX','GS','ORCL','PEP','PFE']
    mu, cov, dates = fetch_returns(tickers, '2015-12-31', '2020-12-31')
    ef = compute_efficient_frontier(mu, cov)
    mvp = ef['mvp']
    tang = ef['tang']
    target_ret = 0.12
    target = get_target_solution(mu, cov, target_ret)

    print(f"MVP Return: {mvp[1]:.4f}, Risk: {mvp[0]:.4f}")
    print(f"Tangency Return: {tang[1]:.4f}, Risk: {tang[0]:.4f}")
    print(f"Target({target_ret}) Portfolio Return: {target[0]:.4f}, Risk: {target[1]:.4f}")

    plot_portfolios(dates, ef, mvp, tang, target_solution=target)

if __name__ == "__main__":
    main()
