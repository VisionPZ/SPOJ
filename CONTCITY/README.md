# CONTCITY — Contaminated City (SPOJ)

<https://www.spoj.com/problems/CONTCITY/>

## Problem

Survivors wait in city locations joined by roads, and helicopters land at given places on given days with limited seats. Find the earliest day when every survivor can board a helicopter, or the greatest number that can be saved when a full rescue is impossible. Walking along roads takes days, and a helicopter can wait at its landing place.

Each test case gives place count, road count, and helicopter count, then survivor counts, roads, and helicopter descriptions. Print one result line per test case. A full rescue uses the exact phrase `All people can be rescued in D day(s).`

| item | bound |
|---|---|
| places and helicopters | 1 to 50 each |
| roads | 1 to 1500 |
| road and landing days | 1 to 1000 |
| helicopter capacity | 1 to 200 |
| total survivors | at most 200 |
| judge limit | 1000 ms, 1536 MB |

A survivor reaches a helicopter at the later of the landing day and the walking time.

Sample input:

```
2
4 4 4
3 4 5 6
1 2 7
2 3 3
3 4 3
4 1 4
4 4 7
6 3 2
5 2 3
3 1 6
4 2 3
2 2 3 1
1 4 3
2 3 3
2 4 2
3 2 4
3 3 2
```

Sample output:

```
All people can be rescued in 6 day(s).
7 survivor(s) can be rescued.
```

## Idea

Treat survivors as parcels and helicopters as vans with limited seats, then test whether all parcels fit by a deadline. Shortest road times give the day each survivor can reach each helicopter. A max-flow test answers one deadline, and binary search over days finds the earliest working deadline. Trying every day from zero to a thousand would repeat the same flow work, so halving the range is faster.

## Why It Works

1. Shortest road times between places come from all-pairs relaxation.
2. A survivor using helicopter h is ready at the later of its landing day and the walking time.
3. A deadline admits an assignment exactly when a flow of all survivors exists.
4. Source edges carry survivors per place, and helicopter edges carry seat limits.
5. Flow capacity grows with the deadline, so binary search finds the smallest working day.

| term | meaning |
|---|---|
| `distances` | shortest walking days between places |
| `rescueTimes` | ready day for each place and helicopter |
| `rescuedByDay` | flow value for one day limit |
| `lowerDay` | smallest day known to work |
| `survivorTotal` | number of people to rescue |

The flow network uses these values at every deadline.

Script-generated trace for the first sample case:

```
quantity | value
survivors | 3 + 4 + 5 + 6 = 18
seat total | 7 + 2 + 3 + 6 = 18
walk 1 -> 4 | 4 days on the direct road
ready day 1 -> helicopter 1 | max(4, 4) = 4
flow at day 5 | 16
flow at day 6 | 18
answer | 6
```

At day five one helicopter is still unreachable, so two survivors cannot board.

## Code

**Bulk input and buffered output.** One input string serves all cases; answers leave in blocks.

```nim
const flushBlockBytes = 1 shl 17
const infiniteDistance = 1 shl 28
const finalDay = 1000

type
  FlowEdge = object
    destination: int
    reverseIndex: int
    capacity: int

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

The flow edge keeps only an endpoint and a capacity.
The integer scanner ignores spaces and blank lines.
The answer buffer flushes in 128 KiB blocks.

**Dinic flow.** A level graph sends blocking flows through the residual network.

```nim
var flowGraph = newSeq[seq[FlowEdge]]()
var levelGraph = newSeq[int]()
var edgeCursor = newSeq[int]()

proc addFlowEdge(sourceIndex, targetIndex, capacityValue: int) =
  let forwardIndex = flowGraph[sourceIndex].len
  flowGraph[sourceIndex].add FlowEdge(destination: targetIndex, reverseIndex: flowGraph[targetIndex].len, capacity: capacityValue)
  flowGraph[targetIndex].add FlowEdge(destination: sourceIndex, reverseIndex: forwardIndex, capacity: 0)

