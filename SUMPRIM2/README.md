# SUMPRIM2 — Sum of primes (reverse mode) (SPOJ)

<https://www.spoj.com/problems/SUMPRIM2/>

## Problem

Given `S`, the sum of all primes from 2 up to some last prime `P`, report that last prime `P`. The sum reverses the usual task: find the bound from the total.

Input: one line with the integer `S`. Output: one line with `P`. Write `PS(n)` for the sum of primes at most `n`, so the input satisfies `S = PS(P)`.

| item | bound |
|---|---|
| last prime `P` | 0 < P to 10^12 |
| sum `S` | about 2 * 10^22 at the top bound |
| input files | 20 |
| judge limit | 3000 ms, 1536 MB |

Sample input:

```
77
```

Sample output:

```
19
```

The second statement sample uses `S = 24739512092254535` and output `999999937`.

## Idea

Estimate the answer by area, then verify it locally, like finding a shelf from the total shelf length. The prime sum grows like `x^2 / (2 ln x)`. Inverting that curve lands within a million of the answer. A sieve over that small window fixes the exact value.

Computing `PS(x)` by sieving all numbers to `x` is impossible at `10^12`. A Meissel-Lehmer style sweep keeps sums only at values `x / i` and at small values up to square root of `x`. Each prime removes the composites it owns. The sweep costs about `x^(3/4)` steps and needs a 128-bit style accumulator, since sums exceed 64 bits.

Binary search over `x` would call the sweep about 40 times. One call plus a local sieve finishes here.

The takeaway: invert the smooth curve first, then spend one exact sweep and a short sieve.

## Why It Works

1. `PS(x)` equals the sum of integers from 2 to `x` minus the sum of composites up to `x`.
2. Every composite has one smallest prime factor `p`, and it equals `p * q` with `q >= p`.
3. After processing primes below `p`, the stored sum at `x` holds numbers with no smaller factor, including primes below `p`.
4. Subtracting `PS(p - 1)` from the stored sum at `x / p` leaves exactly the valid `q` values.
5. Processing primes in order and values from large to small keeps every sub-sum in its pre-update state.
6. After all primes up to square root of `x`, only primes remain, so `largeSum[1]` is `PS(x)`.

| term | meaning |
|---|---|
| `largeSum` | running sum at each value `x / i` |
| `smallSum` | running sum at each value up to square root of `x` |
| `primePrefix` | prime sums below each small bound |
| `beforePrime` | `PS(p - 1)`, excluded when removing composites |
| `candidate` | estimated location of `P` |

Worked sweep for `x = 10`, where primes up to square root of 10 are 2 and 3:

| stage | `largeSum[1]` | cells changed |
|---|---|---|
| start | 54 | all sums `2 + 3 + ... + v` |
| after `p = 2` | 26 | remove `2 * (1 + 2 + 3 + 4 + 5) = 30` |
| after `p = 3` | 17 | remove `3 * 3 = 9` |

The result 17 is `2 + 3 + 5 + 7`, as required. Walking the local sieve down from 17 reaches `S = 10` at prime 5 and `S = 7` at prime 3.

A `Wide` value uses two 64-bit limbs, so it holds sums near `10^22` with exact carries.

## Code

**Input and wide arithmetic.** The decimal sum is parsed digit by digit into two limbs.

```nim
import math

{.push checks: off.}

const flushBlockBytes = 1 shl 17
const limbMask = 4294967295'u64
const windowRadius = 1000000'i64

type Wide = object
  lo: uint64
  hi: uint64

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
```

The limbs `lo` and `hi` hold the low and high 64-bit parts.

**Arithmetic helpers.** Subtraction borrows and multiplication carries across limbs.

```nim
proc makeWide(value: int64): Wide =
  Wide(lo: uint64(value), hi: 0'u64)

proc addWide(first: Wide, second: Wide): Wide =
  let lowPart = first.lo + second.lo
  var carry = 0'u64
  if lowPart < first.lo: carry = 1
  Wide(lo: lowPart, hi: first.hi + second.hi + carry)

proc subWide(first: Wide, second: Wide): Wide =
  let lowPart = first.lo - second.lo
  var borrow = 0'u64
  if first.lo < second.lo: borrow = 1
  Wide(lo: lowPart, hi: first.hi - second.hi - borrow)

proc cmpWide(first: Wide, second: Wide): int =
  if first.hi != second.hi:
    if first.hi < second.hi: return -1
    return 1
  if first.lo < second.lo: return -1
  if first.lo > second.lo: return 1
  return 0

proc toFloatWide(value: Wide): float =
  return float(value.hi) * 18446744073709551616.0 + float(value.lo)
```

