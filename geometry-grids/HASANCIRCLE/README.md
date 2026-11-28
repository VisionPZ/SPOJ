# HASANCIRCLE — Goni the Geometrician (SPOJ)
<https://www.spoj.com/problems/HASANCIRCLE/>

## Problem

A point C and a circle radius are given. Print the area of sector OAB to three decimal places.

Point O is the origin. Point A lies on the positive x axis. Point B lies on the circle at the height of C.
The first line gives x and y of C. The second line gives radius r.
The statement notes that ABCO was a mistake and asks for sector OAB.

| Item | Value |
|---|---|
| Input | two integers, then one radius per case |
| Output | sector area with three decimals |
| Time limit | 1000 ms |
| Memory limit | 1536 MB |

Only the height y and the radius set the sector angle.

The statement gives two sample cases verbatim.

```
1 1
2
```

```
1.047
```

```
3 8
25
```

```
101.790
```

## Idea

Think of slicing a pizza from the center to the rim; the slice size follows the angle at the center.
Point B sits at the same height as C, so the sine of that angle is y over r.
The program takes the arcsine to get radians, then multiplies by half the radius squared.
A numeric sweep along the arc would need many steps per case.

One arcsine and one product give the exact area.

## Why It Works

1. CB is parallel to OA, so B and C share the same y value.
2. The horizontal offset to B is the square root of r squared minus y squared.
3. Sine of angle AOB equals y over r, so arcsine returns that angle in radians.
4. Sector area equals half of r squared times the angle in radians.
5. Fixed formatting rounds the result to three decimal places.
6. The x coordinate moves C along the chord and leaves the angle unchanged.

The main terms and values:

| Term | Meaning |
|---|---|
| `pointY` | height of C, and therefore of B |
| `radius` | distance from O to the circle |
| `heightRatio` | y divided by r |
| `sectorAngle` | angle AOB in radians |
| `formatFloat` | writes three digits after the decimal point |

The sector depends on the height ratio, not on the x input.

A script trace of the first sample case shows the numbers.

```
C: (1, 1), radius: 2
B horizontal offset: 1.732051
angle radians: 0.523599
area rounded: 1.047
```

Half of four times 0.523599 rounds to the sample answer.

## Code

**Read the whole stream.**
```nim
import math, strutils

const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'
```

One string holds the input. Both math modules support the judge compiler.

**Scan decimal integers.**
```nim
proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value
```

Whitespace is skipped before each number. The index always moves forward.

**Buffer output in blocks.**
```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The buffer flushes after 128 KiB. One reset reuses the string.

**Compute each sector area.**
```nim
var scanPos = 0

while true:
  while scanPos < inputData.len and inputData[scanPos] <= ' ':
    scanPos += 1
  if scanPos >= inputData.len:
    break
  let pointX = nextInt(inputData, scanPos)
  discard pointX
  let pointY = nextInt(inputData, scanPos)
  let radius = nextInt(inputData, scanPos)
  let heightRatio = float(pointY) / float(radius)
  let sectorAngle = arcsin(heightRatio)
  let sectorArea = 0.5 * float(radius) * float(radius) * sectorAngle
  appendOutput(formatFloat(sectorArea, ffDecimal, 3))
  outputBuffer.add '\n'
```

The loop ends at the input boundary. The x value is read and discarded.
Arcsine gives radians, and fixed formatting keeps three decimals.

**Emit the final partial block.**
```nim
stdout.write outputBuffer
outputBuffer.setLen 0
```

The last write clears the remaining text. Each case ends with a newline.

## Complexity

Parsing and trigonometry both take constant work per case.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Area | one arcsine per case | constant |
| Output | one write per full block | block buffer |

Each case costs the same regardless of coordinate size.

| Measure | Big O |
|---|---|
| Time | O(input tokens) |
| Space | O(input bytes) |

Sampling the arc with many small triangles would cost far more per case, so the closed form wins.
