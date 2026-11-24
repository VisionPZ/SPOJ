## Problem

Pedestrians stand at different points on one side of a street. At the green light each walks a straight line at constant speed to the far side. You choose a starting point, a start delay, an angle, and a speed at most `v`, then cross. Count the most pedestrians you can meet at the same place and time while both are in the street. Print one maximum per test case.

| Quantity | Bound |
| --- | --- |
| Test cases | 100 |
| Pedestrians per case | 10000 |
| Street width | 1 to 100 m |
| Speed limit | 1 to 10000 m/s |
| Angle step | 1/60 degree, from -5000 to 5000 |
| Time limit | 17000 ms |

The work must scale to a group of 10000 people sharing one crossing time.

## Idea

Split people by crossing time. Within one group your crossing time equals theirs, so a start point and a far-side point hit a person exactly when those two points straddle that person's segment. Sweep the start point and keep far-side counts in a lazy segment tree. Small cases additionally enumerate delayed strategies by solving four linear equations per candidate hit set.

One person costs two range updates and one range maximum query in the sweep. The delayed pass costs a fixed polynomial in the small-group size.

## Why It Works

A person starts at `x` and ends at `p = x + tan(a) * w` at time `t`.

Your path from start `s` to far-side point `q` crosses theirs exactly when `(s - x) * (q - p) <= 0`, and `s` never equals `x`.

The speed limit caps horizontal travel: `D = sqrt((v * t)^2 - w^2)`, so `q` lies between `s - D` and `s + D`.

For a start in a gap between two neighboring people, the reachable far-side points form one interval. Moving a person from the right set to the left set adds one to cells below its far-side point and subtracts one from cells above it.

A delayed strategy has four unknowns: start point `s`, far-side time `B`, delay `A`, and `m = A * q - s * B`.

A collision with person `j` becomes the linear equation `t_j * s + x_j * B - far_j * A + m = x_j * t_j`.

Four such equations determine a candidate strategy, and intersections with fixed-delay or fixed-time planes cover the remaining optima.

The sample has width 20 and speed cap 2, so the two people with crossing time 10 can only be met at the far edge, giving 2.

## Code

```nim
{.passC: "-O3".}
{.optimization: speed.}
{.push checks: off.}
{.push overflowChecks: off.}
{.push rangeChecks: off.}
{.push boundChecks: off.}
{.push stackTrace: off.}

import algorithm
import math

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const infinityValue = 1e100
const equalFarSideEpsilon = 1e-11
const smallGroupLimit = 12
const radiansPerMinute = 3.14159265358979323846 / 10800.0
const missingValue = -1000000000
const maximumCrossingTime = 10000
const validEpsilon = 1e-7
const solveEpsilon = 1e-10
```

The pragmas disable runtime checks in the release build. Constants name the scanner base, the flush size, and the geometric tolerances.

```nim
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9') and data[position] != '-':
    position += 1
  var sign = 1
  if position < data.len and data[position] == '-':
    sign = -1
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int(data[position]) - firstDigitValue
    position += 1
  return value * sign

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The input loop reads the whole stream once. The scanner walks by index and keeps the minus sign. The output buffer flushes every 256 KiB.

```nim
var treeMax: seq[int] = @[]
var treeLazy: seq[int] = @[]
var treeSize = 0

proc applyTree(node, delta: int) =
  treeMax[node] += delta
  treeLazy[node] += delta

proc pushTree(node: int) =
  if treeLazy[node] != 0 and node < treeSize:
    applyTree(node * 2, treeLazy[node])
    applyTree(node * 2 + 1, treeLazy[node])
    treeLazy[node] = 0

proc addTree(node, low, high, fromIndex, toIndex, delta: int) =
  if fromIndex <= low and high <= toIndex:
    applyTree(node, delta)
    return
  pushTree(node)
  let middle = (low + high) div 2
  if fromIndex <= middle: addTree(node * 2, low, middle, fromIndex, toIndex, delta)
  if toIndex > middle: addTree(node * 2 + 1, middle + 1, high, fromIndex, toIndex, delta)
  treeMax[node] = max(treeMax[node * 2], treeMax[node * 2 + 1])

proc queryTree(node, low, high, fromIndex, toIndex: int): int =
  if fromIndex <= low and high <= toIndex: return treeMax[node]
  pushTree(node)
  let middle = (low + high) div 2
  var bestValue = missingValue
  if fromIndex <= middle: bestValue = max(bestValue, queryTree(node * 2, low, middle, fromIndex, toIndex))
  if toIndex > middle: bestValue = max(bestValue, queryTree(node * 2 + 1, middle + 1, high, fromIndex, toIndex))
  return bestValue
```

The tree covers one point cell and one open interval cell per distinct far-side value. Updates and queries cost a logarithmic number of steps.

```nim
proc solveGroup(width, maxSpeed, crossingTime: int, raws: seq[RawPedestrian]): int =
  let speedTime = int64(maxSpeed) * int64(crossingTime)
  if speedTime < int64(width): return 0
  let widthSquared = int64(width) * int64(width)
  let displacement = sqrt(float(speedTime * speedTime - widthSquared))
```

This guard drops groups the speed limit cannot reach. The displacement is the largest horizontal travel at that crossing time.

```nim
proc solveLinearSystem(rows: seq[LinearRow]): seq[float] =
  let variableCount = 4
  var matrix = newSeq[LinearRow](rows.len)
  for rowIndex in 0 ..< rows.len:
    matrix[rowIndex] = rows[rowIndex]
  for column in 0 ..< variableCount:
    var pivotRow = -1
    for rowIndex in column ..< matrix.len:
      if abs(matrix[rowIndex][column]) > solveEpsilon:
        pivotRow = rowIndex
        break
    if pivotRow == -1: return @[]
```

Gaussian elimination solves the four-by-four systems used by the delayed pass. A zero pivot means the candidate set is degenerate and is skipped.

```nim
  if peopleCount <= smallGroupLimit:
    let delayed = delayedSolve(streetWidth, speedLimit, allPeople)
    if delayed > best: best = delayed
```

The main driver buckets people by crossing time, runs the fast sweep on every bucket, and adds the delayed pass only for small cases. The answer is the best of both.

## Complexity

Reading and scanning cost O(total integers) time and O(input bytes) space.

One group costs O(n log n) to sort and O(n log n) to sweep, with O(n) tree space.

The delayed pass enumerates subsets up to size four and costs O(n^4) candidates times O(n) verification for a small group.

Total time is O(N log n) for large groups plus the small-case pass. Total extra space is O(n) beyond the input buffer.