The float form is used only for the initial estimate.

**Decimal parsing and products.** Products of two bounds use 32-bit halves and shifts.

```nim
proc addDigit(value: var Wide, digit: int64) =
  let newLow = value.lo + uint64(digit)
  if newLow < value.lo: value.hi += 1
  value.lo = newLow

proc mulSmall(value: Wide, factor: int64): Wide =
  let factorValue = uint64(factor)
  let lowHalf = value.lo and limbMask
  let highHalf = value.lo shr 32
  let bottomPart = lowHalf * factorValue
  let topPart = highHalf * factorValue
  let newLow = bottomPart + (topPart shl 32)
  var carry = topPart shr 32
  if newLow < bottomPart: carry += 1
  Wide(lo: newLow, hi: value.hi * factorValue + carry)

proc productWide(first: int64, second: int64): Wide =
  let firstValue = uint64(first)
  let secondValue = uint64(second)
  let firstLow = firstValue and limbMask
  let firstHigh = firstValue shr 32
  let secondLow = secondValue and limbMask
  let secondHigh = secondValue shr 32
  let bottomPart = firstLow * secondLow
  let crossPart = firstLow * secondHigh + firstHigh * secondLow
  let newLow = bottomPart + (crossPart shl 32)
  var carry = crossPart shr 32
  if newLow < bottomPart: carry += 1
  Wide(lo: newLow, hi: firstHigh * secondHigh + carry)

proc triangleWide(value: int64): Wide =
  if value < 2: return makeWide(0)
  let half = if value mod 2 == 0: value div 2 else: (value + 1) div 2
  let other = if value mod 2 == 0: value + 1 else: value
  return subWide(productWide(half, other), makeWide(1))

proc parseWide(data: string, pos: var int): Wide =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  result = makeWide(0)
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    result = mulSmall(result, 10)
    addDigit(result, int64(int(data[pos]) - 48))
    pos += 1
```

Parsing never converts the whole sum into one machine integer.

**Prime sieve.** Base primes are shared by the sweep and the local window.

```nim
proc smallPrimes(limit: int64): seq[int64] =
  var composite = newSeq[bool](int(limit) + 1)
  result = newSeq[int64](0)
  for value in 2 .. int(limit):
    if not composite[value]:
      result.add int64(value)
      var multiple = value * value
      while multiple <= int(limit):
        composite[multiple] = true
        multiple += value
```

Marking starts at the square of each prime.

**Summatory sweep.** One exact `PS` evaluation.

```nim
proc primeSum(limit: int64): Wide =
  if limit < 2: return makeWide(0)
  var root = int64(sqrt(float(limit)))
  while (root + 1) * (root + 1) <= limit: root += 1
  while root * root > limit: root -= 1
  let primes = smallPrimes(root)
  var smallSum = newSeq[int64](int(root) + 1)
  for value in 2 .. int(root):
    smallSum[value] = value * (value + 1) div 2 - 1
  var largeSum = newSeq[Wide](int(root) + 1)
  for divisor in 1 .. int(root):
    largeSum[divisor] = triangleWide(limit div int64(divisor))
  var primePrefix = newSeq[int64](int(root) + 1)
  var running = 0'i64
  var primeIndex = 0
  for value in 0 .. int(root):
    while primeIndex < primes.len and primes[primeIndex] <= int64(value):
      running += primes[primeIndex]
      primeIndex += 1
    primePrefix[value] = running
  for prime in primes:
    let square = prime * prime
    let beforePrime = primePrefix[int(prime) - 1]
    let beforeWide = makeWide(beforePrime)
    let maxDivisor = min(root, limit div square)
    let primeValue = int(prime)
    let splitDivisor = min(int(maxDivisor), int(root) div primeValue)
    if splitDivisor >= 1:
      for divisor in 1 .. splitDivisor:
        let quotientSum = largeSum[divisor * primeValue]
        let removed = mulSmall(subWide(quotientSum, beforeWide), prime)
        largeSum[divisor] = subWide(largeSum[divisor], removed)
    if splitDivisor < int(maxDivisor):
      for divisor in splitDivisor + 1 .. int(maxDivisor):
        let quotientIndex = int64(divisor) * prime
        let quotientSum = makeWide(int64(smallSum[int(limit div quotientIndex)]))
        let removed = mulSmall(subWide(quotientSum, beforeWide), prime)
        largeSum[divisor] = subWide(largeSum[divisor], removed)
    var value = int(root)
    while int64(value) >= square:
      let quotient = value div primeValue
      smallSum[value] -= primeValue * (smallSum[quotient] - beforePrime)
      value -= 1
  return largeSum[1]
```

