# SHORTCUT — Shortcut (SPOJ)
<https://www.spoj.com/problems/SHORTCUT/>

## Problem

A route consists of straight sections of 10 meters each, ending at numbered break points. Find the shortest horizontal or vertical shortcut joining two break points, with ties broken by earliest start and furthest end.

Input: an integer t, then t cases. Each case gives section count n, then a string of n letters N, E, S or W. Output: four fields, the length in sections, the begin point, the end point, and the direction letter.

The statement sets these bounds.

| Item | Bound |
| --- | --- |
| Test cases | t from input |
| Sections n | 3 to 250000 |
| Route letters | N, E, S or W |
| Break point numbers | 0 through n |
| Judge time limit | 1302 ms |
| Judge memory limit | 1536 MB |

At least one shortcut always exists.

The sample input:

```
1
12
NNNENNWWWSSW
```

The sample output:

```
2 3 11 W
```

## Idea

Lay the route on a grid and group rest points by row, like sorting addresses by street. Two points on the same row can be joined horizontally. Adjacent rest points in sorted order give the shortest horizontal gap, so only neighbors matter. Do the same by column for vertical shortcuts.

The program uses counting sort on x and y instead of a comparison sort. Coordinates can be negative, so an offset shifts them into non-negative buckets. Each rest point is visited twice, once per direction. A pair of nested loops over all points would cost O(n squared), which is impossible at 250000 sections.

Counting sort turns a quadratic search into two linear scans.

## Why It Works

Four facts carry the program.

1. A shortcut joins two break points on the same row or the same column. The route never revisits a place, so each row and column holds distinct positions.
2. For a fixed row, the shortest gap comes from two break points adjacent in x order. Any third point between them would make one gap shorter.
3. Counting sort groups points by coordinate in O(n) time. The offset of n plus 2 keeps negative coordinates positive.
4. Skipping index differences of one avoids the trivial shortcut between consecutive sections. The tie rules then pick the earliest begin and the furthest end.

Each term has one job.

| Term | Meaning |
| --- | --- |
| `orderByX` | break point indices sorted by x coordinate |
| `orderByY` | break point indices sorted by y coordinate |
| `lastOnRow` | most recent point seen at a y value |
| `coordinateOffset` | shift that keeps buckets non-negative |

Lengths are integers in section units, so no rounding occurs.

A script traces the sample route NNNENNWWWSSW.

```text
break 0 (0,0)   3 (0,3)   6 (1,5)   9 (-2,5)   11 (-2,3)
row y=3 holds breaks 3 and 11, gap 2 in x
row y=5 holds breaks 6 and 9, gap 3 in x
best length 2, begin 3, end 11, direction W
```

The shortest gap spans two sections, from break 3 to break 11.

## Code

**Scanner.** One index walks the whole input buffer.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18

proc nextInt(inputData: string, i: var int): int =
  while i < inputData.len and (inputData[i] < '0' or inputData[i] > '9'):
    i.inc
  result = 0
  while i < inputData.len and inputData[i] >= '0' and inputData[i] <= '9':
    result = result * 10 + (ord(inputData[i]) - firstDigitValue)
    i.inc
```

The first loop skips letters and spaces, so the route string is bypassed. The scanner reads each number in one digit pass.

**Tie rule.** One helper decides whether a candidate wins.

```nim
proc considerShortcut(lengthValue: int, firstBreak: int, secondBreak: int,
                      horizontal: bool, xPositions: seq[int], yPositions: seq[int],
                      bestLength: var int, bestBegin: var int, bestEnd: var int,
                      bestDirection: var char) =
  var beginBreak = firstBreak
  var endBreak = secondBreak
  if firstBreak > secondBreak:
    beginBreak = secondBreak
    endBreak = firstBreak
  let improves = lengthValue < bestLength or
    (lengthValue == bestLength and beginBreak < bestBegin) or
    (lengthValue == bestLength and beginBreak == bestBegin and endBreak > bestEnd)
  if improves:
    bestLength = lengthValue
    bestBegin = beginBreak
    bestEnd = endBreak
    if horizontal:
      if xPositions[endBreak] > xPositions[beginBreak]:
        bestDirection = 'E'
      else:
        bestDirection = 'W'
    else:
      if yPositions[endBreak] > yPositions[beginBreak]:
        bestDirection = 'N'
      else:
        bestDirection = 'S'
```

The begin and end are ordered by route index, not by position. The three conditions match the length, begin and end tie rules. Direction follows the coordinate difference.

**Input and reusable arrays.** Buffers grow only when a larger case arrives.

```nim
var inputData = ""
var lineBuffer = ""
while readLine(stdin, lineBuffer):
  inputData.add lineBuffer
  inputData.add '\n'

var outputBuffer = ""
var i = 0
let testCount = nextInt(inputData, i)

