# NDIV — n-divisors (SPOJ)

<https://www.spoj.com/problems/NDIV/>

## Problem

Count the integers in [a, b] that have exactly n positive divisors. Only a short interval is queried, so the work depends on its length.

Input is one line with three integers a, b and n. Output one line with the count.

| item | bound |
|---|---|
| interval ends a, b | 1 to 1000000000 |
| interval length b - a | 0 to 10000 |
| divisor target n | 1 to 100 |
| judge limit | 1000 ms, 1536 MB |

The interval length drives the design, not the size of its endpoints.

Sample input:

```
1 7 2
```

Sample output:

```
4
```

## Idea

Stamp divisor counts across the interval, like marking every tenth house on a street. Each small prime visits its multiples once, so no number needs a fresh factor search.

The algorithm sieves primes up to sqrt(b), then sweeps each prime over the interval. A prime visit costs one division per multiple, and a leftover factor above sqrt(b) contributes one more divisor. The naive method trial-divides every number up to sqrt(b), which repeats the same work thousands of times.

Takeaway: sweep primes over the short interval instead of factoring each value alone.

## Why It Works

1. Every divisor count comes from prime exponents: product of (exponent + 1).
2. A prime sweep finds the full exponent for each multiple in one pass.
3. After all primes up to sqrt(b), a remainder above 1 is a single unused prime factor.
4. That leftover multiplies the divisor count by 2.
5. The answer counts entries whose divisor total equals n.

| term | meaning |
|---|---|
| `remainders` | each interval value after its small prime factors are removed |
| `divisorCounts` | running product of (exponent + 1) for each value |
| `primeCandidates` | primes up to sqrt(b) |
| `targetDivisors` | the requested divisor count n |

The two arrays advance together, so every value keeps its own state.

A script-generated divisor table for 1..7:

```
number   divisors
1         1
2         2
3         2
4         3
5         2
6         4
7         2
```

Four entries equal 2, matching the sample answer 4.

## Code

**Input and scanning.** The hand reader loads a, b and n.

```nim
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

let lowBound = nextInt(inputData, scanPos)
let highBound = nextInt(inputData, scanPos)
let targetDivisors = nextInt(inputData, scanPos)
```

Only one query exists, so scanning stops after three values.
The interval length is at most 10001.
All values fit in 64-bit integers.

**Prime sieve.** A plain sieve lists the offsets needed by the sweep.

```nim
let spanLength = highBound - lowBound + 1
var remainders = newSeq[int](spanLength)
var divisorCounts = newSeq[int](spanLength)
for spanIndex in 0 .. spanLength - 1:
  remainders[spanIndex] = lowBound + spanIndex
  divisorCounts[spanIndex] = 1

var rootBound = 1
while rootBound * rootBound <= highBound:
  rootBound += 1

var isComposite = newSeq[bool](rootBound + 1)
var primeCandidates = newSeq[int]()
for candidate in 2 .. rootBound:
  if not isComposite[candidate]:
    primeCandidates.add candidate
    var multiple = candidate * candidate
    while multiple <= rootBound:
      isComposite[multiple] = true
      multiple += candidate
```

Each interval slot starts with count 1.
The integer root loop avoids floating point.
Marking starts at the square of each prime.

**Segmented sweep.** Each prime strips its powers from every multiple in range.

```nim
for primeValue in primeCandidates:
  if primeValue * primeValue > highBound:
    break
  var firstMultiple = ((lowBound + primeValue - 1) div primeValue) * primeValue
  var numberValue = firstMultiple
  while numberValue <= highBound:
    let spanIndex = numberValue - lowBound
    var exponent = 0
    while remainders[spanIndex] mod primeValue == 0:
      remainders[spanIndex] = remainders[spanIndex] div primeValue
      exponent += 1
    if exponent > 0:
      divisorCounts[spanIndex] = divisorCounts[spanIndex] * (exponent + 1)
    numberValue += primeValue

var matchingCount = 0
for spanIndex in 0 .. spanLength - 1:
  var divisorTotal = divisorCounts[spanIndex]
  if remainders[spanIndex] > 1:
    divisorTotal = divisorTotal * 2
  if divisorTotal == targetDivisors:
    matchingCount += 1
```

Division comes before multiplication to keep values small.
The first multiple is rounded up from the lower bound.
A leftover remainder adds exactly one prime factor.

**Buffered output.** The single count is written once.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

appendOutput($matchingCount)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The buffer helper follows the common write path.
One newline closes the single output line.
The final write flushes the short buffer.

## Complexity

The sieve is tiny, and the sweep visits each prime's multiples once.

| phase | time | space |
|---|---|---|
| prime sieve | O(sqrt(b) log log sqrt(b)) | sqrt(b) booleans |
| divisor sweep | O((b - a) sum 1/p) | two interval arrays |
| final count | O(b - a) | none extra |
| output | one line | block buffer |

Interval length controls the sweep, while b controls only the sieve size.

| measure | Big O |
|---|---|
| time | O(sqrt(b) log log b + (b - a) log log b) |
| space | O(sqrt(b) + (b - a)) |

Factoring every number separately costs O((b - a) sqrt(b)) and wastes most divisions.

Takeaway: reuse each prime across the whole interval.
