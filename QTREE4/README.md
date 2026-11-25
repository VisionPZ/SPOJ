# QTREE4 — Query on a tree IV (SPOJ)

<https://www.spoj.com/problems/QTREE4/>

## Problem

A tree has white and black nodes. Flip one node at a time and report the largest distance between two white nodes, where the two nodes may be the same.

Input gives the node count, N minus one weighted edges, then the operation count and the operations. A line C a flips node a and a line A asks for the answer. Print one line per query, or the disappearance line when no white node remains.

| item | bound |
|---|---|
| nodes N | up to 100000 |
| queries Q | up to 100000 |
| edge weight | −1000 to 1000 |
| output lines | number of A operations |
| judge limit | 1000 ms, 1536 MB |

The operation count rules out recomputing all white pairs after each flip.

Sample input:

```
3
1 2 1
1 3 1
7
A
C 1
A
C 2
A
C 3
A
```

Sample output:

```
2
2
0
They have disappeared.
```

## Idea

Split the tree into centre regions, like finding the longest trip between two neighbourhoods by keeping the best outgoing road from each neighbourhood.

Centroid decomposition gives every node a logarithmic list of ancestor centroids. For each centroid, a heap per branch holds the best white distance from that centroid into the branch. The two best values from different branches give the best path through that centroid. A global heap holds one contribution per centroid.
A flip touches only the ancestor list of one node. Recomputing all white pairs after a flip would cost quadratic time.
Lazy heaps with version numbers discard outdated values without removing them from the middle.

## Why It Works

1. For any two nodes, the highest centroid separating them sees them in two different branches.
2. The best path through a centroid uses the two largest branch values from distinct branches.
3. Negative distances and a single white node are handled by clamping the contribution to zero.
4. A version number invalidates an old heap entry when that node or branch changes.
5. The global heap top is the maximum contribution over all centroids after stale entries are removed.

| term | meaning |
|---|---|
| `branchHeaps` | lazy max-heap of white distances for one centroid branch |
| `entryVersion` | validity stamp for one node-to-centroid entry |
| `centroidHeaps` | best value per branch at one centroid |
| `answerHeap` | current contribution of every centroid |
| `refreshBranch` | clean one branch heap and update its centroid |
| `refreshCentroid` | recompute the two best branches and the global entry |

The table names the heaps that make flips local.

Worked example from the sample operations:

```
start: white 1 2 3, best distance = 2
after C 1: white 2 3, best distance = 2
after C 2: white 3, best distance = 0
after C 3: no white node, print the disappearance line
```

The traced answers match the sample output.

## Code

**Lazy heaps.** A shared pair of max-heap routines serves every branch, centroid and global list.

```nim
proc heapPush(heap: var seq[HeapNode], item: HeapNode) =
  heap.add item
  var position = heap.len - 1
  while position > 0:
    let parentPosition = (position - 1) div 2
    if heap[parentPosition].value >= heap[position].value:
      break
    swap heap[parentPosition], heap[position]
    position = parentPosition

proc heapPop(heap: var seq[HeapNode]): HeapNode =
  let rootItem = heap[0]
  let lastItem = heap[heap.len - 1]
  heap.setLen(heap.len - 1)
  if heap.len > 0:
    heap[0] = lastItem
    var position = 0
    while true:
      let leftChild = position * 2 + 1
      let rightChild = leftChild + 1
      var largestChild = leftChild
      if rightChild < heap.len and heap[rightChild].value > heap[leftChild].value:
        largestChild = rightChild
      if leftChild >= heap.len or heap[position].value >= heap[largestChild].value:
        break
      swap heap[position], heap[largestChild]
      position = largestChild
  return rootItem

```

Heap nodes carry a value and two integer fields.
Callers interpret those fields as versions and identifiers.
Both operations run in logarithmic time.

**Centroid lists.** These routines split components and record node-to-centroid distances.

