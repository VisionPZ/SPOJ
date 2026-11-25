# LAND — Subdividing a Land (SPOJ)

<https://www.spoj.com/problems/LAND/>

## Problem

Choose integer side lengths `a` and `b` for a square complex and its equal square blocks. Keep block area at half the complex area or less, then minimise wasted green space and finally minimise `a` and `b`.

Each test case is one line holding `n`, the block count. A line holding `0` ends the input. Print `Case X: a b` with a case number starting at one.

| item | bound |
|---|---|
| block count n | 1 to 10000 |
| answer size | both values fit a signed 64-bit integer |
| judge limit | 2484 ms, 1536 MB |

The half-area rule drives the design.

Sample input:

```
1
2
0
```

Sample output:

```
Case 1: 3 2
Case 2: 2 1
```

## Idea

half-area rule becomes a Pell equation, like finding the closest rational answer to a square root. Write the rule as `a^2 - 2*n*b^2 >= 0`. The smallest possible waste is zero when `2*n` is a square, and one otherwise; the latter case is the Pell equation `a^2 - 2*n*b^2 = 1`. Continued fractions give its smallest solution in logarithmic time. Direct search over `b` fails because the smallest solution can be enormous. Take the fundamental Pell solution as the answer.

## Why It Works

1. Green space equals `a^2 - n*b^2`.
2. Half the complex is `a^2 / 2`, so the rule is `a^2 >= 2*n*b^2`.
3. Waste is `a^2 - 2*n*b^2`, which must stay non-negative.
4. Squares of form `2*n` give waste zero at `a = sqrt(2*n), b = 1`.
5. Other values give waste one at the fundamental Pell solution, which has the smallest `a`.
6. The packing rule `floor(a/b)^2 >= n` follows from `a^2 >= 2*n*b^2`.

| term | meaning |
|---|---|
| `doubledArea` | `2*n`, the Pell coefficient |
| `rootArea` | integer part of the square root of `doubledArea` |
| `periodLength` | number of terms in one continued-fraction period |
| `currentNumerator` | numerator of the current convergent |

A trace for `n = 5` gives `doubledArea = 10` and `rootArea = 3`. The expansion repeats after one term, so the period is odd. The convergent at index one is `19/6`, and `19^2 - 10*6^2 = 361 - 360 = 1`. The generator confirms the pair.

## Code

**Input and integer square root.** The scanner loads every case and rounds the square root exactly.

```nim
import math

const flushBlockBytes = 1 shl 17

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

proc integerRoot(value: int64): int64 =
  var root = int64(sqrt(float(value)))
  while (root + 1) * (root + 1) <= value:
    root += 1
  while root * root > value:
    root -= 1
  return root
```

The root starts from a float estimate and corrects by integer steps.
Every comparison stays in 64-bit arithmetic.
The block reader skips all separators between numbers.

**Continued fractions.** One period yields the fundamental solution.

```nim
proc pellSolution(doubledArea: int64): (int64, int64) =
  let rootArea = integerRoot(doubledArea)
  if rootArea * rootArea == doubledArea:
    return (rootArea, int64(1))
  var partialNumerator = int64(0)
  var partialDenominator = int64(1)
  var partialQuotient = rootArea
  var prevPrevNumerator = int64(0)
  var prevPrevDenominator = int64(1)
  var prevNumerator = int64(1)
  var prevDenominator = int64(0)
  var currentNumerator = rootArea
  var currentDenominator = int64(1)
  var periodLength = 0
  while true:
    partialNumerator = partialDenominator * partialQuotient - partialNumerator
    partialDenominator = (doubledArea - partialNumerator * partialNumerator) div partialDenominator
    partialQuotient = (rootArea + partialNumerator) div partialDenominator
    prevPrevNumerator = prevNumerator
    prevPrevDenominator = prevDenominator
    prevNumerator = currentNumerator
    prevDenominator = currentDenominator
    currentNumerator = partialQuotient * prevNumerator + prevPrevNumerator
    currentDenominator = partialQuotient * prevDenominator + prevPrevDenominator
    periodLength += 1
    if partialQuotient == 2 * rootArea:
      break
  if periodLength mod 2 == 0:
    return (prevNumerator, prevDenominator)
  for stepIndex in 1 .. periodLength - 1:
    partialNumerator = partialDenominator * partialQuotient - partialNumerator
    partialDenominator = (doubledArea - partialNumerator * partialNumerator) div partialDenominator
    partialQuotient = (rootArea + partialNumerator) div partialDenominator
    prevPrevNumerator = prevNumerator
    prevPrevDenominator = prevDenominator
    prevNumerator = currentNumerator
    prevDenominator = currentDenominator
    currentNumerator = partialQuotient * prevNumerator + prevPrevNumerator
    currentDenominator = partialQuotient * prevDenominator + prevPrevDenominator
  return (currentNumerator, currentDenominator)
```

An even period stops at the previous convergent.
An odd period continues for one more copy of the period.
Products stay below the final answer, so they fit 64 bits.

**Output loop.** Each case writes one formatted line.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var caseNumber = 1
while true:
  let blockCount = nextInt(inputData, scanPos)
  if blockCount == 0:
    break
  let doubledArea = int64(2 * blockCount)
  let answer = pellSolution(doubledArea)
  appendOutput("Case " & $caseNumber & ": " & $answer[0] & " " & $answer[1])
  outputBuffer.add '\n'
  caseNumber += 1

stdout.write outputBuffer
outputBuffer.setLen 0
```

Zero ends the loop without a line.
The case counter starts at one.
One final flush writes any remaining bytes.

## Complexity

Each case expands one continued fraction and formats one line.

| phase | time | space |
|---|---|---|
| input read | one pass over all bytes | one input string |
| Pell solve | one period of continued fractions | constant working values |
| output | one buffered line per case | block buffer |

The period length grows slowly with `n`, so cases stay small.

| measure | Big O |
|---|---|
| time per case | O(log n) continued-fraction steps |
| space | O(total input bytes) |

A brute search over block side `b` would scan millions of values for some inputs.
Continued fractions reach the same answer in a handful of steps.
