# TETRA — Sphere in a Tetrahedron (SPOJ)

<https://www.spoj.com/problems/TETRA/>

## Problem

The input gives the six edge lengths of a tetrahedron in a fixed order. For each one, compute the radius of a sphere tangent to all four faces.

Input: `N` cases. Each line holds six integers: `WX WY WZ XY XZ YZ`, the edges of tetrahedron `WXYZ` in that order. Output: one radius per line, with exactly four digits after the decimal point.

The bounds from the statement:

| Item | Bound |
|---|---|
| Test cases `N` | at most 30 |
| Edge lengths | integers up to 1000 |
| Output | four decimal digits |
| Judge limit | 1000 ms, 1536 MB |

Each case is a fixed-size calculation, so the work stays tiny even at the limit.

The sample case:

```
2
1 1 1 1 1 1
1000 999 998 5 5 6
```

```
0.2041
1.4189
```

## Idea

Cut the tetrahedron into four pyramids whose tips meet at the sphere's center. Each pyramid has the same height, the radius `r`, and one face as its base. Their volumes add to the whole volume, so `V = (1/3) × S × r`, where `S` is the total surface area. Rearranging gives `r = 3V / S`. Heron's formula gives each triangular face's area from its three edges, and an expanded Cayley–Menger (edge-based volume) formula gives `V` from all six edges. Cost per case: about 60 floating-point operations, with no allocation.

Placing the corners in 3D and solving for the center would need a coordinate system and a small linear system. The volume formula needs neither.

## Why It Works

Three facts carry the solution.

1. The sphere center lies the same distance `r` from every face. Each pyramid has volume `area × r / 3`. Adding the four gives `V = S × r / 3`, hence `r = 3V / S`.
2. Heron's formula gives a triangle's area from its three sides. With `s = (a + b + c) / 2`, area is `sqrt(s × (s - a) × (s - b) × (s - c))`.
3. The Cayley–Menger determinant returns the squared volume of a tetrahedron from its six edge lengths. `tetraVolume` uses the expanded form of that determinant, divides by 288 after the square root, and returns `sqrt(termSum) / 12`.

The quantities the program computes:

| Term | Meaning |
|---|---|
| `triangleArea(a, b, c)` | area of one face by Heron's formula |
| `surface` | sum of the four face areas |
| `tetraVolume` | volume from the six edges |
| `inradius` | `3 × volume / surface` |

The four faces and the six edges of the input cover every part of the formulas.

A script-traced example for the regular tetrahedron with every edge equal to 1:

```
face area by Heron (1, 1, 1): 0.4330127
surface S = 4 * 0.4330127 = 1.7320508
volume  V = 0.1178511
r = 3V / S = 0.2041241 -> 0.2041
```

The result matches the first sample line. The `max(0.0, ...)` calls in both square roots guard against tiny negative values from floating-point rounding.

`fixedString` scales by 10000, adds 0.5, and truncates, which rounds the radius to four digits.

## Code

**Squares and face areas.** Each face is a triangle with three known edges.

```nim
import math

const flushBlockBytes = 1 shl 17
const decimalPlaces = 4

proc square(value: float): float =
  return value * value

proc triangleArea(firstEdge, secondEdge, thirdEdge: float): float =
  var halfPerimeter = (firstEdge + secondEdge + thirdEdge) / 2.0
  var areaSquare = halfPerimeter * (halfPerimeter - firstEdge) *
                   (halfPerimeter - secondEdge) * (halfPerimeter - thirdEdge)
  return sqrt(max(0.0, areaSquare))
```

`square` names the repeated multiplication, so the volume formula stays readable. `triangleArea` runs in constant time and clamps a negative product to zero before the square root.

**Volume.** The expanded Cayley–Menger determinant, written with named squared edges.

