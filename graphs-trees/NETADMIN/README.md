# NETADMIN — Smart Network Administrator (SPOJ)
<https://www.spoj.com/problems/NETADMIN/>

## Problem

A village finally gets one internet connection at the administrator's house. Every neighbor needs a cable from that house, and each cable must have its own color.

Cables may share a street only when their colors differ. Find the smallest number of colors that serves every willing household.

Input: the first integer is t, the number of cases. Each case gives n houses, m streets, and k clients. Then come k client house numbers and m street pairs. Output: one integer per case, the minimum color count.

These are the bounds and the judge limits:

| Item | Bound |
| --- | --- |
| Test cases t | at most 500 |
| Houses n | at most 500 |
| Clients k | at most n |
| Streets m | from the input |
| Time limit | 4072 ms |
| Memory limit | 1536 MB |

The sample has four clients in the first case and three in the second:

```
2
5 5 4
2 3 4 5
1 2
1 3
2 3
2 4
3 5
8 8 3
4 5 7
1 2
1 8
8 7
1 3
3 6
3 2
2 4
2 5
```

```
2
1
```

The first case needs two colors; the second needs one.

## Idea

Turn colors into street capacity, then search for the smallest capacity that works. Picture one cable per house, with a street able to carry at most one cable of each color.

The program builds a flow network. A super-source sends one unit to each client. Each client sends toward the administrator's house. Every street allows c units, where c is the tested color count.

A maximum-flow (largest possible transport through a network) routine checks whether all k units arrive. Feasibility grows with c, so binary search finds the minimum in log k steps. Each flow uses a push-relabel (push excess toward the sink while relabeling heights) solver with reusable arrays.

The search costs O(log k) flow computations. The naive approach tries every color count from 1 upward and pays up to k flows.

Takeaway: capacity plus binary search replaces a linear scan of color counts.

## Why It Works

Four facts support the reduction.

1. Give each client a unit of flow. Serving all k clients means sending k units to the administrator's house.
2. A street used by more than c cables would repeat a color. Capacity c on every street enforces the color rule exactly.
3. `enoughColors(c)` returns true exactly when the maximum flow reaches k. That is the definition of a feasible color count.
4. If c colors work, then c + 1 colors also work. Monotone feasibility lets binary search find the smallest working c.

The network layout uses these parts:

| Term | Meaning |
| --- | --- |
| Node 0 | super-source, one unit sent to each client |
| Node 1 | sink, the administrator's house |
| `clientList` | houses that need a cable |
| `edgeFirst`, `edgeSecond` | street endpoints |
| `infiniteFlow` | capacity of a source-to-client arc |
| `enoughColors` | true when a tested capacity serves every client |

A script traces the binary search on the first sample case:

```
| tested capacity | max flow | serves 4 clients? |
| --- | --- | --- |
| 2 | 4 | yes |
| 1 | 2 | no |

smallest feasible capacity = 2, so the answer is 2
```

The flow of 2 at capacity 1 proves that one color cannot serve four clients.

## Code

**Graph storage.** Flat arrays hold arcs and the push-relabel state.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const infiniteFlow = 1 shl 29

var head = newSeq[int](0)
var inHead = newSeq[int](0)
var toNode = newSeq[int](0)
var arcCap = newSeq[int](0)
var nextArc = newSeq[int](0)
var nextIn = newSeq[int](0)
var nodeHeight = newSeq[int](0)
var nodeExcess = newSeq[int](0)
var gapCount = newSeq[int](0)
var nodeDistance = newSeq[int](0)
var iterArc = newSeq[int](0)
var inQueue = newSeq[bool](0)
var activeQueue = newSeq[int](0)
var relabelQueue = newSeq[int](0)
var clientList = newSeq[int](0)
var edgeFirst = newSeq[int](0)
var edgeSecond = newSeq[int](0)
var arcCount = 0
var nodeCount = 0
var queueFront = 0
var queueBack = 0
var pushCounter = 0
```

Arrays grow once to the largest case, then get reused. No per-arc object is allocated. Setup cost is O(number of arcs).

**Input.** The scanner reads the whole stream once.

```nim
proc nextInt(data: string, scanPos: var int): int =
  while scanPos < data.len and (data[scanPos] < '0' or data[scanPos] > '9'):
    scanPos += 1
  result = 0
  while scanPos < data.len and data[scanPos] >= '0' and data[scanPos] <= '9':
    result = result * 10 + (int(data[scanPos]) - firstDigitValue)
    scanPos += 1
```

The scan skips non-digits and stops at the buffer end. `scanPos` is a `var` parameter, so progress survives each call. The cost is one pass over the input bytes.

**Arcs.** Each undirected street becomes two arcs in each direction.

```nim
proc reverseArcIndex(arcIndex: int): int =
  if arcIndex mod 2 == 0: arcIndex + 1 else: arcIndex - 1

