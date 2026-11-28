# PITPAIR — Pythagorean Legacy (SPOJ)

<https://www.spoj.com/problems/PITPAIR/>

## Problem

For each count N, find the smallest hypotenuse shared by exactly N different integer right triangles. Print the shorter leg of each triangle in ascending order.

Input: the first value is the case count t. Each later value is one N.
Output: for each case, print R alone on a line, then the N shorter legs, one per line.
Let 2N + 1 be the product to match, and 2e + 1 the part from one prime exponent.

The bounds from the statement and the judge page:

| Item | Bound |
|---|---|
| Test cases t | at most 100 |
| Requested count N | 1 to 2000 |
| Hypotenuse R | fits a signed 64-bit integer |
| Judge limit | 2250 ms, 1536 MB |

The triangle count determines the work; the 64-bit bound limits which hypotenuses can answer a case.

The sample input:

```
2
1
2
```

The sample output:

```
5
3
25
7
15
```

Both cases print one radius and all their legs.

## Idea

Split the odd number 2N + 1 into factors, then turn each factor into an exponent. Think of packing boxes: the largest item goes into the smallest box, because small bases grow slowest.

The triangle count of a hypotenuse is (2e + 1) multiplied over its prime exponents, minus 1, divided by 2. So those factors must multiply to 2N + 1. The program lists every factor split, puts larger exponents on smaller primes, and keeps the smallest product.

Each allowed prime is a sum of two squares. Complex powers of that prime list every way to write R squared as two squares, and each way gives one triangle. Conjugate states repeat a leg, so sorting removes the copies. A hand scanner reads the whole input once, and one buffer writes output in blocks.

Testing every hypotenuse upward and listing its triples each time costs far more. Factor once, build once, then print the legs.

## Why It Works

Four facts carry the proof.

1. A prime that is 1 modulo 4 is a sum of two squares in one way. Its powers give the primitive pairs of that prime.
2. A hypotenuse with exponents e has exactly the count above, because each prime contributes 2e + 1 choices.
3. Moving a larger exponent to a smaller prime shrinks the product, so exponents must run from large to small.
4. Every representation of R squared as two squares gives one triangle, and its shorter leg is the smaller square root.

The terms used in the construction:

| Term | Meaning |
|---|---|
| `2N + 1` | the product that the factors must reach |
| `2e + 1` | the factor contributed by one prime exponent |
| `oneModFourPrimes` | primes 5, 13, 17, and so on |
| `exponentTable` | the winning exponent list for each count |

The table converts a requested count into a fixed list of exponents.

A script trace for N = 4 makes the numbers visible:

```
N = 4; 2N+1 = 9; split 9 = 3 * 3
exponents 1 and 1 on primes 5 and 13 give R = 65
primitive hypotenuse | pair (small, large) | scale | shorter leg
   5 | (1, 2) | 13 | 39
  13 | (2, 3) |  5 | 25
  65 | (1, 8) |  1 | 16
  65 | (4, 7) |  1 | 33
sorted shorter legs: [16, 25, 33, 39]
```

The four legs are the full answer for N = 4, in the required order.

## Code

**Shared constants and tables.** The prime list and the answer arrays live for the whole run.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const maxTriangleCount = 2000
const primeCount = 12
const hypotenuseLimit = int64(9223372036854775807)

const oneModFourPrimes: array[0..primeCount - 1, int64] = [int64(5), int64(13), int64(17), int64(29), int64(37), int64(41), int64(53), int64(61), int64(73), int64(89), int64(97), int64(101)]
const primeRealParts: array[0..primeCount - 1, int64] = [int64(2), int64(3), int64(4), int64(5), int64(6), int64(5), int64(7), int64(6), int64(8), int64(8), int64(9), int64(10)]
const primeImagParts: array[0..primeCount - 1, int64] = [int64(1), int64(2), int64(1), int64(2), int64(1), int64(4), int64(2), int64(5), int64(3), int64(5), int64(4), int64(1)]

var bestRadius: array[0..maxTriangleCount, int64]
var exponentTable: array[0..maxTriangleCount, array[0..primeCount - 1, int]]
var exponentScratch: array[0..primeCount - 1, int]
```

The first prime is 5, since a factor needs exponent at least 1. The arrays hold one radius and exponent list per count, so no test case rebuilds them.

**Factor split and precompute.** Every count gets its smallest radius once, before any input is read.

```nim
proc limitedPower(baseValue: int64, exponentValue: int, limitValue: int64): int64 =
  result = 1'i64
  for _ in 1..exponentValue:
    if result > limitValue div baseValue:
      return -1'i64
    result = result * baseValue

proc searchPartitions(remainingValue, previousFactor, depth: int, currentProduct: int64, representationProduct: int) =
  if remainingValue == 1:
    let triangleCount = (representationProduct - 1) div 2
    if triangleCount >= 1 and triangleCount <= maxTriangleCount:
      if bestRadius[triangleCount] == 0 or currentProduct < bestRadius[triangleCount]:
        bestRadius[triangleCount] = currentProduct
        for factorIndex in depth..<primeCount:
          exponentScratch[factorIndex] = 0
        for factorIndex in 0..<primeCount:
          exponentTable[triangleCount][factorIndex] = exponentScratch[factorIndex]
    return
  if depth >= primeCount: return
  var factorCandidate = 3
  while factorCandidate <= remainingValue:
    if factorCandidate <= previousFactor and remainingValue mod factorCandidate == 0:
      let exponentValue = (factorCandidate - 1) div 2
      let powerValue = limitedPower(oneModFourPrimes[depth], exponentValue, hypotenuseLimit div currentProduct)
      if powerValue > 0:
        exponentScratch[depth] = exponentValue
        searchPartitions(remainingValue div factorCandidate, factorCandidate, depth + 1, currentProduct * powerValue, representationProduct * (2 * exponentValue + 1))
    factorCandidate += 2

