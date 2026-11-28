# CS345A1 — Red Blue Line Segments (SPOJ)
<https://www.spoj.com/problems/CS345A1/>

## Problem

Count pairs of horizontal blue and vertical red segments that touch or cross inside the unit square.

Input starts with n. Next come n blue lines with x1 x2 y, then n red lines with y1 y2 x. All values lie in [0, 1], and endpoints may be given in either order. Output one integer, the pair count.

| quantity | bound |
|---|---|
| segments of each color | n up to 100000 |
| coordinates | real numbers in [0, 1] |
| answer | up to n squared |
| judge limit | 2000 ms, 1536 MB |

A left-to-right sweep handles the largest input with room to spare.

Sample input:

```
3
0.36295 0.557494 0.184032
0.0479258 0.214097 0.508344
0.234284 0.969098 0.739363
0.499323 0.739797 0.138495
0.829265 0.22551 0.290582
0.791082 0.069214 0.450979
```

Sample output:

```
4
```

Four of the nine red blue pairs meet. A shared endpoint counts as a meeting.

## Idea

Sweeping left to right is like reading a barcode: each red line asks how many blue lines lie under its pen at that moment.

Represent each blue segment as an add event at its left end and a remove event at its right end. Each red segment becomes one query event at its x position. A Fenwick tree over compressed blue y levels answers each query by a range count.

Each event costs O(log n), so the sweep takes O(n log n). Comparing all red blue pairs would take O(n^2), which is far too slow at the limit.

Keep active blue levels in a Fenwick tree and ask only the relevant red queries.

## Why It Works

1. A pair intersects when x lies in the blue span and the blue y lies in the red span.
2. During the sweep, active blue segments are those covering the current x.
3. Add events run before queries, and queries before removes, at the same x.
4. That order makes shared endpoints count as intersections.
5. Compressed y levels let a Fenwick tree count active blue segments in a y range.
6. Adding the query results over all red segments gives the pair count.

| term | meaning |
|---|---|
| `SegmentEvent` | one add, query, or remove action at a coordinate |
| `levelValues` | sorted distinct y levels of blue segments |
| `events` | all sweep actions ordered by coordinate and kind |
| `fenwick` | count of active blue segments at each level |
| `intersectionCount` | running total of intersecting pairs |

Compressed levels turn real coordinates into small integer indices.

Blue segment x from 0.1 to 0.3 at y equals 0.2 meets red segment x equals 0.3 with y from 0.2 to 0.4. The add event at 0.1 runs first, the query at 0.3 finds the active level, and the remove event at 0.3 runs last.

In the sample, red x equals 0.499323 meets the first blue segment because 0.499323 lies between 0.36295 and 0.557494, and 0.184032 lies between 0.138495 and 0.739797.

Reversed endpoints are swapped before use. The answer uses `int64` because n squared can reach ten billion.

## Code

**Input and parsing.** The reader loads text and parses integers and decimals by hand.

```nim
const flushBlockBytes = 1 shl 17

type
  SegmentEvent = object
    coord: float
    kind: int
    yIndex: int
    lowerIndex: int
    upperIndex: int

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

proc nextFloat(data: string, pos: var int): float =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '.' and data[pos] != '-':
    pos += 1
  var sign = 1.0
  if pos < data.len and data[pos] == '-':
    sign = -1.0
    pos += 1
  var whole = 0.0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    whole = whole * 10.0 + float(int(data[pos]) - 48)
    pos += 1
  var fraction = 0.0
  var scale = 1.0
  if pos < data.len and data[pos] == '.':
    pos += 1
    while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
      fraction = fraction * 10.0 + float(int(data[pos]) - 48)
      scale = scale * 10.0
      pos += 1
  return sign * (whole + fraction / scale)

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The float scanner reads whole and fractional parts separately.
`appendOutput` flushes in large blocks.

**Ordering helpers.** Sorts and binary searches support the sweep.

```nim
proc sortFloats(values: var seq[float], lowIndex: int, highIndex: int) =
  if lowIndex >= highIndex:
    return
  var leftCursor = lowIndex
  var rightCursor = highIndex
  let pivot = values[lowIndex + (highIndex - lowIndex) div 2]
  while leftCursor <= rightCursor:
    while values[leftCursor] < pivot:
      leftCursor += 1
    while values[rightCursor] > pivot:
      rightCursor -= 1
    if leftCursor <= rightCursor:
      swap values[leftCursor], values[rightCursor]
      leftCursor += 1
      rightCursor -= 1
  sortFloats(values, lowIndex, rightCursor)
  sortFloats(values, leftCursor, highIndex)

proc eventLess(left: SegmentEvent, right: SegmentEvent): bool =
  if left.coord < right.coord:
    return true
  if left.coord > right.coord:
    return false
  return left.kind < right.kind

proc sortEvents(items: var seq[SegmentEvent], lowIndex: int, highIndex: int) =
  if lowIndex >= highIndex:
    return
  let pivotIndex = lowIndex + (highIndex - lowIndex) div 2
  swap items[lowIndex], items[pivotIndex]
  let pivot = items[lowIndex]
  var lessEnd = lowIndex
  var cursor = lowIndex + 1
  var greaterStart = highIndex
  while cursor <= greaterStart:
    if eventLess(items[cursor], pivot):
      swap items[lessEnd], items[cursor]
      lessEnd += 1
      cursor += 1
    elif eventLess(pivot, items[cursor]):
      swap items[cursor], items[greaterStart]
      greaterStart -= 1
    else:
      cursor += 1
  sortEvents(items, lowIndex, lessEnd - 1)
  sortEvents(items, greaterStart + 1, highIndex)

