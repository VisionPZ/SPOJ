# CCOST — Calculate The Cost (SPOJ)

<https://www.spoj.com/problems/CCOST/>

## Problem

A map lists weighted trees on a plane. For each rectangular plot, report the total weight of trees inside it or on its border. Several trees may share one point, and every tree on that point counts.

The first line holds the test count. Each test gives a tree count, then one line per tree with x, y and weight, then a query count, then one line per plot with lower-left and upper-right corners. Print one total per plot, with no blank lines between tests.

| item | bound |
|---|---|
| tests | up to 10 |
| trees per test | up to 100000 |
| plots per test | up to 50000 |
| coordinates | 0 to 10000000 |
| tree weight | up to 10000 |
| input size | about 15 MB |
| judge limit | 1000 ms, 1536 MB |

The large product of tree count and query count rules out scanning every tree per plot.

Sample input:

```
1
3
1 1 2
2 2 3
3 3 4
2
1 1 1 2
0 0 5 5
```

Sample output:

```
2
9
```

The first plot holds one tree; the second plot holds all three.

## Idea

Sweep a vertical line across the map, like a scanner reading a page one column at a time. A prefix total over y then answers four corner events per plot, and inclusion-exclusion combines them. This is an offline sweep with a Fenwick tree over compressed y coordinates. Sorting costs O((n + R) log n), and each event costs O(log n). Checking every tree for every plot costs O(nR), which is far slower. Sweep once, keep totals over y, then combine four signed events per plot.

## Why It Works

1. Define F(X, Y) as the total weight of trees with x at most X and y at most Y.
2. The weight inside a plot equals F(x2, y2) minus F(x1 - 1, y2) minus F(x2, y1 - 1) plus F(x1 - 1, y1 - 1).
3. Sorting trees by x lets one sweep add each tree exactly once, when the sweep reaches its x.
4. Compressing y to the distinct tree y values keeps the Fenwick tree small and exact.
5. A prefix query up to Y uses the count of compressed y values not greater than Y.

| term | meaning |
|---|---|
| `PointRecord` | one tree with x, y, weight and compressed y slot |
| `QueryEvent` | one signed corner term of a plot |
| `uniqueY` | sorted distinct tree y values |
| `fenwickSum` | total weight over the first few y slots |

Each plot needs four events, and their signs implement inclusion-exclusion.

A trace of the sample trees at y values 1, 2, 3:

| event x | event y | sign | prefix total |
|---|---|---|---|
| 0 | 2 | minus | 0 |
| 1 | 2 | plus | 2 |
| 5 | 5 | plus | 9 |
| 5 | -1 | minus | 0 |

The two plot totals become 2 and 9, matching the sample output.

## Code

**Sorting helpers.** Merge sort orders trees and events, and binary search finds y slots.

```nim
const flushBlockBytes = 1 shl 17

type PointRecord = tuple[x: int, y: int, value: int, yIndex: int]
type QueryEvent = tuple[x: int, yBound: int, sign: int, queryIndex: int]

proc pointComesBefore(left, right: PointRecord): bool = left.x <= right.x
proc eventComesBefore(left, right: QueryEvent): bool = left.x <= right.x
proc valueComesBefore(left, right: int): bool = left <= right

proc mergeSort[T](data: var seq[T], temp: var seq[T], low: int, high: int, comesBefore: proc(left, right: T): bool) =
  if low >= high:
    return
  let mid = (low + high) div 2
  mergeSort(data, temp, low, mid, comesBefore)
  mergeSort(data, temp, mid + 1, high, comesBefore)
  var leftPos = low
  var rightPos = mid + 1
  var writePos = low
  while leftPos <= mid and rightPos <= high:
    if comesBefore(data[leftPos], data[rightPos]):
      temp[writePos] = data[leftPos]
      leftPos += 1
    else:
      temp[writePos] = data[rightPos]
      rightPos += 1
    writePos += 1
  while leftPos <= mid:
    temp[writePos] = data[leftPos]
    leftPos += 1
    writePos += 1
  while rightPos <= high:
    temp[writePos] = data[rightPos]
    rightPos += 1
    writePos += 1
  for indexValue in low .. high:
    data[indexValue] = temp[indexValue]

proc upperBound(values: seq[int], target: int): int =
  var low = 0
  var high = values.len
  while low < high:
    let mid = (low + high) div 2
    if values[mid] <= target:
      low = mid + 1
    else:
      high = mid
  return low
```

One comparator serves each record type.
Binary search turns a y bound into a slot count.
The sort runs in O(n log n) with a scratch sequence.

**Input and tree structure.** The reader loads all numbers, and the Fenwick tree tracks live weights.

