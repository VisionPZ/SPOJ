# CABLETV — Cable TV Network (SPOJ)

<https://www.spoj.com/problems/CABLETV/>

## Problem

For each cable network, report the smallest number of relays whose removal disconnects the network, or n when no removal disconnects it.

Input begins with t, the number of data sets. Each data set gives n and m, then m pairs (u,v) with u < v. A pair contains no spaces inside it; other whitespace is free. Output one safety factor per data set, starting at the beginning of a line.

The statement sets these bounds:

| Item | Bound |
|---|---|
| Data sets t | at most 20 |
| Relays n | 0 to 50 |
| Cables m | 0 to n(n−1)/2 |
| Judge time | 5000 ms |
| Memory | 1536 MB |
| Source size | 50000 B |

The cable bound caps m at 1225, so each network stays small.

Sample input:

```
5
0 0
1 0
3 3 (0,1) (0,2) (1,2)
2 0
5 7 (0,1) (0,2) (1,3) (1,2) (1,4) (2,3) (3,4)
```

Sample output:

```
0
1
3
0
2
```

The five lines give the safety factor of each sample network in order.

## Idea

Cutting a cable network is like blocking checkpoints between two cities. Different city pairs need different blockades, so we test every relay pair.

The algorithm is vertex connectivity through a vertex-splitting max-flow model. Each relay becomes an in-node and an out-node joined by a one-unit arc. Each cable becomes two unlimited arcs. We run Dinic's blocking-flow search for every relay pair without a direct cable.

One flow visits at most 100 nodes and about 5000 arcs. It stops once it reaches the best cut found so far. Trying every subset of relays needs up to 2^50 connectivity checks per case, which cannot finish.

A few hundred capped flows replace an exponential search.

## Why It Works

1. The in-node to out-node arc makes every route through a relay spend one unit. Cutting that arc removes the relay.
2. The two endpoint relays get unlimited arcs, so they never count toward the cut.
3. Each cable gives one unlimited arc in each direction, so a cable survives any removal of other relays.
4. Two relays joined by a cable keep their direct arc. No removal of other relays separates them, so we skip those pairs.
5. A connected network with a missing cable has at least one separable pair. The smallest cut over those pairs is the safety factor. When no pair separates, the network is complete and rule 1 gives n.

The model uses these pieces:

| Term | Meaning |
|---|---|
| in(v) -> out(v), capacity 1 | one removable relay |
| out(u) -> in(v), capacity `largeCapacity` | one cable in each direction |
| source out(s), sink in(t) | a route from relay s to relay t |
| `minCutValue` result | relays whose removal separates s and t |
| `bestCut` cap | early stop when a pair cannot improve the answer |

The cut counts only removable relays, which matches the removed set in the statement.

A script traces a four-relay cycle:

```
relays: 4, cables: [(0, 1), (1, 2), (2, 3), (3, 0)]
pairs without a direct cable: [(0, 2), (1, 3)]
pair (0,2): smallest separating set (1, 3) of size 2
pair (1,3): smallest separating set (0, 2) of size 2
minimum over pairs: 2
safety factor: 2
```

Both pairs need two relays, so the cycle reports 2.

## Code

**Constants.** Six fixed values size the buffers and capacities.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const maxVertexCount = 50
const maxNodeCount = 100
const maxEdgeCount = 6000
const largeCapacity = 1000
```

The node array holds 100 entries for 50 split relays. The arc array holds 6000 entries, above 2n + 4m at the worst case. The large capacity exceeds every answer, so cable arcs never form a cut.

**Bulk read.** All input lines land in one string before parsing.

```nim
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value
```

The loop appends a newline for every line, so stray spaces cannot desync the scanner. `nextInt` skips every non-digit, which accepts the statement's (u,v) pairs. Each digit comes from `firstDigitValue`, with no parse call.

**Output buffer.** One buffer holds all result lines.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

A flush happens only when the buffer passes `flushBlockBytes`. `setLen 0` reuses the same allocation. The driver writes the tail once at the end.

**Graph storage.** Flat arrays hold the flow graph for one data set.

```nim
var scanPos = 0
var adjacent: array[maxVertexCount * maxVertexCount, bool]
var nodeHead: array[maxNodeCount, int]
var edgeTo: array[maxEdgeCount, int]
var edgeNext: array[maxEdgeCount, int]
var baseCap: array[maxEdgeCount, int]
var workCap: array[maxEdgeCount, int]
var splitEdge: array[maxVertexCount, int]
var level: array[maxNodeCount, int]
var iterEdge: array[maxNodeCount, int]
var queueNodes: array[maxNodeCount, int]
var edgeCount = 0
var nodeCount = 0

proc addArc(fromNode, toNode, capacity: int) =
  edgeTo[edgeCount] = toNode
  edgeNext[edgeCount] = nodeHead[fromNode]
  baseCap[edgeCount] = capacity
  nodeHead[fromNode] = edgeCount
  edgeCount += 1
  edgeTo[edgeCount] = fromNode
  edgeNext[edgeCount] = nodeHead[toNode]
  baseCap[edgeCount] = 0
  nodeHead[toNode] = edgeCount
  edgeCount += 1
```

Every arc gets a forward slot and a reverse slot, so `edgeIdx xor 1` finds its partner. `baseCap` keeps original capacities for the next pair. Adjacency uses one flat array of 2500 flags.

**Connectivity probe.** A BFS rejects already disconnected networks.

```nim
proc graphConnected(vertexCount: int): bool =
  if vertexCount <= 1: return true
  var seen: array[maxVertexCount, bool]
  var queue: array[maxVertexCount, int]
  var headPos = 0
  var tailPos = 0
  queue[tailPos] = 0
  tailPos += 1
  seen[0] = true
  while headPos < tailPos:
    let current = queue[headPos]
    headPos += 1
    for neighbor in 0..<vertexCount:
      if adjacent[current * maxVertexCount + neighbor] and not seen[neighbor]:
        seen[neighbor] = true
        queue[tailPos] = neighbor
        tailPos += 1
  for vertex in 0..<vertexCount:
    if not seen[vertex]: return false
  return true
