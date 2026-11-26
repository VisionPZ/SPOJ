# HASANSM — Spending Money (SPOJ)

<https://www.spoj.com/problems/HASANSM/>

## Problem

Hasan has P taka. Dairy Milk costs M each and must be bought in packs of 1, 2, 4, or 8, so any whole number of them can be bought. KitKat costs N each and must be bought in packs of 7, 14, or 28, so the total KitKat count is always a multiple of 7. Hasan wants to spend as much as possible. Print the smallest leftover money.

The first line holds T. Each test gives P, M, N.

| item | bound |
|---|---|
| tests T | 1 ≤ T ≤ 25 |
| P | 1 ≤ P ≤ 3×10^10 |
| M, N | 30 ≤ M, N ≤ 10^10 |
| sum of P | ≤ 1.2×10^11 |
| judge limit | 5000 ms, 1536 MB |

The leftover is the smallest residue of one arithmetic progression, found without looping over every pack count.

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

Buying 1, 2, 4, or 8 bars at a time still lets Hasan reach any total count, because packs of 1 exist. KitKat packs are all multiples of 7, so his KitKat total is 7y for some y. The spend is therefore M·x + 7N·y for free choices of x and y.

For a fixed y, the best x spends everything below P − 7N·y, so the leftover is (P − 7N·y) mod M. The task becomes: find the smallest value of an arithmetic progression taken modulo M, with y running from 0 to floor(P / 7N).

A Euclidean descent answers that in logarithmic steps, like gcd but tracking the minimum residue.

Takeaway: reduce spending to one progression, then use a gcd-like descent.

## Why It Works

1. Any count x of Dairy Milk is reachable, so only the total matters.
2. KitKat totals are exactly the multiples of 7N in price.
3. For fixed y, the leftover is (P − 7N·y) mod M, an arithmetic progression in y with step −7N.
4. The loop keeps the best residue seen. If no term wraps past M, the terms strictly increase and the start is already minimal.
5. When terms do wrap, the Euclidean step replaces (M, step) by (step, M mod step), the same reduction that makes gcd fast, and carries the wrapped minima into the smaller problem.
6. The number of rounds is logarithmic, so 10^10-sized inputs finish instantly.

For the sample, 150 with M = 30 and 7N = 245: no KitKat fits, so the leftover is 150 mod 30 = 0. For 167, 40, 35 the leftover is 167 mod 40 = 7. For 99999989, 31, 31 the step 217 is a multiple of 31, so every leftover equals 99999989 mod 31 = 3.

When the step is 0 modulo M, every y gives the same residue and the start value is returned unchanged.

## Code

**Input and scanning.** The hand reader loads the file and parses 64-bit values.

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
```

The scanner skips spaces and newlines.
`int64` holds P up to 3×10^10 exactly.

**Buffered output.** One string collects the answer lines.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

Large outputs flush in blocks.
One final write closes the remaining text.

**Progression minimum.** The descent mirrors Euclid's algorithm.

```nim
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
```

`blockCount` counts how many multiples of the modulus the progression crosses.
No crossing means the start is the minimum.
Each round swaps modulus and step, shrinking like gcd.

**Per-test setup.** The progression terms come straight from the prices.

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

`stepValue` is −7N modulo M, so y steps move the residue correctly.
`stepLimit` is the largest affordable pack count.
The minimum residue is the smallest leftover.

## Complexity

Each test runs one short descent.

| phase | time | space |
|---|---|---|
| read input | one pass over the file | one string |
| descent | logarithmic rounds per test | none |
| output | one line per test | one block buffer |

| measure | Big O |
|---|---|
| time | O(T log M) |
| space | O(1) |

Trying every pack count would loop up to 10^10 times per test.

Takeaway: a gcd-shaped descent finds the minimum residue.
