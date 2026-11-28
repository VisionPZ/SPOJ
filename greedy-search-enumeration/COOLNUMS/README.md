<https://www.spoj.com/problems/COOLNUMS/>

## Problem

Count numbers in `[A,B]` whose digits can be split into two groups of equal sum. Splitting digits into equal halves is exactly a subset-sum question: the digit total must be even, and some subset must reach half that total.

Each test case is one line with two unsigned integers `A` and `B`. A line `0 0` ends the input. Print one count per test case. About 50 cases appear, and `B` is at most `4 * 10^9`.

| item | bound |
|---|---|
| range endpoints | 1 to `4 * 10^9` |
| digits per number | at most 10 |
| test cases | about 50 |
| judge limit | 5673 ms, 1536 MB |

The sample input:

```
1 11
12 20
1 20
3 100
6354 234363
123456789 234567891
0 0
```

The sample output:

```
1
0
1
9
82340
54801678
```

## Idea

Treat the reachable digit sums as a row of light switches: adding a digit flips on every switch that is that many steps to the right. This is a bitset shift. Counting numbers up to `X` becomes a digit-by-digit walk where each suffix state stores how many completions finish cool. The state depends only on how many of each digit were used, so one memo table serves every query.

## Why It Works

1. A digit partition with equal sums exists exactly when the total digit sum is even and a subset sums to half of it.
2. The reachable sums after a prefix form a set; adding digit `d` changes it to `old union (old shifted by d)`.
3. The highest reachable sum equals the total digit sum, because choosing all digits is a subset.
4. Only the multiset of digits matters for reachability, so a base-11 code of the ten digit counts identifies the state.
5. The suffix count for a state is reused by every query, since it never depends on the bound.
6. Counting up to `X` fixes the smaller-prefix branches at each digit and adds the cached suffix counts.

| term | meaning |
|---|---|
| `lowBits`, `highBits` | reachable sums 0..63 and 64..90 as two bit words |
| `code` | base-11 encoding of the ten digit counts |
| `countCompletions` | number of cool completions from one state |
| `countUpTo` | count of cool numbers from 0 to the bound |

The table names the state and the two counting routines.

A worked trace for `23450`:

| digit | reachable sums after the digit |
|---|---|
| start | 0 |
| 2 | 0, 2 |
| 3 | 0, 2, 3, 5 |
| 4 | 0, 2, 3, 4, 5, 6, 7, 9 |
| 5 | 0, 2, 3, 4, 5, 6, 7, 9, 10, 11, 12, 14 |
| 0 | unchanged |

The total is 14 and the target 7 is reachable, so 23450 is cool.

## Code

**Input and scanner.** All input lines enter one buffer, and `nextInt` skips whitespace.

```nim
import tables

const flushBlockBytes = 1 shl 17
const digitCount = 10
const highestSumBit = 27

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
```

The scanner skips all non-digit characters.
Both endpoints are non-negative, so no signed branch is needed.

**Buffered output and state encoding.** One output string batches answers, and base-11 powers encode digit counts.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var basePowers = newSeq[int](digitCount)
basePowers[0] = 1
for digit in 1 .. digitCount - 1:
  basePowers[digit] = basePowers[digit - 1] * 11

