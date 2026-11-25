# ADAHOSE — Ada and Hose (SPOJ)

<https://www.spoj.com/problems/ADAHOSE/>

## Problem

A square field gives each cell a hose capacity. Find the largest flow from the field top to the field bottom, where neighbouring hoses share water freely.

The first line gives N. The next N lines give N capacities each. Output one integer, the maximal flow per time.

| item | bound |
|---|---|
| field size N | 1 to 1000 |
| hose capacity | 0 to 1000 |
| judge limit | 2000 ms, 1536 MB |

The grid size drives the design; capacities stay small.

Sample input:

```
3
9 3 2
1 9 3
3 3 9
```

Sample output:

```
26
```

## Idea

Cut the field side to side, like slicing a loaf to separate the top from the bottom. Planar min cut turns that slice into a cheapest left-to-right cell walk, and Dijkstra finds that walk. Moving into a cell costs its hose capacity, so a walk costs the sum of its cells. A direct max-flow build needs far more nodes and edges. The cheapest walk gives the answer after doubling.

## Why It Works

1. Water enters through the top row and leaves through the bottom row.
2. Every hose side has capacity equal to its cell value, and touching hoses share water.
3. A cut separating top from bottom is a chain of cells from the left edge to the right edge.
4. Cutting a cell crosses two of its sides, so the chain costs two times the cell capacity.
5. The cheapest such chain equals the maximal flow by planar min-cut duality.
6. Dijkstra from every left-edge cell finds that cheapest chain.

| term | meaning |
|---|---|
| `hoseFlows` | capacity stored for each cell |
| `shortestFlow` | cheapest walk reaching a cell from the left edge |
| `heapDistance` | priority value of a heap entry |
| `bestFlow` | cheapest walk reaching the right edge |

The table maps each grid quantity to one array in the code.

A script trace of the sample walks the middle row:

| step | cell | added cost | running cost |
|---|---|---|---|
| start | row 2, column 1 | 1 | 1 |
| step 1 | row 2, column 2 | 9 | 10 |
| step 2 | row 2, column 3 | 3 | 13 |

Doubling thirteen gives the sample answer twenty six.

Zero capacities are legal, so the heap must allow a distance of zero.

## Code

**Input and heap helpers.** The reader loads every cell, and two arrays hold the binary heap.

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

proc pushNode(distanceValue: int64, nodeIndex: int, heapDistance: var seq[int64], heapNode: var seq[int], heapSize: var int) =
  heapDistance.setLen(heapSize + 1)
  heapNode.setLen(heapSize + 1)
  var childIndex = heapSize
  heapSize += 1
  while childIndex > 0:
    let parentIndex = (childIndex - 1) div 2
    if heapDistance[parentIndex] <= distanceValue:
      break
    heapDistance[childIndex] = heapDistance[parentIndex]
    heapNode[childIndex] = heapNode[parentIndex]
    childIndex = parentIndex
  heapDistance[childIndex] = distanceValue
  heapNode[childIndex] = nodeIndex

proc popNode(heapDistance: var seq[int64], heapNode: var seq[int], heapSize: var int): tuple[distanceValue: int64, nodeIndex: int] =
  let bestDistance = heapDistance[0]
  let bestNode = heapNode[0]
  heapSize -= 1
  if heapSize > 0:
    let movedDistance = heapDistance[heapSize]
    let movedNode = heapNode[heapSize]
    var parentIndex = 0
    while true:
      let leftIndex = parentIndex * 2 + 1
      if leftIndex >= heapSize:
        break
      let rightIndex = leftIndex + 1
      var childIndex = leftIndex
      if rightIndex < heapSize and heapDistance[rightIndex] < heapDistance[leftIndex]:
        childIndex = rightIndex
      if heapDistance[childIndex] >= movedDistance:
        break
      heapDistance[parentIndex] = heapDistance[childIndex]
      heapNode[parentIndex] = heapNode[childIndex]
      parentIndex = childIndex
    heapDistance[parentIndex] = movedDistance
    heapNode[parentIndex] = movedNode
  return (bestDistance, bestNode)

