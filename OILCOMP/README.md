# OILCOMP — Oil Company (SPOJ)

<https://www.spoj.com/problems/OILCOMP/>

## Problem

Choose grid cells with the largest total reserve while forbidding any two chosen cells that share an edge. Print the best total for each map.

Input starts with the number of maps. Each map gives width W and height H, followed by H rows of W reserves. Output the case number and the maximum total.

| item | bound |
|---|---|
| width W | 1 to 20 |
| height H | 1 to 20 |
| reserve per cell | 0 to 9999 |
| judge limit | 2857 ms, 1536 MB |

Color the grid like a chessboard. Chosen black cells and chosen white cells never touch along an edge.

Sample input:

```
2
2 2
2 3
3 5
3 2
4 1 1
2 1 4
```

Sample output:

```
Case 1: 7
Case 2: 8
```

## Idea

View the grid as a checkerboard of black and white stones. Remove the cheapest set that blocks every touching pair. Pick cells by paying the least forbidden cost.

A checkerboard makes adjacent cells opposite colors. The grid graph is bipartite. The best chosen set is the total reserve minus a minimum weighted vertex cover. A flow network finds that cover with a min cut. The source reaches black cells with reserve capacity. White cells reach the sink with reserve capacity. Infinite edges cross board adjacencies.

Each flow edge is built once per map. A naive subset search would test almost 2^400 layouts. The flow gives the exact cover in polynomial time. Takeaway: convert choosing into cutting, then subtract the cut.

## Why It Works

1. Adjacent cells always have opposite chessboard parity.
2. A cut containing a black cell pays its reserve, so that cell joins the cover.
3. A cut containing a white cell pays its reserve for the same reason.
4. Infinite edges forbid a black cell outside the cut next to a white cell inside it.
5. The cut therefore describes a valid cover, and the min cut gives its least cost.
6. Chosen cells are exactly the cells left out of that cover.

| term | meaning |
|---|---|
| `totalOil` | sum of all reserves on the map |
| `minimumCover` | value of the minimum weighted vertex cover |
| `infiniteCapacity` | capacity that forbids crossing an adjacency |
| `levelValues` | breadth-first distances for Dinic blocking flows |

For the 2 by 2 sample, the total is 13. The two diagonal cells holding 2 and 5 can both be chosen, so the answer is 7 and the cover costs 6. The second sample totals 13, and a cover costing 5 leaves 8.

Infinite capacity exceeds any possible reserve sum, so no adjacency edge ever appears in a minimum cut.

## Code

**Input and output.** The driver reads every map and writes one answer line each.

```nim
const flushBlockBytes = 1 shl 17
const infiniteCapacity: int64 = 1_000_000_000_000

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
```

Each reserve is stored in the total and also assigned to a source or sink edge. Adjacent cells get an infinite edge from black to white.

**Flow core.** Dinic builds level layers, pushes blocking flow, and repeats until the sink is unreachable.