```nim
proc collectComponent(startNode: int): seq[int] =
  var componentNodes = newSeq[int]()
  var traversalStack = newSeq[int]()
  traversalStack.add startNode
  componentParent[startNode] = 0
  while traversalStack.len > 0:
    let currentNode = traversalStack[traversalStack.len - 1]
    traversalStack.setLen(traversalStack.len - 1)
    componentNodes.add currentNode
    var edgePointer = adjacencyHead[currentNode]
    while edgePointer != -1:
      let neighborNode = edgeTarget[edgePointer]
      if not removed[neighborNode] and neighborNode != componentParent[currentNode]:
        componentParent[neighborNode] = currentNode
        traversalStack.add neighborNode
      edgePointer = edgeNext[edgePointer]
  return componentNodes

proc findCentroid(componentNodes: seq[int]): int =
  for nodeIndex in componentNodes:
    subtreeSize[nodeIndex] = 1
  for nodePosition in componentNodes.len - 1 .. 0:
    let currentNode = componentNodes[nodePosition]
    let parentNode = componentParent[currentNode]
    if parentNode != 0:
      subtreeSize[parentNode] = subtreeSize[parentNode] + subtreeSize[currentNode]
  let totalNodes = componentNodes.len
  var bestCentroid = componentNodes[0]
  var bestMaximum = totalNodes + 1
  for nodeIndex in componentNodes:
    var maximumPart = totalNodes - subtreeSize[nodeIndex]
    var edgePointer = adjacencyHead[nodeIndex]
    while edgePointer != -1:
      let neighborNode = edgeTarget[edgePointer]
      if not removed[neighborNode] and componentParent[neighborNode] == nodeIndex:
        if subtreeSize[neighborNode] > maximumPart:
          maximumPart = subtreeSize[neighborNode]
      edgePointer = edgeNext[edgePointer]
    if maximumPart < bestMaximum:
      bestMaximum = maximumPart
      bestCentroid = nodeIndex
  return bestCentroid

proc collectBranch(startNode: int, centroidIndex: int, branchId: int, initialDistance: int64) =
  var traversalStack = newSeq[int]()
  var distanceStack = newSeq[int64]()
  traversalStack.add startNode
  distanceStack.add initialDistance
  componentParent[startNode] = centroidIndex
  addPathEntry(startNode, centroidIndex, initialDistance, branchId)
  while traversalStack.len > 0:
    let currentNode = traversalStack[traversalStack.len - 1]
    let currentDistance = distanceStack[distanceStack.len - 1]
    traversalStack.setLen(traversalStack.len - 1)
    distanceStack.setLen(distanceStack.len - 1)
    var edgePointer = adjacencyHead[currentNode]
    while edgePointer != -1:
      let neighborNode = edgeTarget[edgePointer]
      if not removed[neighborNode] and neighborNode != componentParent[currentNode]:
        componentParent[neighborNode] = currentNode
        let branchDistance = currentDistance + int64(edgeWeight[edgePointer])
        addPathEntry(neighborNode, centroidIndex, branchDistance, branchId)
        traversalStack.add neighborNode
        distanceStack.add branchDistance
      edgePointer = edgeNext[edgePointer]

```

Iterative walks avoid deep tree recursion.
A branch holds one original-tree component beside the centroid.
Accumulated distances allow negative edge weights.

**Refresh rules.** These routines clean stale entries and publish new contributions.

```nim
proc refreshCentroid(centroidIndex: int) =
  while centroidHeaps[centroidIndex].len > 0 and
        centroidHeaps[centroidIndex][0].secondField != branchVersion[centroidHeaps[centroidIndex][0].firstField]:
    discard heapPop(centroidHeaps[centroidIndex])
  var bestValue = negativeInfinite
  var bestBranch = -1
  var secondValue = negativeInfinite
  if centroidHeaps[centroidIndex].len > 0:
    let firstItem = heapPop(centroidHeaps[centroidIndex])
    bestValue = firstItem.value
    bestBranch = firstItem.firstField
    while centroidHeaps[centroidIndex].len > 0:
      let topItem = centroidHeaps[centroidIndex][0]
      if topItem.secondField != branchVersion[topItem.firstField]:
        discard heapPop(centroidHeaps[centroidIndex])
        continue
      if topItem.firstField != bestBranch:
        secondValue = topItem.value
        break
      discard heapPop(centroidHeaps[centroidIndex])
    heapPush(centroidHeaps[centroidIndex], firstItem)
  var contribution: int64 = 0
  if bestValue > negativeInfinite div 2:
    if secondValue > negativeInfinite div 2:
      contribution = bestValue + secondValue
    if contribution < 0:
      contribution = 0
  if contribution != centroidValue[centroidIndex]:
    centroidValue[centroidIndex] = contribution
    centroidVersion[centroidIndex] += 1
    heapPush(answerHeap, HeapNode(value: contribution, firstField: centroidIndex,
                                  secondField: centroidVersion[centroidIndex]))

proc refreshBranch(branchId: int, centroidIndex: int) =
  while branchHeaps[branchId].len > 0:
    let topItem = branchHeaps[branchId][0]
    if topItem.firstField == entryVersion[topItem.secondField]:
      break
    discard heapPop(branchHeaps[branchId])
  let newBest = if branchHeaps[branchId].len > 0: branchHeaps[branchId][0].value else: negativeInfinite
  if newBest != branchBest[branchId]:
    branchBest[branchId] = newBest
    branchVersion[branchId] += 1
    if newBest > negativeInfinite div 2:
      heapPush(centroidHeaps[centroidIndex], HeapNode(value: newBest, firstField: branchId,
                                                      secondField: branchVersion[branchId]))
    refreshCentroid(centroidIndex)

```

