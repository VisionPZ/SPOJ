# CANDY4 — Candy IV (SPOJ)

<https://www.spoj.com/problems/CANDY4/>

## Problem

Two boxes each hold n candies. Each day one box is chosen, box 1 with probability p and box 2 with probability 1 - p, and a candy is eaten when the box is not empty. When a chosen box is found empty, report the expected number of candies left in the other box.

| item | bound |
|---|---|
| candies per box n | 1 to 20000 |
| probability p | 0 to 1, six decimal places |
| test cases | until end of input |
| accepted error | absolute error at most 1e-2 |
| judge limit | 2000 ms, 1536 MB |

Each answer uses the format `Case k: value` with six decimal places.

Sample input:

```
10 0.400000
100 0.500000
124 0.432650
325 0.325100
532 0.487520
2276 0.720000
```

Sample output:

```
Case 1: 3.528175
Case 2: 10.326044
Case 3: 28.861945
Case 4: 167.965476
Case 5: 32.601816
Case 6: 1390.500000
```

## Idea

Count the ways each emptying event can happen, like listing all possible orders of red and blue draws before the first failed draw. The last draw must hit the empty box. Before it, that box was drawn n times and the other box j times. Sum the remaining candy counts weighted by those probabilities. Direct powers overflow, so the sum runs in log space with a compensated factorial table.

| term | meaning |
|---|---|
| `boxSize` | candies initially in each box |
| `firstProbability` | probability p of choosing box 1 |
| `eatenCandies` | candies taken from the other box |
| `combinationLog` | log of the binomial coefficient |
| `expectedValue` | accumulated probability-weighted remainder |

One pass per side handles all possible j values.

## Why It Works

1. To empty box 1, the final draw must choose box 1 and find it empty.
2. Before that draw, box 1 was drawn n times and box 2 was drawn j times.
3. The first n + j draws can be ordered in C(n + j, j) ways.
4. Each ordering has probability p^(n+1) (1-p)^j and leaves n - j candies.
5. Swapping the roles gives the symmetric sum for box 2.
6. Log factorials keep binomial coefficients finite for n up to 20000.

| term | meaning |
|---|---|
| C(n + j, j) | number of draw orders with j draws from the other box |
| `combinationLog` | log factorial difference for that coefficient |
| `sideExpectation` | one of the two symmetric sums |

The two sums cover every possible emptying event.

A worked example with n = 1 and p = 0.5:

```
j = 0: C(1,0) = 1, probability 0.5^2 = 0.25, remainder 1
j = 1: C(2,1) = 2, probability 0.5^3 = 0.125, remainder 0
one side contributes 0.25, two sides contribute 0.5
```

The trace gives the expected remainder for one candy per box.

## Code

**Input and probability scanner.** The reader parses the box size and the six-decimal probability.

```nim
import math
import strutils

const firstDigitValue = 48
const flushBlockBytes = 1 shl 17
const maximumBoxSize = 20000

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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

proc nextProbability(data: string, pos: var int): float64 =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var wholePart = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    wholePart = wholePart * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  var fractionalPart = 0
  var fractionalDigits = 0
  if pos < data.len and data[pos] == '.':
    pos += 1
    while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
      fractionalPart = fractionalPart * 10 + int(data[pos]) - firstDigitValue
      fractionalDigits += 1
      pos += 1
  var scale = 1.0
  if fractionalDigits > 0:
    for digitIndex in 0 .. fractionalDigits - 1:
      scale = scale * 10.0
  return float64(wholePart) + float64(fractionalPart) / scale
```

The scanner keeps the decimal point out of the integer value.
Six fractional digits give an exact scale of one million.
The input ends when no further box size appears.

**Log-space sum.** A compensated factorial table supports both symmetric expectations.

```nim
var logFactorials = newSeq[float64](2 * maximumBoxSize + 1)
var summationCompensation = 0.0
for valueIndex in 1 .. 2 * maximumBoxSize:
  let compensatedTerm = ln(float64(valueIndex)) - summationCompensation
  let updatedSum = logFactorials[valueIndex - 1] + compensatedTerm
  summationCompensation = (updatedSum - logFactorials[valueIndex - 1]) - compensatedTerm
  logFactorials[valueIndex] = updatedSum

proc sideExpectation(boxSize: int, ownProbability: float64, otherProbability: float64): float64 =
  if ownProbability <= 0.0:
    return 0.0
  if otherProbability <= 0.0:
    return float64(boxSize)
  var total = 0.0
  for eatenCandies in 0 .. boxSize:
    let combinationLog = logFactorials[boxSize + eatenCandies] -
                         logFactorials[boxSize] - logFactorials[eatenCandies]
    let exponent = combinationLog +
                   float64(boxSize + 1) * ln(ownProbability) +
                   float64(eatenCandies) * ln(otherProbability)
    total += float64(boxSize - eatenCandies) * exp(exponent)
  return total
```

Kahan compensation keeps the factorial sums accurate.
Zero probabilities take a direct branch and avoid log of zero.
Each term stays finite before exponentiation.

**Driver and output.** Both empty-box cases are added and printed with six decimals.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var caseIndex = 0
while true:
  let boxSize = nextInt(inputData, scanPos)
  if boxSize == 0:
    break
  let firstProbability = nextProbability(inputData, scanPos)
  let secondProbability = 1.0 - firstProbability
  let expectedValue = sideExpectation(boxSize, firstProbability, secondProbability) +
                      sideExpectation(boxSize, secondProbability, firstProbability)
  caseIndex += 1
  appendOutput("Case " & $caseIndex & ": " & formatFloat(expectedValue, ffDecimal, 6))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Case numbering starts at one.
The two calls to `sideExpectation` cover both boxes.
Buffered output keeps writes to a minimum.

## Complexity

The factorial table is built once and the sums dominate per case.

| phase | time | space |
|---|---|---|
| input read | one pass over case lines | one input string |
| expectation | two passes over j = 0 to n | constant |
| output | one line per case | block buffer |

The table cost is shared by every case.

| measure | Big O |
|---|---|
| time | O(n) per case |
| space | O(n) for the shared table |

A direct product of powers would overflow long before n reaches 20000.

The log-space sum gives the required accuracy within a linear pass.
