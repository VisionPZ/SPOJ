# IITWPC4I — Petya and the Road Repairs (SPOJ)
<https://www.spoj.com/problems/IITWPC4I/>

## Problem

Repair roads so every citizen reaches at least one milkman at the lowest total cost. A milkman already has milk, so a citizen who is a milkman needs no road. Print impossible when some citizen cannot reach any milkman.

The first line holds T. Each case starts with n and m, then n zeros or ones, then m lines u v c.
Print one cost per case, or the word impossible on its own line.

The bounds are:

| item | bound |
|---|---|
| test cases T | 1 to 100 |
| citizens n | 1 to 100000 |
| roads m | at most 200000 |
| repair cost c | 1 to 1000000000 |
| judge limit | 1000 ms, 1536 MB |

Costs can sum beyond a 32-bit integer.

Sample input:

```
1
5 7
0 1 0 1 0
1 2 11
1 3 1
1 5 17
2 3 1
3 5 18
4 5 3
2 4 5
```

Citizens two and four are milkmen.

Sample output:

```
5
```

Three cheap roads connect every citizen to a milkman.

## Idea

Think of an imaginary depot linked to every milkman for free, and buy the cheapest road tree that reaches that depot.

Kruskal's algorithm sorts all roads by cost and joins components with a disjoint-set structure. The free links place every milkman in the depot component from the start. A spanning tree on n+1 nodes uses exactly n joins, so the join count reveals unreachable citizens. Trying every road subset grows exponentially.

One sort and one disjoint-set sweep solve each case.

## Why It Works

1. A free edge joins the depot to each real milkman.
2. The minimum tree on all n+1 nodes gives the cheapest repair set.
3. Kruskal takes edges in increasing cost order.
4. The disjoint set skips any edge inside one component.
5. Union by size keeps each find step short.
6. A tree on n+1 nodes uses exactly n joins.
7. Fewer than n joins means some citizen cannot reach the depot.

The main names are:

| term | meaning |
|---|---|
| `edgeCost` | repair cost of one road, or zero for a milkman link |
| `parentNode` | parent of each node in the disjoint set |
| `componentSize` | size of each component |
| `unionCount` | joins accepted so far |
| `totalCost` | running cost in a 64-bit integer |
| `compareEdges` | comparator used by the sort |

The depot has index zero in every array.

The generator produced these accepted roads for the sample:

| road | cost | joined? | running total |
|---|---|---|---|
| 1-3 | 1 | yes | 1 |
| 2-3 | 1 | yes | 2 |
| 4-5 | 3 | yes | 5 |
| 2-4 | 5 | no | 5 |
| 1-2 | 11 | no | 5 |
| 1-5 | 17 | no | 5 |
| 3-5 | 18 | no | 5 |

Three paid roads join every citizen to a milkman.

A case with no milkmen has no free links, so the join count stays short. Integer costs are summed in int64 to avoid overflow.

## Code

**Input and output helpers.** The source reads once, scans integers, and sorts edge indexes through a comparator.

```nim
import algorithm

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

var edgeSource = newSeq[int](0)
var edgeDestination = newSeq[int](0)
var edgeCost = newSeq[int](0)
var edgeOrder = newSeq[int](0)
var parentNode = newSeq[int](0)
var componentSize = newSeq[int](0)

proc compareEdges(leftEdge, rightEdge: int): int =
  if edgeCost[leftEdge] < edgeCost[rightEdge]:
    return -1
  if edgeCost[leftEdge] > edgeCost[rightEdge]:
    return 1
  return 0

proc findRoot(nodeIndex: int): int =
  if parentNode[nodeIndex] != nodeIndex:
    parentNode[nodeIndex] = findRoot(parentNode[nodeIndex])
  return parentNode[nodeIndex]

```

`findRoot` compresses paths as it walks up the tree.
`compareEdges` reads costs from the shared global array.
Block writes keep stdout calls rare.

**Kruskal sweep.** Free milkman links join the road list, then the sorted edges are tested.

```nim
let testCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. testCount - 1:
  let citizenCount = nextInt(inputData, scanPos)
  let roadCount = nextInt(inputData, scanPos)
  var milkmanFlags = newSeq[int](citizenCount + 1)
  var milkmanCount = 0
  for citizenIndex in 1 .. citizenCount:
    milkmanFlags[citizenIndex] = nextInt(inputData, scanPos)
    if milkmanFlags[citizenIndex] == 1:
      milkmanCount += 1
  let totalEdges = roadCount + milkmanCount
  edgeSource.setLen(totalEdges)
  edgeDestination.setLen(totalEdges)
  edgeCost.setLen(totalEdges)
  edgeOrder.setLen(totalEdges)
  var edgeIndex = 0
  for roadIndex in 0 .. roadCount - 1:
    let firstCitizen = nextInt(inputData, scanPos)
    let secondCitizen = nextInt(inputData, scanPos)
    let repairCost = nextInt(inputData, scanPos)
    edgeSource[edgeIndex] = firstCitizen
    edgeDestination[edgeIndex] = secondCitizen
    edgeCost[edgeIndex] = repairCost
    edgeIndex += 1
  for citizenIndex in 1 .. citizenCount:
    if milkmanFlags[citizenIndex] == 1:
      edgeSource[edgeIndex] = 0
      edgeDestination[edgeIndex] = citizenIndex
      edgeCost[edgeIndex] = 0
      edgeIndex += 1
  for orderIndex in 0 .. totalEdges - 1:
    edgeOrder[orderIndex] = orderIndex
  sort(edgeOrder, compareEdges)
  parentNode.setLen(citizenCount + 1)
  componentSize.setLen(citizenCount + 1)
  for nodeIndex in 0 .. citizenCount:
    parentNode[nodeIndex] = nodeIndex
    componentSize[nodeIndex] = 1
  var unionCount = 0
  var totalCost: int64 = 0
  for orderIndex in 0 .. totalEdges - 1:
    let currentEdge = edgeOrder[orderIndex]
    var rootFirst = findRoot(edgeSource[currentEdge])
    var rootSecond = findRoot(edgeDestination[currentEdge])
    if rootFirst == rootSecond:
      continue
    if componentSize[rootFirst] < componentSize[rootSecond]:
      let swapRoot = rootFirst
      rootFirst = rootSecond
      rootSecond = swapRoot
    parentNode[rootSecond] = rootFirst
    componentSize[rootFirst] = componentSize[rootFirst] + componentSize[rootSecond]
    totalCost = totalCost + int64(edgeCost[currentEdge])
    unionCount += 1
    if unionCount == citizenCount:
      break
  if unionCount < citizenCount:
    appendOutput("impossible")
  else:
    appendOutput($totalCost)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0

```

Each accepted join adds its cost to `totalCost`.
The sweep stops once all citizens join the depot.
A short `unionCount` prints the impossible message.

## Complexity

The work splits into phases:

| phase | time | space |
|---|---|---|
| input read | one pass over m roads | one input string |
| edge sort | one sort of m plus milkman links | one index array |
| disjoint set | almost constant work per edge | two node arrays |
| output | one line per case | block buffer |

The edge sort dominates the work.

The asymptotic costs are:

| measure | Big O |
|---|---|
| time | O((m + n) times log(m + n)) per case |
| space | O(m + n) per case |

Testing all road subsets would grow exponentially with m.

Sorting once and joining components gives the minimum cost directly.
