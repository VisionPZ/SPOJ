# LINE — Connect Line Segments (SPOJ)

<https://www.spoj.com/problems/LINE/>

## Problem

Join n line segments into one polyline using new segments between endpoints. Minimize the total length of that polyline, which includes the original segments. Self-intersection is allowed.

Each case starts with n, followed by four real coordinates per segment. A single 0 ends the input. Print the case number and the minimum length with five decimals.

| item | bound |
|---|---|
| segments n | 2 to 14 |
| coordinates | -100 to 100 |
| output precision | 5 decimals |
| judge limit | 1000 ms, 1536 MB |

The answer equals the fixed original length plus the shortest set of n-1 connectors.

Sample input:

```
4
0 1 0 9
10 1 10 9
1 0 9 0
1 10 9 10
2
1.2 3.4 5.6 7.8
5.6 3.4 1.2 7.8
0
```

Sample output:

```
Case 1: 36.24264
Case 2: 16.84508
```

## Idea

String the given segments like beads on one cord. Keep the shortest way to join consecutive beads. Each join uses one endpoint from each neighboring segment. A subset and a free end capture the whole state.

The DP stores the least added length for every used subset, last segment, and free endpoint. Adding a segment joins that free end to one of the new segment's ends. The new free end is the other end of the new segment.

Each transition does two distance lookups. Trying every ordering by brute force would visit factorial permutations. The subset table shares all partial chains. Takeaway: remember the best chain for each subset and endpoint.

## Why It Works

1. A single polyline visits every segment exactly once, so the segments form a path.
2. Inside that path, each interior segment uses both endpoints to meet its two neighbors.
3. The first and last segment each leave one endpoint unused.
4. A state with a used subset, a last segment, and a free endpoint describes every partial path.
5. Joining a new segment consumes the free end and leaves the new segment's other end free.
6. Closing the path needs no extra connector, so the answer is the best state over the full subset.

| term | meaning |
|---|---|
| `endpointDistance` | Euclidean distance between any two endpoints |
| `originalLength` | sum of the n given segment lengths |
| `bestCost` | least added length for a subset, last segment, and free end |
| `fullMask` | bit mask with every segment used |

A worked example uses the first sample. Four vertical and horizontal segments each measure 8, giving 32. Three diagonal connectors of length sqrt(2) add about 4.24264. The printed total is 36.24264.

The generator checks this value before writing the sample, so the table stays anchored to the statement.

## Code

**Input and scanning.** The reader accepts integers and real numbers, including signs and decimals.

```nim
import strutils
import math

const flushBlockBytes = 1 shl 17
const firstDigitValue = 48

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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

proc isRealCharacter(character: char): bool =
  return (character >= '0' and character <= '9') or character == '-' or
    character == '+' or character == '.' or character == 'e' or character == 'E'

proc nextReal(data: string, pos: var int): float64 =
  while pos < data.len and not isRealCharacter(data[pos]):
    pos += 1
  var token = ""
  while pos < data.len and isRealCharacter(data[pos]):
    token.add data[pos]
    pos += 1
  return parseFloat(token)

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc distanceBetween(x1: float64, y1: float64, x2: float64, y2: float64): float64 =
  let deltaX = x1 - x2
  let deltaY = y1 - y2
  return sqrt(deltaX * deltaX + deltaY * deltaY)
```

The hand scanner builds a real token from digit and punctuation characters. Parsing uses parseFloat once per coordinate.

**Distance setup.** Every endpoint pair gets one Euclidean distance before the DP starts.

