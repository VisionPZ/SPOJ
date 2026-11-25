# IITWPC4E — Maggu's Solar Panels (SPOJ)

<https://www.spoj.com/problems/IITWPC4E/>

## Problem

Find the total power from overlapping solar panels, where power equals the union area of the rectangles times a fixed rate. Overlaps generate power once, so the task is a rectangle union area problem.

Input starts with N and R, the panel count and power per unit area. Each of the next N lines gives x, y, X, Y, the bottom-left and top-right corners of one panel. Print one integer, the total power.

| item | bound |
|---|---|
| panels N | 1 to 100000 |
| coordinates | -100000000 to 100000000 |
| power rate R | 1 to 100 |
| judge limit | 3000 ms, 1536 MB |

Each panel has sides parallel to the axes, and x is at most X while y is at most Y.

Sample input:

```
3 2
-6 0 3 6
0 4 6 10
4 -2 9 6
```

Sample output:

```
240
```

## Idea

Sweep a vertical line across the panels and measure the lit height at each x position, like counting water in a row of tanks as a wave passes. The covered height stays constant between corner x coordinates, so area is height times width for each strip.

The algorithm uses a sweep line with a segment tree over compressed y coordinates. Each event costs O(log N), and the sort costs O(N log N). Testing every pair of panels or every grid cell would need up to 10^10 operations. The tree tracks how many rectangles cover each y interval, so it reports the covered length in one query.

Coordinate compression plus a sweep turns overlapping rectangles into one-dimensional range updates.

## Why It Works

1. Only x values at panel edges can change the covered y set.
2. Between two consecutive edge x values, the covered y set stays fixed.
3. Each panel adds its y interval at x and removes it at X.
4. A segment tree node stores a cover count and the covered length of its y interval.
5. A positive cover count means the whole node interval is lit.
6. Summing height times strip width over all strips gives the exact union area.

| term | meaning |
|---|---|
| `SweepEvent` | one add or remove action at an x coordinate |
| `coverCounts` | number of panels covering each tree node |
| `coveredLengths` | lit y length stored at each node |
| `unionArea` | accumulated area before scaling by power |

The table names match the object and field names in the code.

The worked trace uses the sample panels:

```
strip -6..0 width 6: covered y 0..6, length 6, area 36
strip  0..3 width 3: covered y 0..10, length 10, area 30
strip  3..4 width 1: covered y 4..10, length 6, area 6
strip  4..6 width 2: covered y -2..10, length 12, area 24
strip  6..9 width 3: covered y -2..6, length 8, area 24
union area = 120, power = 120 * 2 = 240
```

The trace reproduces the sample output 240.

Zero-width and zero-height panels are skipped before events are built.

## Code

**Input, events and coverage tree.** The reader parses signed coordinates, then the sweep tree maintains covered y lengths.

```nim
import algorithm

const flushBlockBytes = 1 shl 17

type SweepEvent = object
  eventX: int
  lowerY: int
  upperY: int
  flipDelta: int

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  var negativeValue = false
  if pos < data.len and data[pos] == '-':
    negativeValue = true
    pos += 1
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  if negativeValue:
    return -value
  return value

proc compareIntegers(leftValue: int, rightValue: int): int =
  if leftValue < rightValue:
    return -1
  if leftValue > rightValue:
    return 1
  return 0

proc compareEvents(leftEvent: SweepEvent, rightEvent: SweepEvent): int =
  return compareIntegers(leftEvent.eventX, rightEvent.eventX)

var yCoordinates: seq[int]
var coverCounts: seq[int]
var coveredLengths: seq[int]

proc findYIndex(value: int): int =
  var lowIndex = 0
  var highIndex = yCoordinates.len - 1
  while lowIndex <= highIndex:
    let middleIndex = (lowIndex + highIndex) div 2
    if yCoordinates[middleIndex] < value:
      lowIndex = middleIndex + 1
    elif yCoordinates[middleIndex] > value:
      highIndex = middleIndex - 1
    else:
      return middleIndex
  return lowIndex

proc pullCoverage(nodeIndex: int, leftIndex: int, rightIndex: int) =
  if coverCounts[nodeIndex] > 0:
    coveredLengths[nodeIndex] = yCoordinates[rightIndex + 1] - yCoordinates[leftIndex]
  elif leftIndex == rightIndex:
    coveredLengths[nodeIndex] = 0
  else:
    coveredLengths[nodeIndex] = coveredLengths[nodeIndex * 2] + coveredLengths[nodeIndex * 2 + 1]

proc updateCoverage(nodeIndex: int, leftIndex: int, rightIndex: int,
                    queryLeft: int, queryRight: int, delta: int) =
  if queryLeft <= leftIndex and rightIndex <= queryRight:
    coverCounts[nodeIndex] += delta
    pullCoverage(nodeIndex, leftIndex, rightIndex)
    return
  let middleIndex = (leftIndex + rightIndex) div 2
  if queryLeft <= middleIndex:
    updateCoverage(nodeIndex * 2, leftIndex, middleIndex, queryLeft, queryRight, delta)
  if queryRight > middleIndex:
    updateCoverage(nodeIndex * 2 + 1, middleIndex + 1, rightIndex, queryLeft, queryRight, delta)
  pullCoverage(nodeIndex, leftIndex, rightIndex)
```

