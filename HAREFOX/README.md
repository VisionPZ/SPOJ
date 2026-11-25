# HAREFOX — Hares and Foxes (SPOJ)
<https://www.spoj.com/problems/HAREFOX/>

## Problem

The input gives coefficients and starting values of a linear recurrence for two populations.
Determine the long-term fate of each population and print the matching fixed sentence.

The input holds about 5000 cases. The first line is a case count. Each case has six real numbers a, b, c, d, h, and f, written two per line, followed by a blank line. Each number uses at most ten characters. Print one of six fixed sentences describing the limits of hares and foxes.

The judge limits are:

| Item | Value |
| --- | --- |
| Cases | about 5000 |
| Numbers per case | 6 |
| Number text length | at most 10 characters |
| Time limit | 5 s |
| Memory limit | 1536 MB |

Every case writes one long sentence, so output dominates the run.

The sample input reads:

```text
2
2 0.500000
0.500000 0.600000
2 3

0.100000 1
2 0.100000
1 1

```

The sample output reads:

```text
Both hares and foxes will overgrow.
Hares will die out while foxes will overgrow.
```

## Idea

Find the dominant part of a recurrence, like spotting the largest term as it outgrows the rest. Both populations obey the same second-order linear recurrence (each term is a fixed combination of two earlier terms). Its characteristic roots (solutions of the associated quadratic) set the long-term behavior. From each starting value, the program computes that root's weight and picks the dominant active one. Each case costs a fixed number of float operations, whatever the year count. Simulating year by year would cost O(years), could overflow, and still never reach a limit. Takeaway: solve the quadratic once, then read off each limit.

## Why It Works

1. The update equations are `h(next) = a*h - b*f` and `f(next) = c*f + d*h`.
2. With `p = a + c` and `q = a*c + b*d`, both populations obey `x(k+2) = p*x(k+1) - q*x(k)`.
3. The roots of `t² - p*t + q = 0` are `L1` and `L2`; the gap is `D = p² - 4q`.
4. The weights are `A = (x1 - L2*x0) / (L1 - L2)` and `B = (L1*x0 - x1) / (L1 - L2)`.
5. Then `x(k) = A*L1^k + B*L2^k`, so the largest active magnitude decides the limit.
6. A positive root above 1 gives signed infinity, while a negative or complex dominant root gives no limit.
7. Tolerances of 1e-9 and 1e-7 absorb rounding in magnitudes and weights.

The table defines the terms.

| Term | Meaning |
| --- | --- |
| `traceValue` | p, the sum of a and c |
| `determinant` | q, equal to a*c + b*d |
| `discriminant` | D, equal to p² - 4q |
| `rootGap` | square root of D when D is positive |
| `classifySequence` | maps one population to a limit code |

These five terms set the two limits.

A script evaluated the second sample case.

| Term | Value |
| --- | --- |
| p | 2.1 |
| q | 0.3 |
| D | 3.21 |
| L1 | 1.9458 |
| L2 | 0.1542 |
| hare weight A | -0.5884 |
| fox weight A | 1.0861 |

The hares trend to minus infinity and the foxes to plus infinity. The program prints "Hares will die out while foxes will overgrow."

## Code

**Constants and number readers.** The code defines the six answer strings and scans integers and reals by hand.

