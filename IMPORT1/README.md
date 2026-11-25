# IMPORT1 — The Importance (SPOJ)

<https://www.spoj.com/problems/IMPORT1/>

## Problem

An undirected weighted graph is given. For each node, measure how often it lies on shortest paths between other pairs of nodes, weighted by the number of equally short routes. Print one real number with three decimals per node.

The first line gives the number of cases. Each case starts with n and m, followed by m edges with endpoints and a positive weight. Node numbers run from 1 to n, with at most one edge per pair. Every pair has at least one shortest path and at most 10 to the tenth paths.

| item | bound |
|---|---|
| nodes n | at most 100 |
| edges m | at most 4500 |
| edge weight | 1 to 1000 |
| path count | at most 10 to the tenth |
| judge limit | 1000 ms |

The node bound makes all pairs shortest paths affordable.

Sample input:

```
1
4 4
1 2 1
2 3 1
3 4 1
4 1 1
```

Sample output:

```
1.000
1.000
1.000
1.000
```

## Idea

A node is important when many shortest routes must pass through it, like a bridge that traffic has to cross.

The algorithm runs Floyd Warshall once to get every distance and every shortest path count. Then it tests each node as a midpoint for every ordered pair and adds the fraction of routes that go through it. Each case costs cubic time. Enumerating all shortest paths with a search per pair costs far more on dense graphs.

Counting routes during Floyd Warshall turns the fraction sum into a fixed table lookup.

## Why It Works

1. Floyd Warshall relaxes each midpoint in turn and stores the shortest distance for every ordered pair.
2. When a candidate distance is smaller, the number of shortest routes becomes the product of the two subpath counts.
3. When a candidate distance ties, the two products are added to the existing count.
4. A node lies on a shortest s to t route exactly when distance s v plus distance v t equals distance s t.
5. Among all shortest routes, the share through v equals count s v times count v t divided by count s t.
6. Summing that share over ordered pairs with both ends different from v gives the importance of v.

| term | meaning |
|---|---|
| `distances` | shortest distance for every ordered pair |
| `pathCounts` | number of shortest routes for every ordered pair |
| `sourceViaIndex` | table slot for a source and the midpoint |
| `throughPaths` | routes from source to target that pass through the midpoint |
| `importance` | accumulated fraction sum for one node |

The table names the values used by the midpoint sum.

A trace for node 2 of the sample graph:

```
pair  shortest routes  routes through node 2  share
1 3   2                1                       0.500
3 1   2                1                       0.500
1 4   1                0                       0.000
4 1   1                0                       0.000
```

The six ordered pairs among the other three nodes sum to 1.000, matching the sample.

## Code

**Input and buffers.** The program reads all test cases into one string.

```nim
import strutils

const flushBlockBytes = 1 shl 17
const unreachableDistance: int64 = 1000000000000

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

The scanner reads past spaces and line breaks.
The distance tables stay in flat arrays.
All node answers are written through one buffer.

**Floyd Warshall with route counts.** Each midpoint updates distances and route counts.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 ..< caseCount:
  let nodeCount = nextInt(inputData, scanPos)
  let edgeCount = nextInt(inputData, scanPos)
  var distances = newSeq[int64](nodeCount * nodeCount)
  var pathCounts = newSeq[int64](nodeCount * nodeCount)
  for sourceNode in 0 ..< nodeCount:
    for targetNode in 0 ..< nodeCount:
      let matrixIndex = sourceNode * nodeCount + targetNode
      if sourceNode == targetNode:
        distances[matrixIndex] = 0
        pathCounts[matrixIndex] = 1
      else:
        distances[matrixIndex] = unreachableDistance
  for edgeIndex in 0 ..< edgeCount:
    let firstNode = nextInt(inputData, scanPos) - 1
    let secondNode = nextInt(inputData, scanPos) - 1
    let edgeWeight = int64(nextInt(inputData, scanPos))
    let forwardIndex = firstNode * nodeCount + secondNode
    let backwardIndex = secondNode * nodeCount + firstNode
    distances[forwardIndex] = edgeWeight
    distances[backwardIndex] = edgeWeight
    pathCounts[forwardIndex] = 1
    pathCounts[backwardIndex] = 1
  for viaNode in 0 ..< nodeCount:
    for sourceNode in 0 ..< nodeCount:
      if sourceNode == viaNode:
        continue
      let sourceViaIndex = sourceNode * nodeCount + viaNode
      let sourceViaDistance = distances[sourceViaIndex]
      if sourceViaDistance >= unreachableDistance:
        continue
      let sourceViaCount = pathCounts[sourceViaIndex]
      for targetNode in 0 ..< nodeCount:
        if targetNode == viaNode:
          continue
        let viaTargetIndex = viaNode * nodeCount + targetNode
        let candidateDistance = sourceViaDistance + distances[viaTargetIndex]
        let directIndex = sourceNode * nodeCount + targetNode
        if candidateDistance < distances[directIndex]:
          distances[directIndex] = candidateDistance
          pathCounts[directIndex] = sourceViaCount * pathCounts[viaTargetIndex]
        elif candidateDistance == distances[directIndex]:
          pathCounts[directIndex] = pathCounts[directIndex] +
                                    sourceViaCount * pathCounts[viaTargetIndex]
```

Self pairs start with distance zero and one route.
Endpoints equal to the midpoint are skipped so routes are not doubled.
A tie adds the new product to the stored count.

**Importance sum.** Each node becomes the midpoint in a full pair scan.

```nim
  for importanceNode in 0 ..< nodeCount:
    var importance: float = 0.0
    for sourceNode in 0 ..< nodeCount:
      if sourceNode == importanceNode:
        continue
      let sourceViaIndex = sourceNode * nodeCount + importanceNode
      let sourceViaDistance = distances[sourceViaIndex]
      if sourceViaDistance >= unreachableDistance:
        continue
      for targetNode in 0 ..< nodeCount:
        if targetNode == importanceNode or targetNode == sourceNode:
          continue
        let viaTargetIndex = importanceNode * nodeCount + targetNode
        let viaTargetDistance = distances[viaTargetIndex]
        if viaTargetDistance >= unreachableDistance:
          continue
        let directIndex = sourceNode * nodeCount + targetNode
        if sourceViaDistance + viaTargetDistance == distances[directIndex]:
          let throughPaths = float(pathCounts[sourceViaIndex]) *
                             float(pathCounts[viaTargetIndex])
          if pathCounts[directIndex] > 0:
            importance = importance + throughPaths / float(pathCounts[directIndex])
    appendOutput(formatFloat(importance, ffDecimal, 3))
    outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The split equality finds exactly the routes through the midpoint.
Float division keeps the fractional share accurate to three decimals.
Every node writes one line, then the buffer flushes once more.

## Complexity

Both tables are filled once per case, then scanned once more.

| phase | time | space |
|---|---|---|
| input read | one pass over edge lines | one input string |
| Floyd Warshall | n cubed relaxations | two tables of n squared integers |
| importance sum | n cubed midpoint checks | one float per node |
| output | one line per node | block buffer |

The phase table shows that the two cubic phases dominate.

| measure | Big O |
|---|---|
| time | O(n cubed) per case |
| space | O(n squared) per case |

Enumerating shortest paths with a search per pair would multiply that cost by the number of routes.
