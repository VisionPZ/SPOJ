# QTREE5 — Query on a tree V (SPOJ)

<https://www.spoj.com/problems/QTREE5/>

## Problem

A tree starts with every node black. A toggle flips one node between black and white, and a query asks for the smallest distance from a given node to any white node.

Input gives N, then N-1 edges, then Q instructions. Instruction `0 i` toggles node `i`. Instruction `1 v` asks the nearest-white distance to node `v`, or `-1` when no white node exists.

| item | bound |
|---|---|
| nodes N | up to 100000 |
| instructions Q | up to 100000 |
| judge limit | 1000 ms, 1536 MB |

Both N and Q reach 100000, so each instruction needs polylogarithmic work.

Sample input:

```
10
1 2
1 3
2 4
1 5
1 6
4 7
7 8
5 9
1 10
10
0 6
0 6
0 6
1 3
0 1
0 1
1 3
1 10
1 4
1 6
```

Sample output:

```
2
2
2
3
0
```

## Idea

Think of each centroid as a lookout tower with a bucket for every branch leading away from it. Each bucket keeps the closest white node on that branch, like a guard reporting the nearest light. A query walks up the tower chain and ignores only the bucket containing the starting node.

The algorithm is centroid decomposition with lazy min-heaps. A toggle updates one bucket and one tower per ancestor. A query reads the best two buckets per tower, so it can skip the blocked branch in constant time.

A breadth-first search per query would cost O(N) each and fail at Q = 100000.

## Why It Works

1. Removing a centroid splits its component into branches of at most half the size.
2. Every node has at most O(log N) centroid ancestors, one per decomposition level.
3. For an ancestor c, the nearest white node to v through c is `dist(v,c)` plus the closest white distance from c in any other branch.
4. Each branch keeps a min-heap of white-node distances, with stale entries removed lazily on top.
5. Each tower keeps a heap of branch minima, so the best two distinct branches are available after cleaning stale entries.

| term | meaning |
|---|---|
| `partHeaps` | min-heaps of white distances for branches of a centroid |
| `centroidHeaps` | min-heaps of branch minima, one per centroid |
| `selfPart` | branch id representing the centroid node itself |
| `ancestorCentroid` | centroid ancestors of a node |
| `farDistance` | sentinel used when a branch has no white node |

For the sample, after toggling node 6 three times it stays white. The query at node 3 sees centroid 1 and skips the branch holding node 3, giving distance 2 through node 6.

## Code

**Heap and input.** Min-heaps store `(key, id)` pairs; the id is a node in branch heaps and a branch id in tower heaps.

```nim
const flushBlockBytes = 1 shl 17
const farDistance = 1 shl 28

type HeapEntry = tuple[key: int, id: int]
type MinHeap = seq[HeapEntry]

proc heapPush(heap: var MinHeap; entry: HeapEntry) =
  heap.add entry
  var childIndex = heap.len - 1
  while childIndex > 0:
    let parentIndex = (childIndex - 1) div 2
    if heap[parentIndex].key <= heap[childIndex].key:
      break
    let parentEntry = heap[parentIndex]
    heap[parentIndex] = heap[childIndex]
    heap[childIndex] = parentEntry
    childIndex = parentIndex

proc heapPop(heap: var MinHeap): HeapEntry =
  result = heap[0]
  let lastEntry = heap.pop()
  if heap.len > 0:
    heap[0] = lastEntry
    var parentIndex = 0
    while true:
      let leftIndex = parentIndex * 2 + 1
      let rightIndex = leftIndex + 1
      var smallestIndex = leftIndex
      if rightIndex < heap.len and heap[rightIndex].key < heap[leftIndex].key:
        smallestIndex = rightIndex
      if smallestIndex >= heap.len or heap[parentIndex].key <= heap[smallestIndex].key:
        break
      let smallerEntry = heap[smallestIndex]
      heap[smallestIndex] = heap[parentIndex]
      heap[parentIndex] = smallerEntry
      parentIndex = smallestIndex

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

var nodeCount = nextInt(inputData, scanPos)
var headEdge = newSeq[int](nodeCount + 1)
for index in 0 .. nodeCount:
  headEdge[index] = -1
var edgeTarget = newSeq[int](2 * nodeCount)
var edgeNext = newSeq[int](2 * nodeCount)
var edgeCursor = 0

proc addEdge(fromNode, toNode: int) =
  edgeTarget[edgeCursor] = toNode
  edgeNext[edgeCursor] = headEdge[fromNode]
  headEdge[fromNode] = edgeCursor
  edgeCursor += 1

for edgeIndex in 0 .. nodeCount - 2:
  let firstNode = nextInt(inputData, scanPos)
  let secondNode = nextInt(inputData, scanPos)
  addEdge(firstNode, secondNode)
  addEdge(secondNode, firstNode)
```

