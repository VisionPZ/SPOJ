# FUNMODSEQ — Funny Modular Sequence (SPOJ)

<https://www.spoj.com/problems/FUNMODSEQ/>

## Problem

Each neighboring pair in a sequence multiplies to 1 modulo p, and every term lies in 0 to p - 1. Given the first term a1, the modulus p and the length n, report the sum of all n terms, or -1 when the sequence cannot continue. The modulus need not be prime.

The input starts with the test count T. Each following line gives a1, p and n. Print one answer per test in input order.

| item | bound |
|---|---|
| tests T | 1 to 100000 |
| first term a1 | 1 to 100000, and a1 < p |
| modulus p | up to 1000000000 |
| length n | 1 to 1000000000 |
| judge limit | 1000 ms, 1536 MB |

All terms and moduli stay inside these bounds.

Sample input:

```
2
2 3 2
3 7 2
```

Sample output:

```
4
8
```

The first sequence is 2, 2 and the second is 3, 5.

## Idea

A modular inverse is a partner that brings a product back to one, and applying it twice returns the original number, like turning a lock key over twice. The extended Euclidean algorithm finds that partner or proves none exists. The sequence then alternates between a value and its inverse, so a whole pair sums to a fixed amount. Walking up to a billion terms would be hopeless, while the closed pair sum costs constant time after one inverse computation.

## Why It Works

1. The condition on neighbors makes each next term the modular inverse of the current term.
2. An inverse exists exactly when the current term and p have gcd 1.
3. Extended Euclid returns that inverse, or reports a gcd above 1.
4. The inverse of an inverse is the original value, so the sequence repeats every two terms.
5. If a1 has no inverse, the answer is -1; otherwise every later term also has an inverse.
6. A complete pair contributes a1 plus its inverse, and an odd length adds one more a1.

| term | meaning |
|---|---|
| `modularInverse` | extended Euclid routine returning -1 on failure |
| `inverseValue` | partner of the first term modulo p |
| `pairSum` | sum of one full two-term period |
| `pairCount` | number of complete periods in n |
| `totalSum` | sum written for the test |

The table uses the sample rows and one failing case.

| a1 | p | inverse | n | answer |
|---|---|---|---|---|
| 2 | 3 | 2 | 2 | 4 |
| 3 | 7 | 5 | 2 | 8 |
| 2 | 4 | none | 5 | -1 |

The last row has gcd 2 with the modulus, so no valid partner exists.

## Code

**Input and scanner.** The stream is loaded once and parsed by a hand scanner.

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The scanner skips spaces and line breaks.
The buffer flushes only when it grows large.
All arithmetic stays in 64-bit integers.

**Inverse and pair sum.** Extended Euclid handles non-prime moduli.

```nim
proc modularInverse(value: int64, modulusValue: int64): int64 =
  var oldRemainder = value
  var newRemainder = modulusValue
  var oldCoefficient: int64 = 1
  var newCoefficient: int64 = 0
  while newRemainder != 0:
    let quotient = oldRemainder div newRemainder
    let nextRemainder = oldRemainder - quotient * newRemainder
    oldRemainder = newRemainder
    newRemainder = nextRemainder
    let nextCoefficient = oldCoefficient - quotient * newCoefficient
    oldCoefficient = newCoefficient
    newCoefficient = nextCoefficient
  if oldRemainder != 1:
    return -1
  var inverseValue = oldCoefficient mod modulusValue
  if inverseValue < 0:
    inverseValue += modulusValue
  return inverseValue

let testCount = nextInt(inputData, scanPos)
for testIndex in 0 .. testCount - 1:
  let firstValue = nextInt(inputData, scanPos)
  let modulusValue = nextInt(inputData, scanPos)
  let termCount = nextInt(inputData, scanPos)
  let inverseValue = modularInverse(int64(firstValue), int64(modulusValue))
  if inverseValue < 0:
    appendOutput("-1")
  else:
    let pairSum = int64(firstValue) + inverseValue
    let pairCount = int64(termCount) div 2
    var totalSum = pairCount * pairSum
    if termCount mod 2 == 1:
      totalSum += int64(firstValue)
    appendOutput($totalSum)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

A gcd above one returns the failure marker.
A negative coefficient is shifted into range.
The period sum avoids any loop over n.

## Complexity

One inverse computation serves each test.

| phase | time | space |
|---|---|---|
| input read | one pass over three values per test | one input string |
| inverse | one Euclidean step chain per test | a few variables |
| output | one line per test | block buffer |

The logarithm is taken over the modulus.

| measure | Big O |
|---|---|
| time | O(T log p) |
| space | O(input bytes) |

Building the sequence term by term would cost O(n) per test and fail at a billion terms.
The period closes after two terms, so each test finishes with one Euclidean chain.
