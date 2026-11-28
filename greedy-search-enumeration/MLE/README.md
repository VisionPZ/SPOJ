# MLE — Memory Limit Exceeded (SPOJ)

<https://www.spoj.com/problems/MLE/>

## Problem

Report the squared distance from every point to its nearest neighbor. Coordinates are integers, and no two points in a case coincide.

Input starts with T, then each case gives n and n coordinate pairs.

Output n lines per case, in input order. Line i holds the squared Euclidean distance from point i to the closest other point.

| item | bound |
|---|---|
| test cases T | up to 15 |
| points n | 2 to 100000 |
| coordinates | integers, may be negative |
| judge limit | 5000 ms, 1536 MB |

The point count forces a subquadratic search.

Sample input:

```
2
10
17 41
0 34
24 19
8 28
14 12
45 5
27 31
41 11
42 45
36 27
15
0 0
1 2
2 3
3 2
4 0
8 4
7 4
6 3
6 1
8 0
11 0
12 2
13 1
14 2
15 0
```

Sample output:

```
200
100
149
100
149
52
97
52
360
97
5
2
2
2
5
1
1
2
4
5
5
2
2
2
5
```

## Idea

File points into sorted drawers, each with a label of its rectangle, and skip any drawer whose rectangle cannot beat the best distance found so far. The algorithm is a kd-tree with bounding boxes and branch-and-bound nearest-neighbor queries. Building sorts once and costs O(n log n); each query visits O(log n) nodes on typical data.

Comparing every pair costs O(n^2), which is hopeless at 100000 points. Rectangle bounds discard whole subtrees before any point inside them is touched.

## Why It Works

1. Sorting by x and splitting at the median gives a balanced binary tree.
2. Each node stores the rectangle covering every point in its subtree.
3. The distance from the query point to that rectangle is a lower bound for the subtree.
4. A subtree is skipped when its rectangle bound is at least the current best distance.
5. The nearer child is searched first, so the best distance shrinks early.
6. The search ignores the query point itself and keeps the smallest squared distance.

The answer uses squared distance, so no square root appears.

| term | meaning |
|---|---|
| `IndexedPoint` | coordinate pair plus its input position |
| `boxDistance` | lower bound from the query to a node rectangle |
| `bestDistance` | smallest squared distance found during a query |
| `nodeOriginal` | input index stored at each tree node |

Bounds and point data live in arrays indexed by tree node.

A trace for the first sample point, at (17, 41):

```
candidate (27,31)   200    best = 200
candidate (8,28)    250    keep 200
candidate (0,34)    338    keep 200
candidate (24,19)   533    keep 200
answer              200
```

The trace matches the first line of the sample output.

Squared differences stay inside 64-bit integers even for large coordinates.

## Code

**Input and scanner.** All stdin is read once, with signs allowed.

```nim
import algorithm

const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int64 =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-':
    pos += 1
  var negative = false
  if pos < data.len and data[pos] == '-':
    negative = true
    pos += 1
  var value: int64 = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int64(int(data[pos]) - 48)
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

The scanner handles minus signs. Distances and coordinates use 64-bit values. The buffer flushes in blocks.

**Point order.** Sorting by x prepares the balanced tree.

```nim
type
  IndexedPoint = tuple[x: int64, y: int64, originalIndex: int]

proc comparePoints(left: IndexedPoint, right: IndexedPoint): int =
  if left.x < right.x:
    return -1
  if left.x > right.x:
    return 1
  if left.y < right.y:
    return -1
  if left.y > right.y:
    return 1
  return 0
```

The y coordinate breaks x ties. The input index travels with each point. One sort serves the whole case.

**Tree construction and search.** Rectangles guard every subtree walk.

```nim
var nodePointX = newSeq[int64]()
var nodePointY = newSeq[int64]()
var nodeOriginal = newSeq[int]()
var leftChild = newSeq[int]()
var rightChild = newSeq[int]()
var boxMinX = newSeq[int64]()
var boxMaxX = newSeq[int64]()
var boxMinY = newSeq[int64]()
var boxMaxY = newSeq[int64]()

