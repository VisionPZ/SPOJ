# EAGLE1 — Eagle and Dogs (SPOJ)

<https://www.spoj.com/problems/EAGLE1/>

## Problem

Eagle walks along unused roads of a weighted tree until no unused road remains at his current intersection. For each starting intersection, report the largest number of dogs he can see on such a walk.

The first line gives the test count T. Each test case gives n, then n - 1 triples u, v, d. Print n space-separated values per case.

| item | bound |
|---|---|
| test count T | 1 to 10 |
| intersections n | 2 to 100000 |
| dogs per road d | 1 to 10^9 |
| judge limit | 1000 ms, 1536 MB |

An unused road cannot be retraced, so a walk follows a simple path away from its start.

Sample input:

```
1
4
1 2 3
3 2 4
3 4 5
```

Sample output:

```
12 9 7 12
```

## Idea

A walk that never reuses a road follows one simple path, like walking away from a camp along one branch and never doubling back. The worst path from a node ends at a farthest node, and in a tree every farthest node is an endpoint of the diameter.

The algorithm finds the two diameter endpoints with three iterative tree walks. Distances from both endpoints give the answer for all nodes at once. A naïve search from each node would run a full traversal n times.

Each traversal is linear in n, and no recursion is used, so deep chains stay safe.

## Why It Works

1. After crossing an edge, Eagle cannot cross it again, so the walk never returns to a visited node.
2. Any simple path from a start can be realized by choosing its edges in order.
3. The worst score from a start is therefore its maximum weighted distance to another node.
4. In a tree, a farthest node from any start is one of the two diameter endpoints.
5. Taking the larger of the two endpoint distances gives that maximum.

| term | meaning |
|---|---|
| `farthestWalk` | iterative traversal returning the farthest node and filling distances |
| `fromFirstEnd` | distances from the first diameter endpoint |
| `fromSecondEnd` | distances from the second diameter endpoint |
| `edgeWeight` | dogs seen on one directed edge slot |
| `head` | first edge slot stored for each intersection |

Distances use int64 because a chain can exceed 10^13 dogs.

A script-generated trace for the sample tree:

```
diameter ends 1 and 4
dist from 1: 0 3 7 12
dist from 4: 12 9 5 0
answer:      12 9 7 12
```

The last row matches the sample output.

## Code

**Input and traversal.** Edges are stored in forward and reverse slots, and walks use an explicit stack.

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

proc farthestWalk(nodeCount: int, head: seq[int], neighborNode: seq[int], nextEdge: seq[int], edgeWeight: seq[int64], startNode: int, distances: var seq[int64]): int =
  for nodeIndex in 0 .. nodeCount:
    distances[nodeIndex] = -1
  var walkStack = newSeq[int](nodeCount + 1)
  var stackTop = 0
  walkStack[0] = startNode
  distances[startNode] = 0
  var farthestNode = startNode
  while stackTop >= 0:
    let currentNode = walkStack[stackTop]
    stackTop -= 1
    if distances[currentNode] > distances[farthestNode]:
      farthestNode = currentNode
    var edgeIndex = head[currentNode]
    while edgeIndex != -1:
      let neighbor = neighborNode[edgeIndex]
      if distances[neighbor] < 0:
        distances[neighbor] = distances[currentNode] + edgeWeight[edgeIndex]
        stackTop += 1
        walkStack[stackTop] = neighbor
      edgeIndex = nextEdge[edgeIndex]
  return farthestNode
```

Negative distance marks an unvisited node.
The stack never holds more than n nodes.
Each edge slot is inspected once per walk.

**Endpoints and output.** Three walks produce the two distance arrays, then one line is emitted.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let nodeCount = nextInt(inputData, scanPos)
  var head = newSeq[int](nodeCount + 1)
  for nodeIndex in 0 .. nodeCount:
    head[nodeIndex] = -1
  let edgeSlots = 2 * (nodeCount - 1)
  var neighborNode = newSeq[int](edgeSlots)
  var nextEdge = newSeq[int](edgeSlots)
  var edgeWeight = newSeq[int64](edgeSlots)
  var edgeIndex = 0
  for edgeNumber in 0 .. nodeCount - 2:
    let firstNode = nextInt(inputData, scanPos)
    let secondNode = nextInt(inputData, scanPos)
    let dogCount = int64(nextInt(inputData, scanPos))
    neighborNode[edgeIndex] = secondNode
    edgeWeight[edgeIndex] = dogCount
    nextEdge[edgeIndex] = head[firstNode]
    head[firstNode] = edgeIndex
    edgeIndex += 1
    neighborNode[edgeIndex] = firstNode
    edgeWeight[edgeIndex] = dogCount
    nextEdge[edgeIndex] = head[secondNode]
    head[secondNode] = edgeIndex
    edgeIndex += 1
  var fromStart = newSeq[int64](nodeCount + 1)
  var fromFirstEnd = newSeq[int64](nodeCount + 1)
  var fromSecondEnd = newSeq[int64](nodeCount + 1)
  let firstEnd = farthestWalk(nodeCount, head, neighborNode, nextEdge, edgeWeight, 1, fromStart)
  let secondEnd = farthestWalk(nodeCount, head, neighborNode, nextEdge, edgeWeight, firstEnd, fromFirstEnd)
  discard farthestWalk(nodeCount, head, neighborNode, nextEdge, edgeWeight, secondEnd, fromSecondEnd)
  for nodeIndex in 1 .. nodeCount:
    if nodeIndex > 1:
      appendOutput(" ")
    appendOutput($(max(fromFirstEnd[nodeIndex], fromSecondEnd[nodeIndex])))
  appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

The first walk finds one end from node 1.
The second finds the opposite end and its distances.
The third fills distances from that opposite end.

## Complexity

Building the adjacency lists and walking the tree are both linear in n.

| phase | time | space |
|---|---|---|
| input read | one pass over input bytes | one input string |
| adjacency build | one visit per input edge | 2(n - 1) edge slots |
| three walks | three visits per node and edge | three distance arrays |
| output | one buffered line per case | block buffer |

The walks dominate the runtime for large n.

| measure | Big O |
|---|---|
| time | O(n) per test case |
| space | O(n) |

Trying each start separately would need n full traversals; this method uses three.