Large values run in increasing divisor order, which is decreasing value order.

**Estimate and local sieve.** The smooth curve places the window, and primes inside it are listed.

```nim
proc liApproximation(value: float): float =
  let logarithm = ln(value)
  let denominator = 2.0 * logarithm
  var power = 1.0
  var total = 1.0
  var factorial = 1.0
  for order in 1 .. 14:
    factorial *= float(order)
    power /= denominator
    total += factorial * power
  return value * value / denominator * total

proc estimateRoot(target: float): int64 =
  var guess = sqrt(2.0 * target * ln(max(target, 2.0)))
  for iteration in 0 .. 9:
    let safeGuess = max(guess, 2.0)
    guess = safeGuess - (liApproximation(safeGuess) - target) * ln(safeGuess) / safeGuess
    if guess < 2.0: guess = 2.0
  return int64(guess)

proc nearbyPrimes(center: int64): seq[int64] =
  let low = max(2'i64, center - windowRadius)
  let high = center + windowRadius
  let span = int(high - low + 1)
  var marked = newSeq[bool](span)
  let root = int64(sqrt(float(high))) + 1
  let basePrimes = smallPrimes(root)
  for prime in basePrimes:
    if prime * prime > high: break
    let square = prime * prime
    var start = ((low + prime - 1) div prime) * prime
    if start < square: start = square
    var multiple = start
    while multiple <= high:
      marked[int(multiple - low)] = true
      multiple += prime
  result = newSeq[int64](0)
  for offset in 0 .. span - 1:
    if not marked[offset]:
      result.add low + int64(offset)
```

The window radius is one million, which covers the estimate error at the top bound.

**Walk to the answer.** Each step adds or removes exactly one prime.

```nim
let targetSum = parseWide(inputData, scanPos)
var candidate = estimateRoot(toFloatWide(targetSum))
if candidate < 2: candidate = 2
var sumAtCandidate = primeSum(candidate)
var answer = 0'i64

proc searchWindow(center: int64, startingSum: Wide): int64 =
  let localPrimes = nearbyPrimes(center)
  var anchor = -1
  for primeIndex in 0 .. localPrimes.len - 1:
    if localPrimes[primeIndex] <= center: anchor = primeIndex
  if anchor < 0: return 0
  var runningSum = startingSum
  if cmpWide(runningSum, targetSum) == 0:
    return localPrimes[anchor]
  var upward = anchor + 1
  while upward < localPrimes.len:
    runningSum = addWide(runningSum, makeWide(localPrimes[upward]))
    if cmpWide(runningSum, targetSum) == 0:
      return localPrimes[upward]
    upward += 1
  runningSum = startingSum
  var downward = anchor - 1
  while downward >= 0:
    runningSum = subWide(runningSum, makeWide(localPrimes[downward + 1]))
    if cmpWide(runningSum, targetSum) == 0:
      return localPrimes[downward]
    downward -= 1
  return 0

answer = searchWindow(candidate, sumAtCandidate)
```

If the window misses, a correction and then a binary search act as guards.

```nim
if answer == 0:
  let difference = toFloatWide(targetSum) - toFloatWide(sumAtCandidate)
  let corrected = float(candidate) + difference * ln(float(candidate)) / float(candidate)
  candidate = int64(max(2.0, corrected))
  sumAtCandidate = primeSum(candidate)
  answer = searchWindow(candidate, sumAtCandidate)

if answer == 0:
  var lower = 2'i64
  var upper = candidate * 2
  if upper < 4: upper = 4
  while lower < upper:
    let middle = (lower + upper) div 2
    if cmpWide(primeSum(middle), targetSum) < 0:
      lower = middle + 1
    else:
      upper = middle
  candidate = lower
  sumAtCandidate = primeSum(candidate)
  answer = searchWindow(candidate, sumAtCandidate)
```

The binary search always brackets `P`, because `PS` increases at every prime.

**Output.** The single line goes through the shared buffer.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

appendOutput($answer)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

## Complexity

| phase | time | space |
|---|---|---|
| input parse | one pass over digits | one input string |
| estimate | fixed 14-term series | constant |
| summatory sweep | about `limit^(3/4)` updates | two arrays of square root of limit |
| local sieve | about `2 * radius * log log` marks | window plus base primes |
| output | one line | 128 KiB buffer |

| measure | Big O |
|---|---|
| time per input | O(x^(3/4)) with x near P |
| space | O(sqrt(x)) plus the window |
| wide operations | exact in two limbs |

Sieving every number to `10^12` costs O(x log log x) time and O(x) space. The sweep keeps only the floor-division values and finishes in a few seconds at the top bound.
