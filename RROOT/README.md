<https://www.spoj.com/problems/RROOT/>

## Problem

Pick `b` and `c` uniformly from a square centered at the origin. Report the chance that `x² + 2bx + c = 0` has real roots.

Input starts with test count T. Each of the next T lines holds one integer side S. Output one probability per line, rounded to six decimal places.

| item | bound |
|---|---|
| test count T | 1 to 24 |
| square side S | 1 to 1000000 |
| coordinate range | -S/2 to S/2 |
| judge limit | 300 ms, 1536 MB |

Real roots require `b² >= c`, so only the area below a parabola inside the square matters.

Sample input:

```
1
8
```

Sample output:

```
0.833333
```

## Idea

Slice the square like a loaf of bread, then measure the slice below the parabola `c = b²` and divide by the whole loaf.

The algorithm is analytic area integration in closed form, at O(1) cost per test. A grid count over the square would need millions of samples and still miss six decimals. Take the area ratio directly.

## Why It Works

1. The discriminant of `x² + 2bx + c` is `4(b² - c)`.
2. Real roots hold exactly when `b² >= c`.
3. The square has area `(2h)² = 4h²` with `h = S/2`.
4. The bad region has height `h - b²` for `|b| <= u` and zero elsewhere.
5. The cutoff `u` is the smaller of `h` and `sqrt(h)`.
6. Dividing bad area by total area, then subtracting from one, gives the answer.

| term | meaning |
|---|---|
| `halfSide` | half of S, the coordinate bound |
| `realRootsProbability` | fraction of the square with real roots |
| `sqrt(halfSide)` | cutoff where `b²` reaches the top edge |

For S = 8, a script evaluated the bad area as `32/3`. The square area is 64, so the bad fraction is `1/6` and the answer is `5/6 = 0.833333`.

Guard the small case: when `halfSide <= 1`, every vertical slice stays inside the square, so the other formula applies.

## Code

**Input and scanning.** One string holds all input, and the hand scanner reads T and each side.

```nim
import math
import strutils

const flushBlockBytes = 1 shl 17

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
```

Each number is built from its digits in order.
The scanner skips all spacing and line breaks.

**Buffered output.** A single buffer collects all answer lines.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The buffer flushes in large blocks.
This keeps writes off the hot path.

**Area formula.** Each side is converted to a probability with one branch.

```nim
let caseCount = nextInt(inputData, scanPos)
var caseIndex = 1
while caseIndex <= caseCount:
  let sideLength = float64(nextInt(inputData, scanPos))
  let halfSide = sideLength / 2.0
  var realRootsProbability: float64
  if halfSide <= 1.0:
    realRootsProbability = 0.5 + halfSide / 6.0
  else:
    realRootsProbability = 1.0 - 1.0 / (3.0 * sqrt(halfSide))
  appendOutput(formatFloat(realRootsProbability, ffDecimal, 6))
  outputBuffer.add '\n'
  caseIndex += 1
stdout.write outputBuffer
outputBuffer.setLen 0
```

The branch selects the correct cutoff.
`formatFloat` fixes six decimal places.
The final write empties the buffer once.

## Complexity

Each test does a constant amount of arithmetic.

| phase | time | space |
|---|---|---|
| input read | one pass over T sides | one input string |
| area formula | O(1) per test | constant |
| output | one formatted line per test | block buffer |

| measure | Big O |
|---|---|
| time | O(T) |
| space | O(T) for input text |

A grid count would spend O(S²) work per test to approximate the same area.

Take the area ratio in closed form and print it directly.
