<https://www.spoj.com/problems/AMR12C/>

## Problem

Ents start at known points with different speeds. Input gives the test count and one position and speed per ent; output the earliest common arrival time with error below `1e-4`.
| item | bound |
|---|---|
| tests | 1 to 10 |
| ents per test | 2 to 50 |
| coordinates | -1000000 to 1000000 |
| speed | 1 to 1000000 |
| judge limit | 1000 ms, 1536 MB |

Every ent travels in a straight line at its own fixed speed.

Sample input:

```
4
3
0 3 3
4 0 4
-3 -4 5
3
0 10 2
0 20 2
0 40 2
3
0 100 15
0 -100 15
8 0 7
3
0 0 1
10000 0 1
5000 8661 1
```

Sample output:

```
1.000000
7.500000
6.666667
5773.751357
```

## Idea

Think of shrinking a target circle around each ent as time grows, like lowering a row of dipping sticks until their tips first touch. The meeting time is the smallest value where all reachability disks overlap. The worst arrival time over a point is a convex function, so a ternary search finds its minimum.

Evaluate that function at one x by another ternary search over y. Each evaluation scans all ents once. Testing time by brute force over a grid instead misses the optimum.

Convexity turns a two-variable search into two one-variable searches.

## Why It Works

1. Ent `i` reaches point `p` within time `T` when its distance is at most `T * speed_i`.
2. The worst arrival time at `p` is the maximum of those distance ratios.
3. A maximum of convex distance functions is convex, so it has one global minimum.
4. For fixed x, the function over y is convex, so ternary search locates its minimum.
5. The function of x after minimizing over y stays convex, so another ternary search works.
6. Seventy steps shrink each search interval far below the required error.

| term | meaning |
|---|---|
| `latestArrival` | worst travel time at one candidate point |
| `bestAtX` | smallest worst time along the vertical line at x |
| `searchSteps` | ternary search iterations per axis |
| `answer` | minimum worst travel time for one test |

For the second sample, x equals twenty-five. The outer ents need `7.5` and the middle ent needs `2.5`, so the worst time is `7.5`.

Distances use floating point and the printed value carries six decimals. The judge allows an error of `1e-4`.

## Code

**Input and helpers.** The scanner accepts negative coordinates and collects all ents.

```nim
import strutils
import math

const flushBlockBytes = 1 shl 17
const searchSteps = 70

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and data[pos] != '-' and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var sign = 1
  if pos < data.len and data[pos] == '-':
    sign = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return sign * value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The minus branch handles southern and western coordinates.
The buffer collects one answer per test.
Bounds come from the ent positions themselves.

**Parsing each test.** Positions, speeds and axis bounds are stored as floats.

```nim
let testCount = nextInt(inputData, scanPos)
for testIndex in 0 .. testCount - 1:
  let entCount = nextInt(inputData, scanPos)
  var entX = newSeq[float](entCount)
  var entY = newSeq[float](entCount)
  var entSpeed = newSeq[float](entCount)
  var minX = 1000000000.0
  var maxX = -1000000000.0
  var minY = 1000000000.0
  var maxY = -1000000000.0
  for entIndex in 0 .. entCount - 1:
    let coordX = nextInt(inputData, scanPos)
    let coordY = nextInt(inputData, scanPos)
    let speed = nextInt(inputData, scanPos)
    entX[entIndex] = float(coordX)
    entY[entIndex] = float(coordY)
    entSpeed[entIndex] = float(speed)
    if entX[entIndex] < minX:
      minX = entX[entIndex]
    if entX[entIndex] > maxX:
      maxX = entX[entIndex]
    if entY[entIndex] < minY:
      minY = entY[entIndex]
    if entY[entIndex] > maxY:
      maxY = entY[entIndex]
```

Positions feed both the speed table and the axis bounds.
Bounds start outside the coordinate range.
No precomputed table is needed.
**Worst arrival.** One scan measures the slowest ent for a candidate point.

```nim
  proc latestArrival(pointX: float, pointY: float): float =
    var worstTime: float = 0.0
    for entIndex in 0 .. entCount - 1:
      let deltaX = pointX - entX[entIndex]
      let deltaY = pointY - entY[entIndex]
      let distance = sqrt(deltaX * deltaX + deltaY * deltaY)
      let travelTime = distance / entSpeed[entIndex]
      if travelTime > worstTime:
        worstTime = travelTime
    return worstTime

  proc bestAtX(pointX: float): float =
    var lowY = minY
    var highY = maxY
    for stepIndex in 0 .. searchSteps - 1:
      let firstY = lowY + (highY - lowY) / 3.0
      let secondY = highY - (highY - lowY) / 3.0
      if latestArrival(pointX, firstY) < latestArrival(pointX, secondY):
        highY = secondY
      else:
        lowY = firstY
    return latestArrival(pointX, (lowY + highY) / 2.0)
```

The distance uses the square root of squared coordinate gaps.
Each speed divides its own distance.
The largest travel time wins.

**Vertical search.** A second ternary search handles the y coordinate.

```nim
  var lowX = minX
  var highX = maxX
  for stepIndex in 0 .. searchSteps - 1:
    let firstX = lowX + (highX - lowX) / 3.0
    let secondX = highX - (highX - lowX) / 3.0
    if bestAtX(firstX) < bestAtX(secondX):
      highX = secondX
    else:
      lowX = firstX
  let answer = bestAtX((lowX + highX) / 2.0)
  appendOutput(formatFloat(answer, ffDecimal, 6))
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The horizontal search calls this function at two probe points.
Both searches use the same step count.
The final value is printed with six decimals.

## Complexity

Each test runs two fixed-depth searches over a small point set.

| phase | time | space |
|---|---|---|
| input read | one pass over all tokens | one input string |
| point scans | search steps squared times ent count | three ent arrays |
| output | one line per test | block buffer |

| measure | Big O |
|---|---|
| time | O(S^2 * N) per test, with S fixed at 70 |
| space | O(N) |

A grid search over the plane would spend far more evaluations for the same accuracy.

Convexity keeps the answer accurate with a fixed number of steps.
