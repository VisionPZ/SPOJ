# STONE — Lifting the Stone (SPOJ)

<https://www.spoj.com/problems/STONE/>

## Problem

Given the vertices of a polygon of uniform height, compute its center of gravity. Print the two coordinates rounded to two decimal places.

Input: `T` cases. Each case starts with `N`, followed by `N` lines of `X Y`, the vertices in order around the polygon. Output: one line per case, two numbers `x y` with exactly two digits after the decimal point.

The bounds from the statement:

| Item | Bound |
|---|---|
| Test cases `T` | about 500 |
| Vertices per polygon `N` | 3 to 1,000,000 |
| Coordinates | \|X\|, \|Y\| ≤ 20,000 |
| Rounding | 0.005 rounds up to 0.01 |
| Judge limit | 5000 ms, 1536 MB |

One polygon can hold a million vertices, so the program must stream them instead of storing them.

The sample case:

```
2
4
5 0
0 5
-5 0
0 -5
4
1 1
11 1
11 11
1 11
```

```
0.00 0.00
6.00 6.00
```

## Idea

A polygon balances at the area-weighted average of its pieces. Cut the polygon into signed triangles, one per edge with the origin as the third corner. Each triangle contributes an area and its own center of mass. The program sums both while reading vertices, then divides once at the end. Cost per vertex: three multiplications and three additions, with only the first and previous vertex kept in memory.

Storing every vertex and triangulating afterward would cost O(N) memory and a second pass. The streaming version keeps O(1) state.

## Why It Works

Three facts carry the formula.

1. The shoelace (surveyor's) formula sums edge crosses: `crossSum = Σ cross_i`. Here `cross_i = x_i × y_{i+1} - x_{i+1} × y_i`. The polygon area is `|crossSum| / 2`. Signed triangles add up correctly even for a dented polygon, since pieces outside the shape cancel.
2. The triangle with corners `(0,0)`, `p_i`, and `p_{i+1}` has its center of mass at `(p_i + p_{i+1}) / 3`. The origin contributes zero to the sum.
3. An area-weighted average divides the sum of area times center by the total area. Each triangle's area is `cross_i / 2`, so the common factor of 2 cancels.

The three sums and the final division:

| Term | Meaning |
|---|---|
| `crossValue` | signed double area of the triangle on one edge |
| `crossSum` | signed double area of the whole polygon |
| `weightedXSum`, `weightedYSum` | `Σ cross_i × (x_i + x_{i+1})` and `Σ cross_i × (y_i + y_{i+1})` |
| `gravityX`, `gravityY` | `weightedXSum / (3 × crossSum)` and likewise for Y |

The signed areas cancel where needed. The result is the center of gravity.

A script-traced example for the diamond `(5,0), (0,5), (-5,0), (0,-5)`:

```
edge (5, 0) -> (0, 5)     cross = 25   xsum += 25*(5+0)   =  125   ysum += 25*(0+5)   =  125
edge (0, 5) -> (-5, 0)    cross = 25   xsum += 25*(0-5)   = -125   ysum += 25*(5+0)   =  125
edge (-5, 0) -> (0, -5)   cross = 25   xsum += 25*(-5+0)  = -125   ysum += 25*(0-5)   = -125
edge (0, -5) -> (5, 0)    cross = 25   xsum += 25*(0+5)   =  125   ysum += 25*(-5+0)  = -125
crossSum = 100   weightedXSum = 0   weightedYSum = 0
gravity = (0 / (3*100), 0 / (3*100)) = (0.00, 0.00)
```

The four triangle centers sit around the origin, and their area weights cancel in pairs. The square sample gives `(6.00, 6.00)` by the same sums.

`fixedString` scales by 100, adds 0.5, and truncates, which implements the required rounding. It adds the minus sign only after rounding, so a tiny negative coordinate prints as `0.00` rather than `-0.00`.

## Code

**Input and signing.** The whole stream goes into one buffer, and the scanner handles the minus sign in coordinates.

```nim
import strutils

const flushBlockBytes = 1 shl 17
const decimalPlaces = 2

proc readAllInput(): string =
  var inputData = ""
  var line: string
  while readLine(stdin, line):
    inputData.add line
    inputData.add "\n"
  return inputData

proc nextInt(inputData: string, i: var int): int =
  while i < inputData.len and inputData[i] <= ' ': i = i + 1
  var negativeValue = inputData[i] == '-'
  if negativeValue: i = i + 1
  var value = 0
  while i < inputData.len and inputData[i] >= '0' and inputData[i] <= '9':
    value = value * 10 + int(inputData[i]) - 48
    i = i + 1
  return if negativeValue: -value else: value
```

The sign branch matters here, since the statement allows negative coordinates. Digit values come from `int(inputData[i]) - 48`, with no parse call and no token object.

**Rounding.** One helper prints a float with a fixed number of digits.

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

Adding 0.5 before truncation is the round-half-up rule from the statement. `decimalPlaces = 2` fixes the loop bound at two, and the padding loop keeps a zero fraction as `00`.

**Driver.** One pass over the vertices keeps two points and three running sums.

```nim
var inputData = readAllInput()
var i = 0
var caseCount = nextInt(inputData, i)
var outputBuffer: string
for _ in 1 .. caseCount:
  var pointCount = nextInt(inputData, i)
  var firstX = nextInt(inputData, i)
  var firstY = nextInt(inputData, i)
  var previousX = firstX
  var previousY = firstY
  var crossSum = 0.0
  var weightedXSum = 0.0
  var weightedYSum = 0.0
  for _ in 1 .. pointCount - 1:
    var currentX = nextInt(inputData, i)
    var currentY = nextInt(inputData, i)
    var crossValue = float(previousX * currentY - currentX * previousY)
    crossSum = crossSum + crossValue
    weightedXSum = weightedXSum + crossValue * float(previousX + currentX)
    weightedYSum = weightedYSum + crossValue * float(previousY + currentY)
    previousX = currentX
    previousY = currentY
  var closingCross = float(previousX * firstY - firstX * previousY)
  crossSum = crossSum + closingCross
  weightedXSum = weightedXSum + closingCross * float(previousX + firstX)
  weightedYSum = weightedYSum + closingCross * float(previousY + firstY)
  var gravityX = weightedXSum / (3.0 * crossSum)
  var gravityY = weightedYSum / (3.0 * crossSum)
  outputBuffer.add fixedString(gravityX, decimalPlaces)
  outputBuffer.add " "
  outputBuffer.add fixedString(gravityY, decimalPlaces)
  outputBuffer.add "\n"
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
stdout.write outputBuffer
```

The inner loop runs `pointCount - 1` times; the closing edge is handled after it, so every edge is counted once. The polygon never collapses to a line, so `crossSum` is never zero. `setLen 0` reuses the output allocation, and the final write covers the tail.

## Complexity

The program reads each coordinate once and does constant work per edge.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| One polygon | O(N) edges with three running sums | O(1) |
| Rounding and write | two fixed strings per case | 128 KiB block |
| Total, 500 cases | O(total vertices) | input bytes plus 128 KiB |

A million-vertex polygon uses four ints and three floats of state, not a million points.

| Measure | Big O |
|---|---|
| Time | O(N) per case, O(total vertices) overall |
| Space | O(1) per case, plus input and output buffers |

Storing vertices and triangulating afterward also costs O(N) time, but it needs O(N) space and a second pass. The shoelace sums need neither.
