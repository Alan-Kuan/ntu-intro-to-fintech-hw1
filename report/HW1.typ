#import "@local/hw-report:1.0.0": *

#show: project.with(
  title: "Introduction to FinTech: HW1",
  authors: (
    (name: "官澔恩", id: "R12922060"),
  ),
  font: ("Times New Roman"),
  numbering: "1"
)
#show math.equation: set text(size: 12pt)

#h(1em)
In this homework, I made a few strategies by applying some well-known technical indicators individually.
After I did some comparisons and analysis,
I finally made a hybrid one, which got the best result.

== Technical Indicators
#h(1em)
The reason I chose these technical indicators was that they can provide signals to buy or sell stocks.
I will show how the indicators generate these signals and how I used them to create strategies.

=== MA Strategy
#h(1em)
Moving average smooths the history prices.
By observing 2 MA lines with different window sizes,
we can determine the timing to buy or sell the stock.
If the line with smaller window size (which is fast line) rise above the other one (which is slow line),
it's likely the stock price will rise as well.
Thus, it's a signal to buy the stock.
Similarly, if the fast line fall below slow line,
it's a signal to sell the stock.

#h(1em)
However, this kind of indicator is "lagging".
It just shows what just happened.
Therefore, instead of buy or sell right after a crosspoint appears,
in my strategy, the buying point and selling point are determined by whether the difference between fast line and slow line is small enough.
This way, it may find a better trading point before the crosspoint.

#h(1em)
In this strategy, tunable parameters are:
- _fast line's window size_
- _slow line's window size_
- _alpha_, which is the acceptable difference of fast line and slow line before falling-down crossing point
- _beta_, which is the acceptable difference of fast line and slow line before rising-up crossing point

=== RSI Strategy
#h(1em)
RSI shows the relative strength of the growth of stock prices.
Similar to previous method, we can calculate 2 RSI lines with different window sizes.
Then, the buying point and selling point can be determined in the same way, i.e., find a point just before the crossing point.

#h(1em)
I also tried an inversed strategy by selling when fast line rises above slow line and buying when fast line falls below slow line.
This is because I wanted to compare the best possible configurations of these 2 strategies,
and I would choose the better one to build the final strategy.

#h(1em)
In this strategy, tunable parameters are:
- _fast line's window size_
- _slow line's window size_
- _alpha_, which is the acceptable difference of fast line and slow line before falling-down crossing point
- _beta_, which is the acceptable difference of fast line and slow line before rising-up crossing point

=== RSI Bound Strategy
#h(1em)
There's another use of RSI indicator.
It tells us whether the stock is overbought or oversold.
If the line rises above an upper-bound threshold, the stock may be overbought.
Similarly, if the line falls below an lower-bound threshold, the stock may be oversold.

#h(1em)
In this strategy, it simply sells if the line rises above the upper-bound threshold, and buys if the line falls below the lower-bound threshold.
Besides, the tunable parameters are:
- _window size_
- _alpha_, which is the upper-bound threshold
- _beta_, which is the lower-bound threshold

=== MACD Strategy
#h(1em)
The last technical indicator I used is MACD.
It shows 2 lines, which are the difference of fast MA line and slow MA line, and the moving average of the difference.
The former reflects the current stock price faster than the latter.
Thus, the former can be seen as a fast line, while the latter is the slow line.
By applying the same technique, we can determine the buying or selling points by observing the crossing points.

#h(1em)
In this strategy, I also tested the inversed version,
i.e., buy at falling-below crossing point and sell at rising-above crossing point.
Later, I compared to find out which was better.
Besides, the tunable parameters are:
- _fast MA line's window size_
- _slow MA line's window size_
- _MACD (signal) line's window size_
- _alpha_, which is the acceptable difference of fast line (DIF line) and slow line (MACD line) before falling-down crossing point
- _beta_, which is the acceptable difference of fast line and slow line before rising-up crossing point

== My Final Strategy (Hybrid Strategy)
#h(1em)
It's easier to explain with the code of my final strategy, so I listed it in the next page.
The hard-coded values are the final results of the search.

#h(1em)
The rule is simple.
If the action determined by the MACD indicator does not contradict to that of RSI,
just take it.
Also, if RSI indicator tells that the stock is overbought or oversold but MACD indicator does not give any action,
then sell or buy accordingly.
In any other cases, it just holds what it have.

#h(1em)
In addition, in case of an unexpected error occurred,
I use "try" and "except" to make sure it just take no action.

