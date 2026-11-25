# EMPTY — Empty Cuboids (SPOJ)
<https://www.spoj.com/problems/EMPTY/>

## Problem

A warehouse wants the biggest box from the origin that contains none of the stored marker points inside.
The program prints the far corner of that box.

Read `t` cases. Each case gives `n` points with integer coordinates from 1 to 10^6.
Find the cuboid with largest volume that has one corner at the origin.
Its edges lie on the positive axes, and no given point lies in its interior.
A point on a wall does not count as inside.

Print three positive integers: the far corner coordinates.
Any largest cuboid is accepted.

The judge bounds follow.

| Quantity | Bound |
| --- | --- |
| Test cases `t` | at most 10 |
| Points per case `n` | at most 5000 |
| Each coordinate | 1 to 1000000 |
| Time limit | 7000 ms |
| Memory limit | 1536 MB |

Up to 50000 points per run rules out a search over coordinate triples.

The sample input and expected output follow verbatim.

```
1
4
3 3 300000
2 200000 5
90000 3 2000
2 2 1000
```

```
1000000 200000 1000
```

The far corner is 1000000 200000 1000 for the sample points.

## Idea

Sweep the x edge and keep a segment tree (a tree storing best values over intervals) for the y and z edges.
Each box edge stops at a point or at the coordinate limit, so point x values cover every answer.

For a fixed X, only points with x < X matter.
For each candidate Y, the largest safe Z is the smallest z among those points with y < Y.
That value never grows as Y grows, so inserting a point lowers it over one interval.
A range update changes that interval in O(log² n) steps.

Cost per case is O(n log² n).
Trying every X, Y, Z triple and checking all points costs O(n^4).
Sweep x and let the tree hold the best y*z.

## Why It Works

Four facts prove the method.

1. A point lies inside box (X,Y,Z) when x < X, y < Y, and z < Z.
   Equality is safe because a wall does not count.
2. For fixed X, the safe Z at Y is the smallest z over points with x < X and y < Y.
   It is 10^6 when no such point exists.
3. That value never grows as Y grows.
   Adding point (y,z) lowers it for Y > y only where the old value exceeds z, which is one interval.
4. The tree stores Y times that value at each compressed Y.
   The root therefore holds the best product for the current X.

The values stored by the tree follow.

| Term | Meaning |
| --- | --- |
| `yValues` | sorted unique point y values plus 10^6 |
| `minZ(Y)` | smallest z of a blocking point with smaller y |
| `treeMax` | largest Y*minZ(Y) in a node interval |
| `treeLazy` | pending z value for a whole interval |

The root gives the best Y and Z for the current X.

A script evaluates every candidate x edge for the sample points.

```
| X edge | best Y*Z | chosen Y | chosen Z | volume |
| --- | --- | --- | --- | --- |
| 2 | 1000000000000 | 1000000 | 1000000 | 2000000000000 |
| 3 | 200000000 | 200000 | 1000 | 600000000 |
| 90000 | 200000000 | 200000 | 1000 | 18000000000000 |
| 1000000 | 200000000 | 200000 | 1000 | 200000000000000 |
the last row is largest, so the answer is 1000000 200000 1000
```

The last row is largest, which gives the sample answer.

## Code

**Constants, point type, and scanner.**

```nim
import algorithm

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const maxEdge = 1000000

type
  Point = object
    coordX: int
    coordY: int
    coordZ: int

proc nextInt(data: string, position: var int): int =
  let dataLength = data.len
  while position < dataLength and (data[position] < '0' or data[position] > '9'):
    position += 1
  var value = 0
  while position < dataLength and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int(data[position]) - firstDigitValue
    position += 1
  return value
```

maxEdge is the coordinate limit of 10^6. A Point keeps the three coordinates in named fields. The scanner walks one input buffer by index. Skipping non-digits absorbs blank lines.

**Tree globals and build.**

