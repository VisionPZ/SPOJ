# ADASALE — Ada and Salesman (SPOJ)
<https://www.spoj.com/problems/ADASALE/>

## Problem

Walk through cities in order and trade items to maximise cash. A license in a city unlocks buying and selling there. Buying the t-th item costs `P * t * city mod MOD`, and selling it pays the same amount. The bag holds at most `bagLimit` items, and cash never limits the trade.

The input gives `cityCount`, `bagLimit`, and `modulus`, then one line of license fees and one line of magic constants. Print the largest achievable cash total.

| item | bound |
|---|---|
| city count | 1 to 3000 |
| bag limit | 1 to 3000 |
| modulus | 1 to 10000 |
| fees and constants | 1 to 1000 |
| judge limit | 3000 ms, 1536 MB |

Cities are numbered from one, and the walk starts with an empty bag.

Sample input:

```
5 1 3
1 1 1 1 1
1 1 1 1 1
```

Sample output:

```
0
```

## Idea

Treat the bag count as gear positions on one dial, and record the best cash at each position after every city. At a licensed city, moving between any two positions costs the difference of two precomputed price totals. Keep the maximum of cash plus that total, then subtract the new total and the fee. Skipping the license leaves the dial unchanged. Enumerating license subsets costs exponential time, while one sweep updates all positions at once.

## Why It Works

1. Define `C[j]` as the sum of prices for items 1 through j in the current city.
2. Buying items i+1 through j costs `C[j] − C[i]`.
3. Selling items i down to j+1 pays `C[i] − C[j]`.
4. Both moves give the same formula, so any count change costs `C[j] − C[i]`.
5. With a license, cash at count j becomes `max(dp[i] + C[i]) − C[j] − L`.
6. Without a license, cash at count j stays `dp[j]`.
7. The answer is the largest cash value after the last city.

These names carry the main values.

| term | meaning |
|---|---|
| `cumulativePrices` | the table of `C[j]` for one city |
| `currentProfit` | best cash at each bag count before the city |
| `bestBase` | largest value of `dp[i] + C[i]` |
| `licenceFee` | price of trading in the current city |
| `tradedProfit` | cash after buying the license and trading |
| `skippedProfit` | cash after walking past the city |

One maximum replaces a separate decision for every bag count.

A script-generated trace of the second sample uses five cities, bag limit five, modulus six, unit fees, and unit constants:

| city | `C[0..5]` | `bestBase` | best cash at counts 0..5 |
|---|---|---|---|
| 1 | 0, 1, 3, 6, 10, 15 | 0 | 0, −2, −4, −7, −11, −16 |
| 2 | 0, 2, 6, 6, 8, 12 | 2 | 1, −1, −4, −5, −7, −11 |
| 3 | 0, 3, 3, 6, 6, 9 | 2 | 1, −1, −2, −5, −5, −8 |
| 4 | 0, 4, 6, 6, 10, 12 | 5 | 4, 0, −2, −2, −5, −8 |
| 5 | 0, 5, 9, 12, 14, 15 | 10 | 9, 4, 0, −2, −5, −6 |

The largest final value is 9.

Each price uses a 64-bit product before the modulus, and totals fit in int64. The constant `negativeInfinity` marks unreachable bag counts.

## Code

**Reader and buffer.** The hand scanner reads three headers and two arrays.

```nim
const flushBlockBytes = 1 shl 17
const negativeInfinity = -1000000000000000'i64

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The parser ignores spaces and line breaks.
The buffer holds the single answer line.

**City arrays.** Fees and constants stay in separate arrays.

```nim
let cityCount = nextInt(inputData, scanPos)
let bagLimit = nextInt(inputData, scanPos)
let modulus = nextInt(inputData, scanPos)
var licenceCosts = newSeq[int](cityCount)
for cityIndex in 0 .. cityCount - 1:
  licenceCosts[cityIndex] = nextInt(inputData, scanPos)
var magicConstants = newSeq[int](cityCount)
for cityIndex in 0 .. cityCount - 1:
  magicConstants[cityIndex] = nextInt(inputData, scanPos)

var currentProfit = newSeq[int64](bagLimit + 1)
var nextProfit = newSeq[int64](bagLimit + 1)
for countIndex in 0 .. bagLimit:
  currentProfit[countIndex] = negativeInfinity
currentProfit[0] = 0
var cumulativePrices = newSeq[int](bagLimit + 1)
```

Only count zero starts reachable.
Two profit arrays avoid allocation inside the loop.

**City sweep.** Each city builds `C`, finds one maximum, and updates every count.

```nim
for cityIndex in 0 .. cityCount - 1:
  let cityNumber = cityIndex + 1
  let stepPrice = (int64(magicConstants[cityIndex]) * int64(cityNumber)) mod int64(modulus)
  var runningPrice = 0
  cumulativePrices[0] = 0
  for countIndex in 1 .. bagLimit:
    runningPrice = (runningPrice + int(stepPrice)) mod modulus
    cumulativePrices[countIndex] = cumulativePrices[countIndex - 1] + runningPrice
  var bestBase = negativeInfinity
  for countIndex in 0 .. bagLimit:
    let candidateBase = currentProfit[countIndex] + int64(cumulativePrices[countIndex])
    if candidateBase > bestBase:
      bestBase = candidateBase
  let licenceFee = int64(licenceCosts[cityIndex])
  for countIndex in 0 .. bagLimit:
    let tradedProfit = bestBase - licenceFee - int64(cumulativePrices[countIndex])
    let skippedProfit = currentProfit[countIndex]
    if tradedProfit > skippedProfit:
      nextProfit[countIndex] = tradedProfit
    else:
      nextProfit[countIndex] = skippedProfit
  swap currentProfit, nextProfit

var bestProfit = currentProfit[0]
for countIndex in 1 .. bagLimit:
  if currentProfit[countIndex] > bestProfit:
    bestProfit = currentProfit[countIndex]

appendOutput($bestProfit)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The step price is added modulo `modulus` for each item.
The final flush writes the best cash total.

## Complexity

Each city builds one price table and updates every bag count once.

| phase | time | space |
|---|---|---|
| input read | one pass over fees and constants | one input string |
| price table | one step per bag count | price array |
| city sweep | one maximum and one update per count | two profit arrays |
| output | one integer | block buffer |

The city sweep sets the overall cost.

| measure | Big O |
|---|---|
| time | O(cityCount * bagLimit) |
| space | O(bagLimit) |

Trying every license subset costs O(2^cityCount), which grows far faster.

Keep one cash value per bag count and sweep the cities once.
