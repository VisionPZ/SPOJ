# RETO4 — Checkpoint (SPOJ)

<https://www.spoj.com/problems/RETO4/>

## Problem

Vasya starts at a point on a line and must visit at least n - 1 checkpoints. Find the shortest distance needed.

The input gives the number of checkpoints and the starting coordinate. The next line gives every checkpoint coordinate. Print one integer, the minimum distance.

| Item | Bound |
|---|---|
| Checkpoint count | 1 to 100000 |
| Start coordinate | -1000000 to 1000000 |
| Checkpoint coordinate | -1000000 to 1000000 |
| Judge limit | 1000 ms, 1536 MB |

The order of visits is free, so only the endpoints of the visited set matter.

The statement shows three samples:

```
3 10
1 7 12
```

```
7
```

```
2 0
11 -10
```

```
10
```

```
5 0
0 0 1000 0 0
```

```
0
```

Skipping the far checkpoint in the first sample leaves the pair 7 and 12.

## Idea

Think of leaving out one stop on a bus route. The route still runs between the same outer stops unless you drop an end.

Sort the checkpoints. Skipping an interior point leaves both outer points, so it never helps. Only three endpoint pairs can win: keep both ends, drop the smallest, or drop the largest. On a line, walking between the ends costs the width plus the shorter trip from the start to one end.

Each candidate costs constant time after sorting, so the work is O(n log n). Checking every subset of checkpoints would take exponential time. Three endpoint pairs settle the answer.

## Why It Works

1. A walk on a line between two endpoints covers the whole interval between them.
2. Removing an interior checkpoint leaves the same interval and the same cost.
3. Removing the smallest or largest endpoint is the only way to shrink that interval.
4. When the start lies between the ends, begin from the nearer end.

The main terms and their meanings:

| Term | Meaning |
|---|---|
| `checkpointPositions` | sorted checkpoint coordinates |
| `travelCost` | shortest walk covering one endpoint pair |
| `widthCost` | distance between the two endpoints |
| `minimumDistance` | best cost over the three endpoint pairs |

These terms describe a walk with no extra turns.

A trace from `gen.py` on the first sample:

```
start 10, sorted points [1, 7, 12]
skip 1: range 7 to 12, left first 8, right first 7
skip 7: range 1 to 12, left first 20, right first 13
skip 12: range 1 to 7, left first 15, right first 9
minimum 7
```

The best walk drops checkpoint 1 and visits 12 first.

## Code

**Input and helpers.** The scanner reads signed integers; the cost routine covers one endpoint pair.

```nim
import algorithm

const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

proc nextInteger(inputData: string, scanPos: var int): int64 =
  while scanPos < inputData.len and inputData[scanPos] != '-' and
        (inputData[scanPos] < '0' or inputData[scanPos] > '9'):
    scanPos += 1
  var signValue = 1'i64
  if scanPos < inputData.len and inputData[scanPos] == '-':
    signValue = -1'i64
    scanPos += 1
  var parsedValue = 0'i64
  while scanPos < inputData.len and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    parsedValue = parsedValue * 10 + int64(int(inputData[scanPos]) - firstDigitValue)
    scanPos += 1
  return signValue * parsedValue

proc comparePositions(leftPosition: int64, rightPosition: int64): int =
  if leftPosition < rightPosition:
    return -1
  if leftPosition > rightPosition:
    return 1
  return 0

proc travelCost(startPosition: int64, leftEnd: int64, rightEnd: int64): int64 =
  if startPosition <= leftEnd:
    return rightEnd - startPosition
  if startPosition >= rightEnd:
    return startPosition - leftEnd
  let widthCost = rightEnd - leftEnd
  let leftFirstCost = (startPosition - leftEnd) + widthCost
  let rightFirstCost = (rightEnd - startPosition) + widthCost
  if leftFirstCost < rightFirstCost:
    return leftFirstCost
  return rightFirstCost
```

The comparator works with Nim 0.19.4, where `sort` needs an explicit order. A start outside the interval needs only one direction.

**Input buffer.** All coordinates enter one string before analysis.

```nim
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let pointCount = int(nextInteger(inputData, scanPos))
let startPosition = nextInteger(inputData, scanPos)
var checkpointPositions = newSeq[int64](pointCount)
for pointIndex in 0 ..< pointCount:
  checkpointPositions[pointIndex] = nextInteger(inputData, scanPos)
```

The sequence holds exactly `pointCount` values. The output buffer flushes in 128 KiB blocks.

**Candidate pairs.** Sorting exposes the three useful endpoint pairs.

```nim
var minimumDistance = 0'i64
if pointCount > 1:
  sort(checkpointPositions, comparePositions)
  let smallest = checkpointPositions[0]
  let largest = checkpointPositions[pointCount - 1]
  let secondSmallest = checkpointPositions[1]
  let secondLargest = checkpointPositions[pointCount - 2]
  minimumDistance = travelCost(startPosition, smallest, largest)
  let skipSmallestCost = travelCost(startPosition, secondSmallest, largest)
  if skipSmallestCost < minimumDistance:
    minimumDistance = skipSmallestCost
  let skipLargestCost = travelCost(startPosition, smallest, secondLargest)
  if skipLargestCost < minimumDistance:
    minimumDistance = skipLargestCost

appendOutput($minimumDistance)
outputBuffer.add '\n'
stdout.write outputBuffer
```

One checkpoint needs no travel, so the answer stays zero. The other cases inspect only the sorted ends.

## Complexity

Sorting dominates the work; the three candidate checks are constant.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input buffer |
| Sorting | one sort of n coordinates | coordinate array |
| Candidate checks | three constant-time walks | no extra storage |

The checkpoint count sets the cost.

The asymptotic bounds are:

| Measure | Big O |
|---|---|
| Time | O(n log n) |
| Space | O(n) |

Testing every skipped checkpoint with a fresh visit order would cost far more. Three endpoint pairs give the same answer after one sort.