```nim
var yValues: seq[int]
var treeMax: seq[int64]
var treeArg: seq[int]
var treeLazy: seq[int]

proc applyValue(nodeIndex, rightBound, value: int) =
  treeMax[nodeIndex] = int64(value) * int64(yValues[rightBound])
  treeArg[nodeIndex] = rightBound
  treeLazy[nodeIndex] = value

proc buildTree(nodeIndex, leftBound, rightBound: int) =
  treeLazy[nodeIndex] = -1
  if leftBound == rightBound:
    treeMax[nodeIndex] = int64(maxEdge) * int64(yValues[leftBound])
    treeArg[nodeIndex] = leftBound
    return
  let middle = (leftBound + rightBound) div 2
  buildTree(nodeIndex * 2, leftBound, middle)
  buildTree(nodeIndex * 2 + 1, middle + 1, rightBound)
  if treeMax[nodeIndex * 2 + 1] >= treeMax[nodeIndex * 2]:
    treeMax[nodeIndex] = treeMax[nodeIndex * 2 + 1]
    treeArg[nodeIndex] = treeArg[nodeIndex * 2 + 1]
  else:
    treeMax[nodeIndex] = treeMax[nodeIndex * 2]
    treeArg[nodeIndex] = treeArg[nodeIndex * 2]

proc pushDown(nodeIndex, leftBound, rightBound: int) =
  let pending = treeLazy[nodeIndex]
  if pending != -1:
    let middle = (leftBound + rightBound) div 2
    applyValue(nodeIndex * 2, middle, pending)
    applyValue(nodeIndex * 2 + 1, rightBound, pending)
    treeLazy[nodeIndex] = -1
```

applyValue sets a whole node to one z value. The largest Y in that interval wins the product. buildTree initializes every leaf to the maximum edge. pushDown clears a stale parent value before a partial update.

**Point query and range update.**

```nim
proc valueAt(nodeIndex, leftBound, rightBound, target: int): int =
  if treeLazy[nodeIndex] != -1:
    return treeLazy[nodeIndex]
  if leftBound == rightBound:
    return int(treeMax[nodeIndex] div int64(yValues[leftBound]))
  let middle = (leftBound + rightBound) div 2
  if target <= middle:
    return valueAt(nodeIndex * 2, leftBound, middle, target)
  return valueAt(nodeIndex * 2 + 1, middle + 1, rightBound, target)

proc assignRange(nodeIndex, leftBound, rightBound, queryLeft, queryRight, value: int) =
  if queryLeft <= leftBound and rightBound <= queryRight:
    applyValue(nodeIndex, rightBound, value)
    return
  pushDown(nodeIndex, leftBound, rightBound)
  let middle = (leftBound + rightBound) div 2
  if queryLeft <= middle:
    assignRange(nodeIndex * 2, leftBound, middle, queryLeft, queryRight, value)
  if queryRight > middle:
    assignRange(nodeIndex * 2 + 1, middle + 1, rightBound, queryLeft, queryRight, value)
  if treeMax[nodeIndex * 2 + 1] >= treeMax[nodeIndex * 2]:
    treeMax[nodeIndex] = treeMax[nodeIndex * 2 + 1]
    treeArg[nodeIndex] = treeArg[nodeIndex * 2 + 1]
  else:
    treeMax[nodeIndex] = treeMax[nodeIndex * 2]
    treeArg[nodeIndex] = treeArg[nodeIndex * 2]
```

valueAt descends to one compressed Y. assignRange covers an interval with log n nodes. After the update, each parent keeps the larger child product. The cost is O(log n) per tree operation.

**Insert one point.**

```nim
proc insertPoint(pointY, pointZ: int) =
  let lastIndex = yValues.len - 1
  var low = 0
  var high = lastIndex
  while low < high:
    let middle = (low + high) div 2
    if yValues[middle] < pointY:
      low = middle + 1
    else:
      high = middle
  let firstAffected = low + 1
  if firstAffected > lastIndex:
    return
  if valueAt(1, 0, lastIndex, firstAffected) <= pointZ:
    return
  var leftIndex = firstAffected
  var rightIndex = lastIndex
  while leftIndex < rightIndex:
    let middle = (leftIndex + rightIndex + 1) div 2
    if valueAt(1, 0, lastIndex, middle) > pointZ:
      leftIndex = middle
    else:
      rightIndex = middle - 1
  assignRange(1, 0, lastIndex, firstAffected, leftIndex, pointZ)
```

