<https://www.spoj.com/problems/BUZZ/>

## Problem

Split a road graph into maximal regions where any two cities share a cycle; each region needs one Buzz whose energy demand is compared with the region's total supply. Assign available Buzz toys to regions to minimize the largest absolute difference, or print No when regions outnumber toys.

| item | bound |
|---|---|
| test cases T | 1 to 101 |
| cities N | 1 to 251 |
| roads E | 0 or more, no parallel roads |
| toys B | 1 to 251 |
| energy per city or toy | 0 to 999 |
| judge limit | 1000 ms, 1536 MB |

An articulation city belongs to every region that contains it, so its energy is counted once per region.

Sample input:

```
2
6 7 3
5 4 8 1 2 6
10 14 9
1 2
2 3
3 1
3 4
4 5
3 5
5 6
4 3 1
5 4 8 1
10
1 2
2 3
3 1
```

Sample output:

```
Buzz Mission 1: 3 3
Buzz Mission 2: 2 No
```

## Idea

Think of a city where two loops of wire meet: that junction belongs to both loops, the same way an articulation city belongs to several regions. Tarjan's edge stack cuts the graph into biconnected blocks, and isolated cities become single-city regions. The pairing of toys to regions is a matching problem, so a binary search on the allowed waste turns each feasibility test into a small assignment check.

The edge stack pops one block whenever a child cannot reach above its parent.

The final binary search returns the smallest waste that still admits a full assignment.

## Why It Works

1. Two cities lie on a common cycle exactly when they share a biconnected block.
2. Tarjan's low value tells whether a subtree can reach above its parent.
3. When it cannot, the edges stacked since that parent form one region.
4. A city appears in each block's edge set, so its supply is added per region.
5. A bridge forms a two-city block; an isolated city forms a one-city block.
6. Binary search checks a waste limit, and augmenting paths test all pairings under it.

| term | meaning |
|---|---|
| `lowReach` | oldest discovery time reachable from a subtree |
| `pendingEdges` | roads waiting to be assigned to a region |
| `regionSupplies` | summed city energy for each region |
| `allowedDeviation` | waste limit in the current matching test |

The first sample has regions with supplies 17, 11 and 8.

Toys 14, 10 and 9 give waste 3, 1 and 1, so the maximum waste is 3.

## Code

**Input and scanning.** The reader loads the graph and the toy demands for each case.

```nim
const flushBlockBytes = 1 shl 17
const maxAdjacencySlots = 64010

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

Each undirected road occupies two adjacency slots.

The scanner ignores spacing and line breaks.

**Region decomposition.** The DFS stack emits one biconnected block at each cut.

```nim
var cityCount = 0
var headEdge = newSeq[int](maxAdjacencySlots)
var edgeTarget = newSeq[int](maxAdjacencySlots)
var edgeNumber = newSeq[int](maxAdjacencySlots)
var nextEdge = newSeq[int](maxAdjacencySlots)
var discoveryTime = newSeq[int](maxAdjacencySlots)
var lowReach = newSeq[int](maxAdjacencySlots)
var vertexMark = newSeq[int](maxAdjacencySlots)
var currentMark = 0
var clockTime = 0
var pendingEdges: seq[int] = @[]
var regionSupplies: seq[int] = @[]
var energySupply = newSeq[int](maxAdjacencySlots)

proc collectComponent(lastEdge: int) =
  currentMark += 1
  var supplyTotal = 0
  while true:
    let currentEdge = pendingEdges[pendingEdges.len - 1]
    pendingEdges.setLen(pendingEdges.len - 1)
    let firstCity = edgeTarget[currentEdge * 2 - 1]
    let secondCity = edgeTarget[currentEdge * 2]
    if vertexMark[firstCity] != currentMark:
      vertexMark[firstCity] = currentMark
      supplyTotal += energySupply[firstCity]
    if vertexMark[secondCity] != currentMark:
      vertexMark[secondCity] = currentMark
      supplyTotal += energySupply[secondCity]
    if currentEdge == lastEdge:
      break
  regionSupplies.add supplyTotal

proc exploreCity(cityHere: int, incomingEdge: int) =
  clockTime += 1
  discoveryTime[cityHere] = clockTime
  lowReach[cityHere] = clockTime
  var edgeSlot = headEdge[cityHere]
  while edgeSlot != 0:
    let neighborCity = edgeTarget[edgeSlot]
    let roadNumber = edgeNumber[edgeSlot]
    if roadNumber != incomingEdge:
      if discoveryTime[neighborCity] == 0:
        pendingEdges.add roadNumber
        exploreCity(neighborCity, roadNumber)
        if lowReach[neighborCity] < lowReach[cityHere]:
          lowReach[cityHere] = lowReach[neighborCity]
        if lowReach[neighborCity] >= discoveryTime[cityHere]:
          collectComponent(roadNumber)
      elif discoveryTime[neighborCity] < discoveryTime[cityHere]:
        if discoveryTime[neighborCity] < lowReach[cityHere]:
          lowReach[cityHere] = discoveryTime[neighborCity]
        pendingEdges.add roadNumber
    edgeSlot = nextEdge[edgeSlot]
