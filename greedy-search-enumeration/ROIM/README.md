# ROIM — Boa viagem, Roim (SPOJ)

<https://www.spoj.com/problems/ROIM/>

## Problem

Two flight plans must go from airport 0 to airport N-1 without sharing any flight. Use as few chartered flights as possible, then minimize the combined fare.

The input holds several cases. Each case starts with N, R, and C, followed by R regular flights and C chartered flights. Each flight gives a start airport, an end airport, and a fare. A line of three zeros ends the input. Print two integers for the charter count and total fare, or print `Boa viagem, Roim` when two plans cannot be formed.

| item | bound |
|---|---|
| airports N | 2 to 225 |
| flights R + C | up to N(N-1)/2 |
| fare per flight | 1 to 100 |
| cases | until the zero line |
| judge limit | 300 ms, 1536 MB |

The airport count drives the design; enumerating every pair of routes grows exponentially.

Sample input:

```
4 5 0
0 1 1
1 3 5
0 2 5
1 2 1
2 3 1

4 4 1
0 1 2
1 3 2
0 2 2
1 2 1
2 3 2

2 1 0
0 1 1
0 0 0
```

Sample output:

```
0 12
1 8
Boa viagem, Roim
```

## Idea

Send two units of flow through a network of one-use flights, like routing two parcels through a grid of single-use tunnels. A large penalty on chartered flights makes the cheapest flow also the one with the fewest charters.

Each flight becomes an edge with capacity one and cost equal to its fare plus a charter penalty. Successive shortest augmenting paths with Dijkstra and node potentials find the cheapest two-unit flow. One augmentation costs O(E log V), and only two augmentations run.

Listing all route pairs would explode on a dense graph. Residual edges let the second route rearrange the first one, which a simple two-path search misses. The takeaway is to model the pair of plans as one small flow problem.

## Why It Works

1. Capacity one on every flight prevents the two plans from sharing a flight.
2. Two units of flow from source to sink decompose into two edge-disjoint routes.
3. A charter edge carries a penalty of 100000, larger than any possible sum of fares.
4. Minimizing weighted cost therefore minimizes charters first and fares second.
5. A reverse residual edge lets the second augmentation cancel and reroute part of the first route.
6. Node potentials keep reduced costs nonnegative, so Dijkstra can replace slower Bellman-Ford.
7. If the sink cannot accept two units, no pair of plans exists.

| term | meaning |
|---|---|
| `FlightEdge` | one directed flight with a reverse counterpart |
| `charterPenalty` | added cost that ranks charters after fares |
| `remainingCapacity` | remaining uses of a flight, zero after one route takes it |
| `traversalCost` | weighted cost of the flight, negative on residual edges |
| `nodePotentials` | accumulated shortest distances that keep costs nonnegative |
| `distanceValues` | reduced distances from the start airport |
| `totalCost` | weighted cost of the two chosen plans |
| `flowValue` | number of plans routed so far |

The table names the values maintained during the two augmentations.

A script trace of the second sample picks two routes. The team uses 0→1→3 with fare 2 + 2 = 4. The other plan uses 0→2→3 with fare 2 + 2 = 4, where the last flight is chartered.

| route | flights | charters | fare |
|---|---|---|---|
| team | 0→1, 1→3 | 0 | 4 |
| other | 0→2, 2→3 | 1 | 4 |
| combined | both routes | 1 | 8 |

The trace reproduces the second sample answer exactly.

The penalty exceeds the largest possible fare sum of 44800. That gap keeps the two objective levels separate. Unreachable sinks end the loop before two units are sent.

## Code

**Input and scanner.** The reader loads all lines and extracts flight numbers, then sets up one output buffer.

```nim
const flushBlockBytes = 1 shl 17
const charterPenalty: int64 = 100000
const infiniteDistance = high(int64) div 4

type FlightEdge = object
  targetNode: int
  reverseIndex: int
  remainingCapacity: int
  traversalCost: int64

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

Blank lines between cases carry no numbers.
The scanner stops at the three-zero terminator.
`appendOutput` flushes only after a full block.

**Residual graph and heap.** Each flight gets a forward edge and a zero-capacity reverse edge.

```nim
var graph: seq[seq[FlightEdge]] = @[]
var distanceValues: seq[int64] = @[]
var parentNodes: seq[int] = @[]
var parentEdges: seq[int] = @[]
var nodePotentials: seq[int64] = @[]
var heapNodes: seq[int] = @[]
var heapDistances: seq[int64] = @[]

proc addFlight(sourceNode: int, targetNode: int, costValue: int64) =
  let forwardIndex = graph[sourceNode].len
  let backwardIndex = graph[targetNode].len
  graph[sourceNode].add FlightEdge(targetNode: targetNode,
    reverseIndex: backwardIndex, remainingCapacity: 1, traversalCost: costValue)
  graph[targetNode].add FlightEdge(targetNode: sourceNode,
    reverseIndex: forwardIndex, remainingCapacity: 0, traversalCost: -costValue)

proc heapPush(distanceValue: int64, nodeIndex: int) =
  heapDistances.add distanceValue
  heapNodes.add nodeIndex
  var childIndex = heapDistances.len - 1
  while childIndex > 0:
    let ancestorIndex = (childIndex - 1) div 2
    if heapDistances[ancestorIndex] <= heapDistances[childIndex]:
      break
    swap heapDistances[ancestorIndex], heapDistances[childIndex]
    swap heapNodes[ancestorIndex], heapNodes[childIndex]
    childIndex = ancestorIndex

