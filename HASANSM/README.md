# HASANSM — Spending Money (SPOJ)
<https://www.spoj.com/problems/HASANSM/>

## Problem

Spend as much as possible from a budget on two chocolate types and report the smallest leftover money.

Dairy milk costs M taka per bar and is bought in packs of 1, 2, 4 or 8 bars.
Kitkat costs N taka per bar and is bought in packs of 7, 14 or 28 bars.
Any number of packs may be bought.
The input starts with T, followed by T lines with P, M and N.
Output one line per case with the minimum remaining money.

| item | bound |
|---|---|
| test cases T | 1 to 25 |
| budget P | 1 to 30000000000 |
| prices M and N | 30 to 10000000000 |
| sum of all P | at most 120000000000 |
| judge limit | 5000 ms, 1536 MB |

The budget can be far larger than a machine word, so arithmetic uses 64-bit values.

Sample input:

```
3
150 30 35
167 40 35
99999989 31 31
```

Sample output:

```
0
7
3
```

## Idea

Both pack lists act like coins you may spend repeatedly, like paying with stacks of two coin sizes.

Packs of 1, 2, 4 and 8 combine into any dairy count, so dairy spend is any multiple of M.
Packs of 7, 14 and 28 combine into any multiple of seven kitkats, so kitkat spend is any multiple of 7N.
For each kitkat pack count, the best dairy count is the largest one that still fits.
That leaves a remainder of P minus 7N times the pack count, taken modulo M.
Scanning every pack count can take billions of steps when N is small.

A Euclidean reduction finds the smallest remainder in logarithmic time.

## Why It Works

1. A pack of one dairy bar means every dairy count is reachable, so dairy spend is M times any integer.
2. A pack of seven kitkats means every multiple of seven bars is reachable, so kitkat spend is 7N times any integer.
3. For a fixed kitkat pack count b, the leftover is (P - 7N*b) mod M.
4. The pack count runs from 0 to P divided by 7N, so the problem is a modular arithmetic progression minimum.
5. The Euclidean reduction replaces modulus and step with smaller values until the step becomes zero.

| term | meaning |
|---|---|
| `budget` | the available money P |
| `milkPrice` | the price M of one dairy bar |
| `kitkatCost` | the price 7N of seven kitkats |
| `minModStep` | the smallest value of a modular progression |
| `leftover` | the minimum remaining money |

For the second sample case P is 167, M is 40 and kitkatCost is 245.
No kitkat pack fits, so the remainder is 167 modulo 40, which is 7.

For the third case M and N are both 31, so kitkatCost is 217 and M divides it.
The step is zero, so the answer is 99999989 modulo 31, which is 3.

## Code

**Input, remainder reduction and output helper.** The reader loads all cases and the reducer shrinks the modulus.

```nim
const flushBlockBytes = 1 shl 17
const packsPerKitkatType = 7

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int64 =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value: int64 = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int64(int(data[pos]) - 48)
    pos += 1
  return value

proc minModStep(modulusValue, stepValue, startValue, stepLimit: int64): int64 =
  var currentModulus = modulusValue
  var currentStep = stepValue mod currentModulus
  var currentStart = startValue mod currentModulus
  var currentLimit = stepLimit
  var bestValue = currentStart
  while currentLimit > 0 and currentStep != 0:
    let shrink = currentModulus mod currentStep
    let blockCount = (currentStart + currentLimit * currentStep) div currentModulus
    if blockCount == 0:
      return bestValue
    let nextStart = (currentStart - shrink + currentStep) mod currentStep
    let nextStep = (currentStep - shrink) mod currentStep
    if nextStart < bestValue:
      bestValue = nextStart
    currentModulus = currentStep
    currentStep = nextStep
    currentStart = nextStart
    currentLimit = blockCount - 1
  return bestValue

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

Each pass replaces the pair of modulus and step with the remainder pair from Euclid's algorithm.
The block count keeps the bound on the number of steps exact.

**Case loop and flush.** Every case produces one leftover line.

```nim
let caseCount = nextInt(inputData, scanPos)
var caseIndex: int64 = 0
while caseIndex < caseCount:
  let budget = nextInt(inputData, scanPos)
  let milkPrice = nextInt(inputData, scanPos)
  let kitkatPrice = nextInt(inputData, scanPos)
  let kitkatCost = packsPerKitkatType * kitkatPrice
  let stepValue = (milkPrice - kitkatCost mod milkPrice) mod milkPrice
  let startValue = budget mod milkPrice
  let stepLimit = budget div kitkatCost
  let leftover = minModStep(milkPrice, stepValue, startValue, stepLimit)
  appendOutput($leftover)
  outputBuffer.add '\n'
  caseIndex += 1

stdout.write outputBuffer
outputBuffer.setLen 0
```

The step is the kitkat cost negated modulo M.
Numbers use int64 so the largest prices and budgets stay exact.

## Complexity

The reducer follows the Euclidean algorithm once per case.

| phase | time | space |
|---|---|---|
| input read | one pass over all cases | one input string |
| remainder reduction | logarithmic division steps | a few integers |
| output | one line per case | block buffer |

| measure | Big O |
|---|---|
| time per case | O(log M) |
| space | O(1) |

Scanning every kitkat pack count would cost P divided by 7N steps per case.

The reduction gives the exact minimum for the full constraint range.
