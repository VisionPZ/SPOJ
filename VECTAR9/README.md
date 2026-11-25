# VECTAR9 — Mangu Numbers (SPOJ)

<https://www.spoj.com/problems/VECTAR9/>

## Problem

List the positive integers divisible by at least one of the first thirteen primes, in ascending order. Given an index k, report the k-th integer in that list. Answers are guaranteed at most the product of the thirteen primes.

Input starts with T, at most 500, followed by one k per line. Print one answer per line.

The bounds from the statement:

| item | bound |
|---|---|
| test cases T | up to 500 |
| answer | at most 304250263527210 |
| judge limit | 1000 ms, 1536 MB |

The huge index range rules out generating the list directly.

Sample input:

```
2
2
3
```

Sample output:

```
3
4
```

## Idea

The divisibility pattern repeats every product of the primes, like a wallpaper tile that restarts after one full width.

One period contains a fixed number of mangu values, so the period index and a local rank replace a huge k. Inclusion-exclusion counts mangu values up to any bound in one sweep over the 8192 prime subsets. A binary search finds the smallest bound whose count reaches the local rank. Counting from scratch per candidate would need a sieve up to the answer. The narrow search window keeps each query fast.

## Why It Works

1. Divisibility by any of the primes repeats with period equal to their product.
2. Each period contains exactly the product minus the totient of the product mangu values.
3. Inclusion-exclusion sums the counts of multiples of every nonempty subset of primes.
4. Odd-size subsets add and even-size subsets subtract, matching the union of multiples.
5. The count rises by at most one per integer, so binary search finds the exact k-th value.
6. The count stays within a small constant of its linear density, so the answer sits near rank times period divided by period count.

The main terms:

| term | meaning |
|---|---|
| `periodValue` | product of the thirteen primes |
| `periodCount` | mangu values inside one period |
| `subsetProducts` | product of primes for each subset mask |
| `localRank` | rank inside the current period |
| `searchMargin` | safe window around the density estimate |

The window bounds the binary search to a short interval rather than the whole period.

A worked trace from the oracle sieve:

```
rank 1    -> 2
rank 2    -> 3
rank 3    -> 4
rank 10   -> 11
rank 100  -> 118
```

For rank 100 the density estimate is about 117, and the true answer 118 lies inside the search window.

## Code

**Subset products.** Every nonempty prime subset gets one divisor and one sign.

```nim
const flushBlockBytes = 1 shl 17
const periodValue: int64 = 304250263527210
const periodCount: int64 = 260105476071210
const basePrimes = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41]
const searchMargin: int64 = 40000

var subsetProducts: array[0 .. 8191, int64]
var subsetSigns: array[0 .. 8191, int]
subsetProducts[0] = 1
subsetSigns[0] = -1
for mask in 1 .. 8191:
  var lowestBit = 1
  var bitIndex = 0
  while (mask and lowestBit) == 0:
    lowestBit = lowestBit shl 1
    bitIndex += 1
  let previousMask = mask - lowestBit
  subsetProducts[mask] = subsetProducts[previousMask] * int64(basePrimes[bitIndex])
  subsetSigns[mask] = -subsetSigns[previousMask]
```

Each mask adds its lowest prime to a smaller mask.
The sign flips with every added prime.
Products fit in a signed 64-bit integer because they divide the period.

**Counting.** One sweep over subsets gives the number of mangu values up to a bound.

```nim
proc countMangu(value: int64): int64 =
  var total: int64 = 0
  for mask in 1 .. 8191:
    let quotient = value div subsetProducts[mask]
    if subsetSigns[mask] == 1:
      total = total + quotient
    else:
      total = total - quotient
  return total
```

The sum starts at zero because the union count has no separate leading term.
Positive signs belong to odd-size subsets.
Every division counts multiples of one subset product.

**Input and output.** The scanner loads all ranks and buffered output collects the answers.

```nim
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

Ranks fit in a signed 64-bit integer.
The parser skips whitespace automatically.
The flush threshold is 131072 bytes.

**Query loop.** Each rank is reduced to a period, then located by binary search.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let requestedRank = int64(nextInt(inputData, scanPos))
  let periodNumber = (requestedRank - 1) div periodCount
  let localRank = (requestedRank - 1) mod periodCount + 1
  let estimate = int64(float(localRank) * float(periodValue) / float(periodCount))
  var lowBound = estimate - searchMargin
  if lowBound < 1:
    lowBound = 1
  var highBound = estimate + searchMargin
  if highBound > periodValue:
    highBound = periodValue
  while lowBound < highBound:
    let middle = lowBound + (highBound - lowBound) div 2
    if countMangu(middle) >= localRank:
      highBound = middle
    else:
      lowBound = middle + 1
  let answer = periodNumber * periodValue + lowBound
  appendOutput($answer)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The estimate uses floating point only to pick a window.
The binary search uses exact integer counts inside that window.
The period offset is added after the local value is found.

## Complexity

Precomputation runs once, and each query runs a short binary search with a fixed-size counting sweep.

| phase | time | space |
|---|---|---|
| subset setup | one step per mask | 8192 divisors and signs |
| input read | one pass over ranks | one input string |
| query loop | about 17 counts per rank | block buffer |

The counting cost per step does not depend on the size of k.

The asymptotic bounds:

| measure | Big O |
|---|---|
| preprocessing | O(2^13) |
| time per query | O(2^13 log window) |
| space | O(2^13) |

A sieve up to the answer would cost a segment per answer, while inclusion-exclusion handles any rank with a bounded sweep.
