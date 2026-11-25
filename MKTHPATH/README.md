# MKTHPATH — Kth Shortest Path (SPOJ)

<https://www.spoj.com/problems/MKTHPATH/>

## Problem

Find the k-th shortest directed path from a start node to a goal node, using no node twice. Paths rank first by total edge length, then by dictionary order of their node sequences.

The input holds datasets until five zeros. Each dataset gives node count, edge count, rank, start, and goal, then one line per directed edge. Output the node sequence with hyphens, or `None` when fewer than k paths exist.

| item | bound |
|---|---|
| nodes `n` | 2 to 50 |
| edges `m` | 0 to n(n-1) |
| requested rank `k` | 1 to 200 |
| edge length | 1 to 10000 |
| judge limit | 600 ms, 1536 MB |

The rank bound drives the design, since the answer needs only the first k paths.

Sample input:

```
5 20 10 1 5
1 2 1
1 3 2
1 4 1
1 5 3
2 1 1
2 3 1
2 4 2
2 5 2
3 1 1
3 2 2
3 4 1
3 5 1
4 1 1
4 2 1
4 3 1
4 5 2
5 1 1
5 2 1
5 3 1
5 4 1
4 6 1 1 4
2 4 2
1 3 2
1 2 1
1 4 3
2 3 1
3 4 1
3 3 5 1 3
1 2 1
2 3 1
1 3 1
0 0 0 0 0
```

Sample output:

```
1-2-4-3-5
1-2-3-4
None
```

## Idea

Grow paths one edge at a time, shortest first, like pulling slips from a sorted pile. This is best-first enumeration with a priority queue ordered by length, then by node sequence.

Store each partial path as one linked record, so extending it adds a single node instead of copying a sequence. A bit mask rejects any path that would visit a node twice.

A shortest-distance map to the goal removes extensions that can never finish. The first k complete paths popped are the answer.

## Why It Works

1. Every edge has positive length, so extending a path always increases its total.
2. A partial path is popped before all of its extensions, since its length is smaller.
3. The heap orders equal-length paths by their node sequences, matching the required tie break.
4. The bit mask keeps every store path simple, as the statement requires.
5. The first time the goal is reached gives the shortest path; the k-th time gives the k-th path.

| term | meaning |
|---|---|
| `pathNodes` | last node of each stored path record |
| `pathParents` | record index of the preceding node |
| `pathMasks` | bit set of nodes already present in a path |
| `distanceToGoal` | shortest remaining length from each node |

The term table names the structures that keep path growth cheap.

A worked example from the sample ranks the first paths of the first dataset:

```
length 3: 1-2-3-5, 1-2-5, 1-3-5, 1-4-3-5, 1-4-5, 1-5
length 4: 1-4-2-3-5, 1-4-2-5
length 5: 1-2-3-4-5, 1-2-4-3-5
rank 10 lands on 1-2-4-3-5, matching the sample
```

Equal lengths follow node order, so the path starting 1-2-3 comes before the one starting 1-2-4.

## Code

**Input and scanning.** One pass loads all datasets, and a hand scanner reads the integers.

```nim
const flushBlockBytes = 1 shl 17
const maxNodes = 50
const unreachableCost = 1000000000

type
  HeapItem = object
    cost: int
    node: int
    pathId: int

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
```

All input items in this problem are non-negative.
A heap item names a path record instead of holding the sequence.
Loading the input once keeps parsing separate from the search.

**Buffered output.** Answer lines collect in a single string.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The buffer writes in large blocks, not once per dataset.
A final write drains the remaining text.

**Path records and heap order.** Linked records and bit masks describe every partial path.

```nim
var edgeWeights: array[maxNodes + 1, array[maxNodes + 1, int]]
var distanceToGoal: array[maxNodes + 1, int]
var goalNode = 0
var nodeCount = 0
var pathNodes = newSeq[int](0)
var pathParents = newSeq[int](0)
var pathMasks = newSeq[uint64](0)

proc lexLessPath(firstId: int, secondId: int): bool =
  var firstOrder: array[maxNodes + 1, int]
  var secondOrder: array[maxNodes + 1, int]
  var firstLength = 0
  var currentId = firstId
  while currentId >= 0:
    firstOrder[firstLength] = pathNodes[currentId]
    firstLength = firstLength + 1
    currentId = pathParents[currentId]
  var secondLength = 0
  currentId = secondId
  while currentId >= 0:
    secondOrder[secondLength] = pathNodes[currentId]
    secondLength = secondLength + 1
    currentId = pathParents[currentId]
  var firstPos = firstLength - 1
  var secondPos = secondLength - 1
  while firstPos >= 0 and secondPos >= 0:
    if firstOrder[firstPos] != secondOrder[secondPos]:
      return firstOrder[firstPos] < secondOrder[secondPos]
    firstPos = firstPos - 1
    secondPos = secondPos - 1
  return firstLength <= secondLength

proc heapLess(firstItem: HeapItem, secondItem: HeapItem): bool =
  if firstItem.cost != secondItem.cost:
    return firstItem.cost < secondItem.cost
  return lexLessPath(firstItem.pathId, secondItem.pathId)
```

Walking parents rebuilds each sequence without allocation.
The heap compares cost first, then the node sequence.
Bit masks make the repeated-node check a single operation.

**Heap operations.** A binary heap keeps the next path ready.