var xPositions = newSeq[int](1)
var yPositions = newSeq[int](1)
var orderByX = newSeq[int](1)
var orderByY = newSeq[int](1)
var xCounts = newSeq[int](1)
var yCounts = newSeq[int](1)
var lastOnRow = newSeq[int](1)
var lastOnColumn = newSeq[int](1)
```

One line loop collects the stream. Each array starts at length one and grows to the largest case.

**Case setup and route walk.** Letters become grid coordinates.

```nim
for j in 0 ..< testCount:
  let sectionCount = nextInt(inputData, i)
  let breakCount = sectionCount + 1
  let coordinateOffset = sectionCount + 2
  let bucketCount = 2 * sectionCount + 5

  if xPositions.len < breakCount:
    xPositions.setLen(breakCount)
    yPositions.setLen(breakCount)
    orderByX.setLen(breakCount)
    orderByY.setLen(breakCount)
  if xCounts.len < bucketCount:
    xCounts.setLen(bucketCount)
    yCounts.setLen(bucketCount)
    lastOnRow.setLen(bucketCount)
    lastOnColumn.setLen(bucketCount)

  for j in 0 .. bucketCount - 1:
    xCounts[j] = 0
    yCounts[j] = 0
    lastOnRow[j] = -1
    lastOnColumn[j] = -1

  while i < inputData.len and inputData[i] <= ' ':
    i.inc

  var currentX = 0
  var currentY = 0
  xPositions[0] = 0
  yPositions[0] = 0
  for j in 1 .. sectionCount:
    case inputData[i]
    of 'N':
      currentY.inc
    of 'S':
      currentY.dec
    of 'E':
      currentX.inc
    of 'W':
      currentX.dec
    else:
      discard
    i.inc
    xPositions[j] = currentX
    yPositions[j] = currentY
```

`breakCount` is `sectionCount + 1`, so home and university are included. Coordinates stay within plus or minus n, so `bucketCount` covers both axes. Clearing touches only `bucketCount` buckets.

**Counting sort.** Prefix sums place each point in order.

```nim
  for k in 0 .. sectionCount:
    xCounts[xPositions[k] + coordinateOffset].inc
    yCounts[yPositions[k] + coordinateOffset].inc

  var xRunning = 0
  var yRunning = 0
  for j in 0 .. bucketCount - 1:
    let xBucketSize = xCounts[j]
    let yBucketSize = yCounts[j]
    xCounts[j] = xRunning
    yCounts[j] = yRunning
    xRunning += xBucketSize
    yRunning += yBucketSize

  for k in 0 .. sectionCount:
    let xSlot = xPositions[k] + coordinateOffset
    orderByX[xCounts[xSlot]] = k
    xCounts[xSlot].inc
    let ySlot = yPositions[k] + coordinateOffset
    orderByY[yCounts[ySlot]] = k
    yCounts[ySlot].inc
```

Counting sort runs in O(n + bucketCount). The offset prevents a negative bucket index. The two order arrays hold break point indices, not coordinates.

**Neighbor scans.** Each adjacent pair gives one candidate.

```nim
  var bestLength = 1 shl 30
  var bestBegin = 0
  var bestEnd = 0
  var bestDirection = 'N'

  for j in 0 .. sectionCount:
    let k = orderByX[j]
    let rowSlot = yPositions[k] + coordinateOffset
    let previousBreak = lastOnRow[rowSlot]
    if previousBreak >= 0:
      if abs(k - previousBreak) != 1:
        let lengthValue = xPositions[k] - xPositions[previousBreak]
        considerShortcut(lengthValue, previousBreak, k, true,
          xPositions, yPositions, bestLength, bestBegin, bestEnd, bestDirection)
    lastOnRow[rowSlot] = k

  for j in 0 .. sectionCount:
    let k = orderByY[j]
    let columnSlot = xPositions[k] + coordinateOffset
    let previousBreak = lastOnColumn[columnSlot]
    if previousBreak >= 0:
      if abs(k - previousBreak) != 1:
        let lengthValue = yPositions[k] - yPositions[previousBreak]
        considerShortcut(lengthValue, previousBreak, k, false,
          xPositions, yPositions, bestLength, bestBegin, bestEnd, bestDirection)
    lastOnColumn[columnSlot] = k
```

The x scan finds horizontal shortcuts, and the y scan finds vertical ones. The difference of one skips consecutive route sections. Each scan visits every break point once.

**Output.** Four fields make one line.

```nim
  outputBuffer.add $bestLength
  outputBuffer.add ' '
  outputBuffer.add $bestBegin
  outputBuffer.add ' '
  outputBuffer.add $bestEnd
  outputBuffer.add ' '
  outputBuffer.add bestDirection
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

if outputBuffer.len > 0:
  stdout.write outputBuffer
```

The final write clears the tail. A flush runs every 256 KiB, which caps memory.

## Complexity

Two counting sorts and two neighbor scans drive each case.

| Phase | Time | Space |
| --- | --- | --- |
| Input read | O(B) for B bytes | B bytes |
| Route walk | O(n) | O(n) |
| Counting sort | O(n + bucketCount) | O(n) |
| Neighbor scans | O(n) | O(bucketCount) |
| Output | O(t) lines | one block |

`bucketCount` is about `2n + 5`, so sorting stays linear.

| Measure | Big O |
| --- | --- |
| Time | O(n + bucketCount) per case |
| Space | O(n + bucketCount) |

Checking all break point pairs would cost O(n squared) time.
