# FOREST2 — Forest (SPOJ)

<https://www.spoj.com/problems/FOREST2/>

## Problem

A map shows circular tree trunks around the origin. Find the farthest visible tree and report its closest distance to the origin.

Input holds several cases. Each case starts with `n`, then `n` lines of integers `x y r`. A line containing zero ends the input. Output holds one line per case with the distance rounded to three decimals.

The bounds from the statement:

| item | bound |
|---|---|
| trees per case | 1 to 1000 |
| center coordinates | -10000 to 10000 |
| radius | 1 to 1000 |
| judge limit | 1100 ms, 1536 MB |

Circles never overlap and never contain the origin, so every tree has a clear direction range.

Sample input:

```
3
10 10 11
1 1 1
-20 -10 20
5
1 2 2
-2 1 1
2 -1 1
-1 -2 2
10000 -10000 1000
0
```

This figure is the sample input copied from the statement.

Sample output:

```
3.142
1.236
```

This figure is the sample output, one distance per case.

## Idea

Treat each tree as a shadow cast on a compass; a tree stays visible when its shadow has a sliver no nearer shadow covers.

Sweep trees from near to far and test each tree before adding its shadow to the union.

Each test scans the current union once, so a case costs O(n^2). Testing every ray direction over a fine grid does far more work. The union sweep keeps only direction intervals that matter.

## Why It Works

1. A circle at distance `d` with radius `r` covers directions within `arcsin(r / d)` of its center bearing.
2. A ray from the origin meets a circle exactly when its direction lies in that circle's direction interval.
3. Processing trees by increasing center distance puts every possible blocker before the tree it blocks.
4. A tree is visible when its direction interval has a part outside the union of earlier intervals.
5. The reported distance is `d - r`, the length from the origin to the closest border point.

The main terms:

| term | meaning |
|---|---|
| `centerDistance` | distance from the origin to the circle center |
| `halfAngle` | angular half width of the circle as seen from the origin |
| `coveredAngles` | sorted merged intervals of directions blocked by nearer trees |
| `nearestDistance` | center distance minus radius, the value printed for a visible tree |

The table names the values that drive the sweep.

A script computed these values for the second sample case:

```
A (1,2,2)   d=2.236 half=63.435 interval=[0.000,126.870] nearest=0.236
B (-2,1,1)  d=2.236 half=26.565 interval=[126.870,180.000] nearest=1.236
C (2,-1,1)  d=2.236 half=26.565 interval=[306.870,360.000] nearest=1.236
D (-1,-2,2) d=2.236 half=63.435 interval=[180.000,306.870] nearest=0.236
E (10000,-10000,1000) d=14142.136 interval=[310.945,319.055] nearest=13142.136
```

Intervals A through D tile the full circle, so E is hidden and B or C gives the answer 1.236.

Angles use double precision, and `angleEpsilon` absorbs rounding at interval boundaries.

Touching shadows from different trees still block a ray, while a shadow that meets only the edge of a tree leaves its interior visible.

Integer scaling with `decimalPlaces` rounds the answer without a format library.

## Code

**Input and scanner.** The reader loads all lines, and the scanner accepts negative coordinates.

```nim
import math

const flushBlockBytes = 1 shl 17
const decimalPlaces = 1000
const fullTurn = 2.0 * PI
const angleEpsilon = 1e-12

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
```

The minus branch handles coordinates such as -20.
One buffer holds every output line.
Parsing advances one index per token.

**Interval helpers.** These two routines test coverage and merge a new direction interval.

```nim
proc intervalCovers(intervals: seq[AngularInterval], firstAngle, lastAngle: float): bool =
  for interval in intervals:
    if interval.firstAngle <= firstAngle + angleEpsilon and
       interval.lastAngle >= lastAngle - angleEpsilon:
      return true
  return false

proc insertInterval(intervals: var seq[AngularInterval], firstAngle, lastAngle: float) =
  var merged = newSeq[AngularInterval](intervals.len + 1)
  var mergedCount = 0
  var currentFirst = firstAngle
  var currentLast = lastAngle
  var placed = false
  for existing in intervals:
    if existing.lastAngle < currentFirst - angleEpsilon:
      merged[mergedCount] = existing
      mergedCount += 1
    elif currentLast < existing.firstAngle - angleEpsilon:
      if not placed:
        merged[mergedCount] = (currentFirst, currentLast)
        mergedCount += 1
        placed = true
      merged[mergedCount] = existing
      mergedCount += 1
    else:
      if existing.firstAngle < currentFirst:
        currentFirst = existing.firstAngle
      if existing.lastAngle > currentLast:
        currentLast = existing.lastAngle
  if not placed:
    merged[mergedCount] = (currentFirst, currentLast)
    mergedCount += 1
  merged.setLen(mergedCount)
  intervals = merged
```

