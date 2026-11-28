# GANNHAT — Closest distance (SPOJ)

<https://www.spoj.com/problems/GANNHAT/>

## Problem

For every point, find the smallest Manhattan distance to any other point. Print one distance per point in input order.

Input starts with the point count, then one x and y pair per point. Output has the same number of lines as points.

| item | bound |
|---|---|
| points N | 1 to 200000 |
| coordinate | 0 to 10^7 |
| output lines | N |
| judge limit | 1000 ms, 1536 MB |

The point count rules out comparing every pair of points.

Sample input:

```
4
0 0
0 1
1 0
1 1
```

Sample output:

```
1
1
1
1
```

## Idea

Search a map by checking the nearest region first and skipping whole regions whose border lies farther than the best distance already found.

A kd-tree splits points alternately by x and y around a median. Each node stores the bounding box of its subtree. A query descends into the nearer child, then visits the far child only when the box border can beat the current best.
A query touches about a logarithmic number of nodes on typical data. Comparing all pairs costs N squared.
The tree is built once and reused for every point.

## Why It Works

1. Alternating median splits keep the tree balanced and give each leaf one point.
2. A bounding box encloses every point below a node.
3. The Manhattan distance from a query point to a box is a lower bound on the distance to any point in that box.
4. A far child is skipped when that lower bound reaches or exceeds the current best.
5. Excluding the query node itself leaves the nearest other point in the answer.

| term | meaning |
|---|---|
| `chooseMedian` | partition a coordinate range around its median |
| `buildTree` | recursive alternating-axis tree construction |
| `computeBounds` | bounding box stored at each node |
| `searchTree` | branch-and-bound nearest-point query |
| `infiniteDistance` | initial best distance for a query |

The table names the pieces that make pruning work.

Worked example on the four sample points:

```
point 1 -> 1
point 2 -> 1
point 3 -> 1
point 4 -> 1
Every corner has one neighbour at distance 1.
```

The traced distances match the sample output.

## Code

**Tree construction.** Median partition and alternating axes build a balanced tree.

```nim
proc chooseMedian(lowIndex: int, highIndex: int, axis: int): int =
  let targetIndex = lowIndex + (highIndex - lowIndex) div 2
  var leftIndex = lowIndex
  var rightIndex = highIndex - 1
  while true:
    let pivotIndex = workingOrder[(leftIndex + rightIndex) div 2]
    let pivotValue = coordinateOf(pivotIndex, axis)
    var lessEnd = leftIndex
    var greaterStart = rightIndex
    var scanIndex = leftIndex
    while scanIndex <= greaterStart:
      let currentIndex = workingOrder[scanIndex]
      let currentValue = coordinateOf(currentIndex, axis)
      if currentValue < pivotValue or (currentValue == pivotValue and currentIndex < pivotIndex):
        swap workingOrder[scanIndex], workingOrder[lessEnd]
        lessEnd += 1
        scanIndex += 1
      elif currentValue > pivotValue or (currentValue == pivotValue and currentIndex > pivotIndex):
        swap workingOrder[scanIndex], workingOrder[greaterStart]
        greaterStart -= 1
      else:
        scanIndex += 1
    if targetIndex < lessEnd:
      rightIndex = lessEnd - 1
    elif targetIndex > greaterStart:
      leftIndex = greaterStart + 1
    else:
      return workingOrder[targetIndex]

var kdPoint = newSeq[int](pointCount + 1)
var kdAxis = newSeq[int](pointCount + 1)
var kdLeftChild = newSeq[int](pointCount + 1)
var kdRightChild = newSeq[int](pointCount + 1)
var nodeCount = 0

proc buildTree(lowIndex: int, highIndex: int, depth: int): int =
  if lowIndex >= highIndex:
    return 0
  let axis = depth mod 2
  let middleIndex = lowIndex + (highIndex - lowIndex) div 2
  let medianPoint = chooseMedian(lowIndex, highIndex, axis)
  nodeCount += 1
  let nodeIndex = nodeCount
  kdPoint[nodeIndex] = medianPoint
  kdAxis[nodeIndex] = axis
  kdLeftChild[nodeIndex] = buildTree(lowIndex, middleIndex, depth + 1)
  kdRightChild[nodeIndex] = buildTree(middleIndex + 1, highIndex, depth + 1)
  return nodeIndex

let treeRoot = buildTree(0, pointCount, 0)
```

Three-way partition handles equal coordinates.
Each level uses one coordinate, then the other.
The node arrays hold the point, axis and children.

**Bounds and search.** Boxes prune branches that cannot improve the answer.