```

The search uses the adjacency matrix, not the flow graph. It returns true for zero or one relay, matching the statement. This O(n^2) check skips all flows for disconnected cases.

**Blocking-flow DFS.** One recursive walk pushes flow along level arcs.

```nim
proc flowDfs(current, sink, available: int): int =
  if current == sink: return available
  var edgeIdx = iterEdge[current]
  while edgeIdx != -1:
    let target = edgeTo[edgeIdx]
    if workCap[edgeIdx] > 0 and level[target] == level[current] + 1:
      let pushed = flowDfs(target, sink, min(available, workCap[edgeIdx]))
      if pushed > 0:
        workCap[edgeIdx] -= pushed
        workCap[edgeIdx xor 1] += pushed
        return pushed
    edgeIdx = edgeNext[edgeIdx]
  iterEdge[current] = -1
  return 0
```

`iterEdge` remembers the last tried arc, so each arc is skipped once per phase. The `xor 1` update maintains residual capacity. A node with no path closes with `iterEdge[current] = -1`.

**Max-flow driver.** BFS builds levels, then DFS pushes until the cap is hit.

```nim
proc minCutValue(source, sink, limit: int): int =
  var total = 0
  while total < limit:
    for node in 0..<nodeCount: level[node] = -1
    level[source] = 0
    var headPos = 0
    var tailPos = 0
    queueNodes[tailPos] = source
    tailPos += 1
    while headPos < tailPos:
      let current = queueNodes[headPos]
      headPos += 1
      var edgeIdx = nodeHead[current]
      while edgeIdx != -1:
        let target = edgeTo[edgeIdx]
        if workCap[edgeIdx] > 0 and level[target] == -1:
          level[target] = level[current] + 1
          queueNodes[tailPos] = target
          tailPos += 1
        edgeIdx = edgeNext[edgeIdx]
    if level[sink] == -1: break
    for node in 0..<nodeCount: iterEdge[node] = nodeHead[node]
    while total < limit:
      let pushed = flowDfs(source, sink, limit - total)
      if pushed == 0: break
      total += pushed
  return total
```

The outer loop stops as soon as `total` reaches `limit`, the best cut so far. BFS fills `queueNodes` only from arcs with positive residual capacity. Each phase costs O(nodes times arcs).

**Driver.** One pass builds each network and tries every pair without a direct cable.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let vertexCount = nextInt(inputData, scanPos)
  let cableCount = nextInt(inputData, scanPos)
  for index in 0..<vertexCount * maxVertexCount: adjacent[index] = false
  nodeCount = vertexCount * 2
  for node in 0..<nodeCount: nodeHead[node] = -1
  edgeCount = 0
  for vertex in 0..<vertexCount:
    splitEdge[vertex] = edgeCount
    addArc(vertex * 2, vertex * 2 + 1, 1)
  for cable in 0..<cableCount:
    let firstVertex = nextInt(inputData, scanPos)
    let secondVertex = nextInt(inputData, scanPos)
    adjacent[firstVertex * maxVertexCount + secondVertex] = true
    adjacent[secondVertex * maxVertexCount + firstVertex] = true
    addArc(firstVertex * 2 + 1, secondVertex * 2, largeCapacity)
    addArc(secondVertex * 2 + 1, firstVertex * 2, largeCapacity)
  var safetyFactor = vertexCount
  if not graphConnected(vertexCount):
    safetyFactor = 0
  else:
    var bestCut = vertexCount
    var sourceVertex = 0
    while sourceVertex < vertexCount and bestCut > 1:
      var sinkVertex = sourceVertex + 1
      while sinkVertex < vertexCount and bestCut > 1:
        if not adjacent[sourceVertex * maxVertexCount + sinkVertex]:
          for edgeIdx in 0..<edgeCount: workCap[edgeIdx] = baseCap[edgeIdx]
          workCap[splitEdge[sourceVertex]] = largeCapacity
          workCap[splitEdge[sinkVertex]] = largeCapacity
          let cutValue = minCutValue(sourceVertex * 2 + 1, sinkVertex * 2, bestCut)
          if cutValue < bestCut: bestCut = cutValue
        sinkVertex += 1
      sourceVertex += 1
    safetyFactor = bestCut
  appendOutput($safetyFactor)
  outputBuffer.add '\n'
stdout.write outputBuffer
```

Split arcs start at capacity 1, and cable arcs get `largeCapacity`. A pair with a direct cable is skipped because its cut stays unlimited. Both loops stop once `bestCut` reaches 1.

## Complexity

The work splits into parsing, graph setup, connectivity, and capped pair flows.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over lines, then one digit pass | input bytes |
| Graph setup | O(n + m) per case | 100 nodes and 6000 arcs |
| Connectivity probe | O(n^2) per case | 50 flags |
| Pair flows | O(n^2) flows, each capped by `bestCut` | 100 level entries |
| Output | one write per 256 KiB block | block buffer |

The bounded node and arc counts keep every phase small at the stated limits.

The asymptotic bounds are:

| Measure | Big O |
|---|---|
| Time | O(t * n^4 * (n + m)) worst case with Dinic over all pairs |
| Space | O(n + m) |

The subset method costs O(t * 2^n * (n + m)), which is far larger at n = 50.
