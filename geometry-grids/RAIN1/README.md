# RAIN1 — November Rain (SPOJ)

<https://www.spoj.com/problems/RAIN1/>

## Problem

Rain falls vertically onto sloping roof segments, some of which shelter others. Compute the water draining from each segment in one second.

Input: `t` cases. Each starts with `n`, then `n` lines `x1 y1 x2 y2`, the endpoints of one sloping segment. Output: `n` lines, one per segment, giving the liters that drain from that segment.

The bounds from the statement:

| Item | Bound |
|---|---|
| Segments `n` | 1 ≤ n ≤ 40000 |
| Coordinates | 0 ≤ x, y ≤ 10^6, `x1 < x2`, `y1 ≠ y2` |
| Overlap | at most 25 segments above any ground point |
| Judge limit | 2742 ms, 1536 MB |

Rain delivers one liter per meter of horizontal plane per second.

The sample input and output:

```
1
6
13 7 15 6
3 8 7 7
1 7 5 6
5 5 9 3
6 3 8 2
9 6 12 8
```

```
2
4
2
11
0
3
```

## Idea

Picture the rain as vertical threads from the sky. The highest sloping segment under each thread catches it, then funnels the water down to its lower end.

The program sweeps left to right over endpoint x-coordinates. At each x it keeps the covering segments sorted by height. Rain over a short x-interval goes to the topmost active segment. A stream leaving a lower endpoint falls onto the first segment below that point.

After the sweep, a queue propagates collected water down the receiver chain. Sorting `2n` coordinates costs O(n log n). Each event inserts into a list of at most 25 segments, so the sweep costs O(n · 25). Checking every pair of segments would cost O(n²).

A short active list turns overlapping slopes into a simple chain of receivers.

## Why It Works

Four facts carry the sweep.

1. Rain falls vertically, so at a fixed x only the highest covering segment catches water. Lower segments there are shielded.
2. Water on a segment runs to its lower endpoint and drops from that point. The first segment below becomes its receiver.
3. Every receiver sits lower than its source, so the links form a forest. A queue processes leaves first and accumulates each contribution once.
4. Heights are compared with integer cross-products in `higherAtX`, so no floating point enters the geometry.

The arrays that drive the sweep:

| Term | Meaning |
|---|---|
| `coordinateList` | sorted unique endpoint x values |
| `activeList` | segments spanning the current x, top first |
| `directWater` | rain caught directly by one segment |
| `receiverIndex` | segment that catches a stream at a lower end |

Integer cross-products keep the height order exact.

A script-traced example with the six sample segments:

```
direct rain:  seg0=2  seg1=4  seg2=2  seg3=2  seg4=0  seg5=3
streams:      seg1 -> seg3 carries 4
              seg2 -> seg3 carries 2
              seg5 -> seg3 carries 3
final seg3 = 2 + 4 + 2 + 3 = 11
output:       2  4  2  11  0  3
```

Segment 4 sits under segment 3 and catches no direct rain, so it drains 0.

## Code

**Buffers and state.** All segment data sits in flat arrays that grow per case.

```nim
import algorithm

const flushBlockBytes = 1 shl 18
const firstDigitValue = 48

var inputData = newStringOfCap(1 shl 20)
var lineBuffer = ""
var i = 0
var outputBuffer = newStringOfCap(flushBlockBytes)

var testCount = 0
var segmentCount = 0
var leftX: seq[int]
var leftY: seq[int]
var rightX: seq[int]
var rightY: seq[int]
var lowerEndX: seq[int]
var lowerEndY: seq[int]
var directWater: seq[int64]
var answerWater: seq[int64]
var receiverIndex: seq[int]
var pendingChildren: seq[int]
var endCoordIndex: seq[int]
var coordinateValues: seq[int]
var coordinateList: seq[int]
var coordinateCount = 0
var currentX = 0
var startHead: seq[int]
var startNext: seq[int]
var streamHead: seq[int]
var streamNext: seq[int]
var activeList: seq[int]
var nextActiveList: seq[int]
var coverList: seq[int]
var queueList: seq[int]
```

The arrays are declared once and resized for each case. `firstDigitValue` supports the hand scanner, and `flushBlockBytes` sets the write block size.

**Scanner and geometry helpers.** Coordinates are found by binary search, and heights by cross-products.

