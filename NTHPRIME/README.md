# NTHPRIME — Nth Prime (SPOJ)

<https://www.spoj.com/problems/NTHPRIME/>

## Problem

Given one index N, output the Nth prime number. A sieve alone cannot reach the largest index, so the answer needs a counting method that skips most integers.

Input is a single line holding the integer N. Output is a single line holding the Nth prime.

| item | bound |
|---|---|
| index N | at most 1000000000 |
| source size | 4000 bytes on the judge |
| judge limit | 2667 ms, 1536 MB |

The first prime has index one.

Sample input:

```
4
```

Sample output:

```
7
```

## Idea

Counting primes up to a bound is like counting people in a stadium by sections instead of checking every seat. Lehmer's prime-counting formula counts primes up to x with a sieve and a few recursive sums. Binary search the smallest x whose count reaches N; that x is prime.

One count costs sublinear work after the sieve. Scanning and testing every integer up to the answer would cost far more for the largest indices. The sieve also supplies every small prime the counting formula needs.

## Why It Works

1. The prime-counting function pi(x) is nondecreasing and jumps only at primes.
2. The smallest x with pi(x) ≥ N is therefore the Nth prime.
3. Lehmer's formula combines a count of integers free of small prime factors with a correction over larger primes.
4. A sieve up to ten million answers every small count directly and lists primes for the correction.
5. Integer cube and square roots set the split points exactly, so no floating drift changes the count.

| term | meaning |
|---|---|
| `primePrefix` | number of primes up to each sieved value |
| `phiCount` | integers up to a value free of the first k primes |
| `primePi` | Lehmer count of primes up to a value |
| `primeIndexWanted` | the input index N |

Known counts such as pi(10^9) = 50847534 confirm the counting routine.

The script example uses N = 4. The count pi(6) is 3, so 6 is too small. The count pi(7) is 4, so the smallest feasible bound is 7. Output 7.

The same binary search gives the 1000000000th prime as 22801763489.

## Code

**Input and sieve.** The hand reader loads N, and the sieve builds primes and prefix counts.

```nim
import math
import tables

const flushBlockBytes = 1 shl 17
const sieveLimit = 10000000
const keyStride = 512

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

A ten million sieve covers every count the recursion needs.
Prefix counts make table lookups constant time.
Prime storage is indexed from zero.

**Counting core.** Memoized phi and Lehmer counts share the sieved primes.

```nim
proc phiCount(value: int64, primeCount: int): int64 =
  var effectiveCount = primeCount
  if value <= 1:
    return value
  if value <= int64(sieveLimit):
    let possibleCount = int(primePrefix[int(value)])
    if effectiveCount > possibleCount:
      effectiveCount = possibleCount
  if effectiveCount == 0:
    return value
  if effectiveCount == 1:
    return value - value div 2
  let cacheKey = value * int64(keyStride) + int64(effectiveCount)
  if phiCache.hasKey(cacheKey):
    return phiCache[cacheKey]
  let counted = phiCount(value, effectiveCount - 1) -
    phiCount(value div int64(primeList[effectiveCount - 1]), effectiveCount - 1)
  phiCache[cacheKey] = counted
  return counted
```

The cache key packs a value and a prime count.
The recursion removes one prime at a time.
Products stay in wide integers.

```nim
proc primePi(value: int64): int64 =
  if value <= int64(sieveLimit):
    return int64(primePrefix[int(value)])
  if piCache.hasKey(value):
    return piCache[value]
  let fourthRoot = integerRoot(value, 4)
  let cubeRoot = integerRoot(value, 3)
  let squareRoot = integerRoot(value, 2)
  let smallCount = primePi(fourthRoot)
  let cubeCount = primePi(cubeRoot)
  let largeCount = primePi(squareRoot)
  var counted = phiCount(value, int(smallCount)) +
    (largeCount + smallCount - 2) * (largeCount - smallCount + 1) div 2
  var primeIndex = int(smallCount)
  while primeIndex < int(largeCount):
    let quotient = value div int64(primeList[primeIndex])
    counted -= primePi(quotient)
    primeIndex += 1
  primeIndex = int(smallCount)
  while primeIndex < int(cubeCount):
    let quotient = value div int64(primeList[primeIndex])
    let limit = primePi(integerRoot(quotient, 2))
    var secondIndex = primeIndex
    while secondIndex < int(limit):
      let doubledQuotient = quotient div int64(primeList[secondIndex])
      counted -= primePi(doubledQuotient) - int64(secondIndex)
      secondIndex += 1
    primeIndex += 1
  piCache[value] = counted
  return counted
```

Fourth, cube, and square roots split the primes into counting groups.
The outer loop subtracts two-factor counts.
The inner loop subtracts three-factor counts.

**Binary search.** The bound from the prime number theorem brackets the answer.

```nim
  var lowValue = int64(primeList[primeList.len - 1])
  let approximate = float64(primeIndexWanted)
  let logIndex = ln(approximate)
  let logLogIndex = ln(logIndex)
  var highValue: int64
  if primeIndexWanted >= 688383:
    let lowerEstimate = approximate *
      (logIndex + logLogIndex - 1.0 + (logLogIndex - 2.1) / logIndex)
    if int64(lowerEstimate) > lowValue:
      lowValue = int64(lowerEstimate)
    highValue = int64(approximate *
      (logIndex + logLogIndex - 1.0 + (logLogIndex - 2.0) / logIndex)) + 100
  else:
    highValue = int64(approximate * (logIndex + logLogIndex)) + 100
  if highValue <= lowValue:
    highValue = lowValue + 1000
  while lowValue < highValue:
    let middleValue = lowValue + (highValue - lowValue) div 2
    if primePi(middleValue) >= primeIndexWanted:
      highValue = middleValue
    else:
      lowValue = middleValue + 1
  answer = lowValue
```

The estimate stays above the answer for every bound here.
Each step halves the remaining interval.
The final lower bound is the required prime.

## Complexity

The sieve runs once; counting and binary search follow.

| phase | time | space |
|---|---|---|
| sieve | one pass over composites | ten million flags and counts |
| phi recursion | a small cached tree per count | cached pairs |
| counting | one pass over large primes per count | cached counts |
| binary search | logarithmic counting calls | none beyond caches |

The sieve cost is paid only once per run.

| measure | Big O |
|---|---|
| time | roughly O(sieveLimit log log sieveLimit + log N times count cost) |
| space | O(sieveLimit) |

Testing each candidate with trial division would grow with the answer itself. Counting by ranges keeps the largest index reachable within the time limit.
