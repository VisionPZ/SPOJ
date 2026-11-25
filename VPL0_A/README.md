# VPL0_A — Another Gift Problem (SPOJ)

<https://www.spoj.com/problems/VPL0_A/>

## Problem

Find the least time to collect every gift and finish at (0, 0) on the last gift's floor. Each elevator ride moves one fixed floor offset and costs one unit. Walking on a floor uses Manhattan steps from (0, 0) and must return there before riding again.

Input starts with T. Each case gives M floors, E elevator offsets, K gifts and grid size N. Then come E signed offsets and K triples of floor, row and column. Output a line with Scenario #i and the minimum time.

| item | bound |
|---|---|
| test cases T | 1 to 10 |
| floors M | 1 to 1000 |
| elevators E | 1 to 100 |
| gifts K | 1 to 10 |
| grid size N | 1 to 1000000 |
| judge limit | 1000 ms, 1536 MB |

K drives the subset search, while M and E drive the elevator search.

Sample input:

```
5
5 1 1 1
1
3 0 0
5 3 1 1
1
4
-1
3 0 0
5 1 2 1
1
2 0 0
4 0 0
10 3 2 1
1
8
-2
4 0 0
6 0 0
5 3 3 5
1
2
-1
2 1 3
2 4 1
2 3 4
```

Sample output:

```
Scenario #1: 3
Scenario #2: 2
Scenario #3: 4
Scenario #4: 3
Scenario #5: 17
```

## Idea

Treat gift floors like delivery stops and plan the order once the travel times are known. Breadth-first search gives ride costs between floors. Two subset searches give the walk inside each floor and the order of stops.

The algorithm builds a floor-distance matrix, solves a Held-Karp walk per floor, then solves a Held-Karp route across gift floors. Each search costs O(2^K * K^2) with K at most 10. Trying all elevator ride orders directly grows without bound.

Takeaway: precompute ride costs, then solve two small subset problems.

## Why It Works

1. Each elevator ride is one step in a directed floor graph, so BFS gives the fewest rides.
2. A ride is possible only when the offset lands inside floors 0 to M-1.
3. Collecting all gifts on one floor in a single visit costs no more than splitting the visit.
4. A Manhattan walk from (0, 0) over a gift set is a small Held-Karp tour.
5. The route search adds ride cost and walk cost when it visits a new gift floor.

| term | meaning |
|---|---|
| `floorDistances` | fewest rides between one source floor and every floor |
| `walkCosts` | shortest origin-to-origin walk for each gift floor |
| `rideMatrix` | ride costs among floor 0 and the gift floors |
| `routeCosts` | best time for each visited-floor mask and current floor |

One ride matrix serves the whole route search.

A script-generated trace for the last sample case:

```
gift floor 2, positions (1,3), (4,1), (3,4)
ride 0 -> 2 using offset +2 = 1
walk (4,1) -> (3,4) -> (1,3) -> origin
steps 5 + 4 + 3 + 4 = 16
total 1 + 16 = 17
```

The trace matches the last sample line.

## Code

**Input and scanning.** The hand reader keeps the minus sign on downward elevators.

