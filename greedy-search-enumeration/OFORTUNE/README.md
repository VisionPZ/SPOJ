# OFORTUNE — Ohgas' Fortune (SPOJ)

<https://www.spoj.com/problems/OFORTUNE/>

## Problem

Pick one bank operation and grow a fund for a fixed number of years. Report the largest final amount among all offered operations.

Each dataset gives the starting fund, the number of years and the number of operations. Each operation gives its interest kind, its annual rate and its fixed annual charge. Simple interest saves each year's interest outside the fund. Compound interest adds each year's interest to the fund.

| item | bound |
|---|---|
| datasets | at most 100 |
| starting fund | 1 to 100000000 |
| years | at most 10 |
| operations per dataset | at most 100 |
| annual charge | at most 100000 |
| judge limit | 1 s, 1536 MB |

Rates are multiples of 1/8192, so every rate has an exact binary form.

Sample input:

```
4
1000000
5
2
0 0.03125 3000
1 0.03125 3000
6620000
7
2
0 0.0732421875 42307
1 0.0740966796875 40942
39677000
4
4
0 0.0709228515625 30754
1 0.00634765625 26165
0 0.03662109375 79468
0 0.0679931640625 10932
10585000
6
4
1 0.0054931640625 59759
1 0.12353515625 56464
0 0.0496826171875 98193
0 0.0887451171875 78966
```

Sample output:

```
1150357
10559683
50796918
20829397
```

## Idea

Treat the interest rate as a whole-number count of 8192ths, like counting eighths with a fixed measuring cup. Scale the rate to an integer once, then compute each year with integer division. A floating-point calculation would need care with fractions of a cent, while scaled integers give the exact truncated interest. One pass over the operations finds the best result.

## Why It Works

1. A rate of k/8192 becomes an integer numerator k after scaling.
2. A year's interest is the fund times k, divided by 8192 with the fraction dropped.
3. Compound interest adds that interest to the fund before the charge is taken.
4. Simple interest adds that interest to a separate total instead.
5. The largest result over all operations is the answer for the dataset.

| term | meaning |
|---|---|
| `rateNumerator` | scaled rate k, an integer from 1 to 1024 |
| `yearlyInterest` | truncated interest for one year |
| `balance` | fund still under operation |
| `savedInterest` | interest kept outside the fund |
| `bestAmount` | largest final amount seen |

A script check of the worked example uses a fund of 1000000, rate 0.03125 and charge 3000. The scaled rate is 256, so year one yields 1000000 * 256 div 8192 = 31250 and leaves 1028250. Year two yields 1028250 * 256 div 8192 = 32132. After five years the compound result is 1150357 and the simple result is 1140311.

Interest is truncated, not rounded to the nearest yen. Integer division by 8192 performs that truncation exactly, so no floating-point guard is needed.

## Code

**Input and buffers.** The reader loads stdin and exposes integer and string tokens.

```nim
const flushBlockBytes = 1 shl 17
const rateScale = 8192'i64

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

proc nextToken(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  var token = ""
  while pos < data.len and data[pos] > ' ':
    token.add data[pos]
    pos += 1
  return token

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The rate arrives as a decimal token, so it needs its own reader.
The output buffer flushes only after reaching its block size.

**Rate scaling.** The decimal digits become an integer count of 8192ths.

```nim
proc rateNumerator(rateText: string): int64 =
  var fraction = 0'i64
  var denominator = 1'i64
  var index = 0
  while index < rateText.len and rateText[index] != '.':
    index += 1
  if index < rateText.len:
    index += 1
  while index < rateText.len:
    fraction = fraction * 10 + int64(int(rateText[index]) - 48)
    denominator = denominator * 10
    index += 1
  return fraction * rateScale div denominator

proc yearlyInterest(balance: int64, numerator: int64): int64 =
  return balance * numerator div rateScale
```

Multiplying by 8192 before dividing keeps the scaling exact.
Integer division drops the fractional part of each year's interest.

**Year loop and driver.** Each operation simulates its own fund over the years.

```nim
proc finalAmount(initialFund: int64, years: int, isCompound: bool,
                 numerator: int64, charge: int64): int64 =
  var balance = initialFund
  var savedInterest = 0'i64
  for yearIndex in 0 .. years - 1:
    var interest = yearlyInterest(balance, numerator)
    if isCompound:
      balance += interest
    else:
      savedInterest += interest
    balance -= charge
  if isCompound:
    return balance
  return balance + savedInterest

let datasetCount = nextInt(inputData, scanPos)
for datasetIndex in 0 .. datasetCount - 1:
  let initialFund = int64(nextInt(inputData, scanPos))
  let years = nextInt(inputData, scanPos)
  let operationCount = nextInt(inputData, scanPos)
  var bestAmount = 0'i64
  for operationIndex in 0 .. operationCount - 1:
    let kind = nextInt(inputData, scanPos)
    let numerator = rateNumerator(nextToken(inputData, scanPos))
    let charge = int64(nextInt(inputData, scanPos))
    let amount = finalAmount(initialFund, years, kind == 1, numerator, charge)
    if amount > bestAmount:
      bestAmount = amount
  appendOutput($bestAmount)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Simple interest keeps its accumulated total separate from the fund.
The driver writes one result line per dataset.

## Complexity

| phase | time | space |
|---|---|---|
| input read | one pass over stdin | one input string |
| rate scaling | one pass over each rate token | constant |
| simulation | years times operations, per dataset | constant |
| output | one line per dataset | block buffer |

| measure | Big O |
|---|---|
| time per dataset | O(operations * years) |
| space | O(size of input) |

Recomputing powers or trying every rate in a table would add work that this direct simulation avoids.

Each dataset finishes after at most a thousand short year steps.