A branch change reaches its centroid heap only when the best value changes.
Two entries from different branches form the centroid contribution.
A negative or single-branch contribution becomes zero.

**Flips and queries.** The driver builds the structure, flips nodes and answers queries.

```nim
var decompositionStack = newSeq[int]()
decompositionStack.add 1
while decompositionStack.len > 0:
  let startNode = decompositionStack[decompositionStack.len - 1]
  decompositionStack.setLen(decompositionStack.len - 1)
  let componentNodes = collectComponent(startNode)
  let centroidIndex = findCentroid(componentNodes)
  let selfBranch = branchVersion.len
  branchVersion.add 0
  branchBest.add negativeInfinite
  branchCentroid.add centroidIndex
  branchHeaps.add newSeq[HeapNode]()
  addPathEntry(centroidIndex, centroidIndex, 0, selfBranch)
  var edgePointer = adjacencyHead[centroidIndex]
  while edgePointer != -1:
    let neighborNode = edgeTarget[edgePointer]
    if not removed[neighborNode]:
      let newBranch = branchVersion.len
      branchVersion.add 0
      branchBest.add negativeInfinite
      branchCentroid.add centroidIndex
      branchHeaps.add newSeq[HeapNode]()
      collectBranch(neighborNode, centroidIndex, newBranch, int64(edgeWeight[edgePointer]))
      decompositionStack.add neighborNode
    edgePointer = edgeNext[edgePointer]
  removed[centroidIndex] = true

for nodeIndex in 1 .. nodeCount:
  for pathEntry in nodeEntries[nodeIndex]:
    heapPush(branchHeaps[pathEntry.branchId], HeapNode(value: pathEntry.distance,
             firstField: 0, secondField: pathEntry.entryId))
for branchId in 0 .. branchVersion.len - 1:
  refreshBranch(branchId, branchCentroid[branchId])
for centroidIndex in 1 .. nodeCount:
  refreshCentroid(centroidIndex)

var isWhite = newSeq[bool](nodeCount + 1)
for nodeIndex in 1 .. nodeCount:
  isWhite[nodeIndex] = true
var whiteCount = nodeCount

proc toggleNode(nodeIndex: int) =
  let turningWhite = not isWhite[nodeIndex]
  isWhite[nodeIndex] = turningWhite
  if turningWhite:
    whiteCount += 1
  else:
    whiteCount -= 1
  for pathEntry in nodeEntries[nodeIndex]:
    let currentEntryId = pathEntry.entryId
    entryVersion[currentEntryId] += 1
    if turningWhite:
      heapPush(branchHeaps[pathEntry.branchId], HeapNode(value: pathEntry.distance,
               firstField: entryVersion[currentEntryId], secondField: currentEntryId))
    refreshBranch(pathEntry.branchId, pathEntry.centroid)

let queryCount = nextInt(inputData, scanPos)
for queryIndex in 0 .. queryCount - 1:
  while scanPos < inputData.len and inputData[scanPos] <= ' ':
    scanPos += 1
  if inputData[scanPos] == 'C':
    scanPos += 1
    let nodeIndex = nextInt(inputData, scanPos)
    toggleNode(nodeIndex)
  else:
    scanPos += 1
    while answerHeap.len > 0 and answerHeap[0].secondField != centroidVersion[answerHeap[0].firstField]:
      discard heapPop(answerHeap)
    if whiteCount == 0:
      appendOutput("They have disappeared.")
    else:
      var bestAnswer: int64 = 0
      if answerHeap.len > 0:
        bestAnswer = answerHeap[0].value
      appendOutput($bestAnswer)
    outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Initial heaps insert every white node once.
Each flip walks one ancestor list and refreshes each branch.
A query reads the global heap top after cleaning stale entries.

## Complexity

Costs follow the centroid depth of each node.

| phase | time | space |
|---|---|---|
| decomposition | O(N log N) | O(N log N) |
| heap setup | O(N log N) | O(N log N) |
| one flip | O(log^2 N) | O(log N) new entries |
| one query | O(1) amortized | O(1) extra |

Flips dominate the phase table.

| measure | Big O |
|---|---|
| preprocessing | O(N log N) |
| per update | O(log^2 N) |
| space | O((N + Q) log N) |

Scanning all white pairs after a flip costs quadratic time and cannot reach Q = 100000.
Centroid lists keep each flip tied to the tree height of the decomposition.
