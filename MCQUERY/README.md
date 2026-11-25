# MCQUERY — MinCut Query (SPOJ)

<https://www.spoj.com/problems/MCQUERY/>

## Problem

For each threshold x, count the unordered vertex pairs whose minimum cut capacity is at most x. The graph is undirected and weighted, and parallel edges are allowed. Blank lines separate the output of successive test cases.

Input starts with the test count. Each case gives the vertex count and edge count, then the edges, then the query count and one threshold per query. Output one count per query.

| Item | Bound |
|---|---|
| Test cases | up to 15 in set 1, 20 in set 2 |
| Vertices | up to 40 in set 1, 150 in set 2 |
| Edges | up to 400 in set 1, 3000 in set 2 |
| Queries | up to 10 in set 1, 30 in set 2 |
| Edge capacity | up to 1000000 |
| Judge limit | 1000 ms, 1536 MB |

The vertex count drives the flow work, since a tree needs one cut per remaining vertex.

Sample input:

```
1
5 0
1
0
```

The graph has five vertices and no edges.

Sample output:

```
10
```

Every pair has cut capacity zero, and five vertices give ten pairs.

## Idea

Compress all pairwise cut values into a tree, like replacing a road map with a skeletal route that preserves every travel bottleneck. In that tree, the cut between two vertices is the smallest edge on their path. Once the tree exists, every query is a count of path minima below a threshold.

The algorithm builds a Gomory-Hu tree with one max-flow computation per vertex. Each flow uses Dinic with current-arc pruning. Sorting all pair minima then answers each query with one binary search. Running a fresh max flow for every query and every pair would cost far more.

## Why It Works

1. A cut partitions the vertices, and its capacity is the sum of edges crossing the partition.
2. Gomory-Hu replaces the graph with a tree whose path minimum equals each pair's min cut.
3. Building the tree takes one s-t cut for each vertex beyond the first.
4. Every unordered pair maps to one tree path and one minimum edge weight.
5. Sorting those minima lets a threshold query count small values in logarithmic time.

| Term | Meaning |
|---|---|
| `capacity` | aggregated undirected edge capacities |
| `parent` | tree parent chosen by Gomory-Hu |
| `treeWeight` | capacity of the edge to the parent |
| `pairValues` | sorted minimum cuts over all vertex pairs |

The terms above are the whole query structure.

A worked trace for the sample:

```
five vertices, no edges, so each tree edge weighs zero
there are ten unordered pairs
all ten path minima are zero
threshold zero counts all ten
```

The trace matches the sample answer.

## Code

**Input, scanner, and output.** Capacities can reach a billion in aggregate, so the matrix uses 64-bit integers.

```nim
import algorithm

const flushBlockBytes = 1 shl 17
const flowInfinity = int64(1) shl 60

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

Parallel edges are summed when the matrix is built.
One block holds many answer lines.

**Dinic state.** Residual arcs are kept in flat arrays with reverse arcs adjacent.

```nim
var flowNodeCount = 0
var flowSource = 0
var flowSink = 0
var flowHead = newSeq[int]()
var flowTarget = newSeq[int]()
var flowCapacity = newSeq[int64]()
var flowNext = newSeq[int]()
var flowLevel = newSeq[int]()
var flowCursor = newSeq[int]()

proc addFlowEdge(fromVertex: int, toVertex: int, capacity: int64) =
  flowTarget.add toVertex
  flowCapacity.add capacity
  flowNext.add flowHead[fromVertex]
  flowHead[fromVertex] = flowTarget.len - 1
  flowTarget.add fromVertex
  flowCapacity.add capacity
  flowNext.add flowHead[toVertex]
  flowHead[toVertex] = flowTarget.len - 1
```

Each undirected edge contributes one pair of arcs.
The reverse arc sits at the index toggled by one.

**Flow phases.** A level graph and a cursor skip arcs that are already exhausted.

```nim
proc flowBfs(): bool =
  flowLevel = newSeq[int](flowNodeCount)
  for vertexIndex in 0 .. flowNodeCount - 1:
    flowLevel[vertexIndex] = -1
  var queue = newSeq[int]()
  flowLevel[flowSource] = 0
  queue.add flowSource
  var queuePos = 0
  while queuePos < queue.len:
    let current = queue[queuePos]
    queuePos += 1
    var edgeIndex = flowHead[current]
    while edgeIndex != -1:
      let nextVertex = flowTarget[edgeIndex]
      if flowCapacity[edgeIndex] > 0 and flowLevel[nextVertex] < 0:
        flowLevel[nextVertex] = flowLevel[current] + 1
        queue.add nextVertex
      edgeIndex = flowNext[edgeIndex]
  return flowLevel[flowSink] >= 0

proc flowDfs(current: int, available: int64): int64 =
  if current == flowSink:
    return available
  var edgeIndex = flowCursor[current]
  while edgeIndex != -1:
    flowCursor[current] = flowNext[edgeIndex]
    let nextVertex = flowTarget[edgeIndex]
    if flowCapacity[edgeIndex] > 0 and flowLevel[nextVertex] == flowLevel[current] + 1:
      let pushed = flowDfs(nextVertex, min(available, flowCapacity[edgeIndex]))
      if pushed > 0:
        flowCapacity[edgeIndex] = flowCapacity[edgeIndex] - pushed
        flowCapacity[edgeIndex xor 1] = flowCapacity[edgeIndex xor 1] + pushed
        return pushed
    edgeIndex = flowCursor[current]
  return 0
