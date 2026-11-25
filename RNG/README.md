# RNG — Random Number Generator (SPOJ)

<https://www.spoj.com/problems/RNG/>

## Problem

Compute the probability that a sum of independent uniform values lands inside a given interval. Each value is drawn uniformly from minus X to plus X, and the chosen X values sum to S.

Input: the first line gives the test count. Each test gives N, A, B, then N positive integers X on the next line. Output: print the probability with exactly nine decimal places per test.

| item | bound |
|---|---|
| factors N | 1 to 10 |
| bounds A and B | -100 to 100, with A ≤ B |
| each X | 1 to 10 |
| judge limit | 1000 ms, 1536 MB |

The interval may lie fully outside the support, so answers can be zero or one.

The sample holds five tests with two negative bounds.

| sample X values | sample bounds | sample answer |
|---|---|---|
| 10 | -100 to 100 | 1.000000000 |
| 10 | 10 to 90 | 0.000000000 |
| 10 | -20 to 5 | 0.750000000 |
| 5 5 | -20 to 5 | 0.875000000 |
| 1 2 3 4 5 | -5 to 10 | 0.864720052 |

The second test cannot occur because its interval lies above the maximum sum.

## Idea

Replace each symmetric uniform draw by a uniform draw from zero to twice X, then shift by S. This turns the question into a cumulative distribution of a sum of plain uniform variables, like stacking uniform blocks and measuring the pile height. The algorithm uses inclusion-exclusion over the 2^N lower endpoints, also called the B-spline CDF formula. Direct numerical integration needs fine grids and drifts, while the formula gives one exact rational answer. Integer arithmetic keeps the alternating sum exact, and one exact division prints the nine decimals.

## Why It Works

1. A draw from minus X to plus X equals a draw from zero to 2X minus X.
2. Summing all draws subtracts S, so the target interval shifts up by S.
3. The CDF of a sum of uniforms from zero to width w is an alternating sum over subsets.
4. A subset contributes the positive part of reach minus its width sum, raised to the power N.
5. Dividing by N times the product of widths gives a probability between zero and one.
6. Subtracting the lower CDF from the upper CDF gives the interval probability.

| term | meaning |
|---|---|
| `widths` | twice each X, the span of one shifted uniform draw |
| `halfSpan` | sum of the X values, the shift applied to both bounds |
| `cdfNumerator` | exact alternating sum for one shifted bound |
| `denominator` | N factorial times the product of widths |
| `BigNumber` | four base-one-billion limbs holding exact integers |

The numerator and denominator are integers, so no floating error enters the comparison.

A scripted trace for the fourth sample gives visible numbers.

| quantity | value |
|---|---|
| widths | 10 and 10 |
| denominator | 2 times 10 times 10 = 200 |
| shifted lower bound | -20 plus 10 = -10 |
| shifted upper bound | 5 plus 10 = 15 |
| numerator difference | 175 minus 0 = 175 |
| answer | 175 divided by 200 = 0.875 |

The lower bound sits below the support, so its CDF is zero.

Exact division rounds the last digit by comparing twice the remainder with the denominator.

## Code

**Input, output, and big integers.** The reader handles negative bounds and the writer flushes by block.

```nim
const flushBlockBytes = 1 shl 17
const bigBase: int64 = 1000000000
const decimalScale: int64 = 1000000000
const decimalPlaces = 9

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and not ((data[pos] >= '0' and data[pos] <= '9') or data[pos] == '-'):
    pos += 1
  var negative = false
  if pos < data.len and data[pos] == '-':
    negative = true
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  if negative:
    return -value
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

type BigNumber = array[0 .. 3, int64]

proc makeBig(value: int64): BigNumber =
  var built: BigNumber = [0.int64, 0.int64, 0.int64, 0.int64]
  built[0] = value
  return built

proc multiplySmall(value: var BigNumber, factor: int64) =
  var carry: int64 = 0
  for limbIndex in 0 .. 3:
    let product = value[limbIndex] * factor + carry
    value[limbIndex] = product mod bigBase
    carry = product div bigBase

proc addBig(target: var BigNumber, other: BigNumber) =
  var carry: int64 = 0
  for limbIndex in 0 .. 3:
    let total = target[limbIndex] + other[limbIndex] + carry
    target[limbIndex] = total mod bigBase
    carry = total div bigBase

proc subtractBig(target: var BigNumber, other: BigNumber) =
  var borrow: int64 = 0
  for limbIndex in 0 .. 3:
    var difference = target[limbIndex] - other[limbIndex] - borrow
    if difference < 0:
      difference += bigBase
      borrow = 1
    else:
      borrow = 0
    target[limbIndex] = difference

proc compareBig(first: BigNumber, second: BigNumber): int =
  for limbIndex in countdown(3, 0):
    if first[limbIndex] > second[limbIndex]:
      return 1
    if first[limbIndex] < second[limbIndex]:
      return -1
  return 0

proc scaledBig(value: BigNumber, factor: int64): BigNumber =
  var built = value
  multiplySmall(built, factor)
  return built

proc differenceBig(first: BigNumber, second: BigNumber): BigNumber =
  var built = first
  subtractBig(built, second)
  return built

proc divideBig(numerator: BigNumber, denominator: BigNumber): tuple[quotient: BigNumber, remainder: BigNumber] =
  var quotient = makeBig(0)
  var remainder = makeBig(0)
  for limbIndex in countdown(3, 0):
    for higher in countdown(3, 1):
      remainder[higher] = remainder[higher - 1]
    remainder[0] = numerator[limbIndex]
    var low: int64 = 0
    var high: int64 = bigBase - 1
    while low < high:
      let middle = (low + high + 1) div 2
      if compareBig(scaledBig(denominator, middle), remainder) <= 0:
        low = middle
      else:
        high = middle - 1
    quotient[limbIndex] = low
    remainder = differenceBig(remainder, scaledBig(denominator, low))
  return (quotient, remainder)
```