```nim
proc compareInt(firstValue: int, secondValue: int): int =
  if firstValue < secondValue:
    return -1
  if firstValue > secondValue:
    return 1
  return 0

proc nextInt(): int =
  while i < inputData.len and (inputData[i] < '0' or inputData[i] > '9'):
    i += 1
  var value = 0
  while i < inputData.len and inputData[i] >= '0' and inputData[i] <= '9':
    value = value * 10 + (int(inputData[i]) - firstDigitValue)
    i += 1
  return value

proc findCoordIndex(value: int): int =
  var i = 0
  var j = coordinateCount - 1
  while i <= j:
    let k = (i + j) div 2
    if coordinateList[k] == value:
      return k
    if coordinateList[k] < value:
      i = k + 1
    else:
      j = k - 1
  return i

proc yNumerator(i: int): int64 =
  let span = int64(rightX[i] - leftX[i])
  let slope = int64(rightY[i] - leftY[i])
  result = int64(leftY[i]) * span + slope * int64(currentX - leftX[i])

proc higherAtX(firstSeg: int, secondSeg: int): bool =
  let firstSpan = int64(rightX[firstSeg] - leftX[firstSeg])
  let secondSpan = int64(rightX[secondSeg] - leftX[secondSeg])
  result = yNumerator(firstSeg) * secondSpan > yNumerator(secondSeg) * firstSpan

proc appendOutputLine(value: int64) =
  outputBuffer.add $value
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

`findCoordIndex` returns the first coordinate at or above a value. `yNumerator` gives a segment's height at `currentX` without dividing. `higherAtX` compares two numerators with a cross-product.

**Input.** The program reads all segments, marks their endpoints, and compresses x values.

```nim
while readLine(stdin, lineBuffer):
  inputData.add lineBuffer
  inputData.add '\n'

testCount = nextInt()

while testCount > 0:
  testCount -= 1
  segmentCount = nextInt()

  leftX = newSeq[int](segmentCount)
  leftY = newSeq[int](segmentCount)
  rightX = newSeq[int](segmentCount)
  rightY = newSeq[int](segmentCount)
  lowerEndX = newSeq[int](segmentCount)
  lowerEndY = newSeq[int](segmentCount)
  directWater = newSeq[int64](segmentCount)
  answerWater = newSeq[int64](segmentCount)
  receiverIndex = newSeq[int](segmentCount)
  pendingChildren = newSeq[int](segmentCount)
  endCoordIndex = newSeq[int](segmentCount)
  startNext = newSeq[int](segmentCount)
  streamNext = newSeq[int](segmentCount)

  coordinateValues = newSeq[int](2 * segmentCount)
  for j in 0 ..< segmentCount:
    leftX[j] = nextInt()
    leftY[j] = nextInt()
    rightX[j] = nextInt()
    rightY[j] = nextInt()
    coordinateValues[2 * j] = leftX[j]
    coordinateValues[2 * j + 1] = rightX[j]
    if leftY[j] < rightY[j]:
      lowerEndX[j] = leftX[j]
      lowerEndY[j] = leftY[j]
    else:
      lowerEndX[j] = rightX[j]
      lowerEndY[j] = rightY[j]

  coordinateValues.sort(compareInt)
  coordinateList = newSeq[int](2 * segmentCount)
  coordinateCount = 0
  for j in 0 ..< 2 * segmentCount:
    if j == 0 or coordinateValues[j] != coordinateValues[j - 1]:
      coordinateList[coordinateCount] = coordinateValues[j]
      coordinateCount += 1
  coordinateList.setLen(coordinateCount)
```

The lower end of each segment is chosen by its smaller y. `coordinateValues` holds both endpoints of every segment. Sorting and removing duplicates leaves the event coordinates.

**Sweep setup.** Start and stream lists bucket segments by x index.

```nim
  startHead = newSeq[int](coordinateCount)
  streamHead = newSeq[int](coordinateCount)
  for j in 0 ..< coordinateCount:
    startHead[j] = -1
    streamHead[j] = -1

  for j in 0 ..< segmentCount:
    let startIndex = findCoordIndex(leftX[j])
    startNext[j] = startHead[startIndex]
    startHead[startIndex] = j

    let finishIndex = findCoordIndex(rightX[j])
    endCoordIndex[j] = finishIndex

    let streamIndex = findCoordIndex(lowerEndX[j])
    streamNext[j] = streamHead[streamIndex]
    streamHead[streamIndex] = j

  activeList = @[]
