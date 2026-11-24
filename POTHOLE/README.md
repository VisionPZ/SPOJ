## Problem

Read a cave with chambers numbered from 1 at the top to n at the bottom. Every listed corridor goes from a chamber to a higher-numbered chamber, so routes run from chamber 1 to chamber n. Each speleologist needs a different corridor out of the top and a different corridor into the bottom. Print the largest number of speleologists that can train at once.

| Quantity | Bound |
| --- | --- |
| Test cases | not bounded in the statement |
| Chambers per cave | 2 to 200 |
| Corridors from one chamber | 0 to n minus i |
| Time limit | 7000 ms |
| Memory limit | 1536 MB |

The small chamber count makes one flow computation per case cheap.

## Idea

Model the cave as a flow network. Each corridor becomes a directed edge toward the higher-numbered chamber. Edges out of chamber 1 carry capacity one, and edges into chamber n carry capacity one. Interior corridors carry infinite capacity because speleologists can share them. Max flow then counts the largest feasible set of routes. Dinic's method builds a level graph, the subgraph of shortest remaining paths, and pushes a blocking flow through it.

Each phase costs O(E) time for at most about n squared edges.

## Why It Works

Every corridor goes from a smaller chamber number to a larger one, so each route is a path from 1 to n. Capacity one on edges from chamber 1 forces distinct starting corridors. Capacity one on edges into chamber n forces distinct ending corridors. Infinite capacity on interior edges never blocks a shared corridor. Flow is integral, so the maximum equals a whole number of routes.

Each corridor adds a forward edge and a reverse edge in adjacent slots.

- Forward update: `edgeCap[edgeIndex] -= pushed`.
- Reverse update: `edgeCap[edgeIndex xor 1] += pushed`.
- The exclusive-or bit selects the other edge of the pair.

The generator computes this trace for the sample cave.

    path 1: 1 -> 3 -> 9 -> 12  bottleneck 1
    path 2: 1 -> 4 -> 11 -> 12  bottleneck 1
    path 3: 1 -> 2 -> 8 -> 12  bottleneck 1
    total flow: 3

Only three paths fit. Corridors through chamber 2 and chamber 5 both need the single exit from chamber 8.

## Code

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const infiniteCapacity = 1000000000

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int(data[position]) - firstDigitValue
    position += 1
  return value
```

The read loop ends at end of input and stores one buffer. The scanner skips blank lines between cases. Digit parsing costs one pass over the input.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The buffer flushes every 256 KiB, never per answer. Reusing it avoids a fresh allocation per flush. Output cost is one write per block.

```nim
var headEdge: seq[int]
var edgeTo: seq[int]
var edgeCap: seq[int]
var edgeNext: seq[int]
var edgeCount = 0
var levelNode: seq[int]
var iterEdge: seq[int]
var queueNode: seq[int]
var nodeTotal = 0

proc addCorridor(fromNode, toNode, capacity: int) =
  edgeTo[edgeCount] = toNode
  edgeCap[edgeCount] = capacity
  edgeNext[edgeCount] = headEdge[fromNode]
  headEdge[fromNode] = edgeCount
  edgeCount += 1
  edgeTo[edgeCount] = fromNode
  edgeCap[edgeCount] = 0
  edgeNext[edgeCount] = headEdge[toNode]
  headEdge[toNode] = edgeCount
  edgeCount += 1
```

Forward star arrays hold the residual graph in flat memory. The reverse edge sits at the next index, so exclusive-or finds it. A corridor with duplicate numbers simply adds another edge.

```nim
proc buildLevels(sourceNode, sinkNode: int): bool =
  for i in 0..nodeTotal:
    levelNode[i] = -1
  var queueHead = 0
  var queueTail = 0
  levelNode[sourceNode] = 0
  queueNode[queueTail] = sourceNode
  queueTail += 1
  while queueHead < queueTail:
    let currentNode = queueNode[queueHead]
    queueHead += 1
    var edgeIndex = headEdge[currentNode]
    while edgeIndex != -1:
      let nextNode = edgeTo[edgeIndex]
      if edgeCap[edgeIndex] > 0 and levelNode[nextNode] == -1:
        levelNode[nextNode] = levelNode[currentNode] + 1
        queueNode[queueTail] = nextNode
        queueTail += 1
      edgeIndex = edgeNext[edgeIndex]
  return levelNode[sinkNode] != -1
```

Breadth-first search visits each chamber once, so the queue fits in n plus one slots. Ignoring zero-capacity edges keeps the level graph correct after updates. This pass costs O(E).

```nim
proc pushFlow(currentNode, sinkNode, limit: int): int =
  if currentNode == sinkNode:
    return limit
  var edgeIndex = iterEdge[currentNode]
  while edgeIndex != -1:
    let nextNode = edgeTo[edgeIndex]
    if edgeCap[edgeIndex] > 0 and levelNode[nextNode] == levelNode[currentNode] + 1:
      let pushed = pushFlow(nextNode, sinkNode, min(limit, edgeCap[edgeIndex]))
      if pushed > 0:
        edgeCap[edgeIndex] -= pushed
        edgeCap[edgeIndex xor 1] += pushed
        return pushed
    edgeIndex = edgeNext[edgeIndex]
    iterEdge[currentNode] = edgeIndex
  return 0

proc maxFlow(sourceNode, sinkNode: int): int =
  result = 0
  while buildLevels(sourceNode, sinkNode):
    for i in 0..nodeTotal:
      iterEdge[i] = headEdge[i]
    while true:
      let pushed = pushFlow(sourceNode, sinkNode, infiniteCapacity)
      if pushed == 0:
        break
      result += pushed
```

The iterator pointer skips exhausted edges, so one phase stays linear in E. The recursion depth stops at n, the number of chambers. Each phase ends when no more flow reaches the sink.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let chamberCount = nextInt(inputData, scanPos)
  nodeTotal = chamberCount
  headEdge.setLen(chamberCount + 1)
  levelNode.setLen(chamberCount + 1)
  iterEdge.setLen(chamberCount + 1)
  queueNode.setLen(chamberCount + 1)
  for i in 0..chamberCount:
    headEdge[i] = -1
  edgeTo.setLen(2 * (chamberCount * chamberCount + 2))
  edgeCap.setLen(2 * (chamberCount * chamberCount + 2))
  edgeNext.setLen(2 * (chamberCount * chamberCount + 2))
  edgeCount = 0
  for fromChamber in 1..<chamberCount:
    let corridorCount = nextInt(inputData, scanPos)
    for j in 0..<corridorCount:
      let toChamber = nextInt(inputData, scanPos)
      var capacity = infiniteCapacity
      if fromChamber == 1 or toChamber == chamberCount:
        capacity = 1
      addCorridor(fromChamber, toChamber, capacity)
  appendOutput($(maxFlow(1, chamberCount)))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The outer loop runs once per case, and the inner loops read exactly the listed corridors. Edge arrays get n squared slots, which covers every possible corridor and its reverse. Capacity one applies only to corridors leaving the top or entering the bottom.

## Complexity

Reading and parsing cost O(E) time per case and one input buffer of space. The flow arrays use O(n squared) slots per case. A phase costs O(nE) time, and at most n phases run, so one case costs O(n squared E). Since E is at most n times n minus one over two, the total is O(t n to the fourth). Trying every subset of corridors would grow far faster than this flow pass.
