# CVXPOLY — Convex Polygons (SPOJ)

<https://www.spoj.com/problems/CVXPOLY/>

## Problem

Count every subset of at least three points whose points all sit on the boundary of their convex hull. Report the count modulo 1234567, once per test case.

Input starts with the test count. Each case gives the point count, then one pair of integer coordinates per point. No three points are collinear and no two points coincide. Coordinates can be negative. Output one count per case.

| Item | Bound |
|---|---|
| Test cases | up to 100 in set 1, 50 in set 2 |
| Points per case | 3 to 100 |
| Coordinate magnitude | up to 10000 |
| Judge limit | 1913 ms, 1536 MB |

The point count sets the cost, since each point can serve as the lowest vertex.

Sample input:

```
2
4
0 0
2 0
2 2
0 2
6
0 0
2 0
2 2
0 2
1 -1
1 3
```

The first case is a square; the second adds two outside points.

Sample output:

```
5
42
```

The square gives four triangles and one square.

## Idea

Give every polygon one home by naming its lowest point, like filing each shape under its bottom corner. Once that corner is fixed, the remaining points above it must form a chain that always turns left.

The algorithm is a dynamic program over pairs of points in angular order around each pivot. Each state counts convex chains ending at an ordered pair, and a new point extends a chain when the turn is left. Trying every subset and rebuilding its hull costs exponential time; this shared-chain count reuses work across all subsets. Each pivot costs a cubic scan, and all pivots finish quickly for a hundred points.

## Why It Works

1. Every convex polygon has one lowest point, using height first and then horizontal position to break ties.
2. All other vertices of that polygon lie above the pivot, so their angles from it span less than a half turn.
3. Walking those vertices left to right by angle gives a chain, and a convex polygon makes every turn on it a left turn.
4. A chain ending at pair (i, j) can extend to k exactly when the turn from i to j to k is left.
5. Each convex polygon has one lowest point and one final chain edge, so the sum over all chains counts it once.

| Term | Meaning |
|---|---|
| `pivot` | lowest vertex of the polygon being counted |
| `upperPoints` | later points sorted by angle around the pivot |
| `chainCounts` | number of convex chains ending at an ordered pair |
| `turn` | cross product deciding a left turn |

The terms above are the only state the program keeps.

A trace for the square in the sample:

```
pivot (0,0): angles (2,0), (2,2), (0,2) give counts 1, 1, 1
turn (2,0)->(2,2)->(0,2) is left, adding one quadrilateral
pivot (2,0): one triangle
pivot (0,2): no later pair
total 5
```

The total matches the first sample answer.

## Code

**Input, scanner, and output.** Coordinates may be negative, so the scanner accepts a minus sign.

```nim
const flushBlockBytes = 1 shl 17
const polygonModulus = 1234567

type
  PlanePoint = object
    pointX: int64
    pointY: int64

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-':
    pos += 1
  var negative = false
  if pos < data.len and data[pos] == '-':
    negative = true
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  if negative:
    return -value
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The sign is consumed before the digits.
Each result line waits in the buffer.

**Ordering helpers.** Position order picks the pivot; cross products give angular order.

```nim
proc pointBefore(first: PlanePoint, second: PlanePoint): bool =
  if first.pointY != second.pointY:
    return first.pointY < second.pointY
  return first.pointX < second.pointX

proc sortPointsByPosition(points: var seq[PlanePoint]) =
  for index in 1 .. points.len - 1:
    let carried = points[index]
    var prior = index - 1
    while prior >= 0 and pointBefore(carried, points[prior]):
      points[prior + 1] = points[prior]
      prior -= 1
    points[prior + 1] = carried

proc angleBefore(pivot: PlanePoint, first: PlanePoint, second: PlanePoint): bool =
  let firstX = first.pointX - pivot.pointX
  let firstY = first.pointY - pivot.pointY
  let secondX = second.pointX - pivot.pointX
  let secondY = second.pointY - pivot.pointY
  let turn = firstX * secondY - firstY * secondX
  return turn > 0

proc sortPointsByAngle(pivot: PlanePoint, points: var seq[PlanePoint]) =
  for index in 1 .. points.len - 1:
    let carried = points[index]
    var prior = index - 1
    while prior >= 0 and angleBefore(pivot, carried, points[prior]):
      points[prior + 1] = points[prior]
      prior -= 1
    points[prior + 1] = carried
```

Insertion sort keeps the code small.
The cross product avoids floating point angles.

**Chain dynamic program.** One pivot at a time, every convex chain is counted.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let pointCount = nextInt(inputData, scanPos)
  var points = newSeq[PlanePoint](pointCount)
  for pointIndex in 0 .. pointCount - 1:
    points[pointIndex].pointX = int64(nextInt(inputData, scanPos))
    points[pointIndex].pointY = int64(nextInt(inputData, scanPos))
  sortPointsByPosition(points)
  var convexCount: int64 = 0
  for pivotIndex in 0 .. pointCount - 1:
    let pivot = points[pivotIndex]
    var upperPoints = newSeq[PlanePoint]()
    for laterIndex in pivotIndex + 1 .. pointCount - 1:
      upperPoints.add points[laterIndex]
    sortPointsByAngle(pivot, upperPoints)
    let upperCount = upperPoints.len
    if upperCount < 2:
      continue
    var chainCounts = newSeq[int](upperCount * upperCount)
    for lastIndex in 0 .. upperCount - 1:
      for nextIndex in 0 .. lastIndex - 1:
        let nextToLast = upperPoints[nextIndex]
        let target = upperPoints[lastIndex]
        let countIndex = nextIndex * upperCount + lastIndex
        chainCounts[countIndex] = (chainCounts[countIndex] + 1) mod polygonModulus
        for earlierIndex in 0 .. nextIndex - 1:
          let earlier = upperPoints[earlierIndex]
          let incomingX = nextToLast.pointX - earlier.pointX
          let incomingY = nextToLast.pointY - earlier.pointY
          let outgoingX = target.pointX - nextToLast.pointX
          let outgoingY = target.pointY - nextToLast.pointY
          let turn = incomingX * outgoingY - incomingY * outgoingX
          if turn > 0:
            let sourceIndex = earlierIndex * upperCount + nextIndex
            chainCounts[countIndex] = (chainCounts[countIndex] + chainCounts[sourceIndex]) mod polygonModulus
    for firstIndex in 0 .. upperCount - 1:
      for secondIndex in firstIndex + 1 .. upperCount - 1:
        convexCount = (convexCount + int64(chainCounts[firstIndex * upperCount + secondIndex])) mod int64(polygonModulus)
  appendOutput($convexCount & "\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

Each chain state is reduced modulo the required modulus.
A left turn extends a chain; a right turn rejects it.
The final sum is printed once per case.

## Complexity

The triple loop over chain endpoints dominates each pivot.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over coordinates | one input string |
| Angle sorting | one insertion sort per pivot | one ordered list |
| Chain counting | a triple loop over upper points | one pair table |
| Output | one write per block | block buffer |

The phase table shows the pair table is the only large structure.

| Measure | Big O |
|---|---|
| Time | O(n^4) over all pivots |
| Space | O(n^2) for one pivot |

Enumerating every subset and taking its hull costs exponential time, while shared chain states reduce the work to a polynomial bound.