```

Breadth-first search builds the level graph.
Depth-first search pushes flow along increasing levels.
The cursor prevents rescanning dead arcs.

**One cut.** The residual reachability set gives the source side of a minimum cut.

```nim
proc computeMinCut(vertexCount: int, capacity: seq[seq[int64]],
                   source: int, sink: int): (int64, seq[bool]) =
  flowNodeCount = vertexCount
  flowSource = source
  flowSink = sink
  flowHead = newSeq[int](vertexCount)
  for vertexIndex in 0 .. vertexCount - 1:
    flowHead[vertexIndex] = -1
  flowTarget.setLen 0
  flowCapacity.setLen 0
  flowNext.setLen 0
  for fromVertex in 0 .. vertexCount - 1:
    for toVertex in fromVertex + 1 .. vertexCount - 1:
      if capacity[fromVertex][toVertex] > 0:
        addFlowEdge(fromVertex, toVertex, capacity[fromVertex][toVertex])
  var totalFlow: int64 = 0
  while flowBfs():
    flowCursor = flowHead
    while true:
      let pushed = flowDfs(source, flowInfinity)
      if pushed == 0:
        break
      totalFlow = totalFlow + pushed
  var reachable = newSeq[bool](vertexCount)
  reachable[source] = true
  var queue = newSeq[int]()
  queue.add source
  var queuePos = 0
  while queuePos < queue.len:
    let current = queue[queuePos]
    queuePos += 1
    var edgeIndex = flowHead[current]
    while edgeIndex != -1:
      let nextVertex = flowTarget[edgeIndex]
      if flowCapacity[edgeIndex] > 0 and not reachable[nextVertex]:
        reachable[nextVertex] = true
        queue.add nextVertex
      edgeIndex = flowNext[edgeIndex]
  return (totalFlow, reachable)
```

The residual graph is rebuilt for each cut.
Reachable vertices form one side of the cut.
The flow value is that cut's capacity.

**Gomory-Hu construction and queries.** One cut per vertex fixes the tree, then sorted pair values answer queries.

```nim
proc pairComparator(first: int64, second: int64): int =
  if first < second:
    return -1
  if first > second:
    return 1
  return 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let vertexCount = nextInt(inputData, scanPos)
  let edgeCount = nextInt(inputData, scanPos)
  var capacity = newSeq[seq[int64]](vertexCount)
  for vertexIndex in 0 .. vertexCount - 1:
    capacity[vertexIndex] = newSeq[int64](vertexCount)
  for edgeIndex in 0 .. edgeCount - 1:
    let firstVertex = nextInt(inputData, scanPos) - 1
    let secondVertex = nextInt(inputData, scanPos) - 1
    let edgeCapacity = int64(nextInt(inputData, scanPos))
    capacity[firstVertex][secondVertex] = capacity[firstVertex][secondVertex] + edgeCapacity
    capacity[secondVertex][firstVertex] = capacity[secondVertex][firstVertex] + edgeCapacity
  var parent = newSeq[int](vertexCount)
  var treeWeight = newSeq[int64](vertexCount)
  for source in 1 .. vertexCount - 1:
    let sink = parent[source]
    let cutResult = computeMinCut(vertexCount, capacity, source, sink)
    let reachable = cutResult[1]
    for vertexIndex in source + 1 .. vertexCount - 1:
      if parent[vertexIndex] == sink and reachable[vertexIndex]:
        parent[vertexIndex] = source
    if reachable[parent[sink]]:
      parent[source] = parent[sink]
      parent[sink] = source
      treeWeight[source] = treeWeight[sink]
      treeWeight[sink] = cutResult[0]
    else:
      treeWeight[source] = cutResult[0]
  var pairValues = newSeq[int64]()
  for source in 0 .. vertexCount - 1:
    for sink in source + 1 .. vertexCount - 1:
      var ancestor = newSeq[bool](vertexCount)
      var current = source
      while true:
        ancestor[current] = true
        if parent[current] == current:
          break
        current = parent[current]
      current = sink
      while not ancestor[current]:
        current = parent[current]
      let commonAncestor = current
      var minimumCut = flowInfinity
      current = source
      while current != commonAncestor:
        minimumCut = min(minimumCut, treeWeight[current])
        current = parent[current]
      current = sink
      while current != commonAncestor:
        minimumCut = min(minimumCut, treeWeight[current])
        current = parent[current]
      pairValues.add minimumCut
  sort(pairValues, pairComparator)
  let queryCount = nextInt(inputData, scanPos)
  if caseIndex > 0:
    appendOutput("\n")
  for queryIndex in 0 .. queryCount - 1:
    let limitValue = int64(nextInt(inputData, scanPos))
    var lowIndex = 0
    var highIndex = pairValues.len
    while lowIndex < highIndex:
      let middle = (lowIndex + highIndex) div 2
      if pairValues[middle] <= limitValue:
        lowIndex = middle + 1
      else:
        highIndex = middle
    appendOutput($lowIndex & "\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

Tree parents may change during construction.
Path minima use the current parent array.
A blank line precedes every case except the first.

## Complexity

Building the tree costs one max-flow computation per vertex.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over edges and queries | one input string |
| Gomory-Hu tree | one Dinic flow per non-root vertex | residual arcs and capacity matrix |
| Pair minima | one upward walk per pair | sorted pair values |
| Queries | one binary search each | block buffer |

The phase table shows the flow phase dominates the runtime.

| Measure | Big O |
|---|---|
| Time | O(n times maxflow plus n squared log n for sorting) |
| Space | O(n squared) for the capacity matrix |

A fresh flow for every pair and query costs far more than one tree plus binary searches.