A binary search finds the first y edge above the point. A second search finds the last edge whose minZ exceeds z. assignRange lowers that whole interval once. Each insertion costs about log² n steps.

**Read the current best.**

```nim
proc considerEdge(edgeX: int, bestVolume: var int64, answerX, answerY, answerZ: var int) =
  let product = treeMax[1]
  let winningIndex = treeArg[1]
  let winningY = yValues[winningIndex]
  let winningZ = valueAt(1, 0, yValues.len - 1, winningIndex)
  let volume = int64(edgeX) * product
  if volume > bestVolume:
    bestVolume = volume
    answerX = edgeX
    answerY = winningY
    answerZ = winningZ
```

considerEdge takes the product and Y index from the root. valueAt recovers the matching Z. One check costs one tree descent.

**Input setup.**

```nim
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var i = 0
let caseCount = nextInt(inputData, i)
var outputBuffer = ""
```

The read loop keeps the whole stream in one buffer. A newline separates neighboring numbers. One output buffer holds all answers.

**Sweep the x edges.**

```nim
var caseIndex = 0
while caseIndex < caseCount:
  let pointCount = nextInt(inputData, i)
  var points = newSeq[Point](pointCount)
  for j in 0..<pointCount:
    points[j].coordX = nextInt(inputData, i)
    points[j].coordY = nextInt(inputData, i)
    points[j].coordZ = nextInt(inputData, i)

  points.sort(proc (left, right: Point): int = left.coordX - right.coordX)

  yValues = @[maxEdge]
  for j in 0..<pointCount:
    yValues.add points[j].coordY
  yValues.sort(proc (left, right: int): int = left - right)
  var yCount = 0
  for j in 0..<yValues.len:
    if j == 0 or yValues[j] != yValues[j - 1]:
      yValues[yCount] = yValues[j]
      yCount += 1
  yValues.setLen yCount

  let lastIndex = yValues.len - 1
  treeMax = newSeq[int64](lastIndex * 4 + 9)
  treeArg = newSeq[int](lastIndex * 4 + 9)
  treeLazy = newSeq[int](lastIndex * 4 + 9)
  buildTree(1, 0, lastIndex)

  var bestVolume: int64 = -1
  var answerX = maxEdge
  var answerY = maxEdge
  var answerZ = maxEdge

  var scanIndex = 0
  while scanIndex < pointCount:
    let edgeX = points[scanIndex].coordX
    considerEdge(edgeX, bestVolume, answerX, answerY, answerZ)
    while scanIndex < pointCount and points[scanIndex].coordX == edgeX:
      insertPoint(points[scanIndex].coordY, points[scanIndex].coordZ)
      scanIndex += 1
  considerEdge(maxEdge, bestVolume, answerX, answerY, answerZ)

  outputBuffer.add $(answerX)
  outputBuffer.add ' '
  outputBuffer.add $(answerY)
  outputBuffer.add ' '
  outputBuffer.add $(answerZ)
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
  caseIndex += 1

stdout.write outputBuffer
outputBuffer.setLen 0
```

Points are sorted by x and grouped into edges. yValues is compressed and the tree is rebuilt per case. Each edge is considered before its points are inserted. The final call handles X = 10^6.

## Complexity

The phases and their costs for one case follow.

| Phase | Time | Space |
| --- | --- | --- |
| Read and sort | O(n log n) | O(n) |
| Build tree | O(n) | O(n) |
| n insertions | O(n log² n) | O(n) |
| Consider edges and write | O(n log n + 1) | one output block |

The tree arrays hold four slots per distinct y value.

The Big O summary follows.

| Measure | Big O |
| --- | --- |
| Time | O(n log² n) per case |
| Space | O(n) per case |

A brute search over X, Y, and Z triples with point checks costs O(n^4) per case.