```nim
import math

const flushBlockBytes = 1 shl 18
const firstDigitValue = 48
const magnitudeTolerance = 1e-9
const coefficientTolerance = 1e-7
const limitZero = 0
const limitPosInf = 1
const limitNegInf = 2
const limitNoLimit = 3

const answerBalance = "Ecological balance will develop."
const answerHaresDie = "Hares will die out while foxes will overgrow."
const answerHaresOver = "Hares will overgrow while foxes will die out."
const answerBothDie = "Both hares and foxes will die out."
const answerBothOver = "Both hares and foxes will overgrow."
const answerChaos = "Chaos will develop."

proc isSpaceChar(ch: char): bool =
  return ch == ' ' or ch == '\n' or ch == '\r' or ch == '\t'

proc nextIntValue(data: string, i: var int): int =
  while i < data.len and (data[i] < char(firstDigitValue) or data[i] > '9'):
    i += 1
  var value = 0
  while i < data.len and data[i] >= char(firstDigitValue) and data[i] <= '9':
    value = value * 10 + (ord(data[i]) - firstDigitValue)
    i += 1
  return value

proc nextRealValue(data: string, i: var int): float =
  while i < data.len and isSpaceChar(data[i]):
    i += 1
  var signValue = 1.0
  if i < data.len and data[i] == '-':
    signValue = -1.0
    i += 1
  elif i < data.len and data[i] == '+':
    i += 1
  var wholePart = 0.0
  while i < data.len and data[i] >= char(firstDigitValue) and data[i] <= '9':
    wholePart = wholePart * 10.0 + float(ord(data[i]) - firstDigitValue)
    i += 1
  var fractionPart = 0.0
  var placeValue = 1.0
  if i < data.len and data[i] == '.':
    i += 1
    while i < data.len and data[i] >= char(firstDigitValue) and data[i] <= '9':
      placeValue *= 10.0
      fractionPart += float(ord(data[i]) - firstDigitValue) / placeValue
      i += 1
  return signValue * (wholePart + fractionPart)
```

The sign branch keeps negative values intact, and the decimal branch handles optional fractions. Blank lines between cases are treated as spaces. Each scanner walks at most one character per input byte.

**Limit classifier.** This block reads one population's limit from two roots and two weights.

```nim
proc classifySequence(initialValue: float, nextValue: float, traceValue: float,
                      determinant: float, discriminant: float, rootGap: float): int =
  if initialValue == 0.0 and nextValue == 0.0:
    return limitZero
  if discriminant < -magnitudeTolerance:
    if determinant < 1.0 - magnitudeTolerance:
      return limitZero
    return limitNoLimit
  let largeRoot = (traceValue + rootGap) * 0.5
  let smallRoot = (traceValue - rootGap) * 0.5
  let largeMag = abs(largeRoot)
  let smallMag = abs(smallRoot)
  if largeMag < 1.0 - magnitudeTolerance and smallMag < 1.0 - magnitudeTolerance:
    return limitZero
  if discriminant > magnitudeTolerance:
    let rootDifference = largeRoot - smallRoot
    let largeCoeff = (nextValue - smallRoot * initialValue) / rootDifference
    let smallCoeff = (largeRoot * initialValue - nextValue) / rootDifference
    let coeffScale = max(abs(largeCoeff), abs(smallCoeff))
    if coeffScale == 0.0:
      return limitZero
    let largeActive = abs(largeCoeff) > coefficientTolerance * coeffScale
    let smallActive = abs(smallCoeff) > coefficientTolerance * coeffScale
    var chosenMag = -1.0
    var chosenRoot = 0.0
    var chosenCoeff = 0.0
    if largeActive:
      chosenMag = largeMag
      chosenRoot = largeRoot
      chosenCoeff = largeCoeff
    if smallActive:
      if smallMag > chosenMag + magnitudeTolerance or
         (abs(smallMag - chosenMag) <= magnitudeTolerance and smallRoot < chosenRoot):
        chosenMag = smallMag
        chosenRoot = smallRoot
        chosenCoeff = smallCoeff
    if chosenMag < 0.0:
      return limitZero
    if chosenMag < 1.0 - magnitudeTolerance:
      return limitZero
    if abs(chosenMag - 1.0) <= magnitudeTolerance:
      return limitNoLimit
    if chosenRoot > 0.0:
      if chosenCoeff > 0.0:
        return limitPosInf
      return limitNegInf
    return limitNoLimit
  let repeatedRoot = traceValue * 0.5
  let rootMagnitude = abs(repeatedRoot)
  if rootMagnitude < 1.0 - magnitudeTolerance:
    return limitZero
  if abs(rootMagnitude - 1.0) <= magnitudeTolerance:
    if abs(repeatedRoot - 1.0) <= magnitudeTolerance:
      let slope = nextValue - initialValue
      let valueScale = max(abs(initialValue), abs(nextValue))
      if valueScale == 0.0 or abs(slope) <= 1e-9 * valueScale:
        if abs(initialValue) <= 1e-9:
          return limitZero
        return limitNoLimit
      if slope > 0.0:
        return limitPosInf
      return limitNegInf
    return limitNoLimit
  if repeatedRoot > 0.0:
    let growthCoeff = nextValue / repeatedRoot - initialValue
    let valueScale = max(abs(initialValue), abs(nextValue / repeatedRoot))
    if valueScale == 0.0 or abs(growthCoeff) <= 1e-9 * valueScale:
      if initialValue > 0.0:
        return limitPosInf
      if initialValue < 0.0:
        return limitNegInf
      return limitZero
    if growthCoeff > 0.0:
      return limitPosInf
    return limitNegInf
  return limitNoLimit
```

