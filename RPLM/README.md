# RPLM — Mountain Cave (SPOJ)
<https://www.spoj.com/problems/RPLM/>

## Problem

Reach the last room from room 0 as early as possible, and among equal arrival times with the shortest travel distance. Tunnels open only during a time window, and hammers can break through blocked tunnels.

Input starts with the case count. Each case gives V, E, and M, then E tunnel records with origin, destination, opening, collapse, distance, and travel time. Print `Scenario #i: T D`, or `Scenario #i: -1` when the last room is unreachable.

| Constraint | Value |
| --- | --- |
| Cases T | 1 to 10 |
| Rooms V | 2 to 100 |
| Tunnels E | 1 to 1000 |
| Hammers M | 0 to 50 |
| Tunnel distance | at most 10 |
| Window times | 1 to 100000 |
| Judge time | 1000 ms |
| Judge memory | 1536 MB |

The sample input and its expected output follow byte for byte.

```
4
6 6 2
0 1 1 18 3 3
0 2 1 12 4 4
0 4 1 3 5 5
2 3 1 8 2 2
3 4 1 5 3 3
4 5 5 20 1 1
6 6 1
0 1 1 18 3 3
0 2 1 12 4 4
0 4 1 3 5 5
2 3 1 8 2 2
3 4 1 5 3 3
4 5 5 20 1 1
6 6 0
0 1 1 18 3 3
0 2 1 12 4 4
0 4 1 3 5 5
2 3 1 8 2 2
3 4 8 25 3 3
4 5 5 20 1 1
3 3 0
0 1 0 5 4 4
1 2 0 5 2 2
0 2 0 5 6 6
```

```
Scenario #1: 6 6
Scenario #2: 7 6
Scenario #3: 12 10
Scenario #4: -1
```

## Idea

Carry two backpack counters, one for time and one for spent hammers, like choosing a route with both a clock and a ticket book.

Each state is a room plus the number of hammers already broken. Waiting until a tunnel opens costs time. Breaking in early costs a hammer. A collapse during the crossing costs another hammer. The program runs Dijkstra over those states and orders them by time, then distance. Trying every departure time would be unbounded. State Dijkstra settles each room and hammer count once. Track both clocks, then pick the first arrival at the last room.

## Why It Works

1. A tunnel entered before its opening time needs one hammer to break in.
2. Waiting until the opening time avoids that hammer but delays arrival.
3. A crossing that ends after the collapse time needs one more hammer.
4. A tunnel entered after its collapse time needs one hammer to clear the existing pile.
5. Dijkstra orders states by arrival time, then distance, and every move increases time.

| Term | Meaning |
| --- | --- |
| `bestTimes` | earliest arrival for each room and hammer count |
| `bestDistances` | shortest distance among equal arrival times |
| `heapTime` | priority queue ordered first by arrival time |
| `hammerNeed` | hammers required for one tunnel crossing |

A script-generated check uses the first sample case. Tunnel 0-4 is free from time 1 to 3 and takes 5 time units. Waiting until time 1 lands at time 6, so one hammer covers the collapse. Breaking in at time 0 lands at time 5 but needs two hammers: one to enter and one for the collapse. With two hammers, the second option wins. Tunnel 4-5 then runs from time 5 to 6, giving arrival 6 and distance 6.

## Code

**Types and scanner.** One tunnel record keeps all six input fields.

```nim
const flushBlockBytes = 1 shl 17
const infiniteCost = high(int64) div 4

type
  Tunnel = object
    destination: int
    openingTime: int
    collapseTime: int
    tunnelLength: int
    travelTime: int

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

Every input number is nonnegative.
The tunnel object mirrors one input record.
The scanner ignores line breaks.

**Output writer.** A single buffer holds all scenario lines.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The buffer flushes in fixed blocks.
The final flush emits any remaining bytes.
No write happens per room.

**Priority queue.** Four parallel arrays store one heap entry each.

```nim
var heapTime = newSeq[int64]()
var heapDistance = newSeq[int64]()
var heapRoom = newSeq[int]()
var heapUsed = newSeq[int]()

