## Problem

Each year the hares and foxes change by two linear equations. The four coefficients and the starting values are given. Decide the long-term limit of each population and print one of six fixed sentences. The input holds about 5000 cases. Each number uses at most ten characters.

The limits are modest for this task.

| Item | Value |
| --- | --- |
| Cases | about 5000 |
| Numbers per case | 6 |
| Number length | at most 10 characters |
| Time limit | 5 s |
| Memory limit | 1536 MB |

Every case writes one line, so the output path carries most of the work.

## Idea

Both populations follow the same second-order recurrence. The two characteristic roots of that recurrence give each limit from the two starting values. Pick the root with the largest active magnitude. A positive root gives a signed infinity, and a negative or complex root gives no limit.

Each case costs a fixed number of float operations, whatever the number of years.

## Why It Works

Let `p` be `a + c` and let `q` be `a * c + b * d`. Both populations obey `x[k+2] = p * x[k+1] - q * x[k]`. The roots of `t*t - p*t + q = 0` are `L1` and `L2`. The discriminant is `D = p*p - 4*q`.

The starting values set the two weights:

`A = (x1 - L2 * x0) / (L1 - L2)`

`B = (L1 * x0 - x1) / (L1 - L2)`

Then `x[k] = A * L1^k + B * L2^k`.

- Both magnitudes below 1 make the sequence tend to zero.
- The largest active root above 1 gives the sign of its weight as the limit.
- A negative dominant root flips sign each step, so no limit exists.
- Complex roots with magnitude at least 1 rotate forever, so no limit exists.

The second sample case works as follows.

| Term | Value |
| --- | --- |
| p | 2.1 |
| q | 0.3 |
| D | 3.21 |
| L1 | 1.9458 |
| L2 | 0.1542 |
| h1 | -0.9 |
| f1 | 2.1 |
| A for hares | -0.5884 |
| A for foxes | 1.0861 |

The hares weight is negative and the foxes weight is positive. The answer is "Hares will die out while foxes will overgrow."

## Code

The scanner reads the whole input once. It skips spaces and the blank line after each case.

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

The scanner walks at most one character per input byte. The sign branch keeps negative values intact.

This block reads the limit of one sequence from the two roots and the two weights.

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

There is one branch for distinct roots and one for a repeated root. The tie rule picks a negative root so oscillation wins. The block runs in constant time.

This block combines the two limits into one sentence.

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

The loop bound is the fixed case count. The square root is skipped when the discriminant is negative. Each case does one classification pass.

The main loop reads once and writes in blocks.

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

The loop runs exactly `caseCount` times. A 256 KiB block bounds the output memory. Flushing in blocks avoids one write per line.

## Complexity

Reading and parsing take time linear in the input size. Classification takes constant time per case. Output takes time linear in the number of cases.

Total time is `O(N)` for `N` cases. Input memory is linear in the input size. Output memory stays under the 256 KiB flush block.

A naive program simulates many years for every case. That costs `O(N * years)` and can overflow.
