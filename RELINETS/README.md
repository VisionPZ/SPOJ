# RELINETS — Reliable Nets (SPOJ)
<https://www.spoj.com/problems/RELINETS/>

## Problem

Choose the cheapest set of links so the network stays connected after any single link breaks. Print the minimum cost, or state that no such set exists.

| item | bound |
|---|---|
| buildings | at most 15 |
| candidate links | at most 20 |
| link cost | positive integer |
| judge limit | 1000 ms, 1536 MB |

Input ends with `0 0`. Output uses one numbered line per test case.

Sample input:

```
4 5
1 2 1
1 3 2
2 4 2
3 4 1
2 3 1
2 1
1 2 5
0 0
```

Sample output:

```
The minimal cost for test case 1 is 6.
There is no reliable net possible for test case 2.
```

## Idea

A reliable net is like a circular bike route: cutting one stretch still lets you ride all the way around. The algorithm tries every link subset and keeps the cheapest one with no bridge. A bridge check walks the subgraph once instead of removing each link and restarting.

## Why It Works

1. A net survives every single cut exactly when it has no bridge.
2. A bridge is an edge whose removal disconnects its component.
3. A depth-first walk gives each node a discovery time and a low link.
4. A tree edge is a bridge when the child's low link exceeds the parent's discovery time.
5. The walk also counts reached nodes, so a disconnected subset is rejected.
6. Checking all subsets and keeping the cheapest valid cost solves the problem.

| term | meaning |
|---|---|
| `subsetPrice` | total cost of one link subset |
| `bestPrice` | cheapest reliable cost found so far |
| `discoveryTime` | visit order of each node, 0 when unseen |
| `lowValue` | earliest discovery reachable from a node |
| `bridgeFound` | flag raised by a bridge during the walk |

For sample case 1, the cycle 1-2-4-3-1 costs 1 + 2 + 1 + 2 = 6. Cutting any of its four links leaves a path through the other three, so the net stays connected. The extra link 2-3 is not needed.

`clockValue` starts at 1, so zero stays reserved for unseen nodes.

## Code

**Input and bridge walk.** The reader loads all numbers, and the recursive walk detects bridges.

```nim
const flushBlockBytes = 1 shl 17
const maximumNodes = 15
const maximumEdges = 20

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

var edgeStart: array[0 .. maximumEdges - 1, int]
var edgeEnd: array[0 .. maximumEdges - 1, int]
var edgePrice: array[0 .. maximumEdges - 1, int]
var nodeTotal = 0
var edgeTotal = 0
var examinedMask = 0
var discoveryTime: array[0 .. maximumNodes - 1, int]
var lowValue: array[0 .. maximumNodes - 1, int]
var clockValue = 0
var bridgeFound = false
var reachedNodes = 0

proc visitNode(currentNode: int, incomingEdge: int) =
  discoveryTime[currentNode] = clockValue
  lowValue[currentNode] = clockValue
  clockValue += 1
  reachedNodes += 1
  for edgeIndex in 0 .. edgeTotal - 1:
    if (examinedMask and (1 shl edgeIndex)) == 0:
      continue
    var neighborNode = -1
    if edgeStart[edgeIndex] == currentNode:
      neighborNode = edgeEnd[edgeIndex]
    elif edgeEnd[edgeIndex] == currentNode:
      neighborNode = edgeStart[edgeIndex]
    else:
      continue
    if edgeIndex == incomingEdge:
      continue
    if discoveryTime[neighborNode] == 0:
      visitNode(neighborNode, edgeIndex)
      if lowValue[neighborNode] > discoveryTime[currentNode]:
        bridgeFound = true
      if lowValue[neighborNode] < lowValue[currentNode]:
        lowValue[currentNode] = lowValue[neighborNode]
    elif discoveryTime[neighborNode] < lowValue[currentNode]:
      lowValue[currentNode] = discoveryTime[neighborNode]

proc isReliable(candidateMask: int): bool =
  if nodeTotal == 1:
    return true
  var degrees: array[0 .. maximumNodes - 1, int]
  for edgeIndex in 0 .. edgeTotal - 1:
    if (candidateMask and (1 shl edgeIndex)) != 0:
      degrees[edgeStart[edgeIndex]] += 1
      degrees[edgeEnd[edgeIndex]] += 1
  for nodeIndex in 0 .. nodeTotal - 1:
    if degrees[nodeIndex] < 2:
      return false
  for nodeIndex in 0 .. nodeTotal - 1:
    discoveryTime[nodeIndex] = 0
    lowValue[nodeIndex] = 0
  examinedMask = candidateMask
  clockValue = 1
  bridgeFound = false
  reachedNodes = 0
  visitNode(0, -1)
  return (not bridgeFound) and reachedNodes == nodeTotal
```

Each node needs two links, so low-degree subsets fail early.
The parent link is skipped by its index, which keeps parallel links correct.
The clock starts at one so zero can mean unseen.

**Subset sweep.** Every subset gets its price, and only cheaper reliable subsets replace the best.

```nim
var testNumber = 0
while true:
  nodeTotal = nextInt(inputData, scanPos)
  edgeTotal = nextInt(inputData, scanPos)
  if nodeTotal == 0 and edgeTotal == 0:
    break
  testNumber += 1
  var totalPrice = 0
  for edgeIndex in 0 .. edgeTotal - 1:
    edgeStart[edgeIndex] = nextInt(inputData, scanPos) - 1
    edgeEnd[edgeIndex] = nextInt(inputData, scanPos) - 1
    edgePrice[edgeIndex] = nextInt(inputData, scanPos)
    totalPrice += edgePrice[edgeIndex]
  var bestPrice = totalPrice + 1
  if nodeTotal == 1:
    bestPrice = 0
  var lowBitPosition = newSeq[int](1 shl edgeTotal)
  for edgeIndex in 0 .. edgeTotal - 1:
    lowBitPosition[1 shl edgeIndex] = edgeIndex
  var subsetPrice = newSeq[int](1 shl edgeTotal)
  for mask in 1 .. (1 shl edgeTotal) - 1:
    let lowBit = mask and (-mask)
    subsetPrice[mask] = subsetPrice[mask xor lowBit] + edgePrice[lowBitPosition[lowBit]]
    if subsetPrice[mask] < bestPrice and isReliable(mask):
      bestPrice = subsetPrice[mask]
  if bestPrice > totalPrice:
    appendOutput("There is no reliable net possible for test case ")
    appendOutput($testNumber)
    appendOutput(".\n")
  else:
    appendOutput("The minimal cost for test case ")
    appendOutput($testNumber)
    appendOutput(" is ")
    appendOutput($bestPrice)
    appendOutput(".\n")
```

The lowest set bit supplies the last added link for each price.
Subsets priced above the current best are skipped without a walk.
A best price above the full set cost means no reliable subset exists.

## Complexity

| phase | time | space |
|---|---|---|
| read links | one pass over m links | link arrays |
| subset sweep | up to 2^m price updates | price table of 2^m words |
| reliability walk | O(n + m) per candidate subset | node arrays |

| measure | Big O |
|---|---|
| per test case | O(2^m * (n + m)) time |
| space | O(2^m) |

Trying to remove every link and rerun connectivity for every subset would multiply the work again.