Distinct roots take the first branch, and a repeated root takes the second. The tie rule prefers a negative root, so oscillation wins. Every path runs in constant time.

**Case answer.** The block combines the two population limits into one sentence.

```nim
proc answerForCase(coeffA: float, coeffB: float, coeffC: float, coeffD: float,
                   initialHares: float, initialFoxes: float): string =
  let traceValue = coeffA + coeffC
  let determinant = coeffA * coeffC + coeffB * coeffD
  let discriminant = traceValue * traceValue - 4.0 * determinant
  var rootGap = 0.0
  if discriminant > 0.0:
    rootGap = sqrt(discriminant)
  let haresNext = coeffA * initialHares - coeffB * initialFoxes
  let foxesNext = coeffC * initialFoxes + coeffD * initialHares
  let hareLimit = classifySequence(initialHares, haresNext, traceValue,
                                   determinant, discriminant, rootGap)
  let foxLimit = classifySequence(initialFoxes, foxesNext, traceValue,
                                  determinant, discriminant, rootGap)
  if hareLimit == limitZero and foxLimit == limitZero:
    return answerBalance
  if hareLimit == limitPosInf and foxLimit == limitPosInf:
    return answerBothOver
  if hareLimit == limitNegInf and foxLimit == limitNegInf:
    return answerBothDie
  if hareLimit == limitNegInf and foxLimit == limitPosInf:
    return answerHaresDie
  if hareLimit == limitPosInf and foxLimit == limitNegInf:
    return answerHaresOver
  return answerChaos
```

The square root is skipped when the discriminant is negative. Each case classifies two populations in one pass. Unmatched limit pairs return the chaos sentence.

**Driver.** The main loop reads once and writes in blocks.

```nim
var inputData = ""
var inputLine: string = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var i = 0
let caseCount = nextIntValue(inputData, i)
var outputBuffer = ""

for j in 0 ..< caseCount:
  let coeffA = nextRealValue(inputData, i)
  let coeffB = nextRealValue(inputData, i)
  let coeffC = nextRealValue(inputData, i)
  let coeffD = nextRealValue(inputData, i)
  let initialHares = nextRealValue(inputData, i)
  let initialFoxes = nextRealValue(inputData, i)
  outputBuffer.add answerForCase(coeffA, coeffB, coeffC, coeffD, initialHares, initialFoxes)
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

if outputBuffer.len > 0:
  stdout.write outputBuffer
  outputBuffer.setLen 0
```

The loop runs exactly `caseCount` times. A 256 KiB block bounds output memory. Flushing in blocks avoids one write per sentence.

## Complexity

| Phase | Time | Space |
| --- | --- | --- |
| Read and parse case | O(input bytes) | O(input bytes) |
| Classify two sequences | O(1) | O(1) |
| Write answer | O(1) per case | one block |

Parsing and writing dominate the run.

Each case costs a fixed number of float operations.

| Measure | Bound |
| --- | --- |
| Total time | O(N) for N cases |
| Input space | O(total input bytes) |
| Output space | under the 256 KiB flush block |

A naive program simulates many years per case. That costs O(N * years) and can overflow before the limit appears.
