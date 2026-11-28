# FN16RIVER — Longest Rivers (SPOJ)

<https://www.spoj.com/problems/FN16RIVER/>

## Problem

Several streams join at confluences, and each join keeps the name of one incoming stream. A river's length is the distance its name travels before it loses the name or reaches the sea. For every source river, report its best rank over all naming choices, with rank 1 for longest and tied rivers sharing the best rank.

Input starts with decimal integers `n` and `m`. The value `n` counts sources, and `m` counts confluences with positive labels. The next `n` lines describe sources; the next `m` lines describe confluences 1 through `m`. Each description holds two base-64 integers `c` and `d`, where `c` is the downstream confluence and `d` is the section length. Confluence 0 is the sea. Output one decimal rank per source, in input order.

| item | bound |
|---|---|
| sources n | 1 to 500000 |
| confluences m | 0 to n - 1 |
| section length d | 1 to 10^9 |
| base-64 digits | 0-9, A-Z, a-z, +, / |
| judge limit | 10000 ms, 1536 MB |

Every confluence from 1 to `m` receives at least two incoming sections, and every source reaches the sea.

Sample input:

```
6 2
0 81
2 AZ
2 Ay
1 5F
1 4n
0 Bz
0 5X
0 11
6 3
1 GN
2 fQ
1 CW
3 B6
0 h/
3 CJ
2 1a
0 Qa
0 U
```

Sample output:

```
5
2
1
3
4
1
1
1
3
6
1
4
```

## Idea

Think of a relay race: at each exchange, one runner's name stays on the baton, and we may pick which runner. Give one river a target length `L`, then count how many rivers must end longer than `L`. Sweep `L` upward and update only the confluences whose incoming streams turn short. A priority queue holds the next flip for each active stream. Recomputing every naming for every river would take quadratic time. The sweep changes each confluence state once, so one pass answers all rivers. Short takeaway: sweep the length threshold, not the rivers.

## Why It Works

1. A river can always keep its name all the way to the sea, giving length equal to its source-to-sea distance.
2. For a target length `L`, call a stream long when its accumulated length exceeds `L`.
3. At a confluence with a long incoming stream, keep that stream and stop the others.
4. At a confluence where all incoming streams are short, keep the shortest one.
5. A short stream turns long only after a section, and that moment is the flip value stored in the heap.
6. An active confluence flips from having a long stream to having only short streams once. It then gets a state and a flip value of its own.
7. The count of long rivers after processing flips up to `L` gives the rank as that count plus one.

| term | meaning |
|---|---|
| `distanceToSea` | source-to-sea length of one river |
| `nodeStates` | confluence state: long present, becoming long, or short |
| `activeChildren` | incoming streams not yet short at a confluence |
| `flowLengths` | accumulated length of the stream kept at a node |
| `longCount` | number of rivers longer than the current threshold |
| `sweepLength` | current threshold `L` |

In the first sample case the source-to-sea lengths include 513, 658, 688, 740, and 765. At threshold 658, the streams from sources with lengths 305 and 335 are short, the confluence keeps the 305 stream, and the added section of 353 makes it reach 658. That stream is not longer than 658, so it adds no long river. The count at each source length produces ranks 5, 4, 3, 2, 1, and 1 in length order.

Base-64 decoding maps digits in order, so `AZ` means 10 times 64 plus 35, or 675. All distances use 64-bit integers, and the heap stores flip values in the same type.

## Code

**Input and decoding.** The reader tokenises text and decodes base-64 numbers.

```nim
import algorithm

const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextToken(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  result = ""
  while pos < data.len and data[pos] > ' ':
    result.add data[pos]
    pos += 1

proc hasNextToken(data: string, pos: int): bool =
  var checkPos = pos
  while checkPos < data.len:
    if data[checkPos] > ' ':
      return true
    checkPos += 1
  return false

proc decimalValue(token: string): int =
  result = 0
  for character in token:
    result = result * 10 + int(character) - 48

proc base64Value(token: string): int64 =
  result = 0
  for character in token:
    var digit = 0
    if character >= '0' and character <= '9':
      digit = int(character) - 48
    elif character >= 'A' and character <= 'Z':
      digit = int(character) - 65 + 10
    elif character >= 'a' and character <= 'z':
      digit = int(character) - 97 + 36
    elif character == '+':
      digit = 62
    else:
      digit = 63
    result = result * 64 + int64(digit)
```

The token reader works across spaces and line breaks.
The header values stay decimal, while section values use base 64.
A confluence label of zero becomes the sea sentinel minus one.

