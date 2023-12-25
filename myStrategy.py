def myStrategy(pastPriceVec, currentPrice):
  import numpy as np
  import talib

  try:
    prices = np.append(pastPriceVec, currentPrice)

    rsi = talib.RSI(prices, 10)
    _, _, hist = talib.MACD(prices, 4, 8, 12)

    rsi_oversold = rsi[-1] < 40
    rsi_overbought = rsi[-1] > 80
    macd_buy = (-0.3 < hist[-1] and hist[-1] < 0 and prices[-1] > prices[-2]) or \
      (hist[-1] > 0 and hist[-2] <= 0)
    macd_sell = (0 < hist[-1] and hist[-1] < 0.1 and prices[-1] < prices[-2]) or \
      (hist[-1] < 0 and hist[-2] >= 0)

    if macd_buy and not rsi_overbought:
      return 1
    if macd_sell and not rsi_oversold:
      return -1
    if rsi_overbought:
      return -1
    if rsi_oversold:
      return 1

  except:
    return 0

  return 0