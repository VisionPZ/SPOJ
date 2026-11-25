# VACCINEP — Vaccine Priority (SPOJ)
<https://www.spoj.com/problems/VACCINEP/>

## Problem

Each town's priority is the number of outbreak towns within box distance 10. Towns are then ordered by decreasing priority and increasing town number.

Input starts with two integers n and k. The next n lines give integer x and y coordinates for towns 1 to n. The final line lists the k town numbers that had an outbreak. Output is a single line with all n town numbers in vaccination order.

| item | bound |
|---|---|
| town count n | 1 to 100000 |
| outbreak count k | 1 to n |
| coordinate x, y | 0 to 1000000000 |
| box distance threshold | 10 |
| judge limit | 1000 ms, 1536 MB |

Box distance between two towns is max of the absolute coordinate differences. An outbreak town counts itself.

Sample input:

```
3 1
0 11
0 10
0 0
3
```

Sample output:

```
2 3 1
```

A second sample has 4 towns and 2 outbreaks. Its coordinates are 0 11, 9 0, 0 1 and 11 11; outbreaks are towns 1 and 2, and the output is 3 1 2 4.

## Idea

Sweep a detector across the map, adding a beacon when it enters range and removing it when it leaves, like scanning a crowd with a metal detector. The algorithm sorts events and town queries by x coordinate. A Fenwick tree over compressed outbreak y values counts active outbreaks in the y window. Each town costs two binary searches and two prefix sums. Comparing every town with every outbreak costs n times k checks. Takeaway: sweep in x, count in y, then place towns into priority buckets.

## Why It Works

1. Box distance at most 10 means both coordinate differences are at most 10.
2. One outbreak adds one priority point to every town in a 21 by 21 square.
3. An add event at x minus 10 and a remove event at x plus 11 delimit that square in x.
4. Sorting events and queries by x makes each event applied once.
5. Compressing outbreak y values keeps the Fenwick tree small.
6. A prefix difference over compressed y counts outbreaks inside the y window.
7. Counting sort visits priorities from high to low and town numbers from low to high.

| term | meaning |
|---|---|
| `meetingRadius` | box distance threshold, which is 10 |
| `eventXs` | x coordinate of each add or remove event |
| `eventDeltas` | plus one for add events, minus one for remove events |
| `compressedYs` | sorted distinct outbreak y coordinates |
| `fenwickTree` | active outbreak counts indexed by compressed y |
| `priorities` | outbreak count for each town |
| `bucketStarts` | first ordered position for each priority |

In the first sample, town 1 at (0, 11) has priority 0, town 2 at (0, 10) has priority 1, and town 3 at (0, 0) has priority 1. The order is town 2, then town 3, then town 1, matching the sample output.

## Code

**Input and helpers.** The reader loads the input and provides bounds, binary searches and index sorting.

```nim
const flushBlockBytes = 1 shl 17
const meetingRadius = 10

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

proc lowerBound(values: seq[int], target: int): int =
  var lowIndex = 0
  var highIndex = values.len
  while lowIndex < highIndex:
    let middleIndex = (lowIndex + highIndex) div 2
    if values[middleIndex] < target:
      lowIndex = middleIndex + 1
    else:
      highIndex = middleIndex
  return lowIndex

proc upperBound(values: seq[int], target: int): int =
  var lowIndex = 0
  var highIndex = values.len
  while lowIndex < highIndex:
    let middleIndex = (lowIndex + highIndex) div 2
    if values[middleIndex] <= target:
      lowIndex = middleIndex + 1
    else:
      highIndex = middleIndex
  return lowIndex

proc mergeRanges(keys: seq[int], indexes: var seq[int], buffer: var seq[int], lowIndex, highIndex: int) =
  if lowIndex >= highIndex:
    return
  let middleIndex = (lowIndex + highIndex) div 2
  mergeRanges(keys, indexes, buffer, lowIndex, middleIndex)
  mergeRanges(keys, indexes, buffer, middleIndex + 1, highIndex)
  var leftPos = lowIndex
  var rightPos = middleIndex + 1
  var writePos = lowIndex
  while leftPos <= middleIndex and rightPos <= highIndex:
    if keys[indexes[leftPos]] <= keys[indexes[rightPos]]:
      buffer[writePos] = indexes[leftPos]
      leftPos += 1
    else:
      buffer[writePos] = indexes[rightPos]
      rightPos += 1
    writePos += 1
  while leftPos <= middleIndex:
    buffer[writePos] = indexes[leftPos]
    leftPos += 1
    writePos += 1
  while rightPos <= highIndex:
    buffer[writePos] = indexes[rightPos]
    rightPos += 1
    writePos += 1
  for position in lowIndex .. highIndex:
    indexes[position] = buffer[position]

proc sortIndicesByKey(keys: seq[int]): seq[int] =
  result = newSeq[int](keys.len)
  for index in 0 .. keys.len - 1:
    result[index] = index
  if keys.len > 1:
    var buffer = newSeq[int](keys.len)
    mergeRanges(keys, result, buffer, 0, keys.len - 1)
```

`lowerBound` counts values below a target.
`upperBound` counts values at or below a target.
`sortIndicesByKey` returns indices ordered by a key array.

**Events and queries.** Each outbreak creates an add and a remove event, and towns are ordered by x.

