# CHOTU — Faridi and Yadav (SPOJ)

<https://www.spoj.com/problems/CHOTU/>

## Problem

Two scientists sit equally far from a center point, one west and one east. A robot carries each stone from one scientist to a student inside a rectangle, then on to the other scientist. Find the largest separation between the scientists that lets every stone arrive with equal weight.

Input starts with the case count t. Each of the next t lines holds two integers X and Y, the rectangle half-width and half-height.

Output the separation for each case with exactly three digits after the decimal point.

| item | bound |
|---|---|
| cases t | fewer than 1000 |
| half-width X | less than 1000 |
| half-height Y | less than X |
| judge limit | 1000 ms, 1536 MB |

The geometry gives one value per case, so output formatting drives the design.

Sample input:

```
1
4 2
```

Sample output:

```
6.928
```

## Idea

Picture a loop of string around two pins: it traces an ellipse, and every point on it has the same total distance to the pins.

The students stand on such an ellipse inside the rectangle. The ellipse must fit a rectangle of half-width X and half-height Y. Its focus half-distance then tops out at the square root of X squared minus Y squared, so the answer is twice that value. A search over candidate separations replaces this one formula with many steps.

A closed-form calculation costs one square root per case.

## Why It Works

1. Constant decay rate turns equal final weights into equal travel times.
2. Constant speed turns equal travel times into equal path lengths.
3. A robot path runs from one scientist, through a student, to the other scientist.
4. Points with a fixed sum of distances to two foci lie on an ellipse.
5. An ellipse with semi-axes a and b and focus half-distance e obeys a squared equals b squared plus e squared.
6. The rectangle caps a at X and b at Y, which maximizes e at the square root of X squared minus Y squared.
7. The scientists sit at both foci, so their separation is twice e.

| term | meaning |
|---|---|
| `horizontalReach` | rectangle half-width X |
| `verticalReach` | rectangle half-height Y |
| `squaredDifference` | X squared minus Y squared |
| `separation` | distance between the two scientists |
| `scaledValue` | separation multiplied by one thousand |
| `fractionText` | three-digit fractional text |

The table tracks one case from input integers to printed text.

A script-traced run on the sample shows every step:

```
X = 4, Y = 2
X^2 - Y^2 = 4*4 - 2*2 = 12
semi-minor axis = sqrt(12) = 3.4641016
separation = 2 * 3.4641016 = 6.9282032
scaled by 1000 and rounded = 6928
printed = 6.928
```

The trace lands on the sample output after rounding to three places.

The guard on `squaredDifference` keeps the root real if a case breaks the X greater than Y promise. Padding `fractionText` keeps three printed places.

## Code

**Input and scanner.** The reader loads all tokens and parses integer bounds.

```nim
import math

const flushBlockBytes = 1 shl 17
const firstDigitValue = 48
const decimalPlaces = 1000
const doubled = 2

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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The scanner skips line breaks and spaces between cases.
The buffer flushes once after the loop, not once per printed line.
The whole block costs one pass over the input characters.

**Geometry and formatting.** Each case computes the root and prints three places.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let horizontalReach = nextInt(inputData, scanPos)
  let verticalReach = nextInt(inputData, scanPos)
  var squaredDifference = horizontalReach * horizontalReach - verticalReach * verticalReach
  if squaredDifference < 0:
    squaredDifference = 0
  let separation = float(doubled) * sqrt(float(squaredDifference))
  let scaledValue = int64(round(separation * float(decimalPlaces)))
  let wholePart = scaledValue div int64(decimalPlaces)
  let fractionPart = scaledValue mod int64(decimalPlaces)
  var fractionText = $fractionPart
  while fractionText.len < 3:
    fractionText = "0" & fractionText
  appendOutput($wholePart & "." & fractionText)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The loop bound is the case count from the first token.
Integer rounding avoids a float printing routine on the judge compiler.
The padding loop runs at most twice per case.

## Complexity

Each case performs one root and a short formatting step.

| phase | time | space |
|---|---|---|
| input read | one pass over tokens | one input string |
| geometry | one square root per case | a few scalars |
| output | one line per case | block buffer |

All three phases stay constant per case.

| measure | Big O |
|---|---|
| time | O(t) |
| space | O(1) beyond input and output buffers |

A binary search over candidate separations costs many square roots per case.
The closed form finishes each case with one root.