proc buildNode(leftBound: int, rightBound: int, points: seq[IndexedPoint]): int =
  if leftBound > rightBound:
    return -1
  let middle = (leftBound + rightBound) div 2
  let nodeIndex = middle
  nodePointX[nodeIndex] = points[middle].x
  nodePointY[nodeIndex] = points[middle].y
  nodeOriginal[nodeIndex] = points[middle].originalIndex
  leftChild[nodeIndex] = buildNode(leftBound, middle - 1, points)
  rightChild[nodeIndex] = buildNode(middle + 1, rightBound, points)
  var lowX = nodePointX[nodeIndex]
  var highX = nodePointX[nodeIndex]
  var lowY = nodePointY[nodeIndex]
  var highY = nodePointY[nodeIndex]
  let nearChild = leftChild[nodeIndex]
  let farChild = rightChild[nodeIndex]
  if nearChild >= 0:
    if boxMinX[nearChild] < lowX: lowX = boxMinX[nearChild]
    if boxMaxX[nearChild] > highX: highX = boxMaxX[nearChild]
    if boxMinY[nearChild] < lowY: lowY = boxMinY[nearChild]
    if boxMaxY[nearChild] > highY: highY = boxMaxY[nearChild]
  if farChild >= 0:
    if boxMinX[farChild] < lowX: lowX = boxMinX[farChild]
    if boxMaxX[farChild] > highX: highX = boxMaxX[farChild]
    if boxMinY[farChild] < lowY: lowY = boxMinY[farChild]
    if boxMaxY[farChild] > highY: highY = boxMaxY[farChild]
  boxMinX[nodeIndex] = lowX
  boxMaxX[nodeIndex] = highX
  boxMinY[nodeIndex] = lowY
  boxMaxY[nodeIndex] = highY
  return nodeIndex

proc boxDistance(queryX: int64, queryY: int64, nodeIndex: int): int64 =
  var deltaX: int64 = 0
  if queryX < boxMinX[nodeIndex]:
    deltaX = boxMinX[nodeIndex] - queryX
  elif queryX > boxMaxX[nodeIndex]:
    deltaX = queryX - boxMaxX[nodeIndex]
  var deltaY: int64 = 0
  if queryY < boxMinY[nodeIndex]:
    deltaY = boxMinY[nodeIndex] - queryY
  elif queryY > boxMaxY[nodeIndex]:
    deltaY = queryY - boxMaxY[nodeIndex]
  return deltaX * deltaX + deltaY * deltaY

proc searchNearest(nodeIndex: int, queryX: int64, queryY: int64,
                   selfIndex: int, bestDistance: var int64,
                   bestPoint: var int) =
  if nodeIndex < 0:
    return
  if boxDistance(queryX, queryY, nodeIndex) >= bestDistance:
    return
  let deltaX = queryX - nodePointX[nodeIndex]
  let deltaY = queryY - nodePointY[nodeIndex]
  let candidateDistance = deltaX * deltaX + deltaY * deltaY
  if nodeOriginal[nodeIndex] != selfIndex and candidateDistance < bestDistance:
    bestDistance = candidateDistance
    bestPoint = nodeOriginal[nodeIndex]
  var nearChild = leftChild[nodeIndex]
  var farChild = rightChild[nodeIndex]
  if queryX >= nodePointX[nodeIndex]:
    nearChild = rightChild[nodeIndex]
    farChild = leftChild[nodeIndex]
  searchNearest(nearChild, queryX, queryY, selfIndex, bestDistance, bestPoint)
  searchNearest(farChild, queryX, queryY, selfIndex, bestDistance, bestPoint)
```

The median split keeps the tree shallow. The rectangle bound prunes a whole subtree. The nearer child is visited first.

**Case loop.** Each point queries the tree and writes one line.

```nim
let testCount = int(nextInt(inputData, scanPos))
for testIndex in 0 .. testCount - 1:
  let pointCount = int(nextInt(inputData, scanPos))
  var pointX = newSeq[int64](pointCount)
  var pointY = newSeq[int64](pointCount)
  var points = newSeq[IndexedPoint](pointCount)
  for pointIndex in 0 .. pointCount - 1:
    let xValue = nextInt(inputData, scanPos)
    let yValue = nextInt(inputData, scanPos)
    pointX[pointIndex] = xValue
    pointY[pointIndex] = yValue
    points[pointIndex] = (x: xValue, y: yValue, originalIndex: pointIndex)
  points.sort(comparePoints)
  nodePointX.setLen pointCount
  nodePointY.setLen pointCount
  nodeOriginal.setLen pointCount
  leftChild.setLen pointCount
  rightChild.setLen pointCount
  boxMinX.setLen pointCount
  boxMaxX.setLen pointCount
  boxMinY.setLen pointCount
  boxMaxY.setLen pointCount
  let rootIndex = buildNode(0, pointCount - 1, points)
  for pointIndex in 0 .. pointCount - 1:
    var bestDistance: int64 = high(int64)
    var bestPoint = -1
    searchNearest(rootIndex, pointX[pointIndex], pointY[pointIndex],
                  pointIndex, bestDistance, bestPoint)
    appendOutput($bestDistance)
    outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Coordinates are kept in input order for queries. Each answer is a squared distance. One line is written per point.

## Complexity

A case sorts once, builds once, and queries once per point.

| phase | time | space |
|---|---|---|
| input read | one pass over coordinate tokens | input string |
| sort and build | n log n sort, linear node setup | node arrays |
| nearest queries | O(log n) nodes per point on typical data | recursion depth |
| output | one line per point | block buffer |

Bounding boxes keep the query walk short.

| measure | Big O |
|---|---|
| build | O(n log n) |
| query | O(log n) average per point |
| space | O(n) |

Checking all point pairs costs O(n^2), which cannot handle 100000 points. Tree pruning replaces that scan with a short walk.
