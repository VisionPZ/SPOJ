# RESOURCE — Resource Management (SPOJ)

<https://www.spoj.com/problems/RESOURCE/>

## Problem

A grid of stations has a height at every cell. Walking follows grid edges only downhill and costs the height drop in effort, while a cable car ride between any two stations costs D dollars and no effort. Find a route visiting every station with the fewest cable rides, then the least effort among those routes.

Each test case starts with N, M, and D, followed by N rows of M heights. The line `0 0 0` ends the input. Print the dollar cost and the effort separated by a space.

| item | bound |
|---|---|
| rows N | 1 to 15 |
| columns M | 1 to 15 |
| ride cost D | 1 to 15 |
| station height | up to 100 |
| judge limit | 500 ms, 1536 MB |

The route may start at any station, so the first walking chain needs no cable ride.

Sample input:

```
2 2 1
1 2
4 3
3 3 7
1 2 1
4 5 3
1 2 1
0 0 0
```

Sample output:

```
0 3
21 8
```

## Idea

String the stations into downhill chains, like threading beads so each thread only runs downward. A minimum path cover in a directed acyclic graph gives the fewest chains, and one cable ride joins each extra chain. A minimum-cost maximum matching chooses the cheapest downhill links. Trying every possible route would explode with the grid size, so matching and flow settle the question in one pass.

## Why It Works

1. Each strictly downhill edge forms one link in a walking chain.
2. Vertex-disjoint chains covering all cells form a path cover of the downhill graph.
3. Maximum matching size equals the cell count minus the path cover size.
4. One cable ride connects two chains, so rides equal path count minus one.
5. The cost of a matched edge is the height drop, so minimum-cost matching gives minimum effort.

| term | meaning |
|---|---|
| `heights` | station height for each cell |
| `flowGraph` | bipartite network of downhill links |
| `totalFlow` | number of matched downhill links |
| `pathCount` | number of chains covering the grid |
| `totalCost` | effort sum of the chosen links |

The flow stores the chain links, not the route itself.

Script-generated trace for the first sample case:

```
quantity | value
grid heights | 1 2 / 4 3
downhill links | 4->1, 4->3, 3->2, 2->1
chosen links | 4->3, 3->2, 2->1
matched links | 3
chain count | 4 - 3 = 1
cable rides | 0
effort | 1 + 1 + 1 = 3
```

One chain covers all four cells, so the ride cost is zero.

## Code

**Bulk input and buffered output.** One input string and one output string carry all cases.

```nim
const flushBlockBytes = 1 shl 17
const largeDistance = 1 shl 28

type
  FlowEdge = object
    destination: int
    reverseIndex: int
    capacity: int
    cost: int

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

Each residual edge stores its reverse index.
The integer scanner ignores line breaks between rows.
The output buffer flushes in 128 KiB blocks.

**Min-cost flow.** Shortest augmenting paths are found with a queue-based relaxation.

```nim
var flowGraph = newSeq[seq[FlowEdge]]()

proc addFlowEdge(sourceIndex, targetIndex, capacityValue, costValue: int) =
  let forwardIndex = flowGraph[sourceIndex].len
  flowGraph[sourceIndex].add FlowEdge(destination: targetIndex, reverseIndex: flowGraph[targetIndex].len, capacity: capacityValue, cost: costValue)
  flowGraph[targetIndex].add FlowEdge(destination: sourceIndex, reverseIndex: forwardIndex, capacity: 0, cost: -costValue)

