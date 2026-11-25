# MPART — Group Partition (SPOJ)

<https://www.spoj.com/problems/MPART/>

## Problem

Place every friend into one of the groups that friend accepts, and make the largest group as small as possible. Names identify friends but do not affect the grouping.

A case starts with N and M, the friend count and group count. The next N lines hold a name followed by allowed group labels from 0 to M-1. A line 0 0 ends the input. Print one integer per case: the smallest possible size of the largest group.

| Item | Bound |
|---|---|
| Friends N | up to 1000 |
| Groups M | up to 500 |
| Test cases | up to 20 |
| Judge limit | 1000 ms, 1536 MB |

Input is large, so the program parses each line without storing names.

Sample input:

```
3 2 
John 0 1 
Rose 1 
Mary 1 
5 4 
ACM 1 2 3 
ICPC 0 1  
Asian 0 2 3 
Regional 1 2 
ShangHai 0 2 
0 0 
```

Sample output:

```
2
2
```

## Idea

Testing a fixed group size works like checking whether a set of equal-sized boxes can hold all items.

Binary search the largest allowed group size. For a candidate size K, build a flow network. The source sends one unit to each friend. Each friend has unit edges to allowed groups. Each group sends capacity K to the sink. A flow that moves one unit per friend exists exactly when the assignment fits. Dinic's algorithm finds that flow in O(E sqrt V) steps for this bipartite network.

## Why It Works

1. If size K works, every larger size also works, so binary search applies.
2. A unit edge from the source to a friend forces that friend to be assigned once.
3. A unit edge from a friend to a group allows exactly one group choice.
4. Capacity K on a group edge limits that group to K friends.
5. Saturating all source edges gives a valid assignment with largest group at most K.

| Term | Meaning |
|---|---|
| `canAssign` | flow test for one candidate size |
| `capacityLimit` | tested group size K |
| `groupEdgeIndex` | edge storing capacity K for each group |
| `levelValues` | breadth-first levels for Dinic |

The table names the parts of one feasibility test.

A script trace for the first sample case:

```
K = 1: Rose and Mary both need group 1, which holds one friend -> infeasible
K = 2: John takes group 0, Rose and Mary take group 1 -> feasible
binary search result 2
```

The trace matches the first sample line.

## Code

**Input and helpers.** The scanner reads headers, skips names, and keeps each friend's allowed groups on one line.

```nim
const flushBlockBytes = 1 shl 17

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

proc isLetterCharacter(value: char): bool =
  return (value >= 'A' and value <= 'Z') or (value >= 'a' and value <= 'z')
```

Names contain letters only, so digit scanning stops at the name.
The line loop ends each friend's group list.
Trailing spaces on a line are skipped without crossing the newline.

**Flow network.** The graph stores forward and reverse edges in parallel arrays.

```nim
var nodeCount = 0
var sourceNode = 0
var sinkNode = 0
var friendBase = 1
var groupBase = 1
var edgeTarget = newSeq[int]()
var edgeNext = newSeq[int]()
var edgeCapacity = newSeq[int]()
var baseCapacity = newSeq[int]()
var nodeHead = newSeq[int]()
var groupEdgeIndex = newSeq[int]()
var levelValues = newSeq[int]()
var cursorEdges = newSeq[int]()
var queueNodes = newSeq[int]()

proc addEdge(fromNode: int, toNode: int, capacityValue: int) =
  let forwardIndex = edgeTarget.len
  edgeTarget.add toNode
  edgeCapacity.add capacityValue
  edgeNext.add nodeHead[fromNode]
  nodeHead[fromNode] = forwardIndex
  edgeTarget.add fromNode
  edgeCapacity.add 0
  edgeNext.add nodeHead[toNode]
  nodeHead[toNode] = forwardIndex + 1

proc buildLevels(): bool =
  for nodeIndex in 0 .. nodeCount - 1:
    levelValues[nodeIndex] = -1
  var queueHead = 0
  var queueTail = 0
  levelValues[sourceNode] = 0
  queueNodes[queueTail] = sourceNode
  queueTail += 1
  while queueHead < queueTail:
    let currentNode = queueNodes[queueHead]
    queueHead += 1
    var edgeIndex = nodeHead[currentNode]
    while edgeIndex != -1:
      if edgeCapacity[edgeIndex] > 0 and levelValues[edgeTarget[edgeIndex]] < 0:
        levelValues[edgeTarget[edgeIndex]] = levelValues[currentNode] + 1
        queueNodes[queueTail] = edgeTarget[edgeIndex]
        queueTail += 1
      edgeIndex = edgeNext[edgeIndex]
  return levelValues[sinkNode] >= 0
```

Reverse edges sit next to their forward edge.
Levels come from one breadth-first pass over residual edges.
The queue array holds each node once.

**Blocking flow.** Dinic pushes flow along level-respecting paths.