**State changes.** The heap orders flip values, and a confluence updates its parent when all children turn short.

```nim
var sourceCount = 0
var parentLabels = newSeq[int](0)
var edgeLengths = newSeq[int64](0)

proc parentNodeOf(nodeIndex: int): int =
  let label = parentLabels[nodeIndex]
  if label == -1:
    return -1
  return sourceCount + label

var eventTimes = newSeq[int64](0)
var eventNodes = newSeq[int](0)

proc eventLess(leftIndex: int, rightIndex: int): bool =
  if eventTimes[leftIndex] < eventTimes[rightIndex]:
    return true
  if eventTimes[leftIndex] > eventTimes[rightIndex]:
    return false
  return eventNodes[leftIndex] < eventNodes[rightIndex]

proc swapEvent(leftIndex: int, rightIndex: int) =
  let savedTime = eventTimes[leftIndex]
  let savedNode = eventNodes[leftIndex]
  eventTimes[leftIndex] = eventTimes[rightIndex]
  eventNodes[leftIndex] = eventNodes[rightIndex]
  eventTimes[rightIndex] = savedTime
  eventNodes[rightIndex] = savedNode

proc siftUpEvent(startIndex: int) =
  var childIndex = startIndex
  while childIndex > 0:
    let parentIndex = (childIndex - 1) div 2
    if eventLess(childIndex, parentIndex):
      swapEvent(childIndex, parentIndex)
      childIndex = parentIndex
    else:
      break

proc siftDownEvent(startIndex: int) =
  var parentIndex = startIndex
  while true:
    let leftIndex = parentIndex * 2 + 1
    if leftIndex >= eventTimes.len:
      break
    let rightIndex = leftIndex + 1
    var smallestIndex = leftIndex
    if rightIndex < eventTimes.len and eventLess(rightIndex, leftIndex):
      smallestIndex = rightIndex
    if eventLess(smallestIndex, parentIndex):
      swapEvent(parentIndex, smallestIndex)
      parentIndex = smallestIndex
    else:
      break

proc pushEvent(flipTime: int64, nodeIndex: int) =
  eventTimes.add flipTime
  eventNodes.add nodeIndex
  siftUpEvent(eventTimes.len - 1)

proc popEvent(flipTime: var int64, nodeIndex: var int) =
  flipTime = eventTimes[0]
  nodeIndex = eventNodes[0]
  let lastIndex = eventTimes.len - 1
  eventTimes[0] = eventTimes[lastIndex]
  eventNodes[0] = eventNodes[lastIndex]
  eventTimes.setLen(lastIndex)
  eventNodes.setLen(lastIndex)
  if eventTimes.len > 0:
    siftDownEvent(0)

var nodeStates = newSeq[int](0)
var activeChildren = newSeq[int](0)
var flowLengths = newSeq[int64](0)
var childLists = newSeq[seq[int]](0)
var sweepLength: int64 = 0
var longCount: int64 = 0

proc notifyParent(childNode: int)

proc notifyParent(childNode: int) =
  let parentNode = parentNodeOf(childNode)
  if parentNode == -1:
    return
  activeChildren[parentNode] -= 1
  if activeChildren[parentNode] == 0 and nodeStates[parentNode] == 0:
    var bestArrival: int64 = high(int64)
    for downstreamNode in childLists[parentNode]:
      let arriving = flowLengths[downstreamNode] + edgeLengths[downstreamNode]
      if arriving < bestArrival:
        bestArrival = arriving
    flowLengths[parentNode] = bestArrival
    let arrivingAtParent = bestArrival + edgeLengths[parentNode]
    if arrivingAtParent > sweepLength:
      nodeStates[parentNode] = 1
      longCount += 1
      pushEvent(arrivingAtParent, parentNode)
    else:
      nodeStates[parentNode] = 2
      notifyParent(parentNode)

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

Each source starts with one flip at its section length.
A confluence reading takes the shortest arriving stream.
The parent learns about a change through the recursive notification.

**Sweep and output.** The driver orders sources by length and answers each at its threshold.

```nim
proc solveRiverSystem() =
  let confluenceCount = parentLabels.len - sourceCount
  let nodeCount = sourceCount + confluenceCount
  childLists = newSeq[seq[int]](nodeCount)
  for nodeIndex in 0 .. nodeCount - 1:
    childLists[nodeIndex] = newSeq[int](0)
  for nodeIndex in 0 .. nodeCount - 1:
    let downstream = parentNodeOf(nodeIndex)
    if downstream != -1:
      childLists[downstream].add nodeIndex
  var distanceToSea = newSeq[int64](nodeCount)
  var pendingNodes = newSeq[int](0)
  for nodeIndex in 0 .. nodeCount - 1:
    if parentNodeOf(nodeIndex) == -1:
      distanceToSea[nodeIndex] = edgeLengths[nodeIndex]
      pendingNodes.add nodeIndex
  while pendingNodes.len > 0:
    let lastIndex = pendingNodes.len - 1
    let currentNode = pendingNodes[lastIndex]
    pendingNodes.setLen(lastIndex)
    for downstreamNode in childLists[currentNode]:
      distanceToSea[downstreamNode] = distanceToSea[currentNode] + edgeLengths[downstreamNode]
      pendingNodes.add downstreamNode
  nodeStates = newSeq[int](nodeCount)
  activeChildren = newSeq[int](nodeCount)
  flowLengths = newSeq[int64](nodeCount)
  for nodeIndex in 0 .. nodeCount - 1:
    if nodeIndex < sourceCount:
      nodeStates[nodeIndex] = 1
    else:
      nodeStates[nodeIndex] = 0
    activeChildren[nodeIndex] = childLists[nodeIndex].len
    flowLengths[nodeIndex] = 0
  eventTimes.setLen(0)
  eventNodes.setLen(0)
  for nodeIndex in 0 .. sourceCount - 1:
    pushEvent(edgeLengths[nodeIndex], nodeIndex)
  longCount = int64(sourceCount)
  var sourceOrder = newSeq[int](sourceCount)
  for nodeIndex in 0 .. sourceCount - 1:
    sourceOrder[nodeIndex] = nodeIndex
  sourceOrder.sort(proc(leftIndex: int, rightIndex: int): int =
    if distanceToSea[leftIndex] < distanceToSea[rightIndex]:
      return -1
    if distanceToSea[leftIndex] > distanceToSea[rightIndex]:
      return 1
    return 0)
  var ranks = newSeq[int64](sourceCount)
  var answerIndex = 0
  while answerIndex < sourceCount:
    let targetLength = distanceToSea[sourceOrder[answerIndex]]
    sweepLength = targetLength
    while eventTimes.len > 0 and eventTimes[0] <= targetLength:
      var flipTime: int64 = 0
      var flippedNode = 0
      popEvent(flipTime, flippedNode)
      if nodeStates[flippedNode] == 1:
        nodeStates[flippedNode] = 2
        longCount -= 1
        notifyParent(flippedNode)
    while answerIndex < sourceCount and distanceToSea[sourceOrder[answerIndex]] == targetLength:
      ranks[sourceOrder[answerIndex]] = longCount + 1
      answerIndex += 1
  for sourceIndex in 0 .. sourceCount - 1:
    appendOutput($(ranks[sourceIndex]))
    outputBuffer.add '\n'