```nim
proc pushItem(heap: var seq[HeapItem], item: HeapItem) =
  heap.add item
  var index = heap.len - 1
  while index > 0:
    let parentIndex = (index - 1) div 2
    if heapLess(heap[index], heap[parentIndex]):
      swap heap[index], heap[parentIndex]
      index = parentIndex
    else:
      break

proc popItem(heap: var seq[HeapItem]): HeapItem =
  result = heap[0]
  let lastIndex = heap.len - 1
  heap[0] = heap[lastIndex]
  heap.setLen(lastIndex)
  var index = 0
  while true:
    let leftChild = 2 * index + 1
    let rightChild = leftChild + 1
    var smallestIndex = index
    if leftChild < heap.len and heapLess(heap[leftChild], heap[smallestIndex]):
      smallestIndex = leftChild
    if rightChild < heap.len and heapLess(heap[rightChild], heap[smallestIndex]):
      smallestIndex = rightChild
    if smallestIndex == index:
      break
    swap heap[index], heap[smallestIndex]
    index = smallestIndex
```

Sift-up restores order after an insertion.
Sift-down restores order after removing the minimum.
Each operation touches one root-to-leaf branch of the heap.

**Goal distances and output.** Reverse Dijkstra prunes paths that cannot finish.

```nim
proc findGoalDistances() =
  var visited: array[maxNodes + 1, bool]
  for node in 1 .. nodeCount:
    distanceToGoal[node] = unreachableCost
    visited[node] = false
  distanceToGoal[goalNode] = 0
  for step in 1 .. nodeCount:
    var chosenNode = 0
    var bestDistance = unreachableCost
    for node in 1 .. nodeCount:
      if not visited[node] and distanceToGoal[node] < bestDistance:
        bestDistance = distanceToGoal[node]
        chosenNode = node
    if chosenNode == 0:
      break
    visited[chosenNode] = true
    for predecessor in 1 .. nodeCount:
      let edgeLength = edgeWeights[predecessor][chosenNode]
      if edgeLength > 0 and not visited[predecessor]:
        let candidate = bestDistance + edgeLength
        if candidate < distanceToGoal[predecessor]:
          distanceToGoal[predecessor] = candidate

proc appendPathFromId(pathId: int) =
  var pathOrder: array[maxNodes + 1, int]
  var pathLength = 0
  var currentId = pathId
  while currentId >= 0:
    pathOrder[pathLength] = pathNodes[currentId]
    pathLength = pathLength + 1
    currentId = pathParents[currentId]
  var pathText = ""
  var position = pathLength - 1
  while position >= 0:
    if position < pathLength - 1:
      pathText.add '-'
    pathText.add $pathOrder[position]
    position = position - 1
  appendOutput(pathText)
  outputBuffer.add '\n'
```

The reverse pass scans the transposed edges from the goal.
Nodes with no route to the goal are skipped during expansion.
The output walk reverses parent links into start-to-goal order.

**Path enumeration.** Each pop either records a finished path or extends it.

```nim
while true:
  let datasetNodes = nextInt(inputData, scanPos)
  let datasetEdges = nextInt(inputData, scanPos)
  let wantedRank = nextInt(inputData, scanPos)
  let startNode = nextInt(inputData, scanPos)
  goalNode = nextInt(inputData, scanPos)
  if datasetNodes == 0 and datasetEdges == 0 and wantedRank == 0 and
     startNode == 0 and goalNode == 0:
    break
  nodeCount = datasetNodes
  for fromNode in 1 .. nodeCount:
    for toNode in 1 .. nodeCount:
      edgeWeights[fromNode][toNode] = 0
  for edgeIndex in 0 .. datasetEdges - 1:
    let fromNode = nextInt(inputData, scanPos)
    let toNode = nextInt(inputData, scanPos)
    let edgeLength = nextInt(inputData, scanPos)
    edgeWeights[fromNode][toNode] = edgeLength
  findGoalDistances()
  pathNodes.setLen(0)
  pathParents.setLen(0)
  pathMasks.setLen(0)
  pathNodes.add startNode
  pathParents.add -1
  pathMasks.add uint64(1) shl uint64(startNode)
  var heap = newSeq[HeapItem](0)
  pushItem(heap, HeapItem(cost: 0, node: startNode, pathId: 0))
  var foundPaths = newSeq[int](0)
  while heap.len > 0 and foundPaths.len < wantedRank:
    let currentItem = popItem(heap)
    if currentItem.node == goalNode:
      foundPaths.add currentItem.pathId
      continue
    for neighbour in 1 .. nodeCount:
      let edgeLength = edgeWeights[currentItem.node][neighbour]
      if edgeLength == 0 or distanceToGoal[neighbour] >= unreachableCost:
        continue
      let neighbourBit = uint64(1) shl uint64(neighbour)
      if (pathMasks[currentItem.pathId] and neighbourBit) != 0:
        continue
      let newPathId = pathNodes.len
      pathNodes.add neighbour
      pathParents.add currentItem.pathId
      pathMasks.add pathMasks[currentItem.pathId] or neighbourBit
      pushItem(heap, HeapItem(cost: currentItem.cost + edgeLength,
                              node: neighbour, pathId: newPathId))
  if foundPaths.len >= wantedRank:
    appendPathFromId(foundPaths[wantedRank - 1])
  else:
    appendOutput("None")
    outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The search stops as soon as k goal paths are recorded.
A reached goal is not expanded, so every recorded path is complete.
A dataset with too few paths prints the single word `None`.

## Complexity

The heap expands only paths shorter than the k-th answer.

| phase | time | space |
|---|---|---|
| input read | one pass over edge lines | input string |
| reverse Dijkstra | O(n^2) per dataset | distance array |
| path search | one expansion per popped partial path | path records and heap |
| output | one block flush per 128 KiB | output buffer |

The phase table shows that the rank bound limits the search.

| measure | Big O |
|---|---|
| time | O(k * (m log k + n)) for typical graphs |
| space | O(number of expanded path records) |

Enumerating every simple path can take exponential time, while best-first search stops after the k-th goal path.
