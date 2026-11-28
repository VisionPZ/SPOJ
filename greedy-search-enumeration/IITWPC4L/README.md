# IITWPC4L — Maggu and Mystery (SPOJ)
<https://www.spoj.com/problems/IITWPC4L/>

## Problem

Each door's key number can move by at most its power in one operation, and operations can stack. Find the fewest operations needed to give at least d doors distinct key numbers.

The first line holds T. Each case starts with n and d, then one line of n lock keys, then one line of n powers.
Print one integer per case, the minimum number of operations.

The bounds are:

| item | bound |
|---|---|
| test cases T | 1 to 20 |
| doors n | 1 to 50 |
| doors to open d | 1 to n |
| lock key value | 1 to 1000 |
| power per door | 1 to 5 |
| judge limit | 10000 ms, 1536 MB |

Door counts allow a bipartite flow network.

Sample input:

```
4
3 2
5 1 3
1 1 1
3 3
1 1 1
2 1 1
4 4
1 1 1 2
1 2 1 1
4 3
1 1 1 2
1 2 1 1
```

The four cases open two, three, four and three doors.

Sample output:

```
0
2
2
1
```

The first case needs no operation at all.

## Idea

Think of each door as a drawer holding the keys it can reach, and pick distinct keys for the cheapest drawers.

Build a min-cost flow network. A source feeds every door, each door feeds reachable key values, and each key feeds the sink with unit capacity. One unit of flow opens one door at one distinct key. Successive shortest augmenting paths give the least total operations. Trying every door assignment grows exponentially.

One flow per case gives the minimum.

## Why It Works

1. One operation moves a door by at most its power.
2. A key at distance delta costs ceil(delta divided by power) operations.
3. A key node carries one unit, so two doors cannot share a key.
4. Sending d units from source to sink opens d doors.
5. Each augmenting path adds the cheapest available unit at that stage.
6. Residual edges let an earlier door move when a better path appears.
7. The key range spans the lowest lock minus 5d to the highest lock plus 5d.

The main names are:

| term | meaning |
|---|---|
| `lockKeys` | starting key number on each door |
| `movePowers` | largest shift one operation can make |
| `addEdge` | adds a forward edge and its reverse residual edge |
| `findCheapestPath` | finds one shortest augmenting path |
| `edgeCapacity` | remaining units on each directed edge |
| `edgeCostValue` | operations charged by that edge |
| `totalOperations` | accumulated answer for one case |

The ring queue keeps path search bounded by the node count.

The generator produced this plan for the second sample case:

| door | lock key | power | chosen key | operations |
|---|---|---|---|---|
| 1 | 1 | 2 | -1 | 1 |
| 2 | 1 | 1 | 1 | 0 |
| 3 | 1 | 1 | 2 | 1 |

The three chosen keys are distinct and cost two operations.

The ceiling division handles every power value. Keys outside the chosen range never improve the answer, since moving one inward lowers its cost.

## Code

**Input and output helpers.** The graph arrays are global so every procedure can share them.

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var adjacencyHead = newSeq[int](0)
var edgeTarget = newSeq[int](0)
var edgeNext = newSeq[int](0)
var edgeCapacity = newSeq[int](0)
var edgeCostValue = newSeq[int](0)
var nodeDistance = newSeq[int64](0)
var inQueue = newSeq[bool](0)
var parentNode = newSeq[int](0)
var parentEdge = newSeq[int](0)
var pathQueue = newSeq[int](0)
var queueCapacity = 0

```

The integer scanner skips all separators.
One output buffer collects the case answers.
Raw stdout writes happen only on buffer flush.

**Flow graph and shortest path.** Each edge gets a reverse edge with negative cost.

```nim
proc addEdge(fromNode, toNode, capacity, costValue: int) =
  let forwardIndex = edgeTarget.len
  edgeTarget.add toNode
  edgeCapacity.add capacity
  edgeCostValue.add costValue
  edgeNext.add adjacencyHead[fromNode]
  adjacencyHead[fromNode] = forwardIndex
  edgeTarget.add fromNode
  edgeCapacity.add 0
  edgeCostValue.add -costValue
  edgeNext.add adjacencyHead[toNode]
  adjacencyHead[toNode] = forwardIndex + 1