Edges use adjacency arrays rather than nested sequences.
Each heap operation moves along one root-to-leaf path.
The scanner reads the tree before decomposition begins.

**Centroid construction.** Subtree sizes and ancestor lists are built with iterative stack walks.

```nim
var aliveNodes = newSeq[bool](nodeCount + 1)
for nodeIndex in 1 .. nodeCount:
  aliveNodes[nodeIndex] = true
var subtreeSizes = newSeq[int](nodeCount + 1)
var walkParent = newSeq[int](nodeCount + 1)
var ancestorCentroid = newSeq[seq[int]](nodeCount + 1)
var ancestorDistance = newSeq[seq[int]](nodeCount + 1)
var ancestorPart = newSeq[seq[int]](nodeCount + 1)
var partHeaps = newSeq[MinHeap](0)
var selfPart = newSeq[int](nodeCount + 1)
var centroidHeaps = newSeq[MinHeap](nodeCount + 1)
var whiteNodes = newSeq[bool](nodeCount + 1)

proc measureSubtrees(startNode, parentNode: int): seq[int] =
  var stackNodes = newSeq[int](0)
  var visitOrder = newSeq[int](0)
  stackNodes.add startNode
  walkParent[startNode] = parentNode
  while stackNodes.len > 0:
    let currentNode = stackNodes.pop()
    visitOrder.add currentNode
    var edgeIndex = headEdge[currentNode]
    while edgeIndex != -1:
      let neighbor = edgeTarget[edgeIndex]
      if neighbor != walkParent[currentNode] and aliveNodes[neighbor]:
        walkParent[neighbor] = currentNode
        stackNodes.add neighbor
      edgeIndex = edgeNext[edgeIndex]
  for orderIndex in countdown(visitOrder.len - 1, 0):
    let currentNode = visitOrder[orderIndex]
    var sizeValue = 1
    var edgeIndex = headEdge[currentNode]
    while edgeIndex != -1:
      let neighbor = edgeTarget[edgeIndex]
      if walkParent[neighbor] == currentNode and aliveNodes[neighbor]:
        sizeValue += subtreeSizes[neighbor]
      edgeIndex = edgeNext[edgeIndex]
    subtreeSizes[currentNode] = sizeValue
  return visitOrder

proc createPart(ownerCentroid: int): int =
  let partIndex = partHeaps.len
  partHeaps.add newSeq[HeapEntry]()
  selfPart[ownerCentroid] = partIndex
  return partIndex

proc recordAncestors(centroidNode, startNode, startDistance, partIndex: int) =
  var stackNodes = newSeq[int](0)
  var stackDistances = newSeq[int](0)
  stackNodes.add startNode
  stackDistances.add startDistance
  walkParent[startNode] = centroidNode
  while stackNodes.len > 0:
    let currentNode = stackNodes.pop()
    let currentDistance = stackDistances.pop()
    ancestorCentroid[currentNode].add centroidNode
    ancestorDistance[currentNode].add currentDistance
    ancestorPart[currentNode].add partIndex
    var edgeIndex = headEdge[currentNode]
    while edgeIndex != -1:
      let neighbor = edgeTarget[edgeIndex]
      if neighbor != walkParent[currentNode] and aliveNodes[neighbor]:
        walkParent[neighbor] = currentNode
        stackNodes.add neighbor
        stackDistances.add currentDistance + 1
      edgeIndex = edgeNext[edgeIndex]

proc decompose(startNode, parentNode: int) =
  let visitOrder = measureSubtrees(startNode, parentNode)
  let totalNodes = visitOrder.len
  var centroidNode = startNode
  var moved = true
  while moved:
    moved = false
    var edgeIndex = headEdge[centroidNode]
    while edgeIndex != -1:
      let neighbor = edgeTarget[edgeIndex]
      if aliveNodes[neighbor]:
        var branchSize = subtreeSizes[neighbor]
        if neighbor == walkParent[centroidNode]:
          branchSize = totalNodes - subtreeSizes[centroidNode]
        if branchSize > totalNodes div 2:
          centroidNode = neighbor
          moved = true
          break
      edgeIndex = edgeNext[edgeIndex]
  aliveNodes[centroidNode] = false
  let ownPart = createPart(centroidNode)
  ancestorCentroid[centroidNode].add centroidNode
  ancestorDistance[centroidNode].add 0
  ancestorPart[centroidNode].add ownPart
  var edgeIndex = headEdge[centroidNode]
  while edgeIndex != -1:
    let neighbor = edgeTarget[edgeIndex]
    if aliveNodes[neighbor]:
      let branchPart = partHeaps.len
      partHeaps.add newSeq[HeapEntry]()
      recordAncestors(centroidNode, neighbor, 1, branchPart)
    edgeIndex = edgeNext[edgeIndex]
  edgeIndex = headEdge[centroidNode]
  while edgeIndex != -1:
    let neighbor = edgeTarget[edgeIndex]
    if aliveNodes[neighbor]:
      decompose(neighbor, centroidNode)
    edgeIndex = edgeNext[edgeIndex]

decompose(1, 0)
```