```

`startHead` lists segments beginning at an x. `streamHead` lists segments whose lower end drops there. Both use linked `next` arrays.

**Sweep over coordinates.** Each event assigns rain and finds stream receivers.

```nim
  for j in 0 ..< coordinateCount:
    currentX = coordinateList[j]
    var coverCount = 0
    for k in activeList:
      coverList[coverCount] = k
      coverCount += 1
    var startSeg = startHead[j]
    while startSeg != -1:
      coverList[coverCount] = startSeg
      coverCount += 1
      startSeg = startNext[startSeg]

    for k in 1 ..< coverCount:
      let keySeg = coverList[k]
      var l = k - 1
      while l >= 0 and higherAtX(keySeg, coverList[l]):
        coverList[l + 1] = coverList[l]
        l -= 1
      coverList[l + 1] = keySeg

    var streamSeg = streamHead[j]
    while streamSeg != -1:
      var receiverSeg = -1
      let sourceHeight = int64(lowerEndY[streamSeg])
      for k in 0 ..< coverCount:
        let candidateSeg = coverList[k]
        let span = int64(rightX[candidateSeg] - leftX[candidateSeg])
        if yNumerator(candidateSeg) < sourceHeight * span:
          receiverSeg = candidateSeg
          break
      receiverIndex[streamSeg] = receiverSeg
      streamSeg = streamNext[streamSeg]

    if j < coordinateCount - 1:
      for k in 0 ..< coverCount:
        let candidateSeg = coverList[k]
        if endCoordIndex[candidateSeg] != j:
          directWater[candidateSeg] += int64(coordinateList[j + 1] - currentX)
          break

    nextActiveList.setLen(0)
    for k in 0 ..< coverCount:
      let candidateSeg = coverList[k]
      if endCoordIndex[candidateSeg] != j:
        nextActiveList.add candidateSeg
    swap activeList, nextActiveList
```

`coverList` collects active and starting segments, then insertion sort orders them by height. A stream scans that sorted list for the first segment below its source. Direct rain goes to the topmost segment whose end is not at this x.

**Propagation and output.** Leaves first, then parents, then one answer line per segment.

```nim
  for j in 0 ..< segmentCount:
    answerWater[j] = directWater[j]
    pendingChildren[j] = 0
  for j in 0 ..< segmentCount:
    let receiverSeg = receiverIndex[j]
    if receiverSeg != -1:
      pendingChildren[receiverSeg] += 1

  queueList = @[]
  for j in 0 ..< segmentCount:
    if pendingChildren[j] == 0:
      queueList.add j
  var queueHead = 0
  while queueHead < queueList.len:
    let currentSeg = queueList[queueHead]
    queueHead += 1
    let receiverSeg = receiverIndex[currentSeg]
    if receiverSeg != -1:
      answerWater[receiverSeg] += answerWater[currentSeg]
      pendingChildren[receiverSeg] -= 1
      if pendingChildren[receiverSeg] == 0:
        queueList.add receiverSeg

  for j in 0 ..< segmentCount:
    appendOutputLine(answerWater[j])

stdout.write outputBuffer
outputBuffer.setLen 0
```

`pendingChildren` counts unreceived streams. Segments with none enter the queue first. Each popped segment adds its water to its receiver. The final write covers the output tail.

## Complexity

Each case sorts coordinates, sweeps once, then propagates through a forest.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Coordinate sort | O(n log n) | O(n) |
| Sweep | O(n) events × O(25) insertion | O(n) |
| Propagation | O(n) queue steps | O(n) |
| Output | one write per 256 KiB block | 256 KiB |
| Total per case | O(n log n + 25n) | O(n) |

The small overlap bound keeps the sweep effectively linear.

| Measure | Big O |
|---|---|
| Time | O(n log n + k · n) with k ≤ 25 |
| Space | O(n) for segment arrays and buffers |

A pairwise comparison of all segments would cost O(n²) per case.

Checking every segment against every x would cost O(n²). The sweep and short active list replace that with O(n log n).
