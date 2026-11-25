# ADAPHONE — Ada and Contact (SPOJ)

<https://www.spoj.com/problems/ADAPHONE/>

## Problem

For each walk between two friends in a tree, count the independent sets of friends formed when phone numbers spread along consecutive IDs. The answer equals the number of path friends minus the number of adjacent ID pairs that both lie on that path. Think of a row of numbered houses where only neighbours can exchange a slip of paper.

| item | bound |
|---|---|
| friends N | 1 to 200000 |
| walks Q | 1 to 200000 |
| edge endpoints | 1 to N |
| judge limit | 3000 ms, 1536 MB |

The first line holds `N` and `Q`. Then come `N - 1` tree edges and `Q` walk endpoints.

Sample input:

```
7 6
1 6
1 3
3 5
5 7
3 2
2 4
6 7
1 4
2 5
4 7
3 1
5 5
```

Sample output:

```
3
1
2
2
2
1
```

## Idea

Count path nodes with a standard LCA, then count adjacent ID pairs on the path with a sweep over Euler-order rectangles, like sweeping a line across a map of intervals. Each pair (i, i+1) contributes exactly when the walk endpoints fall on opposite sides of both tree cuts around that pair. Checking every pair for every walk is far too slow at 200000 by 200000. The takeaway is to turn containment questions into static rectangles and stab them once.

## Why It Works

1. Phone numbers spread only between IDs whose difference is one.
2. Friends met on a walk form one connected group per run of consecutive IDs.
3. The group count equals path size minus the number of adjacent ID pairs on the path.
4. Removing the tree edge from i toward i+1 splits the tree into two components.
5. A pair is on a walk exactly when the two walk endpoints lie in opposite components at both cuts.
6. Each component is one Euler interval or two, so each pair creates at most eight rectangles.

| term | meaning |
|---|---|
| `entryTime` | Euler entry index of a tree node |
| `exitTime` | Euler exit index of a tree node |
| `neighborToward` | first tree step from one node to another |
| `eventYLow` | lower Euler index of one rectangle |
| `bitTree` | Fenwick tree for rectangle stabbing |
| `queryPathLength` | node count of one walk path |

The worked example uses the sample tree and counts from the generator's BFS oracle.

| walk | path friends | adjacent ID pairs on path | answer |
|---|---|---|---|
| 6 to 7 | 6, 1, 3, 5, 7 | 5-6 and 6-7 | 3 |
| 1 to 4 | 1, 3, 2, 4 | 1-2, 2-3, 3-4 | 1 |
| 2 to 5 | 2, 3, 5 | 2-3 | 2 |

For the walk from 6 to 7, the five path friends form three groups: `{5, 6, 7}`, `{1}`, and `{3}`.

Rectangle events are sorted by counting sort because Euler positions are small integers. Fenwick range updates keep the sweep linearithmic.

## Code

**Input and tree walk.** The reader builds an adjacency array and an iterative DFS records Euler times and ancestors.

```nim
const flushBlockBytes = 1 shl 17
const ancestorLevels = 19

proc buildAncestors(ancestorTable: var seq[seq[int]], nodeValue, level: int) =
  for levelIndex in 1 .. level - 1:
    let previousAncestor = ancestorTable[levelIndex - 1][nodeValue]
    ancestorTable[levelIndex][nodeValue] = ancestorTable[levelIndex - 1][previousAncestor]
```

Ancestor levels are filled as nodes are discovered.
The iterative walk avoids deep recursion on a long chain.

```nim
var parentNode = newSeq[int](friendCount + 1)
var depthValue = newSeq[int](friendCount + 1)
var entryTime = newSeq[int](friendCount + 1)
var exitTime = newSeq[int](friendCount + 1)
var ancestorTable = newSeq[seq[int]](ancestorLevels)
for levelIndex in 0 .. ancestorLevels - 1:
  ancestorTable[levelIndex] = newSeq[int](friendCount + 1)

var stackNodes = newSeq[int](friendCount)
var stackEdges = newSeq[int](friendCount)
var stackTop = 0
stackNodes[0] = 1
stackEdges[0] = edgeHead[1]
parentNode[1] = 0
depthValue[1] = 0
entryTime[1] = 0
var timer = 1
while stackTop >= 0:
  let nodeValue = stackNodes[stackTop]
  if stackEdges[stackTop] == -1:
    exitTime[nodeValue] = timer - 1
    stackTop -= 1
  else:
    let edgeIndex = stackEdges[stackTop]
    stackEdges[stackTop] = edgeNext[edgeIndex]
    let neighbor = edgeTarget[edgeIndex]
    if neighbor == parentNode[nodeValue]:
      continue
    parentNode[neighbor] = nodeValue
    depthValue[neighbor] = depthValue[nodeValue] + 1
    ancestorTable[0][neighbor] = nodeValue
    buildAncestors(ancestorTable, neighbor, ancestorLevels)
    entryTime[neighbor] = timer
    timer += 1
    stackTop += 1
    stackNodes[stackTop] = neighbor
    stackEdges[stackTop] = edgeHead[neighbor]
```

Every subtree occupies one contiguous Euler interval.
Binary lifting supports depth climbing and LCA queries.