proc lowerBound(values: seq[float], target: float): int =
  var lowIndex = 0
  var highIndex = values.len
  while lowIndex < highIndex:
    let middle = (lowIndex + highIndex) div 2
    if values[middle] < target:
      lowIndex = middle + 1
    else:
      highIndex = middle
  return lowIndex

proc upperBound(values: seq[float], target: float): int =
  var lowIndex = 0
  var highIndex = values.len
  while lowIndex < highIndex:
    let middle = (lowIndex + highIndex) div 2
    if target < values[middle]:
      highIndex = middle
    else:
      lowIndex = middle + 1
  return lowIndex
```

Both sorts use a middle pivot.
`eventLess` orders by coordinate, then by event kind.
Binary searches map real bounds to level indices.

**Event build.** Endpoints are normalised and y levels are compressed.

```nim
let segmentCount = nextInt(inputData, scanPos)
var horizontalLowXs = newSeq[float](segmentCount)
var horizontalHighXs = newSeq[float](segmentCount)
var horizontalYs = newSeq[float](segmentCount)
var verticalXs = newSeq[float](segmentCount)
var verticalLowYs = newSeq[float](segmentCount)
var verticalHighYs = newSeq[float](segmentCount)

for segmentIndex in 0 .. segmentCount - 1:
  let firstX = nextFloat(inputData, scanPos)
  let secondX = nextFloat(inputData, scanPos)
  let level = nextFloat(inputData, scanPos)
  if firstX < secondX:
    horizontalLowXs[segmentIndex] = firstX
    horizontalHighXs[segmentIndex] = secondX
  else:
    horizontalLowXs[segmentIndex] = secondX
    horizontalHighXs[segmentIndex] = firstX
  horizontalYs[segmentIndex] = level

for segmentIndex in 0 .. segmentCount - 1:
  let firstY = nextFloat(inputData, scanPos)
  let secondY = nextFloat(inputData, scanPos)
  let positionX = nextFloat(inputData, scanPos)
  if firstY < secondY:
    verticalLowYs[segmentIndex] = firstY
    verticalHighYs[segmentIndex] = secondY
  else:
    verticalLowYs[segmentIndex] = secondY
    verticalHighYs[segmentIndex] = firstY
  verticalXs[segmentIndex] = positionX

var sortedYs = newSeq[float](segmentCount)
for segmentIndex in 0 .. segmentCount - 1:
  sortedYs[segmentIndex] = horizontalYs[segmentIndex]
if segmentCount > 0:
  sortFloats(sortedYs, 0, segmentCount - 1)

var levelValues = newSeq[float]()
for segmentIndex in 0 .. segmentCount - 1:
  if segmentIndex == 0 or sortedYs[segmentIndex] != sortedYs[segmentIndex - 1]:
    levelValues.add sortedYs[segmentIndex]

var events = newSeq[SegmentEvent]()
for segmentIndex in 0 .. segmentCount - 1:
  var newEvent: SegmentEvent
  newEvent.yIndex = lowerBound(levelValues, horizontalYs[segmentIndex]) + 1
  newEvent.lowerIndex = 0
  newEvent.upperIndex = 0
  newEvent.coord = horizontalLowXs[segmentIndex]
  newEvent.kind = 0
  events.add newEvent
  newEvent.coord = horizontalHighXs[segmentIndex]
  newEvent.kind = 2
  events.add newEvent

for segmentIndex in 0 .. segmentCount - 1:
  let firstIndex = lowerBound(levelValues, verticalLowYs[segmentIndex]) + 1
  let lastIndex = upperBound(levelValues, verticalHighYs[segmentIndex])
  if firstIndex <= lastIndex:
    var newEvent: SegmentEvent
    newEvent.coord = verticalXs[segmentIndex]
    newEvent.kind = 1
    newEvent.yIndex = 0
    newEvent.lowerIndex = firstIndex
    newEvent.upperIndex = lastIndex
    events.add newEvent

if events.len > 0:
  sortEvents(events, 0, events.len - 1)
```

Reversed endpoints are swapped into low and high order.
Each blue segment contributes one add and one remove event.
Each red segment contributes one query covering its y span.

**Sweep and count.** A Fenwick tree tracks active blue levels.

```nim
var fenwick = newSeq[int](levelValues.len + 1)

proc addFenwick(index: int, delta: int) =
  var position = index
  while position <= levelValues.len:
    fenwick[position] = fenwick[position] + delta
    position = position + (position and (-position))

proc prefixTotal(index: int): int =
  var total = 0
  var position = index
  while position > 0:
    total = total + fenwick[position]
    position = position - (position and (-position))
  return total

var intersectionCount: int64 = 0
for event in events:
  if event.kind == 0:
    addFenwick(event.yIndex, 1)
  elif event.kind == 1:
    intersectionCount = intersectionCount + int64(prefixTotal(event.upperIndex) - prefixTotal(event.lowerIndex - 1))
  else:
    addFenwick(event.yIndex, -1)

appendOutput($intersectionCount)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Add and remove update one level each.
A query subtracts two prefix totals for its range.
The final count uses `int64` for large answers.

## Complexity

Sorting dominates the sweep.

| phase | time | space |
|---|---|---|
| input read | one pass over the text | one input string |
| sorting | O(n log n) for levels and events | three events per segment |
| sweep | one Fenwick update or query per event | one tree of levels |
| output | one integer | block buffer |

At n equals 100000, the tree holds at most 100000 levels.

| measure | Big O |
|---|---|
| time | O(n log n) |
| extra space | O(n) |

Testing every red blue pair would take O(n^2) time.

The sweep counts all intersections with one ordered pass over the events.