proc swapHeapEntries(firstIndex: int, secondIndex: int) =
  swap heapTime[firstIndex], heapTime[secondIndex]
  swap heapDistance[firstIndex], heapDistance[secondIndex]
  swap heapRoom[firstIndex], heapRoom[secondIndex]
  swap heapUsed[firstIndex], heapUsed[secondIndex]

proc precedes(firstIndex: int, secondIndex: int): bool =
  if heapTime[firstIndex] != heapTime[secondIndex]:
    return heapTime[firstIndex] < heapTime[secondIndex]
  return heapDistance[firstIndex] < heapDistance[secondIndex]

proc heapPush(arrivalTime: int64, travelDistance: int64, roomIndex: int, hammerCount: int) =
  heapTime.add arrivalTime
  heapDistance.add travelDistance
  heapRoom.add roomIndex
  heapUsed.add hammerCount
  var childIndex = heapTime.len - 1
  while childIndex > 0:
    let parentIndex = (childIndex - 1) div 2
    if precedes(childIndex, parentIndex):
      swapHeapEntries(childIndex, parentIndex)
      childIndex = parentIndex
    else:
      break

proc heapPop(arrivalResult: var int64, distanceResult: var int64, roomResult: var int, usedResult: var int) =
  arrivalResult = heapTime[0]
  distanceResult = heapDistance[0]
  roomResult = heapRoom[0]
  usedResult = heapUsed[0]
  let finalIndex = heapTime.len - 1
  if finalIndex > 0:
    swapHeapEntries(0, finalIndex)
  heapTime.setLen finalIndex
  heapDistance.setLen finalIndex
  heapRoom.setLen finalIndex
  heapUsed.setLen finalIndex
  var parentIndex = 0
  while true:
    let leftChild = parentIndex * 2 + 1
    if leftChild >= heapTime.len:
      break
    let rightChild = leftChild + 1
    var smallerChild = leftChild
    if rightChild < heapTime.len and precedes(rightChild, leftChild):
      smallerChild = rightChild
    if precedes(smallerChild, parentIndex):
      swapHeapEntries(parentIndex, smallerChild)
      parentIndex = smallerChild
    else:
      break