proc cheapestFlow(sourceIndex, sinkIndex: int): (int, int) =
  var totalFlow = 0
  var totalCost = 0
  while true:
    let nodeCount = flowGraph.len
    var distance = newSeq[int](nodeCount)
    var previousNode = newSeq[int](nodeCount)
    var previousEdge = newSeq[int](nodeCount)
    var queued = newSeq[bool](nodeCount)
    for nodeIndex in 0 .. nodeCount - 1:
      distance[nodeIndex] = largeDistance
      previousNode[nodeIndex] = -1
      previousEdge[nodeIndex] = -1
      queued[nodeIndex] = false
    distance[sourceIndex] = 0
    var queue = newSeq[int]()
    queue.add sourceIndex
    queued[sourceIndex] = true
    var queueHead = 0
    while queueHead < queue.len:
      let currentNode = queue[queueHead]
      queueHead += 1
      queued[currentNode] = false
      for edgeIndex in 0 .. flowGraph[currentNode].len - 1:
        let edge = flowGraph[currentNode][edgeIndex]
        if edge.capacity > 0 and distance[currentNode] + edge.cost < distance[edge.destination]:
          distance[edge.destination] = distance[currentNode] + edge.cost
          previousNode[edge.destination] = currentNode
          previousEdge[edge.destination] = edgeIndex
          if not queued[edge.destination]:
            queued[edge.destination] = true
            queue.add edge.destination
    if previousNode[sinkIndex] == -1:
      break
    var augmentBy = largeDistance
    var walkNode = sinkIndex
    while walkNode != sourceIndex:
      let parentNode = previousNode[walkNode]
      let edgeIndex = previousEdge[walkNode]
      if flowGraph[parentNode][edgeIndex].capacity < augmentBy:
        augmentBy = flowGraph[parentNode][edgeIndex].capacity
      walkNode = parentNode
    walkNode = sinkIndex
    while walkNode != sourceIndex:
      let parentNode = previousNode[walkNode]
      let edgeIndex = previousEdge[walkNode]
      flowGraph[parentNode][edgeIndex].capacity -= augmentBy
      flowGraph[walkNode][flowGraph[parentNode][edgeIndex].reverseIndex].capacity += augmentBy
      totalCost = totalCost + augmentBy * flowGraph[parentNode][edgeIndex].cost
      walkNode = parentNode
    totalFlow += augmentBy
  return (totalFlow, totalCost)
```

Reverse edges carry negative costs.
Each augmentation adds one downhill link.
The queue visits a node at most once at a time.

**Grid setup and answer.** Every cell gets one source link and one sink link.

```nim
while true:
  let rowCount = nextInt(inputData, scanPos)
  let columnCount = nextInt(inputData, scanPos)
  let ticketCost = nextInt(inputData, scanPos)
  if rowCount == 0 and columnCount == 0 and ticketCost == 0:
    break
  let cellCount = rowCount * columnCount
  var heights = newSeq[int](cellCount)
  for cellIndex in 0 .. cellCount - 1:
    heights[cellIndex] = nextInt(inputData, scanPos)
  flowGraph = newSeq[seq[FlowEdge]](2 * cellCount + 2)
  for graphIndex in 0 .. flowGraph.len - 1:
    flowGraph[graphIndex] = newSeq[FlowEdge]()
  let sourceNode = 0
  let sinkNode = 2 * cellCount + 1
  for cellIndex in 0 .. cellCount - 1:
    addFlowEdge(sourceNode, 1 + cellIndex, 1, 0)
    addFlowEdge(1 + cellCount + cellIndex, sinkNode, 1, 0)
  for rowIndex in 0 .. rowCount - 1:
    for columnIndex in 0 .. columnCount - 1:
      let cellIndex = rowIndex * columnCount + columnIndex
      let currentHeight = heights[cellIndex]
      for directionIndex in 0 .. 3:
        var neighborRow = rowIndex
        var neighborColumn = columnIndex
        if directionIndex == 0:
          neighborRow += 1
        elif directionIndex == 1:
          neighborRow -= 1
        elif directionIndex == 2:
          neighborColumn += 1
        else:
          neighborColumn -= 1
        if neighborRow < 0 or neighborRow >= rowCount:
          continue
        if neighborColumn < 0 or neighborColumn >= columnCount:
          continue
        let neighborIndex = neighborRow * columnCount + neighborColumn
        let neighborHeight = heights[neighborIndex]
        if neighborHeight < currentHeight:
          addFlowEdge(1 + cellIndex, 1 + cellCount + neighborIndex, 1, currentHeight - neighborHeight)
  let resultPair = cheapestFlow(sourceNode, sinkNode)
  let pathCount = cellCount - resultPair[0]
  let rideCount = pathCount - 1
  let visitCost = rideCount * ticketCost
  appendOutput($visitCost)
  outputBuffer.add ' '
  appendOutput($resultPair[1])
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Four directions cover all adjacent station pairs.
Only strictly lower neighbours create a link.
The two printed numbers come from one flow result.

## Complexity

Flow augmentation runs once per matched link, at most the cell count.

| phase | time | space |
|---|---|---|
| input read | one pass over heights | one input string |
| graph build | four checks per cell | two arrays per cell |
| min-cost flow | up to cell count augmentations | residual graph |
| output | one line per test case | block buffer |

At most 225 cells appear in one case.

| measure | Big O |
|---|---|
| time per case | O(cells squared times edges) worst case |
| space per case | O(cells) |

Enumerating all routes would grow exponentially with the number of stations.

The flow model keeps the search polynomial and exact.
