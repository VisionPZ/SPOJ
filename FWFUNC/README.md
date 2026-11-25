# FWFUNC — Fight with functions (SPOJ)

<https://www.spoj.com/problems/FWFUNC/>

## Problem

Given some values of a completely multiplicative function that also keeps coprime inputs coprime, decide whether each queried image is forced and print it when it is. Print NO when the given pairs contradict the rules or leave the query open.

The first line holds the test count. Each case gives N, then N lines containing x and f(x), then q, then q query lines containing y. The numbers reach 10 to the power 50, and a unique answer has fewer than 400 digits.

| item | bound |
|---|---|
| test cases | below 20 |
| pairs N | up to 50 |
| queries q | up to 50 |
| x, f(x), y | up to 10 to the power 50 |
| prime factors | up to 100005 |
| judge limit | 1090 ms, 1536 MB |

The large decimals make exponent vectors the useful representation.

Sample input:

```
3
3
2 2
3 2
7 19
1
7
1
6 6
1
6
2
2 2
3 3
1
12
```

Sample output:

```
NO
YES 6
YES 12
```

## Idea

Treat each prime as a color that owns a private set of output primes, like paint cans that never share a color. Every pair then becomes one linear equation per output prime, and each equation has at most one unknown color. Solve those equations independently, and compare the query's exponents across all solutions. Searching all possible functions would be infinite; the equations reduce each output prime to a handful of candidates.

| step | cost |
|---|---|
| factor one big decimal | O(number of small primes) |
| find candidates per output prime | O(pairs times domain primes) |
| combine rows for one query | O(output primes times candidates) |

The pair count and prime count set the work per case.

## Why It Works

1. Complete multiplicativity gives f(n) as the product of f(p) to the power of each exponent of p in n.
2. Coprime inputs must have coprime images, so distinct input primes own disjoint sets of output primes.
3. For one output prime q, any solution assigns q to exactly one input prime p with exponent v.
4. That assignment must satisfy b(i,q) = v times a(i,p) for every given pair, which pins v from any pair where b is positive.
5. A query image is unique when every candidate assignment gives the same exponent for q, including exponent zero for unused output primes.

| term | meaning |
|---|---|
| `expMatrix` | exponent of each input prime in each x |
| `imageMatrix` | exponent of each output prime in each f(x) |
| `candidateLists` | input prime and exponent pairs that fit one output prime |
| `limbs` | base one-billion pieces of a big decimal |

The table names the arrays that hold the equation data.

A script-generated trace for the third sample case:

```
pairs (2, 2) and (3, 3), query y = 12
output prime 2: owner 2, factor 1
output prime 3: owner 3, factor 1
y exponents: w(2) = 2, w(3) = 1
f(y) = 2^(2*1) * 3^(1*1) = 4 * 3 = 12
```

The trace reproduces the sample answer YES 12.

## Code

**Scanner, sieve and big-number factorization.** One read pass loads the case; small primes reduce each large decimal to exponent pairs.

```nim
const flushBlockBytes = 1 shl 17
const maxPrimeValue = 100005
const baseValue = 1000000000
const limbDigits = 9
const digitOffset = 48
const missingIndex = -1

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
    value = value * 10 + int(data[pos]) - digitOffset
    pos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var sievePrimes = newSeq[int]()
block:
  var compositeFlags = newSeq[bool](maxPrimeValue + 1)
  for value in 2 .. maxPrimeValue:
    if not compositeFlags[value]:
      sievePrimes.add value
      if int64(value) * int64(value) <= int64(maxPrimeValue):
        for multiple in countup(value * value, maxPrimeValue, value):
          compositeFlags[multiple] = true

proc nextNumber(data: string, pos: var int): string =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  let startPos = pos
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    pos += 1
  return data[startPos .. pos - 1]

proc parseLimbs(text: string): seq[int64] =
  var limbs = newSeq[int64]()
  var position = text.len - 1
  while position >= 0:
    var limbValue: int64 = 0
    var multiplier: int64 = 1
    for digitIndex in 0 .. limbDigits - 1:
      if position < 0:
        break
      limbValue = limbValue + int64(int(text[position]) - digitOffset) * multiplier
      multiplier = multiplier * 10
      position -= 1
    limbs.add limbValue
  return limbs

proc isUnit(limbs: seq[int64]): bool =
  return limbs.len == 1 and limbs[0] == 1

proc remainderPrime(limbs: seq[int64], primeValue: int): int =
  var remainder: int64 = 0
  for limbIndex in countdown(limbs.len - 1, 0):
    remainder = (remainder * int64(baseValue) + limbs[limbIndex]) mod int64(primeValue)
  return int(remainder)

proc dividePrime(limbs: var seq[int64], primeValue: int) =
  var carry: int64 = 0
  for limbIndex in countdown(limbs.len - 1, 0):
    let currentValue = carry * int64(baseValue) + limbs[limbIndex]
    limbs[limbIndex] = currentValue div int64(primeValue)
    carry = currentValue mod int64(primeValue)
  while limbs.len > 1 and limbs[limbs.len - 1] == 0:
    limbs.setLen(limbs.len - 1)

proc factorNumber(text: string): seq[(int, int)] =
  var factors = newSeq[(int, int)]()
  var limbs = parseLimbs(text)
  if limbs.len == 0:
    return factors
  for primeValue in sievePrimes:
    if isUnit(limbs):
      break
    var exponent = 0
    while remainderPrime(limbs, primeValue) == 0:
      exponent += 1
      dividePrime(limbs, primeValue)
    if exponent > 0:
      factors.add((primeValue, exponent))
  if not isUnit(limbs):
    if limbs.len > 2:
      factors.add((missingIndex, 1))
    else:
      var leftover: int64 = 0
      for limbIndex in countdown(limbs.len - 1, 0):
        leftover = leftover * int64(baseValue) + limbs[limbIndex]
      if leftover > int64(maxPrimeValue):
        factors.add((missingIndex, 1))
  return factors
```

