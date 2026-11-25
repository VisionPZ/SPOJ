# QTREE — Query on a tree (SPOJ)

<https://www.spoj.com/problems/QTREE/>

## Problem

A tree has numbered edges; commands change a cost or ask for the largest cost on the path between two nodes. The program answers every question in command order.

Input starts with the test count. Each test gives the node count, then `N - 1` lines with two endpoints and one cost, then commands ending with `DONE`. A blank line separates tests. Output holds one integer per `QUERY` command, on its own line.

The statement bounds are:

| Item | Bound |
|---|---|
| test cases `t` | at most 20 |
| nodes `N` | at most 10000 |
| edge cost `c` | at most 1000000 |
| edge count | `N - 1` per test |
| judge limit | 1000 ms, 1536 MB |

The node count drives the build cost, and the command count drives the query cost.

The sample input:

```
1

3
1 2 1
2 3 2
QUERY 1 2
CHANGE 1 3
QUERY 1 2
DONE
```

The sample output:

```
1
3
```

## Idea

Cut the tree into long strands so every path becomes a few straight runs. Think of folding a road map into strips: you follow one strip at a time and switch strips only a few times.

Heavy-light decomposition names this trick. One depth-first pass picks the child with the largest subtree at each node. Strands that follow those heavy children are chains, and any root-to-node path crosses at most log N chains. Nodes of one chain sit in consecutive slots of one array, and a max tree over those slots answers interval questions.

A `QUERY` reads at most log N intervals, each in log N steps. A `CHANGE` writes one slot and walks log N levels up the max tree. Walking the path node by node costs O(N) per question, so a long chain makes the naive way slow.

One slot array plus a max tree replaces every path walk.

## Why It Works

Four facts carry the proof.

1. A node keeps one heavy child, the child with the largest subtree. Each move to a light child at least halves the subtree size, so a root path crosses at most log N light edges.
2. Nodes on one chain receive consecutive positions. A chain piece is therefore one interval in the slot array.
3. Each slot stores the cost of the edge from that node to its parent. The root slot stores zero, so a query inside one chain skips the common ancestor's slot.
4. A max tree returns the largest value in an interval in log N steps. A point change stops as soon as its parent value stops moving.

The arrays that make this work:

| Term | Meaning |
|---|---|
| `subtreeSize` | node count below a node, used to pick `heavyChild` |
| `chainHead` | first node of the strand that contains a node |
| `chainPosition` | slot index of a node, consecutive along a strand |
| `edgeCostAtNode` | edge cost stored at the deeper end of an edge |
| `deeperNodeOfEdge` | node where a numbered edge is stored |
| `segmentTree` | max tree over the slot array |

These arrays turn a tree path into a handful of interval maximum queries.

A script-traced example on the statement sample:

```
edges: 1-2 cost 1, 2-3 cost 2
depths: 1=0 2=1 3=2
chain heads: 1=1 2=1 3=1
positions: 1=0 2=1 3=2
cost at node: 1=0 2=1 3=2
segment leaves: [0, 1, 2]
QUERY 1 2: same head, read slots 1..1 -> 1
CHANGE 1 3: edge 1 ends at node 2, slot 1 becomes 3
segment leaves: [0, 3, 2]
QUERY 1 2: same head, read slots 1..1 -> 3
```

The trace gives the same two answers as the sample output.

## Code

**Sizes and storage.** Fixed arrays hold every tree of the legal size.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 17
const maxNodeCount = 10000
const maxEdgeCount = 10000
const maxAdjacencyEntries = 2 * maxEdgeCount
const segmentBase = 16384
const segmentCellCount = 2 * segmentBase
```

The segment base is 16384, the first power of two above 10000. Leaves start there, so an interval becomes two array indexes. The arrays are shared by all test cases.

**Token readers.** Both commands and numbers come from one buffered string.

```nim
proc nextInt(data: string, pos: var int): int =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