```nim
proc tetraVolume(edgeWX, edgeWY, edgeWZ, edgeXY, edgeXZ, edgeYZ: float): float =
  var squareWX = square(edgeWX)
  var squareWY = square(edgeWY)
  var squareWZ = square(edgeWZ)
  var squareXY = square(edgeXY)
  var squareXZ = square(edgeXZ)
  var squareYZ = square(edgeYZ)
  var termSum = 4.0 * squareWX * squareWY * squareWZ -
    squareWX * square(squareWY + squareWZ - squareYZ) -
    squareWY * square(squareWX + squareWZ - squareXZ) -
    squareWZ * square(squareWX + squareWY - squareXY) +
    (squareWY + squareWZ - squareYZ) * (squareWX + squareWZ - squareXZ) *
    (squareWX + squareWY - squareXY)
  return sqrt(max(0.0, termSum)) / 12.0
```

Each name matches one edge from the input line. The clamp before `sqrt` makes degenerate or nearly flat cases safe. The block costs a fixed number of multiplications.

**Rounding.** One helper prints four digits after the point.

```nim
proc fixedString(value: float, places: int): string =
  var scale = 1
  for _ in 1 .. places: scale = scale * 10
  var absoluteValue = if value < 0.0: -value else: value
  var rounded = int64(absoluteValue * float(scale) + 0.5)
  var wholePart = rounded div int64(scale)
  var fractionPart = rounded mod int64(scale)
  var fractionText = $fractionPart
  while fractionText.len < places: fractionText = "0" & fractionText
  var text: string
  if value < 0.0 and rounded > 0: text.add "-"
  text.add $wholePart
  text.add "."
  text.add fractionText
  return text
```

`decimalPlaces = 4` fixes the scale loop and the padding loop. Adding 0.5 before truncation gives the required rounding. Radii are positive here, but the sign branch keeps the helper general.

**Input.** Digits are scanned by index, and each value is positive.

```nim
proc nextInt(inputData: string, i: var int): int =
  while i < inputData.len and inputData[i] <= ' ': i = i + 1
  var value = 0
  while i < inputData.len and inputData[i] >= '0' and inputData[i] <= '9':
    value = value * 10 + int(inputData[i]) - 48
    i = i + 1
  return value
```

The whole stream is read into one buffer before this scanner runs. The `var` parameter keeps the scan position between calls, and no sign branch is needed.

**Driver.** Six integers per case, four face areas, one volume, one radius.

```nim
var inputData: string
var line: string
while readLine(stdin, line):
  inputData.add line
  inputData.add "\n"
var i = 0
var caseCount = nextInt(inputData, i)
var outputBuffer: string
for _ in 1 .. caseCount:
  var edgeWX = float(nextInt(inputData, i))
  var edgeWY = float(nextInt(inputData, i))
  var edgeWZ = float(nextInt(inputData, i))
  var edgeXY = float(nextInt(inputData, i))
  var edgeXZ = float(nextInt(inputData, i))
  var edgeYZ = float(nextInt(inputData, i))
  var surface = triangleArea(edgeWX, edgeWY, edgeXY) +
                triangleArea(edgeWX, edgeWZ, edgeXZ) +
                triangleArea(edgeWY, edgeWZ, edgeYZ) +
                triangleArea(edgeXY, edgeXZ, edgeYZ)
  var volume = tetraVolume(edgeWX, edgeWY, edgeWZ, edgeXY, edgeXZ, edgeYZ)
  var inradius = if surface > 0.0: 3.0 * volume / surface else: 0.0
  outputBuffer.add fixedString(inradius, decimalPlaces)
  outputBuffer.add "\n"
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
stdout.write outputBuffer
```

The four `triangleArea` calls cover the four faces, paired by their shared vertices. The guard on `surface` avoids a divide by zero. Output blocks use `setLen 0` to reuse one allocation, and the final write covers the tail.

## Complexity

Every case does the same fixed calculation.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Four face areas | four constant-time Heron calls | O(1) |
| Volume | one expanded determinant | O(1) |
| Output | one write per 128 KiB block | 128 KiB |
| Total, 30 cases | about 30 × 60 floating-point operations | O(1) |

At most 30 cases run, so the whole program finishes in a few milliseconds.

| Measure | Big O |
|---|---|
| Time | O(1) per case, O(N) for N cases |
| Space | O(1) per case, plus input and output buffers |

A coordinate solver also runs in O(1), but it builds a 3D embedding and solves four plane equations. The determinant formula reaches the radius directly from the six input numbers.