```nim
let townCount = nextInt(inputData, scanPos)
let outbreakCount = nextInt(inputData, scanPos)
var townXs = newSeq[int](townCount + 1)
var townYs = newSeq[int](townCount + 1)
for townIndex in 1 .. townCount:
  townXs[townIndex] = nextInt(inputData, scanPos)
  townYs[townIndex] = nextInt(inputData, scanPos)
var outbreakTowns = newSeq[int](outbreakCount)
for outbreakIndex in 0 .. outbreakCount - 1:
  outbreakTowns[outbreakIndex] = nextInt(inputData, scanPos)

var outbreakYs = newSeq[int](outbreakCount)
for outbreakIndex in 0 .. outbreakCount - 1:
  outbreakYs[outbreakIndex] = townYs[outbreakTowns[outbreakIndex]]
let sortedYIndices = sortIndicesByKey(outbreakYs)
var compressedYs = newSeq[int](outbreakCount)
var compressedCount = 0
for sortPosition in 0 .. outbreakCount - 1:
  let yValue = outbreakYs[sortedYIndices[sortPosition]]
  if compressedCount == 0 or compressedYs[compressedCount - 1] != yValue:
    compressedYs[compressedCount] = yValue
    compressedCount += 1
compressedYs.setLen(compressedCount)

var eventCount = 2 * outbreakCount
var eventXs = newSeq[int](eventCount)
var eventYIndexes = newSeq[int](eventCount)
var eventDeltas = newSeq[int](eventCount)
for outbreakIndex in 0 .. outbreakCount - 1:
  let outbreakTown = outbreakTowns[outbreakIndex]
  let entryIndex = 2 * outbreakIndex
  eventXs[entryIndex] = townXs[outbreakTown] - meetingRadius
  eventDeltas[entryIndex] = 1
  eventXs[entryIndex + 1] = townXs[outbreakTown] + meetingRadius + 1
  eventDeltas[entryIndex + 1] = -1
  let yIndex = lowerBound(compressedYs, townYs[outbreakTown]) + 1
  eventYIndexes[entryIndex] = yIndex
  eventYIndexes[entryIndex + 1] = yIndex
let sortedEventIndices = sortIndicesByKey(eventXs)

var queryKeys = newSeq[int](townCount)
for townIndex in 1 .. townCount:
  queryKeys[townIndex - 1] = townXs[townIndex]
let sortedQueryIndices = sortIndicesByKey(queryKeys)
```

`compressedYs` holds each outbreak y coordinate once.
`eventXs` marks where an outbreak enters and leaves the x window.
`sortedQueryIndices` visits towns from left to right.

**Sweep and priorities.** Active outbreaks are counted per town with Fenwick prefix sums.

```nim
var fenwickTree = newSeq[int](compressedCount + 1)

proc bitAdd(position: int, delta: int) =
  var current = position
  while current <= compressedCount:
    fenwickTree[current] += delta
    current += current and (-current)

proc bitPrefix(position: int): int =
  var current = position
  var total = 0
  while current > 0:
    total += fenwickTree[current]
    current -= current and (-current)
  return total

var priorities = newSeq[int](townCount + 1)
var eventPosition = 0
for queryPosition in 0 .. townCount - 1:
  let townIndex = sortedQueryIndices[queryPosition] + 1
  let townX = townXs[townIndex]
  while eventPosition < eventCount:
    let eventIndex = sortedEventIndices[eventPosition]
    if eventXs[eventIndex] > townX:
      break
    bitAdd(eventYIndexes[eventIndex], eventDeltas[eventIndex])
    eventPosition += 1
  let lowY = townYs[townIndex] - meetingRadius
  let highY = townYs[townIndex] + meetingRadius
  let leftCount = lowerBound(compressedYs, lowY)
  let rightCount = upperBound(compressedYs, highY)
  priorities[townIndex] = bitPrefix(rightCount) - bitPrefix(leftCount)
```

`bitAdd` updates one compressed y position.
`bitPrefix` sums all positions up to a bound.
The difference of two prefixes counts outbreaks inside the y window.

**Ordering and output.** Counting sort places towns into descending priority buckets.

```nim
var priorityCounts = newSeq[int](outbreakCount + 2)
for townIndex in 1 .. townCount:
  priorityCounts[priorities[townIndex]] += 1
var bucketStarts = newSeq[int](outbreakCount + 2)
for priorityValue in 0 .. outbreakCount:
  bucketStarts[priorityValue + 1] = bucketStarts[priorityValue] + priorityCounts[priorityValue]
var bucketCursors = newSeq[int](outbreakCount + 1)
for priorityValue in 0 .. outbreakCount:
  bucketCursors[priorityValue] = bucketStarts[priorityValue]
var orderedTowns = newSeq[int](townCount)
for townIndex in 1 .. townCount:
  let priorityValue = priorities[townIndex]
  orderedTowns[bucketCursors[priorityValue]] = townIndex
  bucketCursors[priorityValue] += 1

var currentPriority = outbreakCount
var firstTownWritten = true
while currentPriority >= 0:
  var bucketPosition = bucketStarts[currentPriority]
  while bucketPosition < bucketStarts[currentPriority + 1]:
    let townIndex = orderedTowns[bucketPosition]
    if firstTownWritten:
      firstTownWritten = false
    else:
      outputBuffer.add ' '
    appendOutput($townIndex)
    bucketPosition += 1
  currentPriority -= 1
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

`bucketStarts` gives each priority a contiguous slice of the output.
Town numbers enter a slice in increasing order.
`appendOutput` collects the whole result line and flushes it once.

## Complexity

The sweep processes n towns and 2k events.

| phase | time | space |
|---|---|---|
| input read | one pass over n coordinates | one input string |
| sorting | n plus 2k keys sorted by merge sort | index arrays |
| sweep | n plus 2k Fenwick updates and queries | compressed y array |
| ordering | n placements into priority buckets | n town slots |

| measure | Big O |
|---|---|
| time | O((n + k) log n) |
| space | O(n + k) |

Checking all town and outbreak pairs would take O(n times k) time. Takeaway: the sweep and Fenwick tree compute every priority in logarithmic time per item.
