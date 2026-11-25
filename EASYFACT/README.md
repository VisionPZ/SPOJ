# EASYFACT — Easy Factorials (SPOJ)

<https://www.spoj.com/problems/EASYFACT/>

## Problem

Count the ways n! can be written as a sum of at least two consecutive positive integers, modulo a prime M. The first line gives T; each of the next T lines gives n and M. Print one count per line.

| item | bound |
|---|---|
| test count T | below 5001 |
| factorial index n | below 10^8 |
| prime modulus M | below 10^9 |
| judge limit | 5000 ms, 1536 MB |

The answer depends only on the odd prime factors of n!.

Sample input:

```
1
3 7
```

Sample output:

```
1
```

## Idea

Removing every factor of two from n! is like unwrapping a parcel to count the distinct boxes inside; only odd factors set the number of consecutive sums. The count equals the number of odd divisors of n! minus one.

The algorithm sieves primes once, then multiplies e + 1 over every odd prime, where e is the exponent of that prime in n!. Large primes are grouped by the value of n div p, and prime-count lookups replace a scan over millions of primes. A direct scan over all primes up to n would repeat millions of steps per test case.

Each query uses a few thousand group steps and stays short even at the largest n.

## Why It Works

1. A representation with k terms exists for each odd divisor k of n!, after mapping the starting value back to a positive integer.
2. The one-term case corresponds to divisor one, so the answer is the odd divisor count minus one.
3. For odd prime p, the exponent in n! is the sum of n div p^j over all powers j.
4. Primes above the square root of n have exponent n div p and can be counted in groups.
5. Modular exponentiation multiplies (group index + 1) by itself once per reachable prime in the group.

| term | meaning |
|---|---|
| `primeCounts` | number of primes at most x, for every x up to the largest n |
| `primeList` | all primes used for the small-prime exponent sums |
| `squareRootLimit` | boundary between direct primes and grouped primes |
| `largeCount` | odd primes with exponent equal to one group index |
| `productValue` | odd divisor count so far, reduced modulo M |

The prime two is excluded from both the direct loop and every group count.

A script-generated trace for n = 9:

```
prime 3 exponent 4 -> factor 5
group 1 primes 5 7 -> factor 2^2 = 4
odd divisor count = 5 * 4 = 20
answer = 20 - 1 = 19
```

The trace gives 19, which agrees with a direct factorization of 9!.

## Code

**Input and power helper.** All cases are read first, then a binary power helper is defined.

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc modPower(baseValue: int64, exponentValue: int64, modulusValue: int64): int64 =
  var resultValue: int64 = 1
  var reducedBase = baseValue mod modulusValue
  var remaining = exponentValue
  while remaining > 0:
    if (remaining and 1) != 0:
      resultValue = (resultValue * reducedBase) mod modulusValue
    reducedBase = (reducedBase * reducedBase) mod modulusValue
    remaining = remaining shr 1
  return resultValue
```

All cases are parsed before any sieve work.
The largest n sets the size of the tables.
Products stay in int64 because M stays below 10^9.

**Prime tables.** An odd-only sieve feeds a prime-count table and a prime list.

```nim
let problemCount = nextInt(inputData, scanPos)
var problemNs = newSeq[int](problemCount)
var problemModuli = newSeq[int](problemCount)
var largestN = 0
for problemIndex in 0 ..< problemCount:
  problemNs[problemIndex] = nextInt(inputData, scanPos)
  problemModuli[problemIndex] = nextInt(inputData, scanPos)
  if problemNs[problemIndex] > largestN:
    largestN = problemNs[problemIndex]

var oddComposite = newSeq[bool](largestN div 2 + 1)
oddComposite[0] = true
var baseValue = 3
while int64(baseValue) * int64(baseValue) <= int64(largestN):
  if not oddComposite[baseValue div 2]:
    var multipleValue = int64(baseValue) * int64(baseValue)
    let stepValue = int64(2 * baseValue)
    while multipleValue <= int64(largestN):
      oddComposite[int(multipleValue) div 2] = true
      multipleValue += stepValue
  baseValue += 2

var primeCounts = newSeq[int32](largestN + 1)
var primeList = newSeq[int]()
primeList.add 2
var runningCount = 0
for candidateValue in 0 .. largestN:
  var candidateIsPrime = false
  if candidateValue == 2:
    candidateIsPrime = true
  elif candidateValue > 2 and (candidateValue and 1) == 1:
    candidateIsPrime = not oddComposite[candidateValue div 2]
  if candidateIsPrime:
    runningCount += 1
    if candidateValue != 2:
      primeList.add candidateValue
  primeCounts[candidateValue] = int32(runningCount)
```

Only odd numbers need composite flags.
The count table answers interval queries in constant time.
Both tables are built once for all cases.

**Answers.** Small primes use direct exponents; larger primes use grouped counts.

```nim
for problemIndex in 0 ..< problemCount:
  let problemN = problemNs[problemIndex]
  let modulusValue = int64(problemModuli[problemIndex])
  let squareRootLimit = int(sqrt(float(problemN)))
  var productValue: int64 = 1
  for primeIndex in 0 ..< primeList.len:
    let primeValue = int64(primeList[primeIndex])
    if primeValue == 2:
      continue
    if primeValue * primeValue > int64(problemN):
      break
    var exponentValue: int64 = 0
    var powerValue = primeValue
    while powerValue <= int64(problemN):
      exponentValue += int64(problemN) div powerValue
      if powerValue > int64(problemN) div primeValue:
        break
      powerValue = powerValue * primeValue
    productValue = (productValue * ((exponentValue + 1) mod modulusValue)) mod modulusValue
  for groupIndex in 1 .. squareRootLimit:
    let upperBound = problemN div groupIndex
    let lowerBound = problemN div (groupIndex + 1)
    var oddUpper = int64(primeCounts[upperBound])
    var oddLower = int64(primeCounts[lowerBound])
    if oddUpper > 0:
      oddUpper -= 1
    if oddLower > 0:
      oddLower -= 1
    let smallUpper = min(upperBound, squareRootLimit)
    let smallLower = min(lowerBound, squareRootLimit)
    var smallUpperCount = int64(primeCounts[smallUpper])
    var smallLowerCount = int64(primeCounts[smallLower])
    if smallUpperCount > 0:
      smallUpperCount -= 1
    if smallLowerCount > 0:
      smallLowerCount -= 1
    let largeCount = oddUpper - oddLower - (smallUpperCount - smallLowerCount)
    if largeCount > 0:
      productValue = (productValue * modPower(int64(groupIndex + 1), largeCount, modulusValue)) mod modulusValue
  let answerValue = if productValue == 0: modulusValue - 1 else: productValue - 1
  appendOutput($answerValue)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Small-prime and grouped counts never overlap.
A zero product still maps to M - 1 after subtracting one.
Answers leave through one shared block buffer.

## Complexity

The sieve is shared by all cases, while each case walks only about the square root of n groups.

| phase | time | space |
|---|---|---|
| input read | one pass over case pairs | two case arrays |
| sieve and counts | one odd sieve up to largest n | flags and count table |
| per-case work | direct primes plus grouped intervals | constant |
| output | one buffered line per case | block buffer |

The table build is amortized across all test cases.

| measure | Big O |
|---|---|
| preprocessing | O(N log log N), N = largest n |
| time per case | O(sqrt(n) log n) |
| space | O(N) |

Visiting every prime up to n for every case would multiply the work by millions.
