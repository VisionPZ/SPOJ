# MOZGEOL — Jenny the GeoLover (SPOJ)

<https://www.spoj.com/problems/MOZGEOL/>

## Problem

Given the shortest side `X` and the smallest angle `Y` of a right triangle, report its hypotenuse. Print six digits after the decimal point for every case.

The first input line holds `T`, the number of cases. Each case gives two real numbers `X` and `Y`, in centimetres and degrees. `X` is opposite `Y`, since both are the smallest parts of the triangle.

| item | bound |
|---|---|
| test cases `T` | at most 10 |
| short side `X` | real number |
| small angle `Y` | real number in degrees |
| judge limit | 500 ms, 1536 MB |

The on-page sample collapses its line breaks. The layout below follows the stated input and output contract.

Sample input:

```
3
7 30
15 30
10 18
```

Sample output:

```
Case 1: 14.000000
Case 2: 30.000000
Case 3: 32.360680
```

The third case divides 10 by the sine of 18 degrees.

## Idea

The short side is the shadow of the hypotenuse, like a ladder's height against its length. Divide the short side by the sine of the small angle to recover the long side. Sine needs radians, so multiply the angle by pi and divide by 180. One sine call and one division settle a case. Building the missing leg first with tangent would need extra work for the same answer.

## Why It Works

1. The smallest angle of a right triangle is opposite the shortest side.
2. Sine equals opposite side over hypotenuse, so `X / sin(Y)` is the hypotenuse.
3. Angles arrive in degrees, while `sin` takes radians.
4. Multiplying by `PI` and dividing by `degreesPerTurn` converts the angle.
5. `formatFloat` rounds the result to six decimal places for output.

| term | meaning |
|---|---|
| `shortSide` | `X`, the shortest side |
| `smallAngle` | `Y`, the smallest angle in degrees |
| `angleRadians` | the same angle measured in radians |
| `hypotenuseLength` | the requested long side |

The generator checks the sample pair `(10, 18)`. It computes `sin(18 degrees) = 0.309017`, then `10 / 0.309017 = 32.360680`. The pair `(7, 30)` gives `sin(30 degrees) = 0.5` and `7 / 0.5 = 14.000000`.

| case | X | Y | hypotenuse |
|---|---|---|---|
| 1 | 7 | 30 | 14.000000 |
| 2 | 15 | 30 | 30.000000 |
| 3 | 10 | 18 | 32.360680 |

The printed values match the sample to the last digit.

## Code

**Input and number scanning.** The reader loads the text, then parses integers and reals by hand.

```nim
import math
import strutils

const flushBlockBytes = 1 shl 17
const degreesPerTurn = 180

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

proc nextFloat(data: string, pos: var int): float =
  while pos < data.len and data[pos] != '.' and data[pos] != '-' and
       (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var signValue = 1.0
  if pos < data.len and data[pos] == '-':
    signValue = -1.0
    pos += 1
  var wholePart = 0.0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    wholePart = wholePart * 10.0 + float(int(data[pos]) - 48)
    pos += 1
  var fractionPart = 0.0
  var scaleValue = 1.0
  if pos < data.len and data[pos] == '.':
    pos += 1
    while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
      scaleValue = scaleValue * 10.0
      fractionPart = fractionPart + float(int(data[pos]) - 48) / scaleValue
      pos += 1
  return signValue * (wholePart + fractionPart)
```

`nextFloat` accepts both whole numbers and decimals.
It skips spaces and line breaks before each value.
The integer case count uses `nextInt`.

**Triangle formula and output.** Each case converts degrees, divides by sine, and formats.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 1 .. caseCount:
  let shortSide = nextFloat(inputData, scanPos)
  let smallAngle = nextFloat(inputData, scanPos)
  let angleRadians = smallAngle * PI / float(degreesPerTurn)
  let hypotenuseLength = shortSide / sin(angleRadians)
  appendOutput("Case " & $caseIndex & ": " & formatFloat(hypotenuseLength, ffDecimal, 6))
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Case numbers start at one.
Six decimals are written even for whole answers.
All lines leave through the shared output buffer.

## Complexity

Each case does a constant amount of arithmetic.

| phase | time | space |
|---|---|---|
| input read | one pass over the text | one input string |
| triangle formula | one sine and one division | constant |
| formatting | six decimals per case | block buffer |
| output | one flush at the end | block buffer |

| measure | Big O |
|---|---|
| time per case | O(1) |
| space per case | O(1) |

Constructing both legs before the hypotenuse would add a tangent and a square root.

The direct sine formula reaches the answer in one step.