proc readRiverSystem(): bool =
  if not hasNextToken(inputData, scanPos):
    return false
  let firstToken = nextToken(inputData, scanPos)
  let nextCountToken = nextToken(inputData, scanPos)
  sourceCount = decimalValue(firstToken)
  let confluenceCount = decimalValue(nextCountToken)
  let nodeCount = sourceCount + confluenceCount
  parentLabels = newSeq[int](nodeCount)
  edgeLengths = newSeq[int64](nodeCount)
  for nodeIndex in 0 .. nodeCount - 1:
    let downstreamToken = nextToken(inputData, scanPos)
    let distanceToken = nextToken(inputData, scanPos)
    let downstream = int(base64Value(downstreamToken))
    parentLabels[nodeIndex] = downstream - 1
    edgeLengths[nodeIndex] = base64Value(distanceToken)
  return true

while readRiverSystem():
  solveRiverSystem()
stdout.write outputBuffer
outputBuffer.setLen 0
```

Distances to the sea come from one traversal of the tree.
Events with flip value at most `L` are processed before answering rivers of length `L`.
Ranks are stored by source index, then written in input order.

## Complexity

The tree traversal is linear, and each state change costs one heap operation.

| phase | time | space |
|---|---|---|
| input read | one pass over all nodes | one input string |
| tree traversal | one pass over n + m nodes | children and distance arrays |
| source sort | one sort of n lengths | order and rank arrays |
| sweep | one push and pop per state change | heap of flip values |
| output | one line per source | block buffer |

| measure | Big O |
|---|---|
| time | O((n + m) log n) |
| space | O(n + m) |

Testing every naming scheme for every river would grow quadratically or worse. The sweep changes each node state once and answers all rivers in one ordered pass. Short takeaway: one threshold sweep replaces all naming schemes.