proc heapPop(): tuple[nodeIndex: int, distanceValue: int64] =
  result.nodeIndex = heapNodes[0]
  result.distanceValue = heapDistances[0]
  let lastNode = heapNodes[heapNodes.len - 1]
  let lastDistance = heapDistances[heapDistances.len - 1]
  heapNodes.setLen(heapNodes.len - 1)
  heapDistances.setLen(heapDistances.len - 1)
  if heapNodes.len > 0:
    heapNodes[0] = lastNode
    heapDistances[0] = lastDistance
    var ancestorIndex = 0
    while true:
      let leftIndex = ancestorIndex * 2 + 1
      let rightIndex = leftIndex + 1
      var smallestIndex = ancestorIndex
      if leftIndex < heapDistances.len and
         heapDistances[leftIndex] < heapDistances[smallestIndex]:
        smallestIndex = leftIndex
      if rightIndex < heapDistances.len and
         heapDistances[rightIndex] < heapDistances[smallestIndex]:
        smallestIndex = rightIndex
      if smallestIndex == ancestorIndex:
        break
      swap heapDistances[ancestorIndex], heapDistances[smallestIndex]
      swap heapNodes[ancestorIndex], heapNodes[smallestIndex]
      ancestorIndex = smallestIndex
```

The reverse edge mirrors the forward cost.
The heap keeps Dijkstra's queue ordered by reduced distance.
Each heap operation touches one branch of the tree.

**Shortest residual path.** Dijkstra uses potentials so every reduced cost stays nonnegative.

```nim
proc shortestPath(sourceNode: int, sinkNode: int): bool =
  for nodeIndex in 0 .. distanceValues.len - 1:
    distanceValues[nodeIndex] = infiniteDistance
  distanceValues[sourceNode] = 0
  heapNodes.setLen 0
  heapDistances.setLen 0
  heapPush(0, sourceNode)
  while heapNodes.len > 0:
    let current = heapPop()
    if current.distanceValue > distanceValues[current.nodeIndex]:
      continue
    for edgeIndex in 0 .. graph[current.nodeIndex].len - 1:
      let edge = graph[current.nodeIndex][edgeIndex]
      if edge.remainingCapacity <= 0:
        continue
      let nextNode = edge.targetNode
      let reducedCost = edge.traversalCost + nodePotentials[current.nodeIndex] -
                        nodePotentials[nextNode]
      let candidateDistance = distanceValues[current.nodeIndex] + reducedCost
      if candidateDistance < distanceValues[nextNode]:
        distanceValues[nextNode] = candidateDistance
        parentNodes[nextNode] = current.nodeIndex
        parentEdges[nextNode] = edgeIndex
        heapPush(candidateDistance, nextNode)
  return distanceValues[sinkNode] < infiniteDistance
```

Stale heap entries are skipped on arrival.
Parent arrays record the cheapest route to each airport.
A false return means the sink is unreachable.

**Case loop.** Two augmentations build the plans, then the penalty and fare are split apart.

```nim
while true:
  let airportCount = nextInt(inputData, scanPos)
  let regularCount = nextInt(inputData, scanPos)
  let charterCount = nextInt(inputData, scanPos)
  if airportCount == 0 and regularCount == 0 and charterCount == 0:
    break
  graph = newSeq[seq[FlightEdge]](airportCount)
  for flightIndex in 1 .. regularCount:
    let departure = nextInt(inputData, scanPos)
    let arrival = nextInt(inputData, scanPos)
    let fare = int64(nextInt(inputData, scanPos))
    addFlight(departure, arrival, fare)
  for flightIndex in 1 .. charterCount:
    let departure = nextInt(inputData, scanPos)
    let arrival = nextInt(inputData, scanPos)
    let fare = int64(nextInt(inputData, scanPos))
    addFlight(departure, arrival, charterPenalty + fare)
  distanceValues = newSeq[int64](airportCount)
  parentNodes = newSeq[int](airportCount)
  parentEdges = newSeq[int](airportCount)
  nodePotentials = newSeq[int64](airportCount)
  var totalCost: int64 = 0
  var flowValue = 0
  let destination = airportCount - 1
  while flowValue < 2:
    if not shortestPath(0, destination):
      break
    for nodeIndex in 0 .. airportCount - 1:
      if distanceValues[nodeIndex] < infiniteDistance:
        nodePotentials[nodeIndex] += distanceValues[nodeIndex]
    var currentNode = destination
    while currentNode != 0:
      let previousNode = parentNodes[currentNode]
      let edgeIndex = parentEdges[currentNode]
      totalCost += graph[previousNode][edgeIndex].traversalCost
      graph[previousNode][edgeIndex].remainingCapacity -= 1
      let reverseIndex = graph[previousNode][edgeIndex].reverseIndex
      graph[currentNode][reverseIndex].remainingCapacity += 1
      currentNode = previousNode
    flowValue += 1
  if flowValue < 2:
    appendOutput("Boa viagem, Roim")
  else:
    appendOutput($(totalCost div charterPenalty))
    appendOutput(" ")
    appendOutput($(totalCost mod charterPenalty))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Potentials are updated after each shortest path.
Augmenting reverses one edge per flight in the chosen route.
Integer division extracts the charter count from the weighted cost.

## Complexity

Each case builds one residual graph and runs two shortest path searches.

| phase | time | space |
|---|---|---|
| input read | one pass over flight lines | one input string |
| graph build | one pair of edges per flight | residual graph |
| two augmentations | two Dijkstra runs over residual edges | distance and parent arrays |
| output | buffered writes | one output buffer |

The two shortest path searches dominate each case.

| measure | Big O |
|---|---|
| time | O(E log V) per augmentation |
| space | O(V + E) |

Enumerating all pairs of routes is exponential in the airport count. Min-cost flow reaches the same answer in two polynomial searches.