```

A mark counter avoids adding one city twice in the same block.

Back edges to ancestors are stacked once, when their target is older.

**Toy matching.** Augmenting paths test one waste limit at a time.

```nim
var toyDemands: seq[int] = @[]
var toyCount = 0
var assignedToy: seq[int] = @[]
var visitedToy: seq[int] = @[]
var allowedDeviation = 0
var visitVersion = 0

proc canAssign(regionIndex: int): bool =
  for toyIndex in 0 .. toyCount - 1:
    let difference = toyDemands[toyIndex] - regionSupplies[regionIndex]
    if (difference < 0 and -difference <= allowedDeviation) or
       (difference >= 0 and difference <= allowedDeviation):
      if visitedToy[toyIndex] != visitVersion:
        visitedToy[toyIndex] = visitVersion
        if assignedToy[toyIndex] == -1 or canAssign(assignedToy[toyIndex]):
          assignedToy[toyIndex] = regionIndex
          return true
  return false

proc feasible(deviation: int): bool =
  allowedDeviation = deviation
  for toyIndex in 0 .. toyCount - 1:
    assignedToy[toyIndex] = -1
  for regionIndex in 0 .. regionSupplies.len - 1:
    visitVersion += 1
    if not canAssign(regionIndex):
      return false
  return true
```

A toy is usable when its demand sits within the allowed waste of a supply.

The visit version replaces clearing the visited array for each region.

**Case driver.** The driver builds the graph, finds regions, then binary searches the waste.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  cityCount = nextInt(inputData, scanPos)
  let roadCount = nextInt(inputData, scanPos)
  toyCount = nextInt(inputData, scanPos)

  for cityIndex in 1 .. cityCount:
    energySupply[cityIndex] = nextInt(inputData, scanPos)

  toyDemands = newSeq[int](toyCount)
  for toyIndex in 0 .. toyCount - 1:
    toyDemands[toyIndex] = nextInt(inputData, scanPos)

  for cityIndex in 0 .. cityCount:
    headEdge[cityIndex] = 0
    discoveryTime[cityIndex] = 0
    lowReach[cityIndex] = 0
    vertexMark[cityIndex] = 0
  var slotCount = 0
  var degreeCounts = newSeq[int](cityCount + 1)
  for roadIndex in 1 .. roadCount:
    let roadStart = nextInt(inputData, scanPos)
    let roadEnd = nextInt(inputData, scanPos)
    slotCount += 1
    edgeTarget[slotCount] = roadEnd
    edgeNumber[slotCount] = roadIndex
    nextEdge[slotCount] = headEdge[roadStart]
    headEdge[roadStart] = slotCount
    degreeCounts[roadStart] += 1
    slotCount += 1
    edgeTarget[slotCount] = roadStart
    edgeNumber[slotCount] = roadIndex
    nextEdge[slotCount] = headEdge[roadEnd]
    headEdge[roadEnd] = slotCount
    degreeCounts[roadEnd] += 1

  clockTime = 0
  currentMark = 0
  pendingEdges = @[]
  regionSupplies = @[]
  for cityIndex in 1 .. cityCount:
    if degreeCounts[cityIndex] > 0 and discoveryTime[cityIndex] == 0:
      exploreCity(cityIndex, 0)
  for cityIndex in 1 .. cityCount:
    if degreeCounts[cityIndex] == 0:
      regionSupplies.add energySupply[cityIndex]

  let regionCount = regionSupplies.len
  appendOutput("Buzz Mission " & $(caseIndex + 1) & ": " & $regionCount & " ")
  if regionCount > toyCount:
    appendOutput("No")
  else:
    var largestGap = 0
    for regionIndex in 0 .. regionCount - 1:
      for toyIndex in 0 .. toyCount - 1:
        let difference = toyDemands[toyIndex] - regionSupplies[regionIndex]
        if difference > largestGap:
          largestGap = difference
        elif -difference > largestGap:
          largestGap = -difference
    assignedToy = newSeq[int](toyCount)
    visitedToy = newSeq[int](toyCount)
    visitVersion = 0
    var lowBound = 0
    var highBound = largestGap
    while lowBound < highBound:
      let middle = (lowBound + highBound) div 2
      if feasible(middle):
        highBound = middle
      else:
        lowBound = middle + 1
    appendOutput($lowBound)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Cities with no roads become single-city regions after the DFS.

The upper waste bound is the largest gap between any toy and any region.

## Complexity

Each road enters and leaves the DFS stack once.

| phase | time | space |
|---|---|---|
| input read | one pass over roads and values | adjacency arrays |
| region decomposition | one DFS over cities and roads | discovery and stack arrays |
| matching search | logarithm of waste times region-to-toy edges | two assignment arrays |

| measure | Big O |
|---|---|
| time | O(E + R log W times matching cost) |
| space | O(N + E) |

Testing every toy permutation would need factorial time.

Binary search and augmenting paths keep the assignment small.