```nim
var caseNumber = 0
while true:
  let segmentCount = nextInt(inputData, scanPos)
  if segmentCount == 0:
    break
  caseNumber += 1
  let endpointCount = segmentCount * 2
  var endpointX = newSeq[float64](endpointCount)
  var endpointY = newSeq[float64](endpointCount)
  for segmentIndex in 0 .. segmentCount - 1:
    endpointX[segmentIndex * 2] = nextReal(inputData, scanPos)
    endpointY[segmentIndex * 2] = nextReal(inputData, scanPos)
    endpointX[segmentIndex * 2 + 1] = nextReal(inputData, scanPos)
    endpointY[segmentIndex * 2 + 1] = nextReal(inputData, scanPos)
  var endpointDistance = newSeq[seq[float64]](endpointCount)
  for endpointIndex in 0 .. endpointCount - 1:
    endpointDistance[endpointIndex] = newSeq[float64](endpointCount)
    for otherIndex in 0 .. endpointCount - 1:
      endpointDistance[endpointIndex][otherIndex] = distanceBetween(
        endpointX[endpointIndex], endpointY[endpointIndex],
        endpointX[otherIndex], endpointY[otherIndex])
  var originalLength = 0'f64
  for segmentIndex in 0 .. segmentCount - 1:
    originalLength += endpointDistance[segmentIndex * 2][segmentIndex * 2 + 1]
  let stateCount = (1 shl segmentCount) * endpointCount * 2
  var bestCost = newSeq[float64](stateCount)
  for stateIndex in 0 .. stateCount - 1:
    bestCost[stateIndex] = 1e30
  for segmentIndex in 0 .. segmentCount - 1:
    let startMask = 1 shl segmentIndex
    for freeEnd in 0 .. 1:
      bestCost[(startMask * endpointCount + segmentIndex) * 2 + freeEnd] = 0'f64
  let fullMask = (1 shl segmentCount) - 1
```

The original segment lengths are read from the same table. The state array stores one cost per subset, last segment, and free end.

**Subset DP.** Each transition appends one unused segment and updates the resulting state.

```nim
  for usedMask in 1 .. fullMask:
    for lastSegment in 0 .. segmentCount - 1:
      if (usedMask and (1 shl lastSegment)) == 0:
        continue
      for freeEnd in 0 .. 1:
        let currentCost = bestCost[(usedMask * endpointCount + lastSegment) * 2 + freeEnd]
        if currentCost > 1e29:
          continue
        for nextSegment in 0 .. segmentCount - 1:
          if (usedMask and (1 shl nextSegment)) != 0:
            continue
          for connectingEnd in 0 .. 1:
            let followingEnd = 1 - connectingEnd
            let updatedMask = usedMask or (1 shl nextSegment)
            let updatedIndex = (updatedMask * endpointCount + nextSegment) * 2 + followingEnd
            let trialCost = currentCost + endpointDistance[
              lastSegment * 2 + freeEnd][nextSegment * 2 + connectingEnd]
            if trialCost < bestCost[updatedIndex]:
              bestCost[updatedIndex] = trialCost
  var shortestConnection = 1e30
  for lastSegment in 0 .. segmentCount - 1:
    for freeEnd in 0 .. 1:
      let finishedCost = bestCost[(fullMask * endpointCount + lastSegment) * 2 + freeEnd]
      if finishedCost < shortestConnection:
        shortestConnection = finishedCost
  let answer = originalLength + shortestConnection
  appendOutput("Case " & $caseNumber & ": " & formatFloat(answer, ffDecimal, 5))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The loop walks subsets in increasing order. A large sentinel marks unreachable states. The final answer adds the shortest connector set to the original length.

## Complexity

Endpoint distances are precomputed once per case before the subset DP begins.

| phase | time | space |
|---|---|---|
| distance table | O(n^2) endpoint pairs | O(n^2) values |
| subset DP | O(2^n * n^2 * 4) transitions | O(2^n * n) states |
| output | one line per case | one block buffer |

| measure | Big O |
|---|---|
| time per case | O(2^n * n^2) |
| space per case | O(2^n * n) |

Permuting all n segments would cost O(n!) time. The subset table collapses every repeated ordering into one state.

Takeaway: one subset state replaces every repeated ordering of the same segments.
