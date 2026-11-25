# BOXLINGS — Boxlings (SPOJ)

<https://www.spoj.com/problems/BOXLINGS/>

## Problem

Rectangles float on a plane together with tiny points. Count the points that lie inside or on the boundary of at least one rectangle. Overlapping rectangles count once per point, and duplicate points each count separately.

Input gives N rectangles and M points. The next N lines hold x1 y1 x2 y2 for opposite corners. The next M lines hold a b for one point each. Coordinates have absolute value at most 10^9. Output one integer, the covered point count.

| item | bound |
|---|---|
| rectangles N | 1 to 200000 |
| points M | 1 to 200000 |
| coordinate magnitude | at most 10^9 |
| judge limit | 4000 ms, 1536 MB |

Both N and M drive the event count, so the sweep must stay near linearithmic.

The sample input:

```
5 10
-1 -1 2 5
4 -3 5 3
1 2 4 4
5 -6 8 -4
1 -2 8 0
1 4
5 4
2 2
3 1
6 -5
5 -1
3 -3
-1 -2
-1 -1
2 -1
```

The sample output:

```
6
```

## Idea

Sweep a vertical line across the plane, like sliding a curtain over a wall and watching which horizontal strips are in shadow. At each x, the active rectangles are those whose x span contains that x. A segment tree over compressed y coordinates tracks how many active rectangles cover each y. Add events come before queries and remove events come after them, so touching edges count. A per-point scan over all rectangles costs N times M. The sweep costs one logarithmic step per event.

## Why It Works

1. Normalise each rectangle so x1 <= x2 and y1 <= y2, since corners may arrive in any order.
2. A point is covered when some active rectangle contains its y at the point's x.
3. Sorting events by x, then by kind, adds rectangles at x before querying points there and removes them afterwards.
4. Compressing all rectangle y edges and point y values keeps every relevant coordinate in one small sorted list.
5. A lazy segment tree counts active rectangles over y ranges, so a point query reads coverage along one leaf path.

| term | meaning |
|---|---|
| `SweepEvent` | one rectangle add, rectangle remove, or point query |
| `allY` | every rectangle edge y and point y before deduplication |
| `coverage` | active rectangle counts held by segment tree nodes |
| `lazyCount` | pending additions stored at a node |

The table names the structures built during the sweep.

A script trace of the ten sample points:

```
point (1, 4): boxes 1, 3
point (5, 4): none
point (2, 2): boxes 1, 3
point (3, 1): none
point (6, -5): box 4
point (5, -1): boxes 2, 5
point (3, -3): none
point (-1, -2): none
point (-1, -1): box 1
point (2, -1): boxes 1, 5
```

Six points have at least one box, which matches the sample answer.

Boundary points count because add events precede queries and remove events follow them at the same x. Zero-area rectangles still update one compressed y leaf.

## Code

**Input and helpers.** The reader loads all lines, then the solver sorts events and searches compressed coordinates.

```nim
import algorithm

const flushBlockBytes = 1 shl 17
const addEvent = 0
const queryEvent = 1
const removeEvent = 2

type SweepEvent = object
  coord: int
  kind: int
  lowY: int
  highY: int

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-':
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

proc compareInts(left: int, right: int): int =
  if left < right:
    return -1
  if left > right:
    return 1
  return 0

proc compareEvents(left: SweepEvent, right: SweepEvent): int =
  if left.coord < right.coord:
    return -1
  if left.coord > right.coord:
    return 1
  if left.kind < right.kind:
    return -1
  if left.kind > right.kind:
    return 1
  return 0

proc findYIndex(values: openArray[int], target: int): int =
  var low = 0
  var high = values.len - 1
  while low <= high:
    let middle = (low + high) div 2
    if values[middle] == target:
      return middle
    if values[middle] < target:
      low = middle + 1
    else:
      high = middle - 1
  return -1
```

`compareEvents` orders adds before queries before removes at one x.
`findYIndex` maps a raw y value to its compressed leaf.
Both helpers run once per event.

**Reading and compression.** Rectangles are normalised and all y values are collected once.

```nim
let rectangleCount = nextInt(inputData, scanPos)
let pointCount = nextInt(inputData, scanPos)
var boxesXLow = newSeq[int](rectangleCount)
var boxesXHigh = newSeq[int](rectangleCount)
var boxesYLow = newSeq[int](rectangleCount)
var boxesYHigh = newSeq[int](rectangleCount)
var pointsX = newSeq[int](pointCount)
var pointsY = newSeq[int](pointCount)
var allY = newSeq[int]()

for rectangleIndex in 0 .. rectangleCount - 1:
  let firstX = nextInt(inputData, scanPos)
  let firstY = nextInt(inputData, scanPos)
  let secondX = nextInt(inputData, scanPos)
  let secondY = nextInt(inputData, scanPos)
  if firstX <= secondX:
    boxesXLow[rectangleIndex] = firstX
    boxesXHigh[rectangleIndex] = secondX
  else:
    boxesXLow[rectangleIndex] = secondX
    boxesXHigh[rectangleIndex] = firstX
  if firstY <= secondY:
    boxesYLow[rectangleIndex] = firstY
    boxesYHigh[rectangleIndex] = secondY
  else:
    boxesYLow[rectangleIndex] = secondY
    boxesYHigh[rectangleIndex] = firstY
  allY.add boxesYLow[rectangleIndex]
  allY.add boxesYHigh[rectangleIndex]

for pointIndex in 0 .. pointCount - 1:
  pointsX[pointIndex] = nextInt(inputData, scanPos)
  pointsY[pointIndex] = nextInt(inputData, scanPos)
  allY.add pointsY[pointIndex]

allY.sort(compareInts)
var yValues = newSeq[int]()
for value in allY:
  if yValues.len == 0 or yValues[yValues.len - 1] != value:
    yValues.add value
```

