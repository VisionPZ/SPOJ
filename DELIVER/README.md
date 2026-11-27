# DELIVER — Delivery Route (SPOJ)

<https://www.spoj.com/problems/DELIVER/>

## Problem

FJ walks between consecutive farms on a grid, then returns to the first farm. Every other farm is a blocked cell, so a leg sometimes needs a detour. The task gives the shortest total walk, or -1 when some leg cannot be made.

Input holds one integer N, then N lines with the x and y coordinate of each farm.

Output holds one integer: the total minutes, or -1.

The bounds from the statement:

| item | bound |
|---|---|
| farms N | 1 to 100 |
| coordinate values | 1 to 1000000 |
| judge limit | 309 ms, 1536 MB |

The fixed visit order keeps the work to N separate shortest-path searches.

Sample input:

```
4
2 2
2 4
2 1
1 3
```

The sample has four farms in a narrow column.

Sample output:

```
12
```

The second leg detours around farm 1 and costs five steps.

## Idea

Put a bus stop at each farm and near each farm, then hop between stops, like walking around a closed building. A shortest leg becomes a chain of L-shaped hops on this small graph.

The method builds a reduced graph of at most five nodes per farm and runs Dijkstra once per leg. Graph construction checks all node pairs against all N farms. Each search visits at most 5N nodes, so both phases cost cubic time in N.

A grid search over a million by a million cells is impossible here.

## Why It Works

1. A shortest grid walk can be reshaped into L-shaped hops between farm centers and free neighbor cells.
2. Each farm contributes its center and up to four free adjacent cells as nodes.
3. Two nodes connect when either L-shaped route avoids every farm center except the two endpoints.
4. For one leg, all farm centers except the start and target become blocked nodes.
5. Dijkstra on the reduced graph finds the shortest legal leg, or returns -1.
6. Adding the N legs, including the return leg, gives the total time.

The main terms and formulas:

| term | meaning |
|---|---|
| `pointIsFarm` | binary search over sorted farm coordinates |
| `inSegment` | test for a farm strictly inside an axis-aligned segment |
| `rightAnglePossible` | check both L-shaped routes between two nodes |
| `shortestLeg` | Dijkstra search with all other farm centers blocked |
| `totalDistance` | sum of all leg lengths |

Blocking only farm centers matches the rule that walks cannot pass through a farm.

A script trace over the sample legs gives:

```
leg 1->2: (2, 2) to (2, 4) base 2 -> 2
leg 2->3: (2, 4) to (2, 1) base 3 -> 5
leg 3->4: (2, 1) to (1, 3) base 3 -> 3
leg 4->1: (1, 3) to (2, 2) base 2 -> 2
total 12
```

The search returns -1 when no unblocked chain reaches the target node.

## Code

**Input and buffer.** One read loads stdin, and answers collect in one string.

```nim
const flushBlockBytes = 1 shl 17
const unreachableValue = int64(1 shl 60)
const deltaX = [1, -1, 0, 0]
const deltaY = [0, 0, 1, -1]

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

The direction arrays build the four free neighbors.
The large sentinel marks nodes that are still unreachable.
Coordinates arrive as plain integers.

**Geometry and graph.** Sorted farm codes support fast point tests and L-shaped edge checks.

```nim
var farmCount = 0
var farmX = newSeq[int](0)
var farmY = newSeq[int](0)
var farmCodes = newSeq[int64](0)

proc pointIsFarm(pointX, pointY: int): bool =
  let targetCode = (int64(pointX) shl 32) or int64(pointY)
  var lowIndex = 0
  var highIndex = farmCodes.len - 1
  while lowIndex <= highIndex:
    let middleIndex = (lowIndex + highIndex) div 2
    if farmCodes[middleIndex] == targetCode:
      return true
    elif farmCodes[middleIndex] < targetCode:
      lowIndex = middleIndex + 1
    else:
      highIndex = middleIndex - 1
  return false

proc inSegment(pointX, pointY, fromX, fromY, toX, toY: int): bool =
  if fromX == toX:
    return pointX == fromX and pointY > min(fromY, toY) and pointY < max(fromY, toY)
  elif fromY == toY:
    return pointY == fromY and pointX > min(fromX, toX) and pointX < max(fromX, toX)
  return false

var nodeX = newSeq[int](0)
var nodeY = newSeq[int](0)
var centerNodes = newSeq[int](0)

proc rightAnglePossible(firstNode, secondNode: int): bool =
  let startX = nodeX[firstNode]
  let startY = nodeY[firstNode]
  let endX = nodeX[secondNode]
  let endY = nodeY[secondNode]
  var verticalGood = true
  if startX != endX and startY != endY and pointIsFarm(startX, endY):
    verticalGood = false
  if verticalGood:
    for farmIndex in 0 .. farmCount - 1:
      if inSegment(farmX[farmIndex], farmY[farmIndex], startX, startY, startX, endY) or
         inSegment(farmX[farmIndex], farmY[farmIndex], startX, endY, endX, endY):
        verticalGood = false
        break
  if verticalGood:
    return true
  var horizontalGood = true
  if startX != endX and startY != endY and pointIsFarm(endX, startY):
    horizontalGood = false
  if horizontalGood:
    for farmIndex in 0 .. farmCount - 1:
      if inSegment(farmX[farmIndex], farmY[farmIndex], startX, startY, endX, startY) or
         inSegment(farmX[farmIndex], farmY[farmIndex], endX, startY, endX, endY):
        horizontalGood = false
        break
  return horizontalGood
