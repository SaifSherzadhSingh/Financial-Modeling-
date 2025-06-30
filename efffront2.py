import numpy as np
import datetime as dt
import yfinance as yf

def getData(stocks, start, end):
    SD = yf.download(stocks, start=start, end=end, ignore_tz=True)
    close = SD["Close"]
    returns = close.pct_change(1).dropna()

    mean_daily = returns.mean()
    cov_daily = returns.cov()

    ann_return = -1+(1 + mean_daily)**250
    return close, ann_return, cov_daily

def portfolioPerformance(weights, ann_return, cov_daily):
    port_return = np.matmul(weights @ ann_return)
    port_vari = np.matmul(weights.T @ cov_daily @ weights) * 252
    return port_return, port_vari

if __name__ == "__main__":
    tickers = ['ABG.JO', 'FSR.JO', 'SBK.JO']
    endd = dt.datetime.now()
    startd = endd - dt.timedelta(days=365)

    close, ann_return, cov_daily = getData(tickers, startd, endd)

    weights = np.array([1/3, 1/3, 1/3])
    ann_ret, ann_vol = portfolioPerformance(weights, ann_return, cov_daily)

    print(f"Annualized Portfolio Return: {ann_ret*100:.2f}%")
    print(f"Annualized Portfolio Volatility: {np.sqrt(ann_vari)*100:.2f}%")
