# DTPOLY2 — Divide Polygon Hard (SPOJ)

<https://www.spoj.com/problems/DTPOLY2/>

## Problem

Count the ways to split a labelled convex N-gon into K pieces using non-crossing vertex-to-vertex diagonals, and report the count modulo M. Cutting order is ignored, and each vertex is distinct.

Input has no leading count. Each line holds N, K, and M, and reading stops at end of file. Print one answer per line.

| item | bound |
|---|---|
| vertices N | at least 3 |
| sum of N over cases | at most 100000000 |
| pieces K | 1 to N-2 |
| modulus M | 1 < M < 2^60 |
| judge limit | 6000 ms, 1536 MB |

The modulus drives the design because it need not be prime.

Sample input:

```
4 2 100
6 3 100
10000000 2 1000000007
10000000 5000000 1000000014000000049
```

Sample output:

```
2
21
984650007
780127215155143528
```

The first two lines are small enough to check by hand.

## Idea

The closed form turns a huge dissection count into two binomial coefficients divided by K, like pricing a crate by weight instead of counting every item. Legendre's formula gives the prime exponent of each factorial, so no large integer is ever built. Subtracting the exponent of K makes the quotient exact, and modular powers rebuild the answer under any modulus. Enumerating dissections would grow exponentially with N. The formula replaces that enumeration with one sieve and a short exponent loop.

## Why It Works

1. The number of dissections into K pieces is binomial(N+K-2, K-1) times binomial(N-3, K-1), divided by K.
2. Legendre's formula gives the exponent of prime p in any factorial as a sum of floor divisions.
3. A binomial exponent is the exponent of the top factorial minus the two lower factorials.
4. Subtracting the exponent of K leaves a nonnegative exponent for every prime.
5. Multiplying prime powers modulo M gives the answer without dividing by a non-invertible value.

| term | meaning |
|---|---|
| `polygonSize` | N vertices |
| `pieceCount` | K pieces |
| `primeFactorCount` | Legendre exponent of a factorial |
| `integerFactorCount` | exponent of a prime in K |
| `netExponent` | final exponent after cancellation |

The table lists the inputs and the two exponent helpers.

A script trace for the first two sample lines follows:

```
N=4 K=2: C(4,1)=4, C(1,1)=1, 4*1/2=2
N=6 K=3: C(7,2)=21, C(3,2)=3, 21*3/3=21
Powers are reduced modulo 100, so both answers stay 2 and 21
```

The trace matches the sample output.

The modular multiply uses a 128-bit intermediate, which guards against overflow when M nears 2^60.

## Code

**Input and modular multiply.** Tokens are read once and products use a wide intermediate.

```nim
const flushBlockBytes = 1 shl 17

proc mulmod128(leftValue, rightValue, modulusValue: uint64): uint64 {.importc: "mulmod128_c", nodecl.}
{.emit: """
static inline unsigned long long mulmod128_c(unsigned long long leftValue, unsigned long long rightValue, unsigned long long modulusValue) {
  return (unsigned long long)(((unsigned __int128)leftValue * (unsigned __int128)rightValue) % (unsigned __int128)modulusValue);
}
""".}

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

There is no leading test count.
The wide product keeps residues below M.
Buffered writes avoid per-line flushing.

**Exponent helpers.** Legendre sums and modular powers stay in 64-bit integers.

```nim
proc powerMod(baseValue, exponentValue, modulusValue: uint64): uint64 =
  var powerResult = 1'u64
  var currentBase = baseValue mod modulusValue
  var currentExponent = exponentValue
  while currentExponent > 0'u64:
    if (currentExponent and 1'u64) == 1'u64:
      powerResult = mulmod128(powerResult, currentBase, modulusValue)
    currentBase = mulmod128(currentBase, currentBase, modulusValue)
    currentExponent = currentExponent shr 1
  return powerResult

proc primeFactorCount(factorialArgument, primeValue: int): int =
  var totalCount = 0
  var primePower = primeValue
  while primePower <= factorialArgument:
    totalCount += factorialArgument div primePower
    if primePower > factorialArgument div primeValue:
      break
    primePower *= primeValue
  return totalCount

proc integerFactorCount(value, primeValue: int): int =
  var remaining = value
  var totalCount = 0
  while remaining mod primeValue == 0:
    remaining = remaining div primeValue
    totalCount += 1
  return totalCount
```

Squaring drives the powers logarithmically.
The power loop stops before an integer overflow.
Both helpers return small non-negative counts.

**Sieve and case loop.** One sieve serves every test case.

```nim
var polygonSizes = newSeq[int]()
var pieceCounts = newSeq[int]()
var moduli = newSeq[int]()
var largestArgument = 0
while scanPos < inputData.len:
  let polygonSize = nextInt(inputData, scanPos)
  let pieceCount = nextInt(inputData, scanPos)
  let modulusValue = nextInt(inputData, scanPos)
  if polygonSize == 0 and pieceCount == 0 and modulusValue == 0:
    break
  polygonSizes.add polygonSize
  pieceCounts.add pieceCount
  moduli.add modulusValue
  let upperArgument = polygonSize + pieceCount - 2
  if upperArgument > largestArgument:
    largestArgument = upperArgument

var isComposite = newSeq[bool](largestArgument + 1)
var primes = newSeq[int]()
for candidate in 2 .. largestArgument:
  if not isComposite[candidate]:
    primes.add candidate
    if int64(candidate) * int64(candidate) <= int64(largestArgument):
      var multiple = candidate * candidate
      while multiple <= largestArgument:
        isComposite[multiple] = true
        multiple += candidate

for caseIndex in 0 .. polygonSizes.len - 1:
  let polygonSize = polygonSizes[caseIndex]
  let pieceCount = pieceCounts[caseIndex]
  let modulusValue = uint64(moduli[caseIndex])
  var answer = 1'u64
  for primeIndex in 0 .. primes.len - 1:
    let primeValue = primes[primeIndex]
    if primeValue > largestArgument:
      break
    if primeValue > polygonSize + pieceCount - 2:
      break
    let firstBinomialExponent = primeFactorCount(polygonSize + pieceCount - 2, primeValue) -
                                primeFactorCount(pieceCount - 1, primeValue) -
                                primeFactorCount(polygonSize - 1, primeValue)
    let secondBinomialExponent = primeFactorCount(polygonSize - 3, primeValue) -
                                 primeFactorCount(pieceCount - 1, primeValue) -
                                 primeFactorCount(polygonSize - pieceCount - 2, primeValue)
    let pieceExponent = integerFactorCount(pieceCount, primeValue)
    let netExponent = firstBinomialExponent + secondBinomialExponent - pieceExponent
    if netExponent > 0:
      answer = mulmod128(answer, powerMod(uint64(primeValue), uint64(netExponent), modulusValue), modulusValue)
  appendOutput($answer)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The sieve bound is the largest N+K-2.
Each prime contributes its reduced exponent.
The final flush emits all answers together.

## Complexity

Each case walks primes up to N+K-2.

| phase | time | space |
|---|---|---|
| input read | one pass over triples | arrays of cases |
| sieve | one pass to the largest bound | Boolean array |
| exponent loop | prime count per case | prime array |
| output | one buffered write | block buffer |

The phase table separates shared sieve work from per-case work.

| measure | Big O |
|---|---|
| time | O(L log log L + pi(L) log N) with L = max N+K-2 |
| space | O(L) |

Enumerating dissections gives exponential time. The closed form and Legendre exponents replace that growth with a sieve and powers.