```nim
type FlowEdge = object
  target: int
  reverseIndex: int
  capacity: int64

var gridWidth = 0
var gridHeight = 0
var sourceNode = 0
var sinkNode = 0
var flowGraph: seq[seq[FlowEdge]]
var levelValues: seq[int]
var nextEdges: seq[int]

proc addFlowEdge(fromNode: int, toNode: int, capacity: int64) =
  let forwardIndex = flowGraph[fromNode].len
  let backwardIndex = flowGraph[toNode].len
  flowGraph[fromNode].add FlowEdge(target: toNode, reverseIndex: backwardIndex,
                                  capacity: capacity)
  flowGraph[toNode].add FlowEdge(target: fromNode, reverseIndex: forwardIndex,
                                 capacity: 0'i64)

proc buildLevels(): bool =
  for nodeIndex in 0 .. levelValues.len - 1:
    levelValues[nodeIndex] = -1
  var queue = newSeq[int](flowGraph.len)
  var head = 0
  var tail = 0
  levelValues[sourceNode] = 0
  queue[tail] = sourceNode
  tail += 1
  while head < tail:
    let nodeIndex = queue[head]
    head += 1
    for edge in flowGraph[nodeIndex]:
      if edge.capacity > 0'i64 and levelValues[edge.target] < 0:
        levelValues[edge.target] = levelValues[nodeIndex] + 1
        queue[tail] = edge.target
        tail += 1
  return levelValues[sinkNode] >= 0

proc pushFlow(nodeIndex: int, available: int64): int64 =
  if nodeIndex == sinkNode:
    return available
  while nextEdges[nodeIndex] < flowGraph[nodeIndex].len:
    let edgeIndex = nextEdges[nodeIndex]
    let edge = flowGraph[nodeIndex][edgeIndex]
    if edge.capacity > 0'i64 and levelValues[edge.target] == levelValues[nodeIndex] + 1:
      let pushed = pushFlow(edge.target, min(available, edge.capacity))
      if pushed > 0'i64:
        flowGraph[nodeIndex][edgeIndex].capacity -= pushed
        flowGraph[edge.target][edge.reverseIndex].capacity += pushed
        return pushed
    nextEdges[nodeIndex] += 1
  return 0'i64

proc maximumFlow(): int64 =
  var totalFlow = 0'i64
  while buildLevels():
    for nodeIndex in 0 .. nextEdges.len - 1:
      nextEdges[nodeIndex] = 0
    while true:
      let pushed = pushFlow(sourceNode, infiniteCapacity)
      if pushed == 0'i64:
        break
      totalFlow += pushed
  return totalFlow
```

Breadth-first search marks reachable nodes. The depth-first push sends flow along layer edges and updates reverse capacities. The loop ends when no augmenting path exists.

**Case setup.** The network is rebuilt for every map, then the cover is subtracted.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseNumber in 1 .. caseCount:
  gridWidth = nextInt(inputData, scanPos)
  gridHeight = nextInt(inputData, scanPos)
  let cellCount = gridWidth * gridHeight
  sourceNode = cellCount
  sinkNode = cellCount + 1
  flowGraph = newSeq[seq[FlowEdge]](cellCount + 2)
  for nodeIndex in 0 .. flowGraph.len - 1:
    flowGraph[nodeIndex] = newSeq[FlowEdge](0)
  var totalOil = 0'i64
  for row in 0 .. gridHeight - 1:
    for column in 0 .. gridWidth - 1:
      let reserve = nextInt(inputData, scanPos)
      totalOil += int64(reserve)
      let cellIndex = row * gridWidth + column
      if (row + column) mod 2 == 0:
        addFlowEdge(sourceNode, cellIndex, int64(reserve))
      else:
        addFlowEdge(cellIndex, sinkNode, int64(reserve))
      if column + 1 < gridWidth:
        let neighborIndex = row * gridWidth + column + 1
        if (row + column) mod 2 == 0:
          addFlowEdge(cellIndex, neighborIndex, infiniteCapacity)
        else:
          addFlowEdge(neighborIndex, cellIndex, infiniteCapacity)
      if row + 1 < gridHeight:
        let neighborIndex = (row + 1) * gridWidth + column
        if (row + column) mod 2 == 0:
          addFlowEdge(cellIndex, neighborIndex, infiniteCapacity)
        else:
          addFlowEdge(neighborIndex, cellIndex, infiniteCapacity)
  levelValues = newSeq[int](flowGraph.len)
  nextEdges = newSeq[int](flowGraph.len)
  let minimumCover = maximumFlow()
  appendOutput("Case " & $caseNumber & ": " & $(totalOil - minimumCover))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Node zero through the cell count hold grid cells. The next two nodes are source and sink. The answer is the total minus the maximum flow.

## Complexity

Each map builds a network with one node per cell and edges for board adjacencies.

| phase | time | space |
|---|---|---|
| network build | one pass over W times H cells | O(W*H) edges |
| Dinic flow | O(V^2 * E) worst case | O(V + E) |
| output | one line per map | one block buffer |

| measure | Big O |
|---|---|
| time per map | O((W*H)^3) worst case |
| space per map | O(W*H) |

Checking every subset would take O(2^(W*H)) time. The flow stays polynomial even at 20 by 20.

Takeaway: minimize the cut once, then read the answer by subtraction.
