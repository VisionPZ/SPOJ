# MUJGEO — Geometry (SPOJ)
<https://www.spoj.com/problems/MUJGEO/>

## Problem

Two triangles sit on a common side AC, and their other sides BC and AD run parallel. Given the angles at A and B of triangle ABC and the lengths BC and AD, find the area of the circle whose diameter is CD. Point E is the centre of that circle, so the required circle passes through C and D.

The input holds one line with four real numbers: angles BAC and ABC in degrees, then the lengths BC and AD. Print one real number, the circle area. An answer counts as correct when its absolute error stays below 1e-6.

The bounds and judge limit are:

| Constraint | Value |
| --- | --- |
| Angles and sides | double precision reals |
| Test cases | one per file |
| Judge limit | 1000 ms, 1536 MB |

The error bound drives the choice of double arithmetic and ten printed decimals.

The sample input and its output follow byte for byte.

```
10 30 40 50
```

```
19311.6239189261
```

## Idea

Picture two triangular plates hinged along edge AC. The far corners C and D lie on a circle sized by the span CD, like a compass opened to half that span. Work out AC from the first triangle, then find CD from the second triangle.

The law of sines gives AC from angle A, angle B, and side BC. Because BC and AD are parallel, angle CAD equals angle ACB, which is 180 minus A minus B. The law of cosines on triangle ACD then gives CD squared. The area is pi times CD squared over four. Each step is constant time, so one case needs a few arithmetic operations.

## Why It Works

1. Triangle ABC has angles A, B, and C = 180 - A - B degrees.
2. The law of sines gives AC = BC times sin(B) over sin(A).
3. Parallel sides BC and AD make angle CAD equal to angle ACB, so its radian value is pi - A - B.
4. The law of cosines gives CD squared as AC squared plus AD squared minus twice their product times cos(CAD).
5. The circle has diameter CD, so its radius is CD over two and its area is pi times CD squared over four.

The main quantities and formulas are:

| Term | Meaning |
| --- | --- |
| `sideAC` | shared side, found by the law of sines |
| `radiansC` | angle CAD in radians, equal to pi - A - B |
| `chordSquared` | CD squared, found by the law of cosines |
| `circleArea` | pi times CD squared over four |

These formulas give the area from the four input numbers alone.

The oracle places A at the origin and C on the x axis, then uses Pythagoras. For the sample it prints these numbers:

```
angle A = 10 deg, angle B = 30 deg, BC = 40, AD = 50
AC = 115.17540966287267
angle CAD = 140 deg
CD squared = 24588.32324663009
area = 19311.6239189261
```

The final line matches the sample output exactly.

## Code

**Imports, constants, and whole-stream input.** The reader stores the stream as one string, and the scanner handles real numbers with an optional exponent.

```nim
import math
import strutils

const flushBlockBytes = 1 shl 17
const circlePi = 3.14159265358979323846

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextDouble(data: string, pos: var int): float =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-' and data[pos] != '+':
    pos += 1
  var signValue = 1.0
  if pos < data.len and (data[pos] == '-' or data[pos] == '+'):
    if data[pos] == '-':
      signValue = -1.0
    pos += 1
  var wholeValue = 0.0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    wholeValue = wholeValue * 10.0 + float(int(data[pos]) - 48)
    pos += 1
  if pos < data.len and data[pos] == '.':
    pos += 1
    var placeValue = 0.1
    while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
      wholeValue = wholeValue + float(int(data[pos]) - 48) * placeValue
      placeValue = placeValue / 10.0
      pos += 1
  if pos < data.len and (data[pos] == 'e' or data[pos] == 'E'):
    pos += 1
    var exponentSign = 1.0
    if pos < data.len and (data[pos] == '-' or data[pos] == '+'):
      if data[pos] == '-':
        exponentSign = -1.0
      pos += 1
    var exponentValue = 0.0
    while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
      exponentValue = exponentValue * 10.0 + float(int(data[pos]) - 48)
      pos += 1
    wholeValue = wholeValue * pow(10.0, exponentSign * exponentValue)
  return signValue * wholeValue

```

`nextDouble` reads a sign, a whole part, a decimal part, and an exponent. It uses `int(data[pos]) - 48` for each digit. One input string keeps the parser independent of line breaks.

**Output buffer.** The writer collects text and flushes whole blocks.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

`appendOutput` writes the buffer once it reaches 131072 bytes. A single answer still goes through the same path.

**Triangle solution and final write.** The program reads four values and applies the two laws.

```nim
let angleAtA = nextDouble(inputData, scanPos)
let angleAtB = nextDouble(inputData, scanPos)
let sideBC = nextDouble(inputData, scanPos)
let sideAD = nextDouble(inputData, scanPos)

let radiansDegree = circlePi / 180.0
let radiansA = angleAtA * radiansDegree
let radiansB = angleAtB * radiansDegree
let radiansC = circlePi - radiansA - radiansB
let sideAC = sideBC * sin(radiansB) / sin(radiansA)
let chordSquared = sideAC * sideAC + sideAD * sideAD - 2.0 * sideAC * sideAD * cos(radiansC)
let circleArea = circlePi * chordSquared / 4.0

appendOutput(formatFloat(circleArea, ffDecimal, 10))
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

`radiansDegree` matches degree-to-radian conversion in one multiply. `sideAC` comes from the law of sines. `chordSquared` uses the law of cosines, and `formatFloat` prints ten decimals.

## Complexity

One case uses a fixed number of reads and arithmetic operations.

| Phase | Time | Space |
| --- | --- | --- |
| Input read | one pass over the stream | one input string |
| Triangle solution | constant time trigonometry | a few reals |
| Output | one formatted line | block buffer |

The input read dominates because the trigonometry never grows with the data.

| Measure | Big O |
| --- | --- |
| Time | O(1) |
| Space | O(n) for the input string |

A coordinate search over possible shapes would add work without improving accuracy. The closed formulas finish in a few operations.