```nim
proc computeBounds(nodeIndex: int) =
  if nodeIndex == 0:
    return
  let pointIndex = kdPoint[nodeIndex]
  var minimumX = xCoordinates[pointIndex]
  var maximumX = xCoordinates[pointIndex]
  var minimumY = yCoordinates[pointIndex]
  var maximumY = yCoordinates[pointIndex]
  let leftChild = kdLeftChild[nodeIndex]
  let rightChild = kdRightChild[nodeIndex]
  computeBounds(leftChild)
  if leftChild != 0:
    if boxMinX[leftChild] < minimumX:
      minimumX = boxMinX[leftChild]
    if boxMaxX[leftChild] > maximumX:
      maximumX = boxMaxX[leftChild]
    if boxMinY[leftChild] < minimumY:
      minimumY = boxMinY[leftChild]
    if boxMaxY[leftChild] > maximumY:
      maximumY = boxMaxY[leftChild]
  computeBounds(rightChild)
  if rightChild != 0:
    if boxMinX[rightChild] < minimumX:
      minimumX = boxMinX[rightChild]
    if boxMaxX[rightChild] > maximumX:
      maximumX = boxMaxX[rightChild]
    if boxMinY[rightChild] < minimumY:
      minimumY = boxMinY[rightChild]
    if boxMaxY[rightChild] > maximumY:
      maximumY = boxMaxY[rightChild]
  boxMinX[nodeIndex] = minimumX
  boxMaxX[nodeIndex] = maximumX
  boxMinY[nodeIndex] = minimumY
  boxMaxY[nodeIndex] = maximumY

computeBounds(treeRoot)

proc searchTree(nodeIndex: int, queryPoint: int, bestDistance: var int, bestPoint: var int) =
  if nodeIndex == 0:
    return
  let candidatePoint = kdPoint[nodeIndex]
  if candidatePoint != queryPoint:
    let distanceValue = abs(xCoordinates[candidatePoint] - xCoordinates[queryPoint]) +
                        abs(yCoordinates[candidatePoint] - yCoordinates[queryPoint])
    if distanceValue < bestDistance:
      bestDistance = distanceValue
      bestPoint = candidatePoint
  let axis = kdAxis[nodeIndex]
  var nearChild = kdLeftChild[nodeIndex]
  var farChild = kdRightChild[nodeIndex]
  if coordinateOf(queryPoint, axis) >= coordinateOf(candidatePoint, axis):
    nearChild = kdRightChild[nodeIndex]
    farChild = kdLeftChild[nodeIndex]
  searchTree(nearChild, queryPoint, bestDistance, bestPoint)
  if farChild != 0:
    var gapX = 0
    if xCoordinates[queryPoint] < boxMinX[farChild]:
      gapX = boxMinX[farChild] - xCoordinates[queryPoint]
    elif xCoordinates[queryPoint] > boxMaxX[farChild]:
      gapX = xCoordinates[queryPoint] - boxMaxX[farChild]
    var gapY = 0
    if yCoordinates[queryPoint] < boxMinY[farChild]:
      gapY = boxMinY[farChild] - yCoordinates[queryPoint]
    elif yCoordinates[queryPoint] > boxMaxY[farChild]:
      gapY = yCoordinates[queryPoint] - boxMaxY[farChild]
    if gapX + gapY < bestDistance:
      searchTree(farChild, queryPoint, bestDistance, bestPoint)

```

Bounds are merged bottom up after construction.
The nearer child is visited before the farther one.
A box gap at least as large as the best distance prunes the child.

**Query loop.** Each point becomes one nearest-point search.

```nim
for pointIndex in 0 .. pointCount - 1:
  var bestDistance = infiniteDistance
  var bestPoint = -1
  searchTree(treeRoot, pointIndex, bestDistance, bestPoint)
  if bestPoint == -1:
    bestDistance = 0
  appendOutput($bestDistance)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

A single point has no neighbor, so its answer is zero.
Block output keeps the N lines cheap.
The tree root serves every query.

## Complexity

Costs split into construction and querying.

| phase | time | space |
|---|---|---|
| median splits | O(N log N) | O(N) |
| bounds pass | O(N) | O(N) |
| N queries | O(N log N) typical | O(1) extra |
| output | N lines | block buffer |

Query work dominates the phase table on large inputs.

| measure | Big O |
|---|---|
| build | O(N log N) |
| query worst case | O(N) |
| space | O(N) |

Pairwise comparison takes O(N^2) time and cannot reach N = 200000.
Box pruning keeps queries short on the judge data.