```nim
proc pushFlow(atNode: int, availableFlow: int): int =
  if atNode == sinkNode:
    return availableFlow
  var pushedTotal = 0
  while cursorEdges[atNode] != -1:
    let edgeIndex = cursorEdges[atNode]
    cursorEdges[atNode] = edgeNext[edgeIndex]
    if edgeCapacity[edgeIndex] > 0 and levelValues[edgeTarget[edgeIndex]] == levelValues[atNode] + 1:
      let nextFlow = pushFlow(edgeTarget[edgeIndex], min(availableFlow - pushedTotal, edgeCapacity[edgeIndex]))
      if nextFlow > 0:
        edgeCapacity[edgeIndex] -= nextFlow
        edgeCapacity[edgeIndex xor 1] += nextFlow
        pushedTotal += nextFlow
        if pushedTotal == availableFlow:
          break
  return pushedTotal

proc canAssign(capacityLimit: int, friendCount: int, groupCount: int): bool =
  for edgeIndex in 0 .. edgeCapacity.len - 1:
    edgeCapacity[edgeIndex] = baseCapacity[edgeIndex]
  for groupIndex in 0 .. groupCount - 1:
    edgeCapacity[groupEdgeIndex[groupIndex]] = capacityLimit
  var totalFlow = 0
  while buildLevels():
    for nodeIndex in 0 .. nodeCount - 1:
      cursorEdges[nodeIndex] = nodeHead[nodeIndex]
    while true:
      let flowBlock = pushFlow(sourceNode, friendCount - totalFlow)
      if flowBlock == 0:
        break
      totalFlow += flowBlock
      if totalFlow == friendCount:
        return true
  return false
```

A cursor skips edges already used at a node.
Base capacities are restored before each test.
Only the group-to-sink edges change with K.

**Case driver.** The graph is built once per case, then binary search reuses it.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while scanPos < inputData.len:
  let friendCount = nextInt(inputData, scanPos)
  let groupCount = nextInt(inputData, scanPos)
  if friendCount == 0 and groupCount == 0:
    break
  nodeCount = friendCount + groupCount + 2
  sourceNode = 0
  friendBase = 1
  groupBase = 1 + friendCount
  sinkNode = friendCount + groupCount + 1
  edgeTarget.setLen 0
  edgeNext.setLen 0
  edgeCapacity.setLen 0
  nodeHead = newSeq[int](nodeCount)
  for nodeIndex in 0 .. nodeCount - 1:
    nodeHead[nodeIndex] = -1
  groupEdgeIndex = newSeq[int](groupCount)
  for friendIndex in 0 .. friendCount - 1:
    addEdge(sourceNode, friendBase + friendIndex, 1)
  for groupIndex in 0 .. groupCount - 1:
    let forwardIndex = edgeTarget.len
    addEdge(groupBase + groupIndex, sinkNode, 1)
    groupEdgeIndex[groupIndex] = forwardIndex
  for friendIndex in 0 .. friendCount - 1:
    while scanPos < inputData.len and inputData[scanPos] != '\n':
      scanPos += 1
    if scanPos < inputData.len:
      scanPos += 1
    while scanPos < inputData.len and isLetterCharacter(inputData[scanPos]):
      scanPos += 1
    while scanPos < inputData.len:
      while scanPos < inputData.len and inputData[scanPos] == ' ':
        scanPos += 1
      if scanPos >= inputData.len or inputData[scanPos] == '\n':
        break
      let groupLabel = nextInt(inputData, scanPos)
      addEdge(friendBase + friendIndex, groupBase + groupLabel, 1)
  baseCapacity = newSeq[int](edgeCapacity.len)
  for edgeIndex in 0 .. edgeCapacity.len - 1:
    baseCapacity[edgeIndex] = edgeCapacity[edgeIndex]
  levelValues = newSeq[int](nodeCount)
  cursorEdges = newSeq[int](nodeCount)
  queueNodes = newSeq[int](nodeCount)
  var lowBound = (friendCount + groupCount - 1) div groupCount
  var highBound = friendCount
  while lowBound < highBound:
    let middleValue = (lowBound + highBound) div 2
    if canAssign(middleValue, friendCount, groupCount):
      highBound = middleValue
    else:
      lowBound = middleValue + 1
  appendOutput($lowBound)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Friend and group nodes are numbered from the header values.
The lower bound rounds the average load upward.
Binary search stops after roughly ten flow tests.

## Complexity

The graph is built once; each binary-search step runs one Dinic search.

| Phase | Time | Space |
|---|---|---|
| Input parse | one pass over group labels | one input string |
| Graph build | one edge per allowed pair | edge arrays |
| Binary search | O(log N) flow tests | level and cursor arrays |
| Output | buffered writes | block buffer |

The table shows that flow tests dominate hard cases.

| Measure | Big O |
|---|---|
| Time | O(log N * E sqrt(N+M)) per case |
| Space | O(N + M + E) |

Trying every assignment would take exponential time, while the flow test stays polynomial.