```nim
proc fenwickAdd(tree: var seq[int64], index: int, delta: int) =
  var position = index + 1
  while position < tree.len:
    tree[position] += int64(delta)
    position += position and (-position)

proc fenwickSum(tree: seq[int64], index: int): int64 =
  var position = index
  var total: int64 = 0
  while position > 0:
    total += tree[position]
    position -= position and (-position)
  return total

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The tree has one extra slot, so the last compressed y fits.
All numbers are non-negative in this problem.
Answers are written into one block buffer.

**Offline sweep.** Events arrive in x order and collect signed prefix totals.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let treeCount = nextInt(inputData, scanPos)
  var points = newSeq[PointRecord](treeCount)
  var yCoordinates = newSeq[int](treeCount)
  for pointIndex in 0 .. treeCount - 1:
    let treeX = nextInt(inputData, scanPos)
    let treeY = nextInt(inputData, scanPos)
    let treeValue = nextInt(inputData, scanPos)
    points[pointIndex] = (x: treeX, y: treeY, value: treeValue, yIndex: 0)
    yCoordinates[pointIndex] = treeY
  if treeCount > 0:
    var scratchY = newSeq[int](treeCount)
    mergeSort(yCoordinates, scratchY, 0, treeCount - 1, valueComesBefore)
  var uniqueY = newSeq[int]()
  for coordinateIndex in 0 .. treeCount - 1:
    if coordinateIndex == 0 or yCoordinates[coordinateIndex] != yCoordinates[coordinateIndex - 1]:
      uniqueY.add yCoordinates[coordinateIndex]
  for pointIndex in 0 .. treeCount - 1:
    points[pointIndex].yIndex = upperBound(uniqueY, points[pointIndex].y) - 1
  let queryCount = nextInt(inputData, scanPos)
  let eventCount = queryCount * 4
  var answers = newSeq[int64](queryCount)
  var events = newSeq[QueryEvent](eventCount)
  var eventIndex = 0
  for queryIndex in 0 .. queryCount - 1:
    let lowerX = nextInt(inputData, scanPos)
    let lowerY = nextInt(inputData, scanPos)
    let upperX = nextInt(inputData, scanPos)
    let upperY = nextInt(inputData, scanPos)
    events[eventIndex] = (x: upperX, yBound: upperY, sign: 1, queryIndex: queryIndex)
    eventIndex += 1
    events[eventIndex] = (x: lowerX - 1, yBound: upperY, sign: -1, queryIndex: queryIndex)
    eventIndex += 1
    events[eventIndex] = (x: upperX, yBound: lowerY - 1, sign: -1, queryIndex: queryIndex)
    eventIndex += 1
    events[eventIndex] = (x: lowerX - 1, yBound: lowerY - 1, sign: 1, queryIndex: queryIndex)
    eventIndex += 1
  if treeCount > 0:
    var scratchPoints = newSeq[PointRecord](treeCount)
    mergeSort(points, scratchPoints, 0, treeCount - 1, pointComesBefore)
  if eventCount > 0:
    var scratchEvents = newSeq[QueryEvent](eventCount)
    mergeSort(events, scratchEvents, 0, eventCount - 1, eventComesBefore)
  var fenwickTree = newSeq[int64](uniqueY.len + 2)
  var pointPosition = 0
  for eventPosition in 0 .. eventCount - 1:
    let currentEvent = events[eventPosition]
    while pointPosition < treeCount and points[pointPosition].x <= currentEvent.x:
      fenwickAdd(fenwickTree, points[pointPosition].yIndex, points[pointPosition].value)
      pointPosition += 1
    let boundIndex = upperBound(uniqueY, currentEvent.yBound)
    let prefixTotal = fenwickSum(fenwickTree, boundIndex)
    answers[currentEvent.queryIndex] += int64(currentEvent.sign) * prefixTotal
  for answerIndex in 0 .. queryCount - 1:
    appendOutput($answers[answerIndex])
    outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

A bound of -1 contributes nothing, which matches an empty prefix.
Each tree enters the Fenwick tree once per test.
Totals use int64 because a large plot can hold 1e9 weight.

## Complexity

Sorting and the sweep drive the cost.

| phase | time | space |
|---|---|---|
| input read | one pass over the numbers | one input string |
| sorting | O((n + R) log n) | trees, events and scratch arrays |
| sweep | O((n + R) log n) | Fenwick tree over distinct y values |
| output | one buffered line per plot | block buffer |

The sort and sweep share the same asymptotic cost.

| measure | Big O |
|---|---|
| time | O((n + R) log n) per test |
| space | O(n + R) per test |

Checking every tree against every plot costs O(nR), far above this bound. Compress y once, sweep x once, and answer all plots with four signed prefix queries each.