proc addArc(fromNode, targetNode, capacity: int) =
  toNode[arcCount] = targetNode
  arcCap[arcCount] = capacity
  nextArc[arcCount] = head[fromNode]
  head[fromNode] = arcCount
  nextIn[arcCount] = inHead[targetNode]
  inHead[targetNode] = arcCount
  arcCount += 1
  toNode[arcCount] = fromNode
  arcCap[arcCount] = 0
  nextArc[arcCount] = head[targetNode]
  head[targetNode] = arcCount
  nextIn[arcCount] = inHead[fromNode]
  inHead[fromNode] = arcCount
  arcCount += 1

proc addStreet(firstHouse, secondHouse, capacity: int) =
  addArc(firstHouse, secondHouse, capacity)
  addArc(secondHouse, firstHouse, capacity)
```

Paired arcs sit at even and odd indices, so `reverseArcIndex` is one addition. The residual arc starts at zero capacity. Each street adds four arcs at O(1) cost.

**Labels.** The queue and two heuristics keep the flow solver fast.

```nim
proc enqueueNode(nodeIndex: int) =
  if nodeIndex != 0 and nodeIndex != 1 and not inQueue[nodeIndex]:
    inQueue[nodeIndex] = true
    activeQueue[queueBack mod activeQueue.len] = nodeIndex
    queueBack += 1

proc globalRelabel(sinkNode: int) =
  for i in 0..nodeCount: nodeDistance[i] = -1
  var front = 0
  var back = 0
  nodeDistance[sinkNode] = 0
  relabelQueue[back] = sinkNode
  back += 1
  while front < back:
    let current = relabelQueue[front]
    front += 1
    var arcIndex = inHead[current]
    while arcIndex != -1:
      let previous = toNode[reverseArcIndex(arcIndex)]
      if arcCap[arcIndex] > 0 and nodeDistance[previous] == -1:
        nodeDistance[previous] = nodeDistance[current] + 1
        relabelQueue[back] = previous
        back += 1
      arcIndex = nextIn[arcIndex]
  for i in 0..nodeCount:
    let newHeight = if nodeDistance[i] == -1: nodeCount + 1 else: nodeDistance[i]
    if newHeight != nodeHeight[i]:
      gapCount[nodeHeight[i]] -= 1
      nodeHeight[i] = newHeight
      gapCount[nodeHeight[i]] += 1

proc relabelNode(nodeIndex: int) =
  let oldHeight = nodeHeight[nodeIndex]
  var minimum = infiniteFlow
  var arcIndex = head[nodeIndex]
  while arcIndex != -1:
    if arcCap[arcIndex] > 0:
      let neighbor = toNode[arcIndex]
      if nodeHeight[neighbor] < minimum: minimum = nodeHeight[neighbor]
    arcIndex = nextArc[arcIndex]
  gapCount[oldHeight] -= 1
  nodeHeight[nodeIndex] = minimum + 1
  gapCount[nodeHeight[nodeIndex]] += 1
  if gapCount[oldHeight] == 0 and oldHeight <= nodeCount:
    for i in 0..nodeCount:
      if nodeHeight[i] > oldHeight and nodeHeight[i] <= nodeCount:
        gapCount[nodeHeight[i]] -= 1
        nodeHeight[i] = nodeCount + 1
        gapCount[nodeHeight[i]] += 1
```

The queue wraps with `mod`, so no node is inserted twice. `globalRelabel` recomputes exact distances from the sink. The gap scan lifts nodes that can no longer reach it. Each pass costs O(arcs) or O(nodes).

**Flow.** Push-relabel sends excess toward the sink.

```nim
proc pushRelabel(sourceNode, sinkNode: int): int =
  queueFront = 0
  queueBack = 0
  pushCounter = 0
  for i in 0..nodeCount:
    nodeExcess[i] = 0
    nodeHeight[i] = 0
    inQueue[i] = false
    iterArc[i] = head[i]
    gapCount[i] = 0
  gapCount[nodeCount + 1] = 0
  gapCount[0] = nodeCount + 1
  nodeHeight[sourceNode] = nodeCount + 1
  gapCount[0] -= 1
  gapCount[nodeCount + 1] += 1
  var arcIndex = head[sourceNode]
  while arcIndex != -1:
    let available = arcCap[arcIndex]
    if available > 0:
      arcCap[arcIndex] = 0
      arcCap[reverseArcIndex(arcIndex)] += available
      let neighbor = toNode[arcIndex]
      nodeExcess[neighbor] += available
      enqueueNode(neighbor)
    arcIndex = nextArc[arcIndex]
  while queueFront < queueBack:
    let current = activeQueue[queueFront mod activeQueue.len]
    queueFront += 1
    inQueue[current] = false
    while nodeExcess[current] > 0:
      var edgeIndex = iterArc[current]
      while edgeIndex != -1:
        let neighbor = toNode[edgeIndex]
        if arcCap[edgeIndex] > 0 and nodeHeight[neighbor] + 1 == nodeHeight[current]:
          let amount = min(nodeExcess[current], arcCap[edgeIndex])
          arcCap[edgeIndex] -= amount
          arcCap[reverseArcIndex(edgeIndex)] += amount
          nodeExcess[current] -= amount
          nodeExcess[neighbor] += amount
          enqueueNode(neighbor)
          pushCounter += 1
          if nodeExcess[current] == 0: break
        edgeIndex = nextArc[edgeIndex]
      iterArc[current] = edgeIndex
      if nodeExcess[current] > 0:
        if iterArc[current] == -1:
          if pushCounter mod (nodeCount * 4 + 1) == 0: globalRelabel(sinkNode)
          relabelNode(current)
          iterArc[current] = head[current]
        else:
          iterArc[current] = nextArc[iterArc[current]]
  return nodeExcess[sinkNode]