```

The heap compares time first.
Equal times compare distance.
Sift operations keep all four arrays aligned.

**Case solver.** Each popped state relaxes every tunnel out of its room.

```nim
let caseTotal = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseTotal - 1:
  let roomCount = nextInt(inputData, scanPos)
  let tunnelCount = nextInt(inputData, scanPos)
  let hammerSupply = nextInt(inputData, scanPos)
  var adjacency = newSeq[seq[Tunnel]](roomCount)
  var tunnelIndex = 0
  while tunnelIndex < tunnelCount:
    let originRoom = nextInt(inputData, scanPos)
    let targetRoom = nextInt(inputData, scanPos)
    let openingTime = nextInt(inputData, scanPos)
    let collapseTime = nextInt(inputData, scanPos)
    let tunnelLength = nextInt(inputData, scanPos)
    let travelTime = nextInt(inputData, scanPos)
    adjacency[originRoom].add Tunnel(destination: targetRoom, openingTime: openingTime, collapseTime: collapseTime, tunnelLength: tunnelLength, travelTime: travelTime)
    adjacency[targetRoom].add Tunnel(destination: originRoom, openingTime: openingTime, collapseTime: collapseTime, tunnelLength: tunnelLength, travelTime: travelTime)
    tunnelIndex += 1
  let stateWidth = hammerSupply + 1
  let stateTotal = roomCount * stateWidth
  var bestTimes = newSeq[int64](stateTotal)
  var bestDistances = newSeq[int64](stateTotal)
  var stateIndex = 0
  while stateIndex < stateTotal:
    bestTimes[stateIndex] = infiniteCost
    bestDistances[stateIndex] = infiniteCost
    stateIndex += 1
  bestTimes[0] = 0
  bestDistances[0] = 0
  heapTime.setLen 0
  heapDistance.setLen 0
  heapRoom.setLen 0
  heapUsed.setLen 0
  heapPush(0, 0, 0, 0)
  var foundTime = int64(-1)
  var foundDistance = int64(0)
  while heapTime.len > 0:
    var currentTime: int64 = 0
    var currentDistance: int64 = 0
    var currentRoom = 0
    var currentUsed = 0
    heapPop(currentTime, currentDistance, currentRoom, currentUsed)
    let currentState = currentRoom * stateWidth + currentUsed
    if currentTime != bestTimes[currentState] or currentDistance != bestDistances[currentState]:
      continue
    if currentRoom == roomCount - 1:
      foundTime = currentTime
      foundDistance = currentDistance
      break
    var tunnelPosition = 0
    while tunnelPosition < adjacency[currentRoom].len:
      let tunnel = adjacency[currentRoom][tunnelPosition]
      var departureTime = currentTime
      var hammerNeed = 0
      if currentTime < tunnel.openingTime:
        let waitingArrival = int64(tunnel.openingTime + tunnel.travelTime)
        if waitingArrival > int64(tunnel.collapseTime):
          hammerNeed = 1
        else:
          hammerNeed = 0
        let waitingState = tunnel.destination * stateWidth + currentUsed + hammerNeed
        if currentUsed + hammerNeed <= hammerSupply and (waitingArrival < bestTimes[waitingState] or (waitingArrival == bestTimes[waitingState] and currentDistance + int64(tunnel.tunnelLength) < bestDistances[waitingState])):
          bestTimes[waitingState] = waitingArrival
          bestDistances[waitingState] = currentDistance + int64(tunnel.tunnelLength)
          heapPush(waitingArrival, currentDistance + int64(tunnel.tunnelLength), tunnel.destination, currentUsed + hammerNeed)
        departureTime = currentTime
        hammerNeed = 1
      elif currentTime <= int64(tunnel.collapseTime):
        hammerNeed = 0
      else:
        hammerNeed = 1
      let directArrival = departureTime + int64(tunnel.travelTime)
      if currentTime < tunnel.openingTime and directArrival > int64(tunnel.collapseTime):
        hammerNeed += 1
      elif currentTime >= tunnel.openingTime and currentTime <= int64(tunnel.collapseTime) and directArrival > int64(tunnel.collapseTime):
        hammerNeed = 1
      let nextUsed = currentUsed + hammerNeed
      if nextUsed <= hammerSupply:
        let nextState = tunnel.destination * stateWidth + nextUsed
        let nextDistance = currentDistance + int64(tunnel.tunnelLength)
        if directArrival < bestTimes[nextState] or (directArrival == bestTimes[nextState] and nextDistance < bestDistances[nextState]):
          bestTimes[nextState] = directArrival
          bestDistances[nextState] = nextDistance
          heapPush(directArrival, nextDistance, tunnel.destination, nextUsed)
      tunnelPosition += 1
  appendOutput("Scenario #" & $(caseIndex + 1) & ": ")
  if foundTime < 0:
    appendOutput("-1")
  else:
    appendOutput($foundTime & " " & $foundDistance)
  appendOutput("\n")
stdout.write outputBuffer
outputBuffer.setLen 0
```

Tunnels are stored in both directions.
The wait option and the break-in option are both tried.
The first popped target room gives the optimal pair.

## Complexity

Dijkstra settles each room and hammer count once, and each settle scans the room's tunnels.

| Phase | Time | Space |
| --- | --- | --- |
| Input read | one pass over E tunnel records | one input string |
| Dijkstra | heap over V times M+1 states | two state tables |
| Tunnel relaxations | two options per tunnel per state | one heap |
| Output | one line per case | one output buffer |

| Measure | Big O |
| --- | --- |
| Time per case | O(E M log(V M)) |
| Space | O(V M) |

Trying all possible waiting times would explore a continuous search space.

Discretizing into room and hammer states turns the search into one bounded Dijkstra run.