Corner order never affects containment after normalisation.
`allY` holds at most 2N + M values before deduplication.
The deduplicated list becomes the segment tree leaf set.

**Segment tree.** Range updates mark active rectangles, and a point query walks one path.

```nim
var coverage = newSeq[int](yValues.len * 4 + 5)
var lazyCount = newSeq[int](yValues.len * 4 + 5)

proc pushDown(node: int, low: int, high: int) =
  if lazyCount[node] == 0 or low == high:
    return
  let leftNode = node * 2
  let rightNode = node * 2 + 1
  coverage[leftNode] = coverage[leftNode] + lazyCount[node]
  lazyCount[leftNode] = lazyCount[leftNode] + lazyCount[node]
  coverage[rightNode] = coverage[rightNode] + lazyCount[node]
  lazyCount[rightNode] = lazyCount[rightNode] + lazyCount[node]
  lazyCount[node] = 0

proc changeRange(node: int, low: int, high: int, fromY: int, toY: int,
                 delta: int) =
  if fromY <= low and high <= toY:
    coverage[node] = coverage[node] + delta
    lazyCount[node] = lazyCount[node] + delta
    return
  pushDown(node, low, high)
  let middle = (low + high) div 2
  if fromY <= middle:
    changeRange(node * 2, low, middle, fromY, toY, delta)
  if toY > middle:
    changeRange(node * 2 + 1, middle + 1, high, fromY, toY, delta)
  coverage[node] = lazyCount[node] + max(coverage[node * 2],
                                         coverage[node * 2 + 1])

proc coveredAt(node: int, low: int, high: int, target: int): int =
  result = lazyCount[node]
  if low == high:
    return
  let middle = (low + high) div 2
  if target <= middle:
    result += coveredAt(node * 2, low, middle, target)
  else:
    result += coveredAt(node * 2 + 1, middle + 1, high, target)
```

Each update touches O(log K) nodes, where K is the compressed size.
Lazy counts move down only when a partial update needs them.
A point query sums the pending counts along one root-to-leaf path.

**Sweep.** Sorted events drive the tree and the final count.

```nim
var events = newSeq[SweepEvent]()
for rectangleIndex in 0 .. rectangleCount - 1:
  let lowIndex = findYIndex(yValues, boxesYLow[rectangleIndex])
  let highIndex = findYIndex(yValues, boxesYHigh[rectangleIndex])
  events.add SweepEvent(coord: boxesXLow[rectangleIndex], kind: addEvent,
                        lowY: lowIndex, highY: highIndex)
  events.add SweepEvent(coord: boxesXHigh[rectangleIndex], kind: removeEvent,
                        lowY: lowIndex, highY: highIndex)
for pointIndex in 0 .. pointCount - 1:
  events.add SweepEvent(coord: pointsX[pointIndex], kind: queryEvent,
                        lowY: findYIndex(yValues, pointsY[pointIndex]),
                        highY: 0)
events.sort(compareEvents)

var coveredPoints: int64 = 0
for event in events:
  if event.kind == addEvent:
    changeRange(1, 0, yValues.len - 1, event.lowY, event.highY, 1)
  elif event.kind == removeEvent:
    changeRange(1, 0, yValues.len - 1, event.lowY, event.highY, -1)
  else:
    if coveredAt(1, 0, yValues.len - 1, event.lowY) > 0:
      coveredPoints += 1

appendOutput($coveredPoints)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

There are exactly 2N + M events in the sorted list.
A positive coverage at query time means at least one rectangle contains the point.
The answer is written once after the sweep.

## Complexity

The sweep processes one event per rectangle edge and one per point.

| phase | time | space |
|---|---|---|
| input read | four integers per rectangle, two per point | one input string |
| coordinate sort | sort of at most 2N + M y values | compressed y list |
| event sweep | one tree operation per event | two tree arrays |
| output | one line | block buffer |

The event sweep dominates the constant work.

| measure | Big O |
|---|---|
| time | O((N + M) log(N + M)) |
| space | O(N + M) |

K is at most 2N + M, so each tree step touches O(log K) nodes.

Testing every point against every rectangle costs N times M operations. The sweep replaces that product with a sort and one logarithmic update or query per event.
