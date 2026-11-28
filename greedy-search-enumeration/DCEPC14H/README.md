# DCEPC14H — Watchers On The Wall (SPOJ)

<https://www.spoj.com/problems/DCEPC14H/>

## Problem

Choose cannon shots from towers on a grid so that no two shots cross in open space, and maximize the total enemy ability destroyed. A shot travels in one compass direction until a wall or tower stops it, and each tower fires any subset of directions.

Input starts with the grid size N, followed by N strings of N characters. Characters are `#` for a wall, `T` for a tower, `0` for empty space, and digits 1 through 9 for enemy ability. Print one integer: the largest damage total.

| item | bound |
|---|---|
| grid side N | up to 500 |
| towers | up to 200 |
| cell symbol | `#`, `T`, `0`, or 1-9 |
| judge limit | 500 ms, 1536 MB |

All cannons fire at the same time. Two shots that meet at an empty or enemy cell are illegal. Shots stopped by a wall or tower before meeting are legal.

Sample input:

```
4
T000
1#T3
292T
9000
```

Sample output:

```
17
```

## Idea

Turn each legal shot into one weighted vertex, then delete the cheapest set of conflicting shots, like removing the fewest blockers so the remaining roads never intersect.

A maximal run of open cells between blockers is a segment, and a tower at either end makes that segment shootable. Two horizontal segments never meet; two vertical segments never meet. A horizontal and a vertical segment meet in at most one cell, so conflicts form a bipartite graph. Maximum weight of non-conflicting shots equals total segment weight minus minimum weight vertex cover. A max-flow min-cut computes that cover in one pass, avoiding exponential subset search.

## Why It Works

1. A cannon destroys every enemy in the open segment next to its tower.
2. Two shots conflict only when their segments share an open cell.
3. Same-direction segments are disjoint, so the conflict graph is bipartite.
4. In a bipartite graph, minimum weighted vertex cover equals a minimum s-t cut.
5. Maximum kept damage is total segment weight minus that cut value.

| term | meaning |
|---|---|
| `horizontalWeights` | enemy totals of shootable horizontal segments |
| `verticalWeights` | enemy totals of shootable vertical segments |
| `flowGraph` | source, segment nodes, and sink for the cut |
| `flowInfinity` | capacity that forbids keeping both ends of a conflict |
| `maximumFlow` | value of the minimum weighted cover |

The worked example uses the sample grid, whose towers sit at the top-left and near the middle.

| direction | segment | damage |
|---|---|---|
| down from top-left | column 1, rows 2-4 | 1 + 2 + 9 = 12 |
| down from middle tower | column 3, row 3 | 2 |
| up from right tower | column 4, rows 1-2 | 3 |

The three chosen segments never meet in open space, and their damage sums to 17.

Every cell belongs to at most one horizontal and one vertical segment, so each conflicting pair gets one infinite edge. Zero-damage segments add no weight and never change the optimum.

## Code

**Input and flow helpers.** The reader loads stdin once, then defines Dinic edge storage and operations.

```nim
const flushBlockBytes = 1 shl 17
const flowInfinity: int64 = 1 shl 40

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

proc nextToken(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  var token = ""
  while pos < data.len and data[pos] > ' ':
    token.add data[pos]
    pos += 1
  return token

proc isBlocker(character: char): bool =
  return character == '#' or character == 'T'

type
  FlowEdge = object
    target: int
    reverseIndex: int
    capacity: int64

var flowGraph = newSeq[seq[FlowEdge]](0)

proc addFlowEdge(fromNode: int, toNode: int, capacity: int64) =
  let forwardIndex = flowGraph[fromNode].len
  flowGraph[fromNode].add FlowEdge(target: toNode, reverseIndex: flowGraph[toNode].len, capacity: capacity)
  flowGraph[toNode].add FlowEdge(target: fromNode, reverseIndex: forwardIndex, capacity: 0)
```

Grid rows are read as whole tokens, so digits and symbols stay intact.
Each edge stores a reverse index for flow cancellation.
Blocking cells are recognised by a single predicate.

**Dinic search.** Levels are built by breadth-first search, then blocking flow is pushed recursively.

```nim
proc buildLevels(sourceNode: int, level: var seq[int]): bool =
  for node in 0 .. level.len - 1:
    level[node] = -1
  var queue = newSeq[int](flowGraph.len)
  var queueHead = 0
  var queueTail = 0
  level[sourceNode] = 0
  queue[queueTail] = sourceNode
  queueTail += 1
  while queueHead < queueTail:
    let node = queue[queueHead]
    queueHead += 1
    for edge in flowGraph[node]:
      if edge.capacity > 0 and level[edge.target] < 0:
        level[edge.target] = level[node] + 1
        queue[queueTail] = edge.target
        queueTail += 1
  return level[flowGraph.len - 1] >= 0

proc pushFlow(node: int, sinkNode: int, pushed: int64, level: seq[int], progress: var seq[int]): int64 =
  if node == sinkNode:
    return pushed
  while progress[node] < flowGraph[node].len:
    let edgeIndex = progress[node]
    let edge = flowGraph[node][edgeIndex]
    if edge.capacity > 0 and level[edge.target] == level[node] + 1:
      let accepted = pushFlow(edge.target, sinkNode, min(pushed, edge.capacity), level, progress)
      if accepted > 0:
        flowGraph[node][edgeIndex].capacity -= accepted
        flowGraph[edge.target][edge.reverseIndex].capacity += accepted
        return accepted
    progress[node] += 1
  return 0

proc maximumFlow(sourceNode: int): int64 =
  var level = newSeq[int](flowGraph.len)
  var total: int64 = 0
  while buildLevels(sourceNode, level):
    var progress = newSeq[int](flowGraph.len)
    while true:
      let pushed = pushFlow(sourceNode, flowGraph.len - 1, flowInfinity, level, progress)
      if pushed == 0:
        break
      total += pushed
  return total

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The progress array skips exhausted edges inside one level graph.
The sink is always the last node of `flowGraph`.
Output is staged in the shared block buffer.

**Segment scan.** Each maximal open run next to a tower becomes one candidate shot.

```nim
let gridSize = nextInt(inputData, scanPos)
var grid = newSeq[string](gridSize)
for rowIndex in 0 .. gridSize - 1:
  grid[rowIndex] = nextToken(inputData, scanPos)

