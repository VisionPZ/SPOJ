# POTHOLE — Potholers (SPOJ)

<https://www.spoj.com/problems/POTHOLE/>

## Problem

Speleologists explore routes from the top chamber to the bottom chamber, moving only downward. Each must use distinct start and finish corridors; find the largest team that can train at once.

Input: `t` cases separated by blank lines. Each case starts with `n`, then `n − 1` lines. Line `i` gives the count of corridors leaving chamber `i`, followed by the higher-numbered chambers they reach. Chamber 1 is the top and chamber `n` is the bottom. Output: one integer per case, the largest team size.

The bounds from the statement:

| Item | Bound |
|---|---|
| Chambers `n` | 2 ≤ n ≤ 200 |
| Corridor direction | from chamber `i` to higher numbers only |
| Start and finish | chamber 1 and chamber `n` |
| Judge limit | 7000 ms, 1536 MB |

Interior corridors may be shared, but the first and last corridors may not be shared.

The sample input and output:

```
1
12
4 3 4 2 5
1 8
2 9 7
2 6 11
1 8
2 9 10
2 10 11
1 12
2 10 12
1 12
1 12
```

```
3
```

## Idea

Treat the cave as a downhill plumbing network and push as many routes through it as possible. Each route is one explorer. Imagine water entering through the top pipes and leaving through the bottom pipes.

The program builds a directed graph from chamber `i` to each higher-numbered chamber it reaches. Corridors leaving chamber 1 and entering chamber `n` get capacity 1. Every other corridor gets infinite capacity. A maximum flow then counts the routes, and capacity 1 enforces the distinct-corridor rule.

The algorithm is Dinic's max flow (a level-graph blocking-flow method). A breadth-first search builds levels, and a depth-first search pushes flow along level-increasing edges. Each phase exhausts all shortest routes before the next search.

Cost per case: one BFS over all edges per phase, plus one DFS per pushed route. With at most 200 chambers, this stays small. Enumerating route sets by hand would grow exponentially with the number of chambers.

Capacity 1 on the entrance and exit corridors turns the route rule into an ordinary flow problem.

## Why It Works

Four facts carry the reduction.

1. Every corridor goes from a lower number to a higher one. Every path therefore runs from chamber 1 down to chamber `n`.
2. Capacity 1 on edges out of 1 and into `n` gives each explorer a distinct entrance and a distinct exit. Infinite capacity on interior edges lets several explorers share them.
3. An integral maximum flow splits into edge-disjoint paths from 1 to `n`. Each unit of flow is one valid explorer.
4. Dinic's BFS finds all shortest augmenting paths, and the DFS blocking flow saturates them. Repeating this reaches the maximum flow.

The flow arrays:

| Term | Meaning |
|---|---|
| `edgeCap` | remaining capacity of one directed corridor |
| `levelNode` | BFS distance from the source, −1 when unreachable |
| `iterEdge` | current arc pointer that skips exhausted edges |
| `infiniteCapacity` | capacity on shared interior corridors |

The integral flow decomposes into paths, so the flow value equals the team size.

A script-traced example with the sample cave of 12 chambers:

```
corridors leaving chamber 1:  1->3, 1->4, 1->2, 1->5   (capacity 1 each)
corridors entering chamber 12: 8->12, 9->12, 10->12, 11->12 (capacity 1 each)

route 1: 1 -> 3 -> 9  -> 12
route 2: 1 -> 4 -> 11 -> 12
route 3: 1 -> 2 -> 8  -> 12
route 4: 1 -> 5 -> 8  -> 12   collides with route 3 at 8 -> 12

max flow = 3
```

Three edge-disjoint routes fit, so three speleologists can train together.

## Code

**Constants and scanner.** The input buffer is read once, and integers are scanned by index.

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

`infiniteCapacity` marks interior corridors as freely shared. `nextInt` skips whitespace and reads each positive integer directly from the buffer.

**Output helper.** Lines collect in one buffer and flush in blocks.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The 256 KiB threshold keeps writes rare. `setLen 0` reuses the same string after each flush.

**Graph storage.** Each corridor adds a forward edge and a reverse edge.

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

The arrays sit side by side, indexed by edge number. The forward capacity is the given value, and the reverse capacity starts at zero. `edgeNext` chains edges that leave the same chamber.

**Level BFS.** `buildLevels` labels each chamber by distance from the source.

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

The queue holds chambers ready to expand. Only edges with positive capacity and an unlabeled endpoint enter the queue. The function returns true when the sink receives a level.

**Blocking flow.** The DFS pushes flow along level-increasing edges.

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
```

`iterEdge` remembers the last tried edge, so each edge is skipped only once per phase. A successful push updates the forward capacity and its reverse twin. A return of zero ends the current phase.

**Max flow loop.** Each BFS phase exhausts its shortest routes.

```nim
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

The outer loop stops when the sink has no level. The inner loop pushes until `pushFlow` returns zero. The running total is the answer.

**Case loop.** Capacities are set from chamber numbers, then flow is computed.

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

Edges from chamber 1 and into chamber `n` get capacity 1; all others get `infiniteCapacity`. The edge arrays are sized for a dense graph and reset per case. One answer line goes out per case.

## Complexity

Each case builds a graph, then runs several BFS and DFS phases.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Graph build | one pass over corridors | O(E) |
| Level BFS | one pass over edges per phase | O(V) |
| Blocking DFS | one pass over edges per phase | O(V) |
| Output | one write per 256 KiB block | 256 KiB |
| Total per case | O(V²E) worst-case Dinic | O(V + E) |

With at most 200 chambers, even the worst-case bound is small.

| Measure | Big O |
|---|---|
| Time | O(V²E) worst case, V ≤ 200 |
| Space | O(V + E) for flow arrays and buffers |

The graph is acyclic, so flow algorithms converge quickly in practice.

Listing every set of edge-disjoint routes would grow exponentially with the chamber count. Max flow reaches the same answer in polynomial time.