The scanner accepts a minus before the interval bounds.
Each limb holds at most nine decimal digits.
Long division finds one quotient limb at a time.

**CDF numerator and final formatting.** One subset sweep supplies each shifted cumulative value.

```nim
proc cdfNumerator(reach: int, widths: seq[int]): BigNumber =
  var positive = makeBig(0)
  var negative = makeBig(0)
  let factorCount = widths.len
  let subsetCount = 1 shl factorCount
  for subsetMask in 0 .. subsetCount - 1:
    var subsetTotal = 0
    for factorIndex in 0 .. factorCount - 1:
      if (subsetMask and (1 shl factorIndex)) != 0:
        subsetTotal += widths[factorIndex]
    let distance = reach - subsetTotal
    if distance < 0:
      continue
    var power = makeBig(int64(distance))
    for exponent in 1 .. factorCount - 1:
      multiplySmall(power, int64(distance))
    var bitCount = 0
    var bits = subsetMask
    while bits != 0:
      bitCount += bits and 1
      bits = bits shr 1
    if (bitCount and 1) == 0:
      addBig(positive, power)
    else:
      addBig(negative, power)
  subtractBig(positive, negative)
  return positive

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let factorCount = nextInt(inputData, scanPos)
  let lowerBound = nextInt(inputData, scanPos)
  let upperBound = nextInt(inputData, scanPos)
  var widths = newSeq[int](factorCount)
  var halfSpan = 0
  for factorIndex in 0 .. factorCount - 1:
    widths[factorIndex] = 2 * nextInt(inputData, scanPos)
    halfSpan += widths[factorIndex] div 2
  var denominator = makeBig(1)
  for divisor in 1 .. factorCount:
    multiplySmall(denominator, int64(divisor))
  for width in widths:
    multiplySmall(denominator, int64(width))
  var upperNumerator = cdfNumerator(upperBound + halfSpan, widths)
  let lowerNumerator = cdfNumerator(lowerBound + halfSpan, widths)
  subtractBig(upperNumerator, lowerNumerator)
  let scaledNumerator = scaledBig(upperNumerator, decimalScale)
  let division = divideBig(scaledNumerator, denominator)
  var quotient = division.quotient
  if compareBig(scaledBig(division.remainder, 2), denominator) >= 0:
    addBig(quotient, makeBig(1))
  let wholePart = quotient[1]
  let fractionPart = quotient[0]
  var fractionText = $fractionPart
  while fractionText.len < decimalPlaces:
    fractionText = "0" & fractionText
  appendOutput($wholePart & "." & fractionText)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Separate positive and negative sums avoid signed big integers.
The remainder comparison rounds the ninth decimal place.
The final flush writes all buffered probability lines.

## Complexity

Each test visits every subset once and raises a small power.

| phase | time | space |
|---|---|---|
| input read | one pass over X values | one input string |
| subset sweep | two passes over 2 to the N subsets | two big accumulators |
| division | four binary searches over one billion | two big temporaries |
| output | one block per line | output buffer |

The subset sweep dominates the runtime for each test.

| measure | Big O |
|---|---|
| time | O(T · 2^N · N) |
| space | O(N) |

Numerical integration needs fine grids and still misses the exact nine decimals that the integer formula delivers.