Each centroid owns one branch per living neighbour.
Ancestor lists hold at most O(log N) entries per node.
Stack walks avoid deep recursion on path-shaped trees.

**Toggles and queries.** Lazy cleaning removes stale heap entries before every decision.

```nim
proc partMinimum(partIndex: int): int =
  while partHeaps[partIndex].len > 0 and not whiteNodes[partHeaps[partIndex][0].id]:
    discard heapPop(partHeaps[partIndex])
  if partHeaps[partIndex].len == 0:
    return farDistance
  return partHeaps[partIndex][0].key

proc cleanCentroidHeap(centroidNode: int) =
  while centroidHeaps[centroidNode].len > 0:
    let topEntry = centroidHeaps[centroidNode][0]
    var expected = partMinimum(topEntry.id)
    if topEntry.id == selfPart[centroidNode]:
      if whiteNodes[centroidNode]:
        expected = 0
      else:
        expected = farDistance
    if topEntry.key == expected:
      break
    discard heapPop(centroidHeaps[centroidNode])

proc toggleNode(nodeIndex: int) =
  whiteNodes[nodeIndex] = not whiteNodes[nodeIndex]
  for recordIndex in 0 ..< ancestorCentroid[nodeIndex].len:
    let centroidNode = ancestorCentroid[nodeIndex][recordIndex]
    let distanceValue = ancestorDistance[nodeIndex][recordIndex]
    let partIndex = ancestorPart[nodeIndex][recordIndex]
    if whiteNodes[nodeIndex]:
      heapPush(partHeaps[partIndex], (key: distanceValue, id: nodeIndex))
    let currentMin = partMinimum(partIndex)
    if currentMin < farDistance:
      heapPush(centroidHeaps[centroidNode], (key: currentMin, id: partIndex))

proc nearestWhiteDistance(nodeIndex: int): int =
  var bestDistance = farDistance
  for recordIndex in 0 ..< ancestorCentroid[nodeIndex].len:
    let centroidNode = ancestorCentroid[nodeIndex][recordIndex]
    let distanceValue = ancestorDistance[nodeIndex][recordIndex]
    let partIndex = ancestorPart[nodeIndex][recordIndex]
    cleanCentroidHeap(centroidNode)
    if centroidHeaps[centroidNode].len == 0:
      continue
    let firstEntry = centroidHeaps[centroidNode][0]
    discard heapPop(centroidHeaps[centroidNode])
    cleanCentroidHeap(centroidNode)
    while centroidHeaps[centroidNode].len > 0 and centroidHeaps[centroidNode][0].id == firstEntry.id:
      discard heapPop(centroidHeaps[centroidNode])
      cleanCentroidHeap(centroidNode)
    var secondKey = farDistance
    if centroidHeaps[centroidNode].len > 0:
      secondKey = centroidHeaps[centroidNode][0].key
    heapPush(centroidHeaps[centroidNode], firstEntry)
    var chosenKey = firstEntry.key
    if centroidNode != nodeIndex and firstEntry.id == partIndex:
      chosenKey = secondKey
    if chosenKey < farDistance and distanceValue + chosenKey < bestDistance:
      bestDistance = distanceValue + chosenKey
  if bestDistance >= farDistance:
    return -1
  return bestDistance

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let instructionCount = nextInt(inputData, scanPos)
for instructionIndex in 0 .. instructionCount - 1:
  let instructionType = nextInt(inputData, scanPos)
  if instructionType == 0:
    let targetNode = nextInt(inputData, scanPos)
    toggleNode(targetNode)
  else:
    let queryNode = nextInt(inputData, scanPos)
    appendOutput($nearestWhiteDistance(queryNode))
    outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

A toggle touches one branch per ancestor.
A query skips only the branch that holds the query node.
The sentinel `farDistance` means no white node was found.

## Complexity

Centroid decomposition is built once before any instruction runs.

| phase | time | space |
|---|---|---|
| input read | one pass over edges and instructions | adjacency arrays |
| decomposition | one centroid per node, O(log N) records each | ancestor and heap arrays |
| toggle | one heap push per centroid ancestor | branch heaps |
| query | two heap reads per centroid ancestor | output buffer |

Each ancestor list has length at most the tree height of the centroid tree.

| measure | Big O |
|---|---|
| time | O(N log N + Q log² N) |
| space | O(N log N) |

A breadth-first search per query would cost O(NQ) in the worst case.
