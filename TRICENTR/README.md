# TRICENTR — Triangle From Centroid (SPOJ)

<https://www.spoj.com/problems/TRICENTR/>

## Problem

A surveyor knows one side of a triangular plot and the centroid's perpendicular distance to each of the three sides. She needs the plot's area and the gap between its orthocenter and centroid.

Input starts with the case count `n`, about 1000. Each following line holds four floating values: side length `a`, then the centroid distances `da`, `db`, and `dc` to sides `a`, `b`, and `c`. Output `n` lines, each with the area and the centroid-to-orthocenter distance formatted to three decimals.

The judge sets these bounds.

| Item | Value |
| --- | --- |
| Test cases | about 1000 |
| Side and distances | floating point values |
| Time limit | 1000 ms |
| Source limit | 50000 B |
| Memory limit | 1536 MB |

The fixed four-number layout keeps each case at constant cost.

The sample input and output follow verbatim.

```
2
3.0 0.8660254038 0.8660254038 0.8660254038
657.8256599140 151.6154399062 213.5392629932 139.4878846649
```

```
3.897 0.000
149604.790 150.275
```

## Idea

Triple each given distance to recover a full height, then follow one fixed formula chain. Think of the centroid as a balance point sitting one third of the way up each height.

The centroid divides every median in a two-to-one ratio, so its distance to a side is one third of that side's height. The program multiplies by three, computes the area, derives the two missing sides, and applies Euler's relation. Each case costs a fixed number of arithmetic steps.

A coordinate geometry solution would solve a system of equations per case. The direct chain finishes in a handful of operations.

A fixed formula chain turns geometry into plain arithmetic.

## Why It Works

Five facts justify the chain.

1. The centroid divides every median two to one. Its perpendicular distance to a side equals one third of that side's height, so `ha = 3·da`, `hb = 3·db`, and `hc = 3·dc`.
2. Any side works as a base. The area is `S = a·ha / 2 = 1.5·a·da`.
3. The same area from another base gives the missing sides: `b = 2·S / hb = a·da / db` and `c = a·da / dc`.
4. The circumradius is `R = a·b·c / (4·S)`. Euler's relation then gives the orthocenter distance: `OH^2 = 9·R^2 - (a^2 + b^2 + c^2)`.
5. The centroid lies two thirds of the way from the orthocenter toward the circumcenter, so `GH = (2/3)·OH`.

The table lists every term of the derivation.

| Term | Value |
| --- | --- |
| `ha`, `hb`, `hc` | 3·da, 3·db, 3·dc |
| `triangleArea` | 1.5·a·da |
| `otherSideB`, `otherSideC` | a·da/db, a·da/dc |
| `circumRadius` | a·b·c/(4·triangleArea) |
| `eulerSquared` | 9·R^2 - (a^2 + b^2 + c^2) |
| `centroidToOrthocenter` | (2/3)·sqrt(eulerSquared) |

The program clamps `eulerSquared` at zero before the square root. An equilateral input can push that value slightly negative through rounding.

The second sample case shows every term with visible numbers.

| Step | Value |
| --- | --- |
| `a` | 657.8256599140 |
| `da`, `db`, `dc` | 151.6154399062, 213.5392629932, 139.4878846649 |
| `ha`, `hb`, `hc` | 454.846320, 640.617789, 418.463654 |
| `triangleArea` | 149604.790214 |
| `otherSideB`, `otherSideC` | 467.064115, 715.019280 |
| `circumRadius` | 367.112838 |
| `eulerSquared` | 50810.467708 |
| `centroidToOrthocenter` | 150.274516 |

Rounding to three decimals gives `149604.790 150.275`, the sample output.

## Code

**Input reader.** The reader accepts integers, signs, decimals, and exponent notation from one buffer.

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

The reader loop ends at the stream boundary, so blank lines cannot break the scan. Building one significand before the single division avoids two-rounding error. The scanner touches each input byte once.

**Formula and output.** The main procedure applies the formula chain and formats the answers.

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

The loop runs exactly `caseCount` times. Clamping `eulerSquared` avoids a square root of a negative number. One buffer flushes after 64 KiB, so stream writes stay rare.

## Complexity

Reading and output scale with text size, while the formula stays fixed.

| Phase | Time | Space |
| --- | --- | --- |
| Input read | O(input bytes) | one input string |
| Formula per case | O(1) | constant |
| Output per case | O(1) | one flush block |

Total work is linear in the input and output text.

| Measure | Big O |
| --- | --- |
| Time | O(input bytes + n) |
| Space | O(input bytes) |

Solving a coordinate system for each triangle costs far more than the constant formula chain.