proc sendFlow(nodeIndex, availableFlow, sinkIndex: int): int =
  if nodeIndex == sinkIndex:
    return availableFlow
  while edgeCursor[nodeIndex] < flowGraph[nodeIndex].len:
    let edgeIndex = edgeCursor[nodeIndex]
    let edgeDestination = flowGraph[nodeIndex][edgeIndex].destination
    if flowGraph[nodeIndex][edgeIndex].capacity > 0 and levelGraph[edgeDestination] == levelGraph[nodeIndex] + 1:
      let pushedFlow = sendFlow(edgeDestination, min(availableFlow, flowGraph[nodeIndex][edgeIndex].capacity), sinkIndex)
      if pushedFlow > 0:
        flowGraph[nodeIndex][edgeIndex].capacity -= pushedFlow
        flowGraph[edgeDestination][flowGraph[nodeIndex][edgeIndex].reverseIndex].capacity += pushedFlow
        return pushedFlow
    edgeCursor[nodeIndex] += 1
  return 0

proc maximumFlow(sourceIndex, sinkIndex: int): int =
  var totalFlow = 0
  while true:
    let nodeCount = flowGraph.len
    levelGraph = newSeq[int](nodeCount)
    for nodeIndex in 0 .. nodeCount - 1:
      levelGraph[nodeIndex] = -1
    levelGraph[sourceIndex] = 0
    var queue = newSeq[int]()
    queue.add sourceIndex
    var queueHead = 0
    while queueHead < queue.len:
      let currentNode = queue[queueHead]
      queueHead += 1
      for edgeIndex in 0 .. flowGraph[currentNode].len - 1:
        let edge = flowGraph[currentNode][edgeIndex]
        if edge.capacity > 0 and levelGraph[edge.destination] == -1:
          levelGraph[edge.destination] = levelGraph[currentNode] + 1
          queue.add edge.destination
    if levelGraph[sinkIndex] == -1:
      break
    edgeCursor = newSeq[int](nodeCount)
    while true:
      let pushedFlow = sendFlow(sourceIndex, infiniteDistance, sinkIndex)
      if pushedFlow == 0:
        break
      totalFlow += pushedFlow
  return totalFlow
```

Each reverse edge cancels an earlier push.
Breadth-first search assigns levels before blocking flow.
The edge cursor avoids rescanning exhausted edges.

**Deadline network.** One day limit builds one network of reachable place-to-helicopter links.

```nim
proc rescuedByDay(dayLimit: int, placeCount, helicopterCount: int, survivorCounts: seq[int], rescueTimes: seq[seq[int]], helicopterCapacities: seq[int]): int =
  let sourceNode = 0
  let sinkNode = placeCount + helicopterCount + 1
  flowGraph = newSeq[seq[FlowEdge]](sinkNode + 1)
  for nodeIndex in 0 .. sinkNode:
    flowGraph[nodeIndex] = newSeq[FlowEdge]()
  for placeIndex in 1 .. placeCount:
    if survivorCounts[placeIndex] > 0:
      addFlowEdge(sourceNode, placeIndex, survivorCounts[placeIndex])
      for heliIndex in 1 .. helicopterCount:
        if rescueTimes[placeIndex][heliIndex] <= dayLimit:
          addFlowEdge(placeIndex, placeCount + heliIndex, survivorCounts[placeIndex])
  for heliIndex in 1 .. helicopterCount:
    addFlowEdge(placeCount + heliIndex, sinkNode, helicopterCapacities[heliIndex])
  return maximumFlow(sourceNode, sinkNode)