```

The loop ends when no active node has excess. `iterArc` remembers the last scanned arc, so each node rescans arcs only after a relabel. The return value is the flow reaching the sink.

**Feasibility.** One capacity test rebuilds the network and runs the flow.

```nim
proc enoughColors(capacity: int): bool =
  for i in 0..nodeCount:
    head[i] = -1
    inHead[i] = -1
  arcCount = 0
  for i in 0..<clientList.len:
    addArc(0, clientList[i], 1)
  for i in 0..<edgeFirst.len:
    addStreet(edgeFirst[i], edgeSecond[i], capacity)
  return pushRelabel(0, 1) == clientList.len
```

Client arcs carry one unit each. Street arcs carry `capacity` units. The test succeeds when the sink receives exactly `clientList.len` units. Rebuilding costs one pass over the stored street list.

**Driver.** Binary search finds the smallest feasible capacity.

```nim
let inputData = readStreamBytes()
var scanPos = 0
let caseCount = nextInt(inputData, scanPos)
var outputBuffer = ""

for caseIndex in 0..<caseCount:
  let houseCount = nextInt(inputData, scanPos)
  let streetCount = nextInt(inputData, scanPos)
  let clientCount = nextInt(inputData, scanPos)
  nodeCount = houseCount
  if head.len <= houseCount:
    head.setLen(houseCount + 1)
    inHead.setLen(houseCount + 1)
    nodeHeight.setLen(houseCount + 1)
    nodeExcess.setLen(houseCount + 1)
    nodeDistance.setLen(houseCount + 1)
    iterArc.setLen(houseCount + 1)
    inQueue.setLen(houseCount + 1)
    activeQueue.setLen(houseCount + 2)
    relabelQueue.setLen(houseCount + 2)
  if gapCount.len < 2 * houseCount + 4: gapCount.setLen(2 * houseCount + 4)
  let neededArcs = 4 * streetCount + 2 * clientCount + 4
  if toNode.len < neededArcs:
    toNode.setLen(neededArcs)
    arcCap.setLen(neededArcs)
    nextArc.setLen(neededArcs)
    nextIn.setLen(neededArcs)
  clientList.setLen(clientCount)
  for i in 0..<clientCount: clientList[i] = nextInt(inputData, scanPos)
  edgeFirst.setLen(streetCount)
  edgeSecond.setLen(streetCount)
  for i in 0..<streetCount:
    edgeFirst[i] = nextInt(inputData, scanPos)
    edgeSecond[i] = nextInt(inputData, scanPos)
  var lowerBound = 0
  var upperBound = clientCount + 1
  while upperBound - lowerBound > 1:
    let middle = (lowerBound + upperBound) div 2
    if enoughColors(middle): upperBound = middle
    else: lowerBound = middle
  outputBuffer.add($upperBound)
  outputBuffer.add('\n')
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

stdout.write outputBuffer
outputBuffer.setLen 0
```

Arrays grow only when a case needs more space. The search starts with `upperBound = clientCount + 1`, which always works. About log(k) flow runs finish each case.

## Complexity

Network setup and the flow search carry the cost.

| Phase | Time | Space |
| --- | --- | --- |
| Input scan | O(total tokens) | O(input size) |
| Network build per test | O(m + k) | O(m + n) |
| One push-relabel run | O(n² √m) worst case | O(m + n) |
| Binary search | O(log k) flow runs | O(m + n) |
| Output | O(cases) | O(block size) |

The binary search dominates, with about log(k) maximum-flow computations per case.

| Measure | Big O |
| --- | --- |
| Time per case | O(log k × flow(n, m)) |
| Space | O(n + m) |

Testing capacities from 1 upward costs up to k flows instead of log k flows.
