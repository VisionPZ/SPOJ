## Problem

Each case gives one side length and the centroid's perpendicular distance to each of the three sides.
The centroid is the point where the three medians meet, and the orthocenter is the point where the three heights meet.
Print the triangle's area and the distance from the orthocenter to the centroid.
Write both values with three digits after the decimal point.

The judge sets these bounds:

| Item | Value |
| --- | --- |
| Cases | about 1000 |
| Time | 1000 ms |
| Memory | 1536 MB |
| Source | 50000 B |

The input holds four numbers per case, and the output holds two.

## Idea

The centroid sits one third of the way up every height, so each height is three times its given distance.
That fact gives the area, the two missing sides, and the orthocenter distance in one fixed sequence.
Each case costs a constant number of arithmetic steps.

## Why It Works

The centroid divides every median in a 2:1 ratio.
Its distance to a side is one third of that side's height.
The same area comes from any side used as a base.
Euler's relation links the circumcenter, the centroid, and the orthocenter.

Each line below gives one term of the derivation.

| Term | Value |
| --- | --- |
| Height on side a | ha = 3 * da |
| Area | S = a * ha / 2 = 1.5 * a * da |
| Side b | b = 2 * S / hb = a * da / db |
| Side c | c = 2 * S / hc = a * da / dc |
| Circumradius | R = a * b * c / (4 * S) |
| Euler relation | OH^2 = 9 * R^2 - (a^2 + b^2 + c^2) |
| Centroid distance | GH = (2 / 3) * OH |

The program clamps OH^2 at zero before it takes the square root.

The second sample case shows every term with numbers.

| Step | Value |
| --- | --- |
| a | 657.8256599140 |
| da, db, dc | 151.6154399062, 213.5392629932, 139.4878846649 |
| ha, hb, hc | 454.846320, 640.617789, 418.463654 |
| S | 149604.790214 |
| b, c | 467.064115, 715.019280 |
| R | 367.112838 |
| OH^2 | 50810.467708 |
| OH | 225.411774 |
| GH | 150.274516 |

Rounding to three decimals gives 149604.790 150.275.

## Code

```nim
import strutils, math

const flushBlockBytes = 1 shl 16

proc readAllInput(): string =
  var currentLine = ""
  while readLine(stdin, currentLine):
    result.add currentLine
    result.add '\n'

proc nextInteger(inputData: string, i: var int): int =
  while i < inputData.len and inputData[i] <= ' ':
    inc i
  var value = 0
  while i < inputData.len and inputData[i] >= '0' and inputData[i] <= '9':
    value = value * 10 + (ord(inputData[i]) - 48)
    inc i
  return value

proc nextDecimal(inputData: string, i: var int): float =
  while i < inputData.len and inputData[i] <= ' ':
    inc i
  var sign = 1.0
  if i < inputData.len and inputData[i] == '-':
    sign = -1.0
    inc i
  elif i < inputData.len and inputData[i] == '+':
    inc i
  var significand = 0.0
  var decimalDigits = 0
  while i < inputData.len and inputData[i] >= '0' and inputData[i] <= '9':
    significand = significand * 10.0 + float(ord(inputData[i]) - 48)
    inc i
  if i < inputData.len and inputData[i] == '.':
    inc i
    while i < inputData.len and inputData[i] >= '0' and inputData[i] <= '9':
      significand = significand * 10.0 + float(ord(inputData[i]) - 48)
      inc decimalDigits
      inc i
  var scale = 1.0
  var j = 0
  while j < decimalDigits:
    scale = scale * 10.0
    inc j
  result = sign * (significand / scale)
  if i < inputData.len and (inputData[i] == 'e' or inputData[i] == 'E'):
    inc i
    var exponentSign = 1
    if i < inputData.len and inputData[i] == '-':
      exponentSign = -1
      inc i
    elif i < inputData.len and inputData[i] == '+':
      inc i
    var exponentValue = 0
    while i < inputData.len and inputData[i] >= '0' and inputData[i] <= '9':
      exponentValue = exponentValue * 10 + (ord(inputData[i]) - 48)
      inc i
    var exponentScale = 1.0
    j = 0
    while j < exponentValue:
      exponentScale = exponentScale * 10.0
      inc j
    if exponentSign > 0:
      result = result * exponentScale
    else:
      result = result / exponentScale
```

The reader loop ends at the stream boundary, so a blank line cannot break the scan.
Building one significand before the single division avoids the two-rounding error of adding whole and fractional parts.
The scanner touches each input byte once.

```nim
proc main() =
  let inputData = readAllInput()
  var i = 0
  let caseCount = nextInteger(inputData, i)
  var outputBuffer = ""
  var j = 0
  while j < caseCount:
    let sideLength = nextDecimal(inputData, i)
    let distToSideA = nextDecimal(inputData, i)
    let distToSideB = nextDecimal(inputData, i)
    let distToSideC = nextDecimal(inputData, i)
    let triangleArea = 1.5 * sideLength * distToSideA
    let otherSideB = sideLength * distToSideA / distToSideB
    let otherSideC = sideLength * distToSideA / distToSideC
    let circumRadius = sideLength * otherSideB * otherSideC / (4.0 * triangleArea)
    var eulerSquared = 9.0 * circumRadius * circumRadius - (sideLength * sideLength + otherSideB * otherSideB + otherSideC * otherSideC)
    if eulerSquared < 0.0:
      eulerSquared = 0.0
    let centroidToOrthocenter = (2.0 / 3.0) * sqrt(eulerSquared)
    outputBuffer.add formatFloat(triangleArea, ffDecimal, 3)
    outputBuffer.add ' '
    outputBuffer.add formatFloat(centroidToOrthocenter, ffDecimal, 3)
    outputBuffer.add '\n'
    if outputBuffer.len >= flushBlockBytes:
      stdout.write outputBuffer
      outputBuffer.setLen 0
    inc j
  stdout.write outputBuffer

main()
```

The main loop runs exactly caseCount times, and caseCount is the first integer in the buffer.
Clamping eulerSquared at zero avoids a square root of a negative number.
One buffer collects every line and flushes after 64 KiB, so stream writes stay rare.
Each case costs a fixed number of operations.

## Complexity

Reading uses O(m) time for m input characters and stores them in one buffer.
The formula pass uses O(1) time and space per case.
Writing uses O(n) time for n output lines and flushes in blocks.

Total time is O(m + n), and total space is O(m).
Reading and writing each value separately would add one stream call per number.