```

An empty place creates no source edge.
A helicopter link exists when its ready day fits the limit.
The returned flow counts rescued survivors.

**Case processing.** Road relaxation and binary search produce the final line.

```nim
let testCount = nextInt(inputData, scanPos)
for testIndex in 0 .. testCount - 1:
  let placeCount = nextInt(inputData, scanPos)
  let roadCount = nextInt(inputData, scanPos)
  let helicopterCount = nextInt(inputData, scanPos)
  var survivorCounts = newSeq[int](placeCount + 1)
  var survivorTotal = 0
  for placeIndex in 1 .. placeCount:
    survivorCounts[placeIndex] = nextInt(inputData, scanPos)
    survivorTotal += survivorCounts[placeIndex]
  var distances = newSeq[seq[int]](placeCount + 1)
  for fromPlace in 0 .. placeCount:
    distances[fromPlace] = newSeq[int](placeCount + 1)
    for toPlace in 0 .. placeCount:
      if fromPlace == toPlace:
        distances[fromPlace][toPlace] = 0
      else:
        distances[fromPlace][toPlace] = infiniteDistance
  for roadIndex in 0 .. roadCount - 1:
    let firstPlace = nextInt(inputData, scanPos)
    let secondPlace = nextInt(inputData, scanPos)
    let travelDays = nextInt(inputData, scanPos)
    if travelDays < distances[firstPlace][secondPlace]:
      distances[firstPlace][secondPlace] = travelDays
      distances[secondPlace][firstPlace] = travelDays
  for viaPlace in 1 .. placeCount:
    for fromPlace in 1 .. placeCount:
      if distances[fromPlace][viaPlace] >= infiniteDistance:
        continue
      for toPlace in 1 .. placeCount:
        if distances[viaPlace][toPlace] < infiniteDistance and distances[fromPlace][toPlace] > distances[fromPlace][viaPlace] + distances[viaPlace][toPlace]:
          distances[fromPlace][toPlace] = distances[fromPlace][viaPlace] + distances[viaPlace][toPlace]
  var helicopterDays = newSeq[int](helicopterCount + 1)
  var helicopterPlaces = newSeq[int](helicopterCount + 1)
  var helicopterCapacities = newSeq[int](helicopterCount + 1)
  for heliIndex in 1 .. helicopterCount:
    helicopterDays[heliIndex] = nextInt(inputData, scanPos)
    helicopterPlaces[heliIndex] = nextInt(inputData, scanPos)
    helicopterCapacities[heliIndex] = nextInt(inputData, scanPos)
  var rescueTimes = newSeq[seq[int]](placeCount + 1)
  for placeIndex in 0 .. placeCount:
    rescueTimes[placeIndex] = newSeq[int](helicopterCount + 1)
    for heliIndex in 0 .. helicopterCount:
      rescueTimes[placeIndex][heliIndex] = infiniteDistance
  for placeIndex in 1 .. placeCount:
    for heliIndex in 1 .. helicopterCount:
      let walkingDays = distances[placeIndex][helicopterPlaces[heliIndex]]
      if walkingDays < infiniteDistance:
        rescueTimes[placeIndex][heliIndex] = max(helicopterDays[heliIndex], walkingDays)
  if rescuedByDay(finalDay, placeCount, helicopterCount, survivorCounts, rescueTimes, helicopterCapacities) < survivorTotal:
    let rescuedCount = rescuedByDay(finalDay, placeCount, helicopterCount, survivorCounts, rescueTimes, helicopterCapacities)
    appendOutput($rescuedCount)
    appendOutput(" survivor(s) can be rescued.")
    outputBuffer.add '\n'
  else:
    var lowerDay = 0
    var upperDay = finalDay
    while lowerDay < upperDay:
      let middleDay = (lowerDay + upperDay) div 2
      if rescuedByDay(middleDay, placeCount, helicopterCount, survivorCounts, rescueTimes, helicopterCapacities) == survivorTotal:
        upperDay = middleDay
      else:
        lowerDay = middleDay + 1
    appendOutput("All people can be rescued in ")
    appendOutput($lowerDay)
    appendOutput(" day(s).")
    outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The last day reveals the best partial rescue.
Binary search narrows the full-rescue day to one value.
Each case prints exactly one line.

## Complexity

All-pairs relaxation runs once per case; each flow test is small.

| phase | time | space |
|---|---|---|
| input read | one pass over case integers | one input string |
| shortest paths | three passes over places squared | distance matrix |
| flow tests | ten networks with about 100 nodes | residual graph |
| output | one line per test case | block buffer |

At most ten flow tests happen per case.

| measure | Big O |
|---|---|
| shortest paths | O(places cubed) |
| flow test | O(edges times survivors) |
| binary search | O(log 1000) flow tests |

Scanning all thousand days would multiply the flow work by a hundred.

The flow model turns assignment choices into capacity checks.