```nim
const flushBlockBytes = 1 shl 17
const impossibleCost = 1000000000

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and data[pos] != '-' and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var sign = 1
  if pos < data.len and data[pos] == '-':
    sign = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return sign * value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The scanner preserves negative offsets.
Output is buffered in fixed blocks.
The sentinel skips unreachable states.

**Per-floor walk.** A subset table finds the shortest closed walk over one floor's gifts.

```nim
proc floorWalkCost(walkRows: seq[int], walkCols: seq[int]): int =
  let pointCount = walkRows.len
  if pointCount == 0:
    return 0
  let stateCount = 1 shl pointCount
  var bestCosts = newSeq[int](stateCount * pointCount)
  for entryIndex in 0 .. bestCosts.len - 1:
    bestCosts[entryIndex] = impossibleCost
  for pointIndex in 0 .. pointCount - 1:
    let stateIndex = (1 shl pointIndex) * pointCount + pointIndex
    bestCosts[stateIndex] = abs(walkRows[pointIndex]) + abs(walkCols[pointIndex])
  for visitedMask in 1 .. stateCount - 1:
    for lastPoint in 0 .. pointCount - 1:
      if (visitedMask and (1 shl lastPoint)) == 0:
        continue
      let stateIndex = visitedMask * pointCount + lastPoint
      let currentCost = bestCosts[stateIndex]
      if currentCost >= impossibleCost:
        continue
      for nextPoint in 0 .. pointCount - 1:
        if (visitedMask and (1 shl nextPoint)) != 0:
          continue
        let stepCost = abs(walkRows[nextPoint] - walkRows[lastPoint]) +
                       abs(walkCols[nextPoint] - walkCols[lastPoint])
        let nextMask = visitedMask or (1 shl nextPoint)
        let nextIndex = nextMask * pointCount + nextPoint
        let candidate = currentCost + stepCost
        if candidate < bestCosts[nextIndex]:
          bestCosts[nextIndex] = candidate
  let fullMask = stateCount - 1
  var shortestWalk = impossibleCost
  for lastPoint in 0 .. pointCount - 1:
    let returnCost = abs(walkRows[lastPoint]) + abs(walkCols[lastPoint])
    let candidate = bestCosts[fullMask * pointCount + lastPoint] + returnCost
    if candidate < shortestWalk:
      shortestWalk = candidate
  return shortestWalk
```

Every tour begins and ends at the origin.
Mask bits track the gifts already visited.
The final step returns from the last gift.

**Elevator distances.** BFS counts rides on the directed floor graph.

```nim
proc floorDistances(sourceFloor: int, floorTotal: int, elevatorOffsets: seq[int]): seq[int] =
  var distances = newSeq[int](floorTotal)
  var queue = newSeq[int](floorTotal)
  for floorNumber in 0 .. floorTotal - 1:
    distances[floorNumber] = -1
  var queueHead = 0
  var queueTail = 0
  distances[sourceFloor] = 0
  queue[queueTail] = sourceFloor
  queueTail += 1
  while queueHead < queueTail:
    let currentFloor = queue[queueHead]
    queueHead += 1
    for elevatorOffset in elevatorOffsets:
      let nextFloor = currentFloor + elevatorOffset
      if nextFloor >= 0 and nextFloor < floorTotal and distances[nextFloor] == -1:
        distances[nextFloor] = distances[currentFloor] + 1
        queue[queueTail] = nextFloor
        queueTail += 1
  return distances