proc findCheapestPath(sourceNode, sinkNode: int): bool =
  for nodeIndex in 0 .. adjacencyHead.len - 1:
    nodeDistance[nodeIndex] = high(int64) div 4
    inQueue[nodeIndex] = false
  nodeDistance[sourceNode] = 0
  var queueHead = 0
  var queueTail = 0
  pathQueue[queueTail] = sourceNode
  queueTail = (queueTail + 1) mod queueCapacity
  inQueue[sourceNode] = true
  while queueHead != queueTail:
    let currentNode = pathQueue[queueHead]
    queueHead = (queueHead + 1) mod queueCapacity
    inQueue[currentNode] = false
    var edgeIndex = adjacencyHead[currentNode]
    while edgeIndex != -1:
      if edgeCapacity[edgeIndex] > 0:
        let nextNode = edgeTarget[edgeIndex]
        let candidateDistance = nodeDistance[currentNode] + int64(edgeCostValue[edgeIndex])
        if candidateDistance < nodeDistance[nextNode]:
          nodeDistance[nextNode] = candidateDistance
          parentNode[nextNode] = currentNode
          parentEdge[nextNode] = edgeIndex
          if not inQueue[nextNode]:
            pathQueue[queueTail] = nextNode
            queueTail = (queueTail + 1) mod queueCapacity
            inQueue[nextNode] = true
      edgeIndex = edgeNext[edgeIndex]
  return nodeDistance[sinkNode] < high(int64) div 4

```

`addEdge` stores capacity and cost in parallel arrays.
`findCheapestPath` relaxes edges with a ring queue.
Parent arrays recover the path after each search.

**Case solve.** The network links source, doors, keys and sink, then sends d units.

```nim
let testCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. testCount - 1:
  let doorCount = nextInt(inputData, scanPos)
  let requiredDoors = nextInt(inputData, scanPos)
  var lockKeys = newSeq[int](doorCount)
  var movePowers = newSeq[int](doorCount)
  var lowestKey = 1000000
  var highestKey = -1000000
  for doorIndex in 0 .. doorCount - 1:
    lockKeys[doorIndex] = nextInt(inputData, scanPos)
    if lockKeys[doorIndex] < lowestKey:
      lowestKey = lockKeys[doorIndex]
    if lockKeys[doorIndex] > highestKey:
      highestKey = lockKeys[doorIndex]
  for doorIndex in 0 .. doorCount - 1:
    movePowers[doorIndex] = nextInt(inputData, scanPos)
  let keyStart = lowestKey - 5 * requiredDoors
  let keyCount = highestKey + 5 * requiredDoors - keyStart + 1
  let sourceNode = 0
  let firstDoorNode = 1
  let firstKeyNode = 1 + doorCount
  let sinkNode = firstKeyNode + keyCount
  let nodeCount = sinkNode + 1
  adjacencyHead.setLen(nodeCount)
  for nodeIndex in 0 .. nodeCount - 1:
    adjacencyHead[nodeIndex] = -1
  edgeTarget.setLen(0)
  edgeNext.setLen(0)
  edgeCapacity.setLen(0)
  edgeCostValue.setLen(0)
  for doorIndex in 0 .. doorCount - 1:
    addEdge(sourceNode, firstDoorNode + doorIndex, 1, 0)
  for keyIndex in 0 .. keyCount - 1:
    addEdge(firstKeyNode + keyIndex, sinkNode, 1, 0)
  for doorIndex in 0 .. doorCount - 1:
    let baseKey = lockKeys[doorIndex]
    let doorPower = movePowers[doorIndex]
    for keyIndex in 0 .. keyCount - 1:
      let keyValue = keyStart + keyIndex
      let keyDistance = if keyValue > baseKey: keyValue - baseKey else: baseKey - keyValue
      let operationCost = (keyDistance + doorPower - 1) div doorPower
      addEdge(firstDoorNode + doorIndex, firstKeyNode + keyIndex, 1, operationCost)
  nodeDistance.setLen(nodeCount)
  inQueue.setLen(nodeCount)
  parentNode.setLen(nodeCount)
  parentEdge.setLen(nodeCount)
  queueCapacity = nodeCount + 1
  pathQueue.setLen(queueCapacity)
  var totalOperations: int64 = 0
  var openedDoors = 0
  while openedDoors < requiredDoors and findCheapestPath(sourceNode, sinkNode):
    var currentNode = sinkNode
    while currentNode != sourceNode:
      let viaEdge = parentEdge[currentNode]
      edgeCapacity[viaEdge] = edgeCapacity[viaEdge] - 1
      edgeCapacity[viaEdge xor 1] = edgeCapacity[viaEdge xor 1] + 1
      currentNode = parentNode[currentNode]
    totalOperations = totalOperations + nodeDistance[sinkNode]
    openedDoors += 1
  appendOutput($totalOperations)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

```

Door to key costs use ceiling division.
Each augmenting path adds one opened door.
The final cost is printed as one integer line.

## Complexity

The work splits into phases:

| phase | time | space |
|---|---|---|
| input read | one pass over door data | one input string |
| graph build | one step per door-key pair | two edge arrays |
| augmenting paths | d shortest path searches | distance and parent arrays |
| output | one line per case | block buffer |

The path searches dominate the work.

The asymptotic costs are:

| measure | Big O |
|---|---|
| time | O(d times nodes times edges) worst case |
| space | O(nodes plus edges) |

Enumerating assignments of doors to keys grows exponentially.

Min-cost flow reuses residual paths and keeps every case small.