The scanner handles negative coordinates through an explicit sign branch.
Binary search maps each y boundary to a compressed index.
A node becomes fully lit whenever its cover count is positive.

**Sweep and output.** Each event adds its strip area before changing coverage, then the tree applies the event.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let panelCount = nextInt(inputData, scanPos)
let powerPerArea = nextInt(inputData, scanPos)
var events = newSeq[SweepEvent](2 * panelCount)
var yValues = newSeq[int](2 * panelCount)
var eventCount = 0
var yValueCount = 0
for panelIndex in 0 .. panelCount - 1:
  let leftX = nextInt(inputData, scanPos)
  let bottomY = nextInt(inputData, scanPos)
  let rightX = nextInt(inputData, scanPos)
  let topY = nextInt(inputData, scanPos)
  if leftX == rightX or bottomY == topY:
    continue
  events[eventCount] = SweepEvent(eventX: leftX, lowerY: bottomY, upperY: topY, flipDelta: 1)
  eventCount += 1
  events[eventCount] = SweepEvent(eventX: rightX, lowerY: bottomY, upperY: topY, flipDelta: -1)
  eventCount += 1
  yValues[yValueCount] = bottomY
  yValueCount += 1
  yValues[yValueCount] = topY
  yValueCount += 1
events.setLen(eventCount)
yValues.setLen(yValueCount)
yValues.sort(compareIntegers)
var compressedYs = newSeq[int](yValueCount)
var compressedCount = 0
for yIndex in 0 .. yValueCount - 1:
  if yIndex == 0 or yValues[yIndex] != yValues[yIndex - 1]:
    compressedYs[compressedCount] = yValues[yIndex]
    compressedCount += 1
compressedYs.setLen(compressedCount)
yCoordinates = compressedYs
coverCounts = newSeq[int](4 * compressedCount + 5)
coveredLengths = newSeq[int](4 * compressedCount + 5)
var unionArea: int64 = 0
if compressedCount >= 2 and eventCount > 0:
  events.sort(compareEvents)
  var previousX = events[0].eventX
  for eventIndex in 0 .. eventCount - 1:
    let currentEvent = events[eventIndex]
    unionArea = unionArea + int64(coveredLengths[1]) * int64(currentEvent.eventX - previousX)
    previousX = currentEvent.eventX
    let lowerIndex = findYIndex(currentEvent.lowerY)
    let upperIndex = findYIndex(currentEvent.upperY) - 1
    if lowerIndex <= upperIndex:
      updateCoverage(1, 0, compressedCount - 1, lowerIndex, upperIndex, currentEvent.flipDelta)
let totalPower = unionArea * int64(powerPerArea)
appendOutput($totalPower)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Area accumulation happens before each event update.
The union area stays under 4 times 10^16, so int64 suffices.
The final power is written once after scaling.

## Complexity

The sweep sorts events once and performs one tree update per event.

| phase | time | space |
|---|---|---|
| input read | one pass over N panels | one input string |
| event sort | O(N log N) comparisons | 2N events |
| sweep | 2N updates, each O(log N) | compressed y array and tree |
| output | one line | block buffer |

Sorting and tree updates dominate, both scaling logarithmically in N.

| measure | Big O |
|---|---|
| time | O(N log N) |
| space | O(N) |

Checking every grid cell could cost 10^10 operations, while the sweep settles the union in N log N steps.