proc relaxNeighbor(neighborIndex: int, travelledFlow: int64, hoseFlows: seq[int64], shortestFlow: var seq[int64], heapDistance: var seq[int64], heapNode: var seq[int], heapSize: var int) =
  let candidateFlow = travelledFlow + hoseFlows[neighborIndex]
  if candidateFlow < shortestFlow[neighborIndex]:
    shortestFlow[neighborIndex] = candidateFlow
    pushNode(candidateFlow, neighborIndex, heapDistance, heapNode, heapSize)
```

The heap holds at most one entry per improvement.
Sift operations keep the smallest distance at the root.
`relaxNeighbor` is the only place a distance changes.

**Seeding the search.** Each left-edge cell starts a walk with cost equal to its own hose.

```nim
let fieldSize = nextInt(inputData, scanPos)
let cellCount = fieldSize * fieldSize
var hoseFlows = newSeq[int64](cellCount)
for rowIndex in 0 .. fieldSize - 1:
  for columnIndex in 0 .. fieldSize - 1:
    hoseFlows[rowIndex * fieldSize + columnIndex] = int64(nextInt(inputData, scanPos))

let infiniteFlow = int64(1) shl 60
var shortestFlow = newSeq[int64](cellCount)
for cellIndex in 0 .. cellCount - 1:
  shortestFlow[cellIndex] = infiniteFlow
var heapDistance = newSeq[int64](cellCount)
var heapNode = newSeq[int](cellCount)
var heapSize = 0
for rowIndex in 0 .. fieldSize - 1:
  let entryCell = rowIndex * fieldSize
  shortestFlow[entryCell] = hoseFlows[entryCell]
  pushNode(shortestFlow[entryCell], entryCell, heapDistance, heapNode, heapSize)
```

All other cells begin at `infiniteFlow`.
One push per left-edge cell seeds the multi-source search.
Cell indices pack a row and column into one integer.

**Walking and answering.** Each popped cell relaxes its four neighbours, then the cheapest exit is doubled.

```nim
while heapSize > 0:
  let poppedNode = popNode(heapDistance, heapNode, heapSize)
  if poppedNode.distanceValue != shortestFlow[poppedNode.nodeIndex]:
    continue
  let rowIndex = poppedNode.nodeIndex div fieldSize
  let columnIndex = poppedNode.nodeIndex mod fieldSize
  if rowIndex > 0:
    relaxNeighbor(poppedNode.nodeIndex - fieldSize, poppedNode.distanceValue, hoseFlows, shortestFlow, heapDistance, heapNode, heapSize)
  if rowIndex + 1 < fieldSize:
    relaxNeighbor(poppedNode.nodeIndex + fieldSize, poppedNode.distanceValue, hoseFlows, shortestFlow, heapDistance, heapNode, heapSize)
  if columnIndex > 0:
    relaxNeighbor(poppedNode.nodeIndex - 1, poppedNode.distanceValue, hoseFlows, shortestFlow, heapDistance, heapNode, heapSize)
  if columnIndex + 1 < fieldSize:
    relaxNeighbor(poppedNode.nodeIndex + 1, poppedNode.distanceValue, hoseFlows, shortestFlow, heapDistance, heapNode, heapSize)

var bestFlow = infiniteFlow
for rowIndex in 0 .. fieldSize - 1:
  let exitCell = rowIndex * fieldSize + fieldSize - 1
  if shortestFlow[exitCell] < bestFlow:
    bestFlow = shortestFlow[exitCell]

appendOutput($(bestFlow * 2))
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Stale heap entries are skipped by the distance check.
Four neighbour checks cover the whole grid.
The answer is written once with the buffered writer.

## Complexity

The search visits cells once and relaxes four edges per cell.

| phase | time | space |
|---|---|---|
| input read | one pass over N squared cells | one capacity array |
| shortest walk | N squared heap pops and four relaxations | two distance arrays and a heap |
| output | one line | block buffer |

Each cell enters the heap only when its distance improves.

| measure | Big O |
|---|---|
| time | O(N squared log N) |
| space | O(N squared) |

A direct max-flow build adds more nodes and takes longer than this dual walk.

Doubling the cheapest chain converts a cut into the required maximal flow.