Trial division stops once the limbs hold one.
Each division mutates the limbs in place.
A leftover beyond the prime bound marks a free input prime.

**Big product output.** Repeated small multiplication builds the decimal answer without a bigint library.

```nim
proc appendProduct(primeValues: seq[int], exponents: seq[int]) =
  var limbs = newSeq[int64]()
  limbs.add 1
  for primeIndex in 0 .. primeValues.len - 1:
    if exponents[primeIndex] > 0:
      for repetition in 0 .. exponents[primeIndex] - 1:
        var carry: int64 = 0
        for limbIndex in 0 .. limbs.len - 1:
          let productValue = limbs[limbIndex] * int64(primeValues[primeIndex]) + carry
          limbs[limbIndex] = productValue mod int64(baseValue)
          carry = productValue div int64(baseValue)
        while carry > 0:
          limbs.add carry mod int64(baseValue)
          carry = carry div int64(baseValue)
  var resultText = $(limbs[limbs.len - 1])
  var limbIndex = limbs.len - 2
  while limbIndex >= 0:
    var partText = $(limbs[limbIndex])
    while partText.len < limbDigits:
      partText = "0" & partText
    resultText.add partText
    limbIndex -= 1
  appendOutput("YES ")
  appendOutput(resultText)
  outputBuffer.add '\n'
```

Each limb carries into the next one.
Lower limbs are padded to nine digits.
The answer appears once, after the YES prefix.

**Equation solving.** Candidate owners are derived from one pair where the output prime appears.

```nim
  var candidateLists = newSeq[seq[(int, int)]](codomainCount)
  var consistent = true
  for primeIndex in 0 .. codomainCount - 1:
    var anchorPair = missingIndex
    for pairIndex in 0 .. pairCount - 1:
      if imageMatrix[pairIndex * codomainCount + primeIndex] > 0:
        anchorPair = pairIndex
        break
    if anchorPair == missingIndex:
      continue
    let targetExponent = imageMatrix[anchorPair * codomainCount + primeIndex]
    var candidateList = newSeq[(int, int)]()
    for domainIndex in 0 .. domainCount - 1:
      let anchorFactor = expMatrix[anchorPair * domainCount + domainIndex]
      if anchorFactor == 0 or targetExponent mod anchorFactor != 0:
        continue
      let factorValue = targetExponent div anchorFactor
      var works = true
      for pairIndex in 0 .. pairCount - 1:
        if imageMatrix[pairIndex * codomainCount + primeIndex] !=
           factorValue * expMatrix[pairIndex * domainCount + domainIndex]:
          works = false
          break
      if works:
        candidateList.add((domainIndex, factorValue))
    if candidateList.len == 0:
      consistent = false
    candidateLists[primeIndex] = candidateList
```

An empty candidate list makes the whole case inconsistent.
A zero output column needs no candidates and contributes exponent zero.
Every remaining candidate fits all pairs by construction.

**Query loop.** Each query multiplies the exponents forced by its own prime factors.

```nim
  let queryCount = nextInt(inputData, scanPos)
  for queryIndex in 0 .. queryCount - 1:
    let queryText = nextNumber(inputData, scanPos)
    if not consistent:
      appendOutput("NO\n")
      continue
    var weights = newSeq[int](domainCount)
    var productExponents = newSeq[int](codomainCount)
    var ambiguous = false
    for factorEntry in factorNumber(queryText):
      let primeValue = factorEntry[0]
      let exponent = factorEntry[1]
      if primeValue < 0 or primeValue > maxPrimeValue:
        ambiguous = true
        break
      if domainIndexOf[primeValue] == missingIndex:
        ambiguous = true
        break
      weights[domainIndexOf[primeValue]] = exponent
    if not ambiguous:
      for primeIndex in 0 .. codomainCount - 1:
        if candidateLists[primeIndex].len == 0:
          productExponents[primeIndex] = 0
        else:
          var expectedExponent = missingIndex
          for candidateEntry in candidateLists[primeIndex]:
            let candidateExponent = weights[candidateEntry[0]] * candidateEntry[1]
            if expectedExponent == missingIndex:
              expectedExponent = candidateExponent
            elif candidateExponent != expectedExponent:
              ambiguous = true
              break
          if ambiguous:
            break
          productExponents[primeIndex] = expectedExponent
    if ambiguous:
      appendOutput("NO\n")
    else:
      appendProduct(codomainValues, productExponents)
```

A query prime absent from all given x leaves f(y) free.
Two candidates with different exponents also leave f(y) free.
Agreeing candidates give one forced decimal answer.

## Complexity

Each case factors its numbers once, then solves one small equation system per output prime.

| phase | time | space |
|---|---|---|
| sieve | one pass up to 100005 | prime flags |
| factorization | small primes per big number | limb arrays |
| equation solving | pairs times domain primes per output prime | two exponent matrices |
| output | repeated small multiplication | limb buffer |

Equation solving dominates for many pairs.

| measure | Big O |
|---|---|
| time | O(P D C) per case for P pairs, D input primes, C output primes |
| space | O(P times (D plus C)) |

Enumerating all admissible functions would never terminate, so the per-prime equations give the practical bound.
