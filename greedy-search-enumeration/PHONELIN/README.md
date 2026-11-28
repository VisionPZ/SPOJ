# PHONELIN — Phone Lines (SPOJ)

<https://www.spoj.com/problems/PHONELIN/>

## Problem

Choose which towers accept connections to maximize total city payments minus tower costs. Each city starts at the nearest tower to its left and, after each success, skips three towers and tries the fourth tower further left. A tower pays D minus the distance, and a city stops at the first tower that is out of range or not selected.

Input holds several test cases. Each starts with D, C, T, followed by C city positions and T lines of tower location and cost. The line `-1 -1 -1` ends the input. Output one profit per test case.

| item | bound |
|---|---|
| cities C | at most 100 |
| towers T | at most 100 |
| D, positions, costs | statement gives no numeric cap |
| judge limit | 100 ms, 1536 MB |

Tower count drives the design, since each tower becomes one choice.

Sample input:

```
4 9 6
23
43
18
15
29
50
41
31
40
32 2
26 0
46 7
48 0
50 3
38 1
-1 -1 -1
```

Sample output:

```
5
```

## Idea

Imagine each tower as a box with a price tag and coins from cities placed inside. Picking a box collects its coins and pays its tag, but picking a later box first is forbidden. That is a maximum weight closure problem, solved by one min-cut. Sorting towers puts each city chain on a simple arithmetic path with step four. Trying every subset would take two to the T choices, while the cut takes polynomial time.

## Why It Works

1. Sorting towers by location makes the nearest left tower easy to find.
2. A city chain uses tower indices k, k-4, k-8, while each distance stays within D.
3. A tower on the chain earns D minus its distance only if every earlier chain tower is selected.
4. Put each tower's total earnings minus its cost on one node.
5. An infinite arc from a later chain tower to an earlier one forbids selecting the later without the earlier.
6. The maximum closed set equals total positive node weight minus the minimum cut.

| term | meaning |
|---|---|
| `nodeWeight` | city payments minus cost for one tower |
| `laterTowers` | chain tower that needs its predecessor |
| `earlierTowers` | predecessor tower in the chain |
| `positiveTotal` | sum of positive node weights |

The cut removes exactly the weight of the towers that cannot be kept.

A script trace for the sample gives:

```
sorted towers  26(0) 32(2) 38(1) 46(7) 48(0) 50(3)
node weights   +1    -2    +2    -7    +2    -3
chains         city 29 -> 26, city 41/40 -> 38, city 50 -> 48
choose         26, 38, 48
profit         1 + 2 + 2 = 5
out            5
```

Every sampled city has a chain of length one, so no closure arc is needed.

## Code

**Input helpers.** All lines are read once; the scanner also reads the negative sentinel.

```nim
const flushBlockBytes = 1 shl 17
const flowInfinity: int64 = 1 shl 60

type FlowEdge = object
  target: int
  nextEdge: int
  capacity: int64

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextSignedInt(data: string, pos: var int): int =
  while pos < data.len and data[pos] != '-' and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var negative = false
  if pos < data.len and data[pos] == '-':
    negative = true
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  if negative:
    return -value
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

`nextSignedInt` detects `-1 -1 -1` without a special line check.
`appendOutput` flushes by block, not by test case.
One final flush ends the stream.

**Weights and closure arcs.** Each city chain adds payments and one direction per step.

```nim
proc bestProfit(rangeLimit: int, cityPositions: seq[int], towerLocations: seq[int],
                towerCosts: seq[int]): int64 =
  let towerCount = towerLocations.len
  var nodeWeight = newSeq[int64](towerCount)
  for towerIndex in 0 .. towerCount - 1:
    nodeWeight[towerIndex] = -int64(towerCosts[towerIndex])
  var laterTowers = newSeq[int](0)
  var earlierTowers = newSeq[int](0)
  for cityIndex in 0 .. cityPositions.len - 1:
    let cityX = cityPositions[cityIndex]
    var nearestIndex = -1
    for towerIndex in 0 .. towerCount - 1:
      if towerLocations[towerIndex] < cityX:
        nearestIndex = towerIndex
      else:
        break
    var chainIndex = nearestIndex
    while chainIndex >= 0:
      let distance = cityX - towerLocations[chainIndex]
      if distance > rangeLimit:
        break
      nodeWeight[chainIndex] = nodeWeight[chainIndex] + int64(rangeLimit - distance)
      let nextIndex = chainIndex - 4
      if nextIndex >= 0 and cityX - towerLocations[nextIndex] <= rangeLimit:
        laterTowers.add nextIndex
        earlierTowers.add chainIndex
      chainIndex = nextIndex