```nim
proc climbToDepth(nodeValue, targetDepth: int): int =
  var currentNode = nodeValue
  for levelIndex in countdown(ancestorLevels - 1, 0):
    let candidate = ancestorTable[levelIndex][currentNode]
    if candidate != 0 and depthValue[candidate] >= targetDepth:
      currentNode = candidate
  return currentNode

proc lowestCommonAncestor(firstNode, secondNode: int): int =
  var leftNode = firstNode
  var rightNode = secondNode
  if depthValue[leftNode] < depthValue[rightNode]:
    swap leftNode, rightNode
  leftNode = climbToDepth(leftNode, depthValue[rightNode])
  if leftNode == rightNode:
    return leftNode
  for levelIndex in countdown(ancestorLevels - 1, 0):
    if ancestorTable[levelIndex][leftNode] != ancestorTable[levelIndex][rightNode]:
      leftNode = ancestorTable[levelIndex][leftNode]
      rightNode = ancestorTable[levelIndex][rightNode]
  return parentNode[leftNode]

proc neighborToward(nodeValue, targetNode: int): int =
  let joiningNode = lowestCommonAncestor(nodeValue, targetNode)
  if nodeValue == joiningNode:
    return climbToDepth(targetNode, depthValue[nodeValue] + 1)
  return parentNode[nodeValue]
```

The first step toward an ancestor is the parent node.
When the start is the ancestor, the child toward the target is used.

**Rectangles.** Each adjacent ID pair becomes rectangles in Euler-order endpoint space.

```nim
var eventXPos = newSeq[int]()
var eventYLow = newSeq[int]()
var eventYHigh = newSeq[int]()
var eventDelta = newSeq[int]()

proc addRectangle(xLow, xHigh, yLow, yHigh: int) =
  if xLow > xHigh or yLow > yHigh:
    return
  eventXPos.add xLow
  eventYLow.add yLow
  eventYHigh.add yHigh
  eventDelta.add 1
  eventXPos.add xHigh + 1
  eventYLow.add yLow
  eventYHigh.add yHigh
  eventDelta.add -1
```

Each rectangle contributes a start event and an end event.
The end event sits one step past the inclusive x bound.

```nim
for firstLabel in 1 .. friendCount - 1:
  let secondLabel = firstLabel + 1
  let firstNeighbor = neighborToward(firstLabel, secondLabel)
  let secondNeighbor = neighborToward(secondLabel, firstLabel)
  var firstLow = newSeq[int]()
  var firstHigh = newSeq[int]()
  if parentNode[firstLabel] == firstNeighbor:
    firstLow.add entryTime[firstLabel]
    firstHigh.add exitTime[firstLabel]
  else:
    if entryTime[firstNeighbor] > 0:
      firstLow.add 0
      firstHigh.add entryTime[firstNeighbor] - 1
    if exitTime[firstNeighbor] < friendCount - 1:
      firstLow.add exitTime[firstNeighbor] + 1
      firstHigh.add friendCount - 1
```

A child neighbour makes the start side the subtree.
A parent neighbour makes it the complement of that subtree.
The same rule applies to the other endpoint.

```nim
  var secondLow = newSeq[int]()
  var secondHigh = newSeq[int]()
  if parentNode[secondLabel] == secondNeighbor:
    secondLow.add entryTime[secondLabel]
    secondHigh.add exitTime[secondLabel]
  else:
    if entryTime[secondNeighbor] > 0:
      secondLow.add 0
      secondHigh.add entryTime[secondNeighbor] - 1
    if exitTime[secondNeighbor] < friendCount - 1:
      secondLow.add exitTime[secondNeighbor] + 1
      secondHigh.add friendCount - 1
  addSideRectangles(firstLow, firstHigh, secondLow, secondHigh)
  addSideRectangles(secondLow, secondHigh, firstLow, firstHigh)
```

Both endpoint orders are added because either friend may start the walk.
One pair contributes at most eight rectangles.

**Sweep.** Events are counted by x, then a Fenwick tree answers each walk at its x position.

```nim
var countByX = newSeq[int](friendCount + 1)
for eventIndex in 0 .. eventXPos.len - 1:
  countByX[eventXPos[eventIndex]] += 1
var offsetByX = newSeq[int](friendCount + 1)
var positionTotal = 0
for xPosition in 0 .. friendCount:
  offsetByX[xPosition] = positionTotal
  positionTotal += countByX[xPosition]
var sortedEvents = newSeq[int](eventXPos.len)
for eventIndex in 0 .. eventXPos.len - 1:
  let xPosition = eventXPos[eventIndex]
  sortedEvents[offsetByX[xPosition]] = eventIndex
  offsetByX[xPosition] += 1
```

Counting sort groups events by their Euler x index.
No comparison sort is needed for millions of events.

```nim
var queryAnswers = newSeq[int](queryCount)
var eventCursor = 0
for xPosition in 0 .. friendCount - 1:
  while eventCursor < sortedEvents.len:
    let eventIndex = sortedEvents[eventCursor]
    if eventXPos[eventIndex] != xPosition:
      break
    bitAdd(eventYLow[eventIndex], eventDelta[eventIndex])
    bitAdd(eventYHigh[eventIndex] + 1, -eventDelta[eventIndex])
    eventCursor += 1
  var queryIndex = queryHead[xPosition]
  while queryIndex != -1:
    queryAnswers[queryIndex] = queryPathLength[queryIndex] - bitSum(entryTime[querySecond[queryIndex]])
    queryIndex = queryNext[queryIndex]
```

Active rectangles are exactly those covering the current x.
The Fenwick point query counts rectangles covering the query's y.

## Complexity

Tree preprocessing and the sweep dominate the runtime.

| phase | time | space |
|---|---|---|
| DFS and LCA setup | O(N log N) | ancestor table |
| rectangle build | O(N) pairs | event arrays |
| sweep | O((N + Q) log N) | Fenwick tree |

| measure | Big O |
|---|---|
| time | O((N + Q) log N) |
| space | O(N log N) |

Checking every consecutive ID pair for every walk costs O(NQ). The takeaway is that rectangle stabbing answers all walks in one sweep.