Coverage needs one merged interval that spans the whole query.
Insertion keeps the list sorted and free of overlaps.
Each call scans at most the current number of trees.

**Sweep and output.** Trees are sorted by distance, then tested and added one by one.

```nim
while true:
  let treeCount = nextInt(inputData, scanPos)
  if treeCount == 0:
    break
  var trees = newSeq[TreeInfo](treeCount)
  for treeIndex in 0 .. treeCount - 1:
    let centerX = float(nextInt(inputData, scanPos))
    let centerY = float(nextInt(inputData, scanPos))
    let radius = float(nextInt(inputData, scanPos))
    let distanceSquared = centerX * centerX + centerY * centerY
    let centerDistance = sqrt(distanceSquared)
    var rayAngle = arctan2(centerY, centerX)
    if rayAngle < 0.0:
      rayAngle += fullTurn
    let halfAngle = arcsin(radius / centerDistance)
    trees[treeIndex].centerDistance = centerDistance
    trees[treeIndex].rayAngle = rayAngle
    trees[treeIndex].halfAngle = halfAngle
    trees[treeIndex].nearestDistance = centerDistance - radius

  var sortIndex = 1
  while sortIndex < treeCount:
    let currentTree = trees[sortIndex]
    var previousIndex = sortIndex - 1
    while previousIndex >= 0 and trees[previousIndex].centerDistance > currentTree.centerDistance:
      trees[previousIndex + 1] = trees[previousIndex]
      previousIndex -= 1
    trees[previousIndex + 1] = currentTree
    sortIndex += 1

  var coveredAngles: seq[AngularInterval] = @[]
  var bestDistance = 0.0
  for treeIndex in 0 .. treeCount - 1:
    let currentTree = trees[treeIndex]
    var firstAngle = currentTree.rayAngle - currentTree.halfAngle
    if firstAngle < 0.0:
      firstAngle += fullTurn
    let lastAngle = firstAngle + 2.0 * currentTree.halfAngle
    var visible = false
    if lastAngle <= fullTurn:
      visible = not intervalCovers(coveredAngles, firstAngle, lastAngle)
    else:
      visible = (not intervalCovers(coveredAngles, firstAngle, fullTurn)) or
                (not intervalCovers(coveredAngles, 0.0, lastAngle - fullTurn))
    if visible and currentTree.nearestDistance > bestDistance:
      bestDistance = currentTree.nearestDistance
    if lastAngle <= fullTurn:
      insertInterval(coveredAngles, firstAngle, lastAngle)
    else:
      insertInterval(coveredAngles, firstAngle, fullTurn)
      insertInterval(coveredAngles, 0.0, lastAngle - fullTurn)

  let scaledDistance = int64(bestDistance * float(decimalPlaces) + 0.5)
  var fractionDigits = $(scaledDistance mod decimalPlaces)
  while fractionDigits.len < 3:
    fractionDigits = "0" & fractionDigits
  appendOutput($(scaledDistance div decimalPlaces) & "." & fractionDigits)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The insertion sort uses center distance as its key.
Wrapped intervals are split at angle zero before testing and insertion.
The scaled integer produces exactly three fractional digits.

## Complexity

Each case sorts the trees and scans a shrinking list of direction intervals.

The cost breakdown by phase:

| phase | time | space |
|---|---|---|
| input read | one pass over the case data | one input string |
| sort by distance | O(n^2) insertion sort | array of n trees |
| interval sweep | O(n^2) coverage tests and insertions | up to 2n intervals |
| output | one line per case | block buffer |

The interval sweep dominates the input and output work.

The overall asymptotic bounds:

| measure | Big O |
|---|---|
| time | O(n^2) per case |
| space | O(n) |

Testing a fine grid of ray directions costs far more than one pass over merged intervals. The sweep keeps only the visible frontier and answers every case from it.