```

Point codes pack two coordinates into one 64-bit key.
Segment tests ignore endpoints, which are legal stops.
An edge exists when at least one L-shaped route is clear.

**Leg search.** Dijkstra uses the reduced graph and blocks unrelated farm centers.

```nim
var adjacency = newSeq[seq[int]](0)
var distanceValues = newSeq[int64](0)
var visitedNodes = newSeq[bool](0)

proc shortestLeg(startNode, targetNode: int): int64 =
  let nodeCount = nodeX.len
  for nodeIndex in 0 .. nodeCount - 1:
    distanceValues[nodeIndex] = unreachableValue
    visitedNodes[nodeIndex] = false
  for farmIndex in 0 .. farmCount - 1:
    if centerNodes[farmIndex] != startNode and centerNodes[farmIndex] != targetNode:
      visitedNodes[centerNodes[farmIndex]] = true
  distanceValues[startNode] = 0
  for stepIndex in 0 .. nodeCount - 1:
    var chosenNode = -1
    for nodeIndex in 0 .. nodeCount - 1:
      if not visitedNodes[nodeIndex]:
        if chosenNode == -1 or distanceValues[nodeIndex] < distanceValues[chosenNode]:
          chosenNode = nodeIndex
    if chosenNode == -1 or distanceValues[chosenNode] >= unreachableValue:
      return -1
    if chosenNode == targetNode:
      return distanceValues[chosenNode]
    visitedNodes[chosenNode] = true
    for edgeIndex in adjacency[chosenNode]:
      if not visitedNodes[edgeIndex]:
        let stepCost = int64(abs(nodeX[chosenNode] - nodeX[edgeIndex]) +
                             abs(nodeY[chosenNode] - nodeY[edgeIndex]))
        let candidate = distanceValues[chosenNode] + stepCost
        if candidate < distanceValues[edgeIndex]:
          distanceValues[edgeIndex] = candidate
  return -1
```

The two endpoint centers stay open for this leg.
The scan picks the closest unvisited node each round.
A sentinel distance means the target cannot be reached.

**Driver.** Nodes, edges, and leg sums finish the route.

```nim
farmCount = nextInt(inputData, scanPos)
farmX = newSeq[int](farmCount)
farmY = newSeq[int](farmCount)
for farmIndex in 0 .. farmCount - 1:
  farmX[farmIndex] = nextInt(inputData, scanPos)
  farmY[farmIndex] = nextInt(inputData, scanPos)
  farmCodes.add((int64(farmX[farmIndex]) shl 32) or int64(farmY[farmIndex]))
for sortIndex in 1 .. farmCodes.len - 1:
  let keyCode = farmCodes[sortIndex]
  var holeIndex = sortIndex
  while holeIndex > 0 and farmCodes[holeIndex - 1] > keyCode:
    farmCodes[holeIndex] = farmCodes[holeIndex - 1]
    holeIndex -= 1
  farmCodes[holeIndex] = keyCode
centerNodes = newSeq[int](farmCount)
for farmIndex in 0 .. farmCount - 1:
  centerNodes[farmIndex] = nodeX.len
  nodeX.add farmX[farmIndex]
  nodeY.add farmY[farmIndex]
  for direction in 0 .. 3:
    let neighborX = farmX[farmIndex] + deltaX[direction]
    let neighborY = farmY[farmIndex] + deltaY[direction]
    if not pointIsFarm(neighborX, neighborY):
      nodeX.add neighborX
      nodeY.add neighborY
let nodeCount = nodeX.len
adjacency = newSeq[seq[int]](nodeCount)
distanceValues = newSeq[int64](nodeCount)
visitedNodes = newSeq[bool](nodeCount)
for firstNode in 0 .. nodeCount - 1:
  for secondNode in firstNode + 1 .. nodeCount - 1:
    if rightAnglePossible(firstNode, secondNode):
      adjacency[firstNode].add secondNode
      adjacency[secondNode].add firstNode
var totalDistance = int64(0)
var routePossible = true
for legIndex in 0 .. farmCount - 1:
  let nextFarm = (legIndex + 1) mod farmCount
  let legDistance = shortestLeg(centerNodes[legIndex], centerNodes[nextFarm])
  if legDistance < 0:
    routePossible = false
    break
  totalDistance += legDistance
if routePossible:
  appendOutput($totalDistance)
else:
  appendOutput("-1")
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Free neighbor cells become graph nodes.
Every node pair gets an edge check once.
One failed leg forces the -1 answer.

## Complexity

Cost comes from building edges and running one search per leg.

| phase | time | space |
|---|---|---|
| input read | one pass over farm coordinates | one input string |
| graph build | O(N) farms times O(N^2) node pairs | O(N^2) adjacency |
| leg searches | N searches over O(N) nodes | two arrays of O(N) |
| output | one line | block buffer |

The graph build and the searches both scale cubically in N.

The overall asymptotic bounds:

| measure | Big O |
|---|---|
| time | O(N^3) |
| space | O(N^2) |

A full grid BFS would span up to a million by a million cells and cannot run here.
The reduced graph keeps both phases small enough for N up to 100.