```

Costs start as negative weights.
Each reachable chain tower adds its payment.
A step inside range creates one closure arc.

**Flow network and Dinic.** Positive weights go from the source, negative weights to the sink.

```nim
  let sourceNode = towerCount
  let sinkNode = towerCount + 1
  let nodeCount = towerCount + 2
  var edgeHead = newSeq[int](nodeCount)
  for nodeIndex in 0 .. nodeCount - 1:
    edgeHead[nodeIndex] = -1
  var edges = newSeq[FlowEdge](0)
  proc addDirected(frm: int, to: int, capacity: int64) =
    edges.add FlowEdge(target: to, nextEdge: edgeHead[frm], capacity: capacity)
    edgeHead[frm] = edges.len - 1
  proc addLink(frm: int, to: int, capacity: int64) =
    addDirected(frm, to, capacity)
    addDirected(to, frm, 0)
  var positiveTotal: int64 = 0
  for towerIndex in 0 .. towerCount - 1:
    if nodeWeight[towerIndex] > 0:
      positiveTotal = positiveTotal + nodeWeight[towerIndex]
      addLink(sourceNode, towerIndex, nodeWeight[towerIndex])
    elif nodeWeight[towerIndex] < 0:
      addLink(towerIndex, sinkNode, -nodeWeight[towerIndex])
  for linkIndex in 0 .. laterTowers.len - 1:
    addLink(laterTowers[linkIndex], earlierTowers[linkIndex], flowInfinity)
```

Each directed link also gets a zero reverse edge.
The infinite links carry no real payment.
The answer starts from the sum of all positive weights.

```nim
  var level = newSeq[int](nodeCount)
  var iteratorEdge = newSeq[int](nodeCount)
  proc breadthFirst(): bool =
    for nodeIndex in 0 .. nodeCount - 1:
      level[nodeIndex] = -1
    var queue = newSeq[int](nodeCount)
    var queueHead = 0
    var queueTail = 0
    level[sourceNode] = 0
    queue[queueTail] = sourceNode
    queueTail += 1
    while queueHead < queueTail:
      let currentNode = queue[queueHead]
      queueHead += 1
      var edgeIndex = edgeHead[currentNode]
      while edgeIndex != -1:
        let targetNode = edges[edgeIndex].target
        if edges[edgeIndex].capacity > 0 and level[targetNode] == -1:
          level[targetNode] = level[currentNode] + 1
          queue[queueTail] = targetNode
          queueTail += 1
        edgeIndex = edges[edgeIndex].nextEdge
    return level[sinkNode] != -1
  proc sendFlow(currentNode: int, pushed: int64): int64 =
    if currentNode == sinkNode:
      return pushed
    while iteratorEdge[currentNode] != -1:
      let edgeIndex = iteratorEdge[currentNode]
      let targetNode = edges[edgeIndex].target
      if edges[edgeIndex].capacity > 0 and level[targetNode] == level[currentNode] + 1:
        let accepted = sendFlow(targetNode, min(pushed, edges[edgeIndex].capacity))
        if accepted > 0:
          edges[edgeIndex].capacity = edges[edgeIndex].capacity - accepted
          edges[edgeIndex xor 1].capacity = edges[edgeIndex xor 1].capacity + accepted
          return accepted
      iteratorEdge[currentNode] = edges[edgeIndex].nextEdge
    return 0
  var totalFlow: int64 = 0
  while breadthFirst():
    for nodeIndex in 0 .. nodeCount - 1:
      iteratorEdge[nodeIndex] = edgeHead[nodeIndex]
    while true:
      let pushed = sendFlow(sourceNode, flowInfinity)
      if pushed == 0:
        break
      totalFlow = totalFlow + pushed
  return positiveTotal - totalFlow
```

Breadth-first search builds the level graph.
The edge iterator resumes each node where it stopped.
Subtracting the cut gives the best profit.

**Driver.** Towers are sorted, then each case is solved and written once.

```nim
while true:
  let rangeLimit = nextSignedInt(inputData, scanPos)
  let cityCount = nextSignedInt(inputData, scanPos)
  let towerCount = nextSignedInt(inputData, scanPos)
  if rangeLimit == -1 and cityCount == -1 and towerCount == -1:
    break
  var cityPositions = newSeq[int](cityCount)
  for cityIndex in 0 .. cityCount - 1:
    cityPositions[cityIndex] = nextSignedInt(inputData, scanPos)
  var towerLocations = newSeq[int](towerCount)
  var towerCosts = newSeq[int](towerCount)
  for towerIndex in 0 .. towerCount - 1:
    towerLocations[towerIndex] = nextSignedInt(inputData, scanPos)
    towerCosts[towerIndex] = nextSignedInt(inputData, scanPos)
  for towerIndex in 1 .. towerCount - 1:
    var earlierIndex = towerIndex
    while earlierIndex > 0 and towerLocations[earlierIndex - 1] > towerLocations[earlierIndex]:
      swap towerLocations[earlierIndex - 1], towerLocations[earlierIndex]
      swap towerCosts[earlierIndex - 1], towerCosts[earlierIndex]
      earlierIndex -= 1
  let profit = bestProfit(rangeLimit, cityPositions, towerLocations, towerCosts)
  appendOutput($profit)
  appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

Insertion sort keeps locations and costs aligned.
The sentinel ends the loop before any work.
Each answer is appended as one line.

## Complexity

The graph has one node per tower plus a source and sink.

| phase | time | space |
|---|---|---|
| input read | one pass over numbers | one input string |
| chain scan | up to C chains of at most T/4 steps | node weights and arc lists |
| min cut | Dinic on T+2 nodes | one edge array |
| output | one line per case | block buffer |

The chain scan is small because each step skips three towers.

| measure | Big O |
|---|---|
| time | O(C*T + T^3) worst case per case |
| space | O(C*T) worst case |

Enumerating all tower subsets would take exponential time; the closure cut stays polynomial.