const highMask = (1'u64 shl highestSumBit) - 1'u64

proc addDigit(lowBits: uint64, highBits: uint64, digit: int): tuple[low: uint64, high: uint64] =
  if digit == 0:
    return (lowBits, highBits)
  let carry = lowBits shr (64 - digit)
  let newLow = lowBits or (lowBits shl digit)
  let newHigh = (highBits or (highBits shl digit) or carry) and highMask
  return (newLow, newHigh)
```

`addDigit` shifts the two word bitset and carries the overflow upward.
The mask keeps only sums that ten digits can reach.

**Coolness test and memoized suffix.** The highest set bit is the digit total, and its half must also be set.

```nim
var completionCache = initTable[int64, int64]()

proc highestReachableSum(lowBits: uint64, highBits: uint64): int =
  if highBits != 0'u64:
    var bitIndex = 63
    while bitIndex >= 0 and (highBits and (1'u64 shl uint(bitIndex))) == 0'u64:
      bitIndex -= 1
    return 64 + bitIndex
  var bitIndex = 63
  while bitIndex >= 0 and (lowBits and (1'u64 shl uint(bitIndex))) == 0'u64:
    bitIndex -= 1
  return bitIndex

proc isCoolState(lowBits: uint64, highBits: uint64): int =
  let total = highestReachableSum(lowBits, highBits)
  if total mod 2 == 1:
    return 0
  let target = total div 2
  if target < 64:
    if (lowBits and (1'u64 shl uint(target))) != 0'u64:
      return 1
    return 0
  if (highBits and (1'u64 shl uint(target - 64))) != 0'u64:
    return 1
  return 0

proc countCompletions(remaining: int, code: int64, lowBits: uint64, highBits: uint64): int64 =
  if remaining == 0:
    return int64(isCoolState(lowBits, highBits))
  if completionCache.hasKey(code):
    return completionCache[code]
  var ways: int64 = 0
  for digit in 0 .. digitCount - 1:
    let shifted = addDigit(lowBits, highBits, digit)
    ways += countCompletions(remaining - 1, code + int64(basePowers[digit]),
                             shifted.low, shifted.high)
  completionCache[code] = ways
  return ways
```

The cache key is the digit-count code, so each state is solved once.
A number with leading zeros uses the same state as its shorter form.

**Bound counting.** Each position adds all smaller digit choices, then fixes the bound digit.

```nim
proc countUpTo(limit: int64): int64 =
  if limit < 0:
    return 0
  var digits = newSeq[int](digitCount)
  var remainder = limit
  for position in countdown(digitCount - 1, 0):
    digits[position] = int(remainder mod 10)
    remainder = remainder div 10
  var answer: int64 = 0
  var lowBits = 1'u64
  var highBits = 0'u64
  var code: int64 = 0
  for position in 0 .. digitCount - 1:
    let currentDigit = digits[position]
    let remaining = digitCount - 1 - position
    for digit in 0 .. currentDigit - 1:
      let shifted = addDigit(lowBits, highBits, digit)
      answer += countCompletions(remaining, code + int64(basePowers[digit]),
                                 shifted.low, shifted.high)
    let shifted = addDigit(lowBits, highBits, currentDigit)
    lowBits = shifted.low
    highBits = shifted.high
    code += int64(basePowers[currentDigit])
  answer += countCompletions(0, code, lowBits, highBits)
  return answer
```

Ten positions cover every bound up to `4 * 10^9`.
The final suffix counts the bound itself.

**Query loop.** Each range answer is the difference of two prefix counts.

```nim
var lowerBound = int64(nextInt(inputData, scanPos))
var upperBound = int64(nextInt(inputData, scanPos))
while not (lowerBound == 0 and upperBound == 0):
  let answer = countUpTo(upperBound) - countUpTo(lowerBound - 1)
  appendOutput($answer)
  outputBuffer.add '\n'
  lowerBound = int64(nextInt(inputData, scanPos))
  upperBound = int64(nextInt(inputData, scanPos))

stdout.write outputBuffer
outputBuffer.setLen 0
```

Subtracting two prefix counts gives the inclusive range count.
The zero sentinel stops before any output for that line.

## Complexity

The memo table solves every reachable digit-count state once; each query then walks ten digit positions.

| phase | time | space |
|---|---|---|
| suffix states | at most 184756 states times 10 digits | one cache entry per state |
| bound count | 10 positions times 10 digit choices | ten digit slots |
| output | one append per case | block buffer |

The phase table shows that the one-time suffix pass dominates for many queries.

| measure | Big O |
|---|---|
| preprocessing | O(C * 10), C the count-vector states |
| time per query | O(10 * 10) cache lookups |
| space | O(C) |

Checking every integer in a range costs O(B-A) subset-sum tests and cannot handle a range of four billion. Caching suffix states makes each range constant time after the shared pass.