#rect(
```python
def myStrategy(pastPriceVec, currentPrice):
  import numpy as np
  import talib

  try:
    prices = np.append(pastPriceVec, currentPrice)

    rsi = talib.RSI(prices, 10)
    _, _, hist = talib.MACD(prices, 4, 8, 12)

    rsi_oversold = rsi[-1] < 40
    rsi_overbought = rsi[-1] > 80
    macd_buy = (-0.3 < hist[-1] and hist[-1] < 0 and prices[-1] > prices[-2]) \
      or (hist[-1] > 0 and hist[-2] <= 0)
    macd_sell = (0 < hist[-1] and hist[-1] < 0.1 and prices[-1] < prices[-2]) \
      or (hist[-1] < 0 and hist[-2] >= 0)

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
```
)

#h(1em)
I used exhaustive search to find the best combination of parameters for my hybrid strategy.
However, since there are 8 tunable parameters in this strategy,
it will take a few hours to finish.
To speed it up, I applied multiprocessing on the search with 32 workers,
and finish my experiments in about 13 minutes.
Below are the tunable parameters and the range I tried.

#align(
  center,
  grid(
    table(
      align: left,
      columns: 3,
      [*Parameter Name*], [*Description*], [*Range*],
      [rsi_ws], [RSI line's window size], [range(2, 21, 2)],
      [rsi_alpha], [RSI's upper-bound threshold], [range(60, 85, 5)],
      [rsi_beta], [RSI's lower-bound threshold], [range(20, 45, 5)],
      [fastperiod], [MACD fast MA's window size], [range(2, 21, 2)],
      [slowperiod], [MACD slow MA's window size], [range(fastperiod + 2, 31, 2)],
      [signalperiod], [MACD line's window size], [range(2, 21, 2)],
      [macd_alpha], [MACD's alpha], [np.arange(0.1, 0.4, 0.1)],
      [macd_beta], [MACD's beta], [np.arange(-0.1, -0.4, -0.1)],
    ),
    align(
      left,
      rect(
        stroke: none,
        [\*range is the Python's range function, and np is numpy]
      )
    )
  )
)

== Others
#h(1em)
In my opinion, the model should be fitted on a period with similar trend to this year
so that it should perform well in the following target interval (2023/10/16 \~ 2023/12/22).
To find the period of time to fit my strategy,
I calculate the correlation coefficients between this year and each past year from 2010 to 2022, which is shown in @rho.
I found trend of stock prices in 2017 is the most related one,
so I pick that interval for fitting.

#figure(
  caption: [Correlation Coefficients Between 2023 and Each Year from 2010 to 2022 (sorted by $rho$)],
  table(
    columns: 14,
    [*Year*], [2017], [2014], [2016], [2019], [2021], [2020], [2013], [2018], [2015], [2011], [2012], [2010], [2022], 
    [*$rho$*], [0.735], [0.723], [0.565], [0.434], [0.390], [0.313], [0.254], [0.108], [-0.186], [-0.232], [-0.467], [-0.529], [-0.704],
  )
)
<rho>

#h(1em)
To evaluate my strategies, I back tested them on this years.
Since our target interval (2023/10/16 \~ 2023/12/22) in this assignment is about 49 trade days,
I calculate return rate every 49 trade days,
and the final result is shown in @rr.

#figure(
  caption: [Return Rate of Different Strategies Back-tested on History Prices in 2023],
  grid(
    table(
      align: (x, y) => {
        if x == 0 { left }
        else if y == 0 { center }
        else { right }
      },
      columns: 7,
      [], [01/03 \~ 03/24], [03/27 \~ 06/07], [06/08 \~ 08/18], [08/21 \~ 10/12], [Total], [Average],
      [Baseline], [4.13%], [6.31%], [-2.85%], [-0.99%], [6.60%], [2.64%],
      [OPT], [27.79%], [17.42%], [15.10%], [16.54%], [76.85%], [30.74%],
      [RSI], [7.70%], [6.53%], [-1.72%], [1.16%], [13.66%], [5.47%],
      [RSI_inv], [1.89%], [-0.58%], [-1.67%], [2.05%], [1.69%], [0.68%],
      [MACD],	[10.30%], [6.08%], [-3.62%], [1.45%], [14.21%], [5.69%],
      [MACD_inv], [18.33%], [-1.19%], [-2.91%], [-1.30%], [12.93%], [5.17%],
      [MA], [8.92%], [6.17%], [-3.01%], [2.31%], [14.39%], [5.76%],
      [RSI_bound], [12.31%], [5.14%], [-4.55%], [3.50%], [16.40%], [6.56%],
      [Hybrid], [10.16%], [4.26%], [-0.12%], [7.65%], [*21.95%*], [8.78%],
    ),
    align(
      left,
      rect(
        stroke: none,
        [\*Baseline is the provided sample, and OPT is the best possible return rate that can be obtained]
      )
    )
  )
)
<rr>

#h(1em)
I found that inversed version of strategies did worse,
so I adopted the normal version in hybrid strategy.