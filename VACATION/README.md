# VACATION — Vacation Planning (SPOJ)

<https://www.spoj.com/problems/VACATION/>

## Problem

Directed flights connect farms, and each requested trip must pass through at least one hub farm. Report how many trips have a valid route and the sum of their minimum costs.

Input gives N, M, K and Q, then M flights with origin, destination and cost, then Q trips with start and end farms. Hubs are farms 1 through K. Output the feasible trip count on the first line and the summed minimum cost on the second line.

| item | bound |
|---|---|
| farms N | 1 to 200 |
| flights M | 1 to 10000 |
| hubs K | 1 to 100 |
| trips Q | 1 to 10000 |
| flight cost | 1 to 1000000 |
| judge limit | 1000 ms, 1536 MB |

The large trip count calls for cheap answers after one preprocessing pass.

Sample input:

```
3 3 1 3
3 1 10
1 3 10
1 2 7
3 2
2 3
1 2
```

Sample output:

```
2
24
```

Trips 3 to 2 and 1 to 2 are feasible, costing 17 and 7.

## Idea

Every valid route connects through a hub, like a flight that must touch a hub airport before reaching its destination. Precompute shortest paths from each hub to every farm and from every farm to each hub. A query then tries each hub as the connecting point and keeps the cheapest pair of legs. Dense Dijkstra costs O(N^2) per run and O(K) per query. Running Dijkstra once per query would cost far more.

## Why It Works

1. Take the first hub on any valid route.
2. That route splits into a start-to-hub leg and a hub-to-end leg.
3. Replacing either leg by a shortest path keeps the hub visit and lowers the cost.
4. Dijkstra on the reversed graph from a hub gives every farm's distance to that hub.
5. Minimizing the two leg lengths over all hubs gives the cheapest valid route.
6. When no hub has both legs finite, no valid route exists.

The main terms:

| term | meaning |
|---|---|
| `forwardEdges` | flight costs in their given direction |
| `reverseEdges` | flight costs with every direction flipped |
| `distancesFromHub` | shortest cost from a hub to each farm |
| `distancesToHub` | shortest cost from each farm to a hub |
| `bestCost` | cheapest connecting route for one trip |

The two distance tables make each query a short scan over hubs.

A script trace of the sample:

```
hub farm: 1
3 -> 1 -> 2 cost: 10 + 7 = 17
2 has no outgoing flight, so no route
1 -> 2 cost: 0 + 7 = 7
count = 2, sum = 24
```

A trip that starts at a hub has a zero first leg, which keeps it valid.

## Code

**Input, scanner, buffers, and Dijkstra.** The graph is stored as two flat cost matrices.

```nim
const flushBlockBytes = 1 shl 17
const infinity = 2305843009213693951'i64

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

proc dijkstra(edges: seq[int64], source: int, nodeCount: int): seq[int64] =
  var distances = newSeq[int64](nodeCount)
  var settled = newSeq[bool](nodeCount)
  for node in 0 .. nodeCount - 1:
    distances[node] = edges[source * nodeCount + node]
  distances[source] = 0'i64
  settled[source] = true
  for stepIndex in 1 .. nodeCount - 1:
    var bestNode = -1
    var bestDistance = infinity
    for node in 0 .. nodeCount - 1:
      if not settled[node] and distances[node] < bestDistance:
        bestDistance = distances[node]
        bestNode = node
    if bestNode < 0:
      break
    settled[bestNode] = true
    for node in 0 .. nodeCount - 1:
      if not settled[node]:
        let edgeCost = edges[bestNode * nodeCount + node]
        if edgeCost < infinity:
          let candidate = bestDistance + edgeCost
          if candidate < distances[node]:
            distances[node] = candidate
  return distances
```

Parallel flights keep only the cheapest cost.
The square matrix makes one Dijkstra run cost O(N^2).
The infinity sentinel marks pairs with no path.

**Distance tables.** Each hub supplies one forward run and one reversed run.

```nim
let farmCount = nextInt(inputData, scanPos)
let flightCount = nextInt(inputData, scanPos)
let hubCount = nextInt(inputData, scanPos)
let tripCount = nextInt(inputData, scanPos)
var forwardEdges = newSeq[int64](farmCount * farmCount)
var reverseEdges = newSeq[int64](farmCount * farmCount)
for edgeIndex in 0 .. farmCount * farmCount - 1:
  forwardEdges[edgeIndex] = infinity
  reverseEdges[edgeIndex] = infinity
for flightIndex in 0 .. flightCount - 1:
  let origin = nextInt(inputData, scanPos) - 1
  let destination = nextInt(inputData, scanPos) - 1
  let cost = int64(nextInt(inputData, scanPos))
  let forwardIndex = origin * farmCount + destination
  let reverseIndex = destination * farmCount + origin
  if cost < forwardEdges[forwardIndex]:
    forwardEdges[forwardIndex] = cost
  if cost < reverseEdges[reverseIndex]:
    reverseEdges[reverseIndex] = cost
var tripStarts = newSeq[int](tripCount)
var tripEnds = newSeq[int](tripCount)
for tripIndex in 0 .. tripCount - 1:
  tripStarts[tripIndex] = nextInt(inputData, scanPos) - 1
  tripEnds[tripIndex] = nextInt(inputData, scanPos) - 1
var distancesToHub = newSeq[int64](hubCount * farmCount)
var distancesFromHub = newSeq[int64](hubCount * farmCount)
for hubIndex in 0 .. hubCount - 1:
  let toHub = dijkstra(reverseEdges, hubIndex, farmCount)
  let fromHub = dijkstra(forwardEdges, hubIndex, farmCount)
  for node in 0 .. farmCount - 1:
    distancesToHub[hubIndex * farmCount + node] = toHub[node]
    distancesFromHub[hubIndex * farmCount + node] = fromHub[node]
```

Farm numbers are converted to zero-based indexes on input.
Each hub contributes two rows to the distance tables.
Trips are kept until both tables are complete.

**Trip answers.** Every hub is tried as the connecting point.

```nim
var possibleTrips = 0
var totalCost: int64 = 0
for tripIndex in 0 .. tripCount - 1:
  let startFarm = tripStarts[tripIndex]
  let endFarm = tripEnds[tripIndex]
  var bestCost = infinity
  for hubIndex in 0 .. hubCount - 1:
    let firstLeg = distancesToHub[hubIndex * farmCount + startFarm]
    let secondLeg = distancesFromHub[hubIndex * farmCount + endFarm]
    if firstLeg < infinity and secondLeg < infinity:
      let candidate = firstLeg + secondLeg
      if candidate < bestCost:
        bestCost = candidate
  if bestCost < infinity:
    possibleTrips += 1
    totalCost += bestCost
appendOutput($(possibleTrips))
outputBuffer.add '\n'
appendOutput($(totalCost))
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

A finite first leg and second leg make the trip feasible.
The total uses int64 because Q routes can sum beyond 32 bits.
Two lines are written once through the block buffer.

## Complexity

Preprocessing dominates, and each query scans the hub list.

| phase | time | space |
|---|---|---|
| input read | one pass over flights and trips | one input string |
| distance tables | O(K) runs of O(N^2) | two N by N matrices |
| queries | O(Q * K) leg checks | two K by N tables |
| output | two lines | block buffer |

The two distance tables hold all reusable results.

| measure | Big O |
|---|---|
| time | O(K * N^2 + Q * K) |
| space | O(N^2 + K * N) |

Running Dijkstra afresh per trip would cost O(Q * M log N).
Sharing the precomputed tables removes that repeated work.