```

Out-of-range landings are discarded.
Each floor is enqueued once.
Unreachable floors keep distance -1.

**Case setup.** Gifts are grouped by floor, then walk and ride costs are built.

```nim
let testCount = nextInt(inputData, scanPos)
for caseIndex in 1 .. testCount:
  let floorTotal = nextInt(inputData, scanPos)
  let elevatorTotal = nextInt(inputData, scanPos)
  let giftTotal = nextInt(inputData, scanPos)
  let gridSize = nextInt(inputData, scanPos)

  var elevatorOffsets = newSeq[int](elevatorTotal)
  for elevatorIndex in 0 .. elevatorTotal - 1:
    elevatorOffsets[elevatorIndex] = nextInt(inputData, scanPos)

  var giftFloorNumbers = newSeq[int](giftTotal)
  var giftRows = newSeq[int](giftTotal)
  var giftCols = newSeq[int](giftTotal)
  var giftFloorIds = newSeq[int](giftTotal)
  for giftIndex in 0 .. giftTotal - 1:
    giftFloorNumbers[giftIndex] = nextInt(inputData, scanPos)
    giftRows[giftIndex] = nextInt(inputData, scanPos)
    giftCols[giftIndex] = nextInt(inputData, scanPos)

  var relevantFloors = newSeq[int]()
  relevantFloors.add 0
  for giftIndex in 0 .. giftTotal - 1:
    let floorNumber = giftFloorNumbers[giftIndex]
    var matchingId = -1
    for floorId in 1 .. relevantFloors.len - 1:
      if relevantFloors[floorId] == floorNumber:
        matchingId = floorId
        break
    if matchingId == -1:
      relevantFloors.add floorNumber
      matchingId = relevantFloors.len - 1
    giftFloorIds[giftIndex] = matchingId

  let relevantCount = relevantFloors.len
  var walkCosts = newSeq[int](relevantCount)
  for floorId in 1 .. relevantCount - 1:
    var walkRows = newSeq[int]()
    var walkCols = newSeq[int]()
    for giftIndex in 0 .. giftTotal - 1:
      if giftFloorIds[giftIndex] == floorId:
        walkRows.add giftRows[giftIndex]
        walkCols.add giftCols[giftIndex]
    walkCosts[floorId] = floorWalkCost(walkRows, walkCols)

  var rideMatrix = newSeq[seq[int]](relevantCount)
  for sourceId in 0 .. relevantCount - 1:
    let distances = floorDistances(relevantFloors[sourceId], floorTotal, elevatorOffsets)
    var rideRow = newSeq[int](relevantCount)
    for targetId in 0 .. relevantCount - 1:
      rideRow[targetId] = distances[relevantFloors[targetId]]
    rideMatrix[sourceId] = rideRow
```

Floor 0 is always the first relevant floor.
Repeated gift floors share one walk cost.
One BFS per relevant floor fills the ride matrix.

**Route search and output.** The second subset table chooses the order of gift floors.

```nim
  let giftFloorCount = relevantCount - 1
  let routeStates = 1 shl giftFloorCount
  var routeCosts = newSeq[int](routeStates * relevantCount)
  for entryIndex in 0 .. routeCosts.len - 1:
    routeCosts[entryIndex] = impossibleCost
  routeCosts[0] = 0
  for visitedMask in 0 .. routeStates - 1:
    for currentId in 0 .. relevantCount - 1:
      let stateIndex = visitedMask * relevantCount + currentId
      let currentCost = routeCosts[stateIndex]
      if currentCost >= impossibleCost:
        continue
      for targetId in 1 .. relevantCount - 1:
        let targetBit = 1 shl (targetId - 1)
        if (visitedMask and targetBit) != 0:
          continue
        let rideCost = rideMatrix[currentId][targetId]
        if rideCost < 0:
          continue
        let nextMask = visitedMask or targetBit
        let nextIndex = nextMask * relevantCount + targetId
        let candidate = currentCost + rideCost + walkCosts[targetId]
        if candidate < routeCosts[nextIndex]:
          routeCosts[nextIndex] = candidate

  let fullMask = routeStates - 1
  var bestTime = impossibleCost
  for currentId in 0 .. relevantCount - 1:
    let candidate = routeCosts[fullMask * relevantCount + currentId]
    if candidate < bestTime:
      bestTime = candidate

  appendOutput("Scenario #" & $(caseIndex) & ": " & $(bestTime) & "\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

A transition pays for the ride and the walk together.
The last floor needs no return ride.
The answer is the minimum over all final floors.

## Complexity

Elevator search and subset search are separate phases.

| phase | time | space |
|---|---|---|
| elevator BFS | O(G * M * E) | M distances |
| per-floor walks | O(K * 2^K * K^2) | 2^K states |
| route search | O(2^K * G^2) | 2^K * G states |
| output | one line per case | block buffer |

G is floor 0 plus the distinct gift floors, at most K + 1.

| measure | Big O |
|---|---|
| time | O(K * M * E + K^2 * 2^K) |
| space | O(M + K * 2^K) |

Enumerating elevator ride orders has no useful bound and cannot finish ten cases.

Takeaway: separate floor travel from floor walking, then solve each with a small search.
