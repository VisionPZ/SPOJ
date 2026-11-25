# PYTRIP2 — Pythagorean triples (medium) (SPOJ)

<https://www.spoj.com/problems/PYTRIP2/>

## Problem

Count Pythagorean triples whose three sides all lie between N and M inclusive. A triple is a set, so order does not matter, and each query needs one count. Inputs contain many queries, and the product T times M stays below 1.21e8.

| item | bound |
|---|---|
| test cases T | 1 to 99 |
| query bounds | 0 < N < M |
| combined bound | T * M < 1.21e8 |
| judge limit | 1000 ms, 1536 MB |

Euclid's formula generates each triple once from two integers of opposite parity and coprime value. Scaling that primitive triple by a positive integer gives every other triple with the same shape.

Sample input:

```
3
1 5
4 10
10 100
```

Sample output:

```
1
1
45
```

## Idea

Generate primitive triples once, then count legal multiples for each query with two divisions. This is like listing every bread recipe once and scaling portions to fit an order. A brute-force scan over pairs of legs repeats the same square checks for every query and grows as M squared. Euclid's parametrization lists shapes only once, and the multiple range follows from two simple bounds. Use that precomputed list for all queries.

## Why It Works

1. A primitive triple has legs m²-n² and 2mn, and hypotenuse m²+n², with m greater than n.
2. Coprime m and n of opposite parity produce each primitive triple once.
3. Every triple equals a positive multiple k of one primitive triple.
4. The smallest leg sets the lower bound k >= ceil(N / smallest leg).
5. The hypotenuse sets the upper bound k <= floor(M / hypotenuse).

| term | meaning |
|---|---|
| `mValue`, `nValue` | Euclid parameters for one primitive triple |
| `smallLeg` | smaller of the two primitive legs |
| `firstMultiple` | first scale that keeps every side at least N |
| `lastMultiple` | last scale that keeps every side at most M |

For the query 4 10, the primitive triple 3 4 5 has smallLeg 3. The first multiple is ceil(4/3) = 2 and the last is floor(10/5) = 2, so one triple qualifies: 6 8 10.

| query | primitive shapes used | answer |
|---|---|---|
| 1 5 | 3 4 5 at scale 1 | 1 |
| 4 10 | 3 4 5 at scale 2 | 1 |
| 10 100 | shapes scaled inside the window | 45 |

The count adds one for each integer scale in that closed interval.

## Code

**Input and scanner.** The reader stores all queries before any computation.

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
```

The largest upper bound drives the one-time precomputation.
All bounds fit in the machine integer type.

**Output helper and gcd.** The buffer collects answers while Euclid filtering uses an integer gcd.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc gcdValues(first: int64, second: int64): int64 =
  var left = first
  var right = second
  while right != 0:
    let remainder = left mod right
    left = right
    right = remainder
  return left
```

The gcd loop uses repeated remainders.
No division by zero occurs because the loop guards on right.

**Primitive generation.** Each valid parameter pair adds one primitive shape.

```nim
let testCount = nextInt(inputData, scanPos)
var lowerBounds = newSeq[int](testCount)
var upperBounds = newSeq[int](testCount)
var maxUpper = 0
for queryIndex in 0 .. testCount - 1:
  lowerBounds[queryIndex] = nextInt(inputData, scanPos)
  upperBounds[queryIndex] = nextInt(inputData, scanPos)
  if upperBounds[queryIndex] > maxUpper:
    maxUpper = upperBounds[queryIndex]

var legOneList = newSeq[int64](0)
var legTwoList = newSeq[int64](0)
var hypotenuseList = newSeq[int64](0)
let rootLimit = int(sqrt(float(maxUpper))) + 1
for mValue in 2 .. rootLimit:
  for nValue in 1 .. mValue - 1:
    let hypotenuse = int64(mValue * mValue + nValue * nValue)
    if hypotenuse > int64(maxUpper):
      break
    if (mValue - nValue) mod 2 == 0:
      continue
    if gcdValues(int64(mValue), int64(nValue)) != 1:
      continue
    let legOne = int64(mValue * mValue - nValue * nValue)
    let legTwo = int64(2 * mValue * nValue)
    legOneList.add legOne
    legTwoList.add legTwo
    hypotenuseList.add hypotenuse
```

The inner loop stops once the hypotenuse exceeds the largest query.
Parity and gcd tests reject parameter pairs that would repeat shapes.

**Query loop.** Two divisions give the count of scales for each primitive shape.

```nim
for queryIndex in 0 .. testCount - 1:
  let lowerBound = int64(lowerBounds[queryIndex])
  let upperBound = int64(upperBounds[queryIndex])
  var tripleCount: int64 = 0
  for tripleIndex in 0 .. hypotenuseList.len - 1:
    let hypotenuse = hypotenuseList[tripleIndex]
    if hypotenuse > upperBound:
      continue
    let smallLeg = min(legOneList[tripleIndex], legTwoList[tripleIndex])
    let firstMultiple = (lowerBound + smallLeg - 1) div smallLeg
    let lastMultiple = upperBound div hypotenuse
    if lastMultiple >= firstMultiple:
      tripleCount = tripleCount + lastMultiple - firstMultiple + 1
  appendOutput($tripleCount)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The smaller leg determines how far the lower bound reaches.
The hypotenuse determines the largest scale that still fits.

## Complexity

Precomputation lists each primitive triple once up to the largest M.

| phase | time | space |
|---|---|---|
| input read | one pass over query pairs | two query arrays |
| precompute | parameter pairs up to sqrt(max M) | three lists of primitive sides |
| query scan | one pass over primitives per query | one block buffer |

| measure | Big O |
|---|---|
| precompute | O(max M log max M) parameter checks |
| query | O(number of primitives with hypotenuse at most M) |
| space | O(number of primitives up to max M) |

A leg-pair scan would test M squared pairs for every query instead of scaling a short list of shapes.

The primitive list is shared, so extra queries add little work beyond their scans.