for triangleIndex in 1..maxTriangleCount:
  searchPartitions(2 * triangleIndex + 1, 2 * triangleIndex + 1, 0, 1'i64, 1)
```

The recursion stops when the remaining factor is 1. It tries odd divisors no larger than the previous one, so each split appears once. `limitedPower` refuses powers past the 64-bit ceiling.

**Token reader.** Digits are scanned by index, so no token object is built.

```nim
proc nextInt(inputData: string, scanPos: var int): int =
  while scanPos < inputData.len and (inputData[scanPos] < '0' or inputData[scanPos] > '9'):
    scanPos += 1
  var value = 0
  while scanPos < inputData.len and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    value = value * 10 + int(inputData[scanPos]) - firstDigitValue
    scanPos += 1
  return value
```

The scan skips non-digits and builds a value from digit bytes. The position survives across calls because it is a `var` parameter.

**Complex helpers.** One tuple holds a real and imaginary part, and buffers are reused.

```nim
type ComplexValue = tuple[realPart: int64, imagPart: int64]

proc makeComplex(realValue, imagValue: int64): ComplexValue =
  result.realPart = realValue
  result.imagPart = imagValue

proc multiplyComplex(leftValue, rightValue: ComplexValue): ComplexValue =
  result.realPart = leftValue.realPart * rightValue.realPart - leftValue.imagPart * rightValue.imagPart
  result.imagPart = leftValue.realPart * rightValue.imagPart + leftValue.imagPart * rightValue.realPart

proc compareLegs(leftValue, rightValue: int64): int =
  if leftValue < rightValue: return -1
  if leftValue > rightValue: return 1
  return 0

var legValues: seq[int64]
var stateValues: seq[ComplexValue]
var nextStateValues: seq[ComplexValue]
var plusPowers: seq[ComplexValue]
var minusPowers: seq[ComplexValue]
```

Products stay within the radius, so each component fits a signed 64-bit value. The comparator sorts legs numerically, and `setLen 0` recycles the buffers.

**Leg collector.** Complex powers of each prime list every representation, then duplicates fall away.

```nim
proc collectLegValues(triangleCount: int) =
  legValues.setLen 0
  stateValues.setLen 0
  stateValues.add makeComplex(1'i64, 0'i64)
  for factorIndex in 0..<primeCount:
    let exponentValue = exponentTable[triangleCount][factorIndex]
    if exponentValue == 0: continue
    plusPowers.setLen 0
    minusPowers.setLen 0
    plusPowers.add makeComplex(1'i64, 0'i64)
    minusPowers.add makeComplex(1'i64, 0'i64)
    for powerIndex in 1..2 * exponentValue:
      plusPowers.add multiplyComplex(plusPowers[powerIndex - 1], makeComplex(primeRealParts[factorIndex], primeImagParts[factorIndex]))
      minusPowers.add multiplyComplex(minusPowers[powerIndex - 1], makeComplex(primeRealParts[factorIndex], -primeImagParts[factorIndex]))
    nextStateValues.setLen 0
    for stateValue in stateValues:
      for choiceIndex in 0..2 * exponentValue:
        let factorValue = multiplyComplex(plusPowers[choiceIndex], minusPowers[2 * exponentValue - choiceIndex])
        nextStateValues.add multiplyComplex(stateValue, factorValue)
    swap(stateValues, nextStateValues)
  for stateValue in stateValues:
    if stateValue.imagPart != 0:
      legValues.add min(abs(stateValue.realPart), abs(stateValue.imagPart))
  legValues.sort(compareLegs)
```

For each prime the loop runs from 0 to twice its exponent. The zero imaginary case is the trivial representation and is skipped. Sorting then removes conjugate copies before output.

**Output driver.** Input is read once, and output leaves in blocks.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let triangleCount = nextInt(inputData, scanPos)
  let radiusValue = bestRadius[triangleCount]
  appendOutput($radiusValue)
  outputBuffer.add '\n'
  collectLegValues(triangleCount)
  var previousLeg = int64(-1)
  for legValue in legValues:
    if legValue != previousLeg:
      appendOutput($legValue)
      outputBuffer.add '\n'
      previousLeg = legValue

stdout.write outputBuffer
```

Each leg is printed once because `previousLeg` suppresses repeats. The final write covers the tail, and block flushing caps memory at `flushBlockBytes`.

## Complexity

The work splits into a one-time table build and a short pass per case.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Table build | divisor scans for 2000 counts | 2000 radii and exponents |
| One case | at most 2N + 1 complex states | N legs |
| Output write | one write per 256 KiB block | block buffer |

The table build runs once, and the largest case stays inside the judge limit.

The overall asymptotic bounds:

| Measure | Big O |
|---|---|
| Time | O(2000 * d) to build, then O(N log N) per case |
| Space | O(2000 + N) |

Here d is the divisor scan for 2N + 1. A search upward over every hypotenuse and its triples grows far faster. The factor split keeps each case small.