proc nextWord(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  let wordStart = pos
  while pos < data.len and data[pos] > ' ':
    pos += 1
  return data[wordStart .. pos - 1]
```

The scan position is a `var` parameter, so it survives across calls. `nextWord` skips the blank line between tests along with all other whitespace. The digit scan builds values without creating token objects.

**Chain building.** Two depth-first walks assign parents, then chain heads.

```nim
proc measureSubtree(nodeIndex, parentIndex: int) =
  parentNode[nodeIndex] = parentIndex
  subtreeSize[nodeIndex] = 1
  heavyChild[nodeIndex] = 0
  var edgeCursor = adjacencyHead[nodeIndex]
  while edgeCursor != 0:
    let neighborNode = adjacencyTo[edgeCursor]
    if neighborNode != parentIndex:
      let weightId = adjacencyEdgeId[edgeCursor]
      nodeDepth[neighborNode] = nodeDepth[nodeIndex] + 1
      edgeCostAtNode[neighborNode] = edgeWeight[weightId]
      deeperNodeOfEdge[weightId] = neighborNode
      measureSubtree(neighborNode, nodeIndex)
      subtreeSize[nodeIndex] += subtreeSize[neighborNode]
      if heavyChild[nodeIndex] == 0 or subtreeSize[neighborNode] > subtreeSize[heavyChild[nodeIndex]]:
        heavyChild[nodeIndex] = neighborNode
    edgeCursor = adjacencyNext[edgeCursor]

proc decomposeChain(nodeIndex, headNode: int) =
  chainHead[nodeIndex] = headNode
  chainPosition[nodeIndex] = nextPosition
  nodeAtPosition[nextPosition] = nodeIndex
  nextPosition += 1
  if heavyChild[nodeIndex] != 0:
    decomposeChain(heavyChild[nodeIndex], headNode)
  var edgeCursor = adjacencyHead[nodeIndex]
  while edgeCursor != 0:
    let neighborNode = adjacencyTo[edgeCursor]
    if neighborNode != parentNode[nodeIndex] and neighborNode != heavyChild[nodeIndex]:
      decomposeChain(neighborNode, neighborNode)
    edgeCursor = adjacencyNext[edgeCursor]
```

The first walk visits N nodes and fills the edge cost at each deeper endpoint. The second walk visits heavy children first, so one chain occupies consecutive slots. Each walk costs O(N).

**Max tree.** Leaves hold slot costs, and internal cells hold maxima.

```nim
proc buildSegmentTree(nodeCount: int) =
  for cellIndex in segmentBase .. segmentCellCount:
    segmentTree[cellIndex] = 0
  for nodeIndex in 1 .. nodeCount:
    segmentTree[segmentBase + chainPosition[nodeIndex]] = edgeCostAtNode[nodeIndex]
  var cellIndex = segmentBase - 1
  while cellIndex >= 1:
    segmentTree[cellIndex] = max(segmentTree[2 * cellIndex], segmentTree[2 * cellIndex + 1])
    cellIndex -= 1

proc updateSegment(positionValue, weightValue: int) =
  var cellIndex = segmentBase + positionValue
  segmentTree[cellIndex] = weightValue
  cellIndex = cellIndex div 2
  while cellIndex >= 1:
    let mergedValue = max(segmentTree[2 * cellIndex], segmentTree[2 * cellIndex + 1])
    if segmentTree[cellIndex] == mergedValue: break
    segmentTree[cellIndex] = mergedValue
    cellIndex = cellIndex div 2

proc querySegment(leftPosition, rightPosition: int): int =
  var leftCell = segmentBase + leftPosition
  var rightCell = segmentBase + rightPosition
  result = 0
  while leftCell <= rightCell:
    if (leftCell and 1) == 1:
      if segmentTree[leftCell] > result: result = segmentTree[leftCell]
      leftCell += 1
    if (rightCell and 1) == 0:
      if segmentTree[rightCell] > result: result = segmentTree[rightCell]
      rightCell -= 1
    leftCell = leftCell div 2
    rightCell = rightCell div 2
```

Clearing starts at `segmentBase`, so past slot values cannot leak into the next test. `updateSegment` stops early once a parent keeps its value. `querySegment` walks two indexes toward each other and reads O(log N) cells.

**Path maximum.** The query climbs chains until both ends share a head.

```nim
proc queryPath(firstNode, secondNode: int): int =
  var nodeA = firstNode
  var nodeB = secondNode
  result = 0
  while chainHead[nodeA] != chainHead[nodeB]:
    if nodeDepth[chainHead[nodeA]] < nodeDepth[chainHead[nodeB]]:
      let swapNode = nodeA
      nodeA = nodeB
      nodeB = swapNode
    let headPosition = chainPosition[chainHead[nodeA]]
    let endPosition = chainPosition[nodeA]
    let chainBest = querySegment(headPosition, endPosition)
    if chainBest > result: result = chainBest
    nodeA = parentNode[chainHead[nodeA]]
  if nodeDepth[nodeA] > nodeDepth[nodeB]:
    let swapNode = nodeA
    nodeA = nodeB
    nodeB = swapNode
  let chainBest = querySegment(chainPosition[nodeA] + 1, chainPosition[nodeB])
  if chainBest > result: result = chainBest
```

The deeper head is always consumed first. The final interval starts one slot past the shared ancestor, because that slot belongs to the edge above the path.

**Driver.** One input read, one output buffer, block writes.

```nim
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
var outputBuffer = ""
let caseCount = nextInt(inputData, scanPos)

for caseIndex in 0 .. caseCount - 1:
  let nodeCount = nextInt(inputData, scanPos)
  adjacencyCount = 0
  for nodeIndex in 1 .. nodeCount:
    adjacencyHead[nodeIndex] = 0
    heavyChild[nodeIndex] = 0
  for weightId in 1 .. nodeCount - 1:
    edgeWeight[weightId] = 0
    deeperNodeOfEdge[weightId] = 0
  nodeDepth[1] = 0
  for weightId in 1 .. nodeCount - 1:
    let fromNode = nextInt(inputData, scanPos)
    let toNode = nextInt(inputData, scanPos)
    let costValue = nextInt(inputData, scanPos)
    edgeWeight[weightId] = costValue
    appendAdjacency(fromNode, toNode, weightId)
    appendAdjacency(toNode, fromNode, weightId)
  measureSubtree(1, 0)
  nextPosition = 0
  decomposeChain(1, 1)
  buildSegmentTree(nodeCount)
  while scanPos < inputData.len:
    let commandWord = nextWord(inputData, scanPos)
    if commandWord == "DONE": break
    if commandWord == "QUERY":
      let firstNode = nextInt(inputData, scanPos)
      let secondNode = nextInt(inputData, scanPos)
      let answerValue = queryPath(firstNode, secondNode)
      outputBuffer.add $answerValue
      outputBuffer.add '\n'
      if outputBuffer.len >= flushBlockBytes:
        stdout.write outputBuffer
        outputBuffer.setLen 0
    elif commandWord == "CHANGE":
      let weightId = nextInt(inputData, scanPos)
      let newWeight = nextInt(inputData, scanPos)
      edgeWeight[weightId] = newWeight
      updateSegment(chainPosition[deeperNodeOfEdge[weightId]], newWeight)

stdout.write outputBuffer
outputBuffer.setLen 0
```

The command loop reads words, so the blank line and the word `DONE` need no special case. `CHANGE` finds the deeper node of an edge before writing its slot. The final write covers the remaining bytes of a small test.

## Complexity

Costs split into one build per test and one short walk per command.

| Phase | Time | Space |
|---|---|---|
| input read | one pass over the input bytes | input bytes |
| tree build | two walks over N nodes | arrays of N slots |
| one `QUERY` | O(log² N) interval reads | no extra storage |
| one `CHANGE` | O(log N) writes up the max tree | no extra storage |
| output | one write per block | block buffer |

The build runs once per test, while each command pays a logarithmic cost.

The overall bounds follow from the chain count and the max tree height.

| Measure | Big O |
|---|---|
| time per test | O(N + Q log² N) |
| space | O(N) |

A path walk costs O(N) per query, so a 10000-node chain needs thousands of steps where the max tree needs dozens. The max tree keeps both commands fast on a long chain.