let cellCount = gridSize * gridSize
var horizontalSegmentId = newSeq[int](cellCount)
var verticalSegmentId = newSeq[int](cellCount)
for cellIndex in 0 .. cellCount - 1:
  horizontalSegmentId[cellIndex] = -1
  verticalSegmentId[cellIndex] = -1
var horizontalWeights = newSeq[int64](0)
var verticalWeights = newSeq[int64](0)

for rowIndex in 0 .. gridSize - 1:
  let rowText = grid[rowIndex]
  var columnIndex = 0
  while columnIndex < gridSize:
    if isBlocker(rowText[columnIndex]):
      columnIndex += 1
      continue
    let startColumn = columnIndex
    var segmentWeight: int64 = 0
    while columnIndex < gridSize and not isBlocker(rowText[columnIndex]):
      let cellValue = rowText[columnIndex]
      if cellValue != '0':
        segmentWeight += int64(int(cellValue) - 48)
      columnIndex += 1
    let endColumn = columnIndex - 1
    var hasTower = false
    if startColumn > 0 and rowText[startColumn - 1] == 'T':
      hasTower = true
    if endColumn < gridSize - 1 and rowText[endColumn + 1] == 'T':
      hasTower = true
    if hasTower:
      let segmentId = horizontalWeights.len
      horizontalWeights.add segmentWeight
      for column in startColumn .. endColumn:
        horizontalSegmentId[rowIndex * gridSize + column] = segmentId

for columnIndex in 0 .. gridSize - 1:
  var rowIndex = 0
  while rowIndex < gridSize:
    if isBlocker(grid[rowIndex][columnIndex]):
      rowIndex += 1
      continue
    let startRow = rowIndex
    var segmentWeight: int64 = 0
    while rowIndex < gridSize and not isBlocker(grid[rowIndex][columnIndex]):
      let cellValue = grid[rowIndex][columnIndex]
      if cellValue != '0':
        segmentWeight += int64(int(cellValue) - 48)
      rowIndex += 1
    let endRow = rowIndex - 1
    var hasTower = false
    if startRow > 0 and grid[startRow - 1][columnIndex] == 'T':
      hasTower = true
    if endRow < gridSize - 1 and grid[endRow + 1][columnIndex] == 'T':
      hasTower = true
    if hasTower:
      let segmentId = verticalWeights.len
      verticalWeights.add segmentWeight
      for row in startRow .. endRow:
        verticalSegmentId[row * gridSize + columnIndex] = segmentId
```

A segment is stored once even when towers sit at both ends.
Cell-to-segment maps make conflict lookup constant time.
Enemy digits contribute their face value to the segment weight.

**Flow construction.** Source capacities are horizontal weights, sink capacities are vertical weights, and crossing pairs get infinite edges.

```nim
let horizontalCount = horizontalWeights.len
let verticalCount = verticalWeights.len
let sourceNode = 0
let sinkNode = horizontalCount + verticalCount + 1
flowGraph = newSeq[seq[FlowEdge]](sinkNode + 1)
for node in 0 .. sinkNode:
  flowGraph[node] = newSeq[FlowEdge](0)
var totalWeight: int64 = 0
for weight in horizontalWeights:
  totalWeight += weight
for weight in verticalWeights:
  totalWeight += weight
for segmentId in 0 .. horizontalCount - 1:
  addFlowEdge(sourceNode, segmentId + 1, horizontalWeights[segmentId])
for segmentId in 0 .. verticalCount - 1:
  addFlowEdge(horizontalCount + 1 + segmentId, sinkNode, verticalWeights[segmentId])
for cellIndex in 0 .. cellCount - 1:
  let horizontalId = horizontalSegmentId[cellIndex]
  let verticalId = verticalSegmentId[cellIndex]
  if horizontalId >= 0 and verticalId >= 0:
    addFlowEdge(horizontalId + 1, horizontalCount + 1 + verticalId, flowInfinity)

let answer = totalWeight - maximumFlow(sourceNode)
appendOutput($answer)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

An infinite edge cannot be cut, so a cut must remove one endpoint.
The cut value is the cheapest set of conflicting shots to drop.
The remaining weight is the maximum legal damage.

## Complexity

Segment discovery scans every cell once, and the flow graph has at most four edges per tower plus conflict edges.

| phase | time | space |
|---|---|---|
| input read | one pass over N grid rows | one input string |
| segment scan | O(N²) cells | two cell maps |
| max flow | O(V²E) worst case on small graphs | vertices plus edges |
| output | one line | block buffer |

| measure | Big O |
|---|---|
| time | O(N² + flow) |
| space | O(N²) |

Trying every subset of shots costs O(2^K) for K candidate segments and fails at 200 towers.
The min-cut formulation replaces that search with one polynomial flow problem.

Infinite capacity must exceed the total damage, so the cut never slices a conflict edge.
The answer uses int64 because sums grow with grid area and enemy values.
