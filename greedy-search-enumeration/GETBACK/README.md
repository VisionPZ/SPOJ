# GETBACK — Get Back! (SPOJ)

<https://www.spoj.com/problems/GETBACK/>

## Problem

Find the least water needed to travel from the oasis to Desertville. Each mile costs one unit of water, a traveler carries at most C units, and restpoints hold unlimited stored water.

Input starts with the number of test cases. Each case gives N, M and C, then M lines with two restpoint numbers and a path length. Restpoint 1 is the oasis and restpoint N is Desertville. Print the minimum water, or -1 when the trip is impossible.

| item | bound |
|---|---|
| restpoints N | below 100 |
| paths M | below 100 |
| capacity C | below 100 |
| path length | below 100 |
| judge limit | 500 ms, 1536 MB |

Every path is usable in both directions.

Sample input:

```
1
9 10 25
1 2 3
2 3 12
3 4 4
3 5 9
4 9 13
5 9 5
2 6 10
6 7 10
7 8 10
8 9 10
```

Sample output:

```
65
```

## Idea

Work backwards from Desertville and ask how much water each restpoint needs, like stocking depots before a long trek. A short leg can be ferried by making round trips that leave water behind. Each extra round trip costs twice the leg length and deposits the spare capacity. The algorithm is Dijkstra on required water, relaxing every road with this ferry formula. A plain shortest-distance search would miss cheaper routes that use more, shorter legs. Takeaway: minimize stocked water, not road length.

## Why It Works

1. Let W be the water that must wait at the far end of a leg of length L.
2. If the traveler cannot return after crossing, a single trip works only when W plus L fits in C.
3. Otherwise each round trip costs 2 L and deposits C minus 2 L at the far end.
4. The last one-way trip deposits at most C minus L, so the number of round trips is the ceiling of the remaining need over the deposit per trip.
5. Since the required water only grows by nonnegative amounts along a leg, Dijkstra can settle restpoints in increasing order of need.

| term | meaning |
|---|---|
| `capacity` | most water carried at once |
| `neededWater` | water required at the far end of a leg |
| `roundTrips` | full return trips for one leg |
| `needed` | least water required at each restpoint |
| `chosenCost` | smallest unsettled need in the current step |

The table defines the quantities in the ferry formula.

In the sample the last leg 4 to 9 has length 13 and capacity 25. A round trip would spend 26 units, so only one one-way trip is possible. The best route uses the short legs 1-2, 2-3, 3-5 and 5-9. The final need at the oasis is 65.

The sample answer 65 follows from the ferry counts along that route.

## Code

**Input and scanning.** The hand reader loads each case and keeps only usable roads.

```nim
const flushBlockBytes = 1 shl 17
const unreachableCost = int64(1 shl 60)

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

Roads longer than the capacity are dropped.
Each usable road is stored in both directions.
Unreachable needs use a large sentinel.

**Ferry formula.** One leg turns a downstream need into an upstream need.

```nim
proc ferryCost(neededWater: int64, legLength: int, capacity: int): int64 =
  if neededWater == 0:
    return int64(legLength)
  if 2 * legLength >= capacity:
    if neededWater + int64(legLength) > int64(capacity):
      return unreachableCost
    return neededWater + int64(legLength)
  let finalLoad = int64(capacity - legLength)
  if neededWater <= finalLoad:
    return neededWater + int64(legLength)
  let depositPerTrip = int64(capacity - 2 * legLength)
  let extraWater = neededWater - finalLoad
  var roundTrips = extraWater div depositPerTrip
  if extraWater mod depositPerTrip != 0:
    roundTrips += 1
  return neededWater + int64(legLength) + 2 * int64(legLength) * roundTrips
```

The first branch covers legs too long for a return trip.
Round trips are rounded up with integer arithmetic.
All costs stay in int64.

**Need propagation.** Dijkstra settles restpoints by increasing need.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let restpointCount = nextInt(inputData, scanPos)
  let pathCount = nextInt(inputData, scanPos)
  let capacity = nextInt(inputData, scanPos)
  var edgeFrom = newSeq[int](0)
  var edgeTo = newSeq[int](0)
  var edgeLength = newSeq[int](0)
  for pathIndex in 0 .. pathCount - 1:
    let firstPoint = nextInt(inputData, scanPos)
    let secondPoint = nextInt(inputData, scanPos)
    let pathLength = nextInt(inputData, scanPos)
    if pathLength > capacity:
      continue
    edgeFrom.add(firstPoint)
    edgeTo.add(secondPoint)
    edgeLength.add(pathLength)
    edgeFrom.add(secondPoint)
    edgeTo.add(firstPoint)
    edgeLength.add(pathLength)
  var needed = newSeq[int64](restpointCount + 1)
  var settled = newSeq[bool](restpointCount + 1)
  for point in 1 .. restpointCount:
    needed[point] = unreachableCost
    settled[point] = false
  needed[restpointCount] = 0
  for stepIndex in 0 .. restpointCount - 1:
    var chosenPoint = -1
    var chosenCost = unreachableCost
    for point in 1 .. restpointCount:
      if not settled[point] and needed[point] < chosenCost:
        chosenPoint = point
        chosenCost = needed[point]
    if chosenPoint == -1:
      break
    settled[chosenPoint] = true
    for edgeIndex in 0 .. edgeFrom.len - 1:
      if edgeFrom[edgeIndex] != chosenPoint:
        continue
      let neighborPoint = edgeTo[edgeIndex]
      if settled[neighborPoint]:
        continue
      let candidateCost = ferryCost(chosenCost, edgeLength[edgeIndex], capacity)
      if candidateCost < needed[neighborPoint]:
        needed[neighborPoint] = candidateCost
  if needed[1] >= unreachableCost:
    appendOutput("-1\n")
  else:
    appendOutput($needed[1])
    outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The destination starts with zero need.
Each step relaxes all roads out of the settled point.
A sentinel need becomes the -1 answer.

## Complexity

The graph has fewer than 100 restpoints and paths.

| phase | time | space |
|---|---|---|
| input read | one pass over M roads | one input string |
| need propagation | N selections plus M relaxations per case | two arrays of N values |
| output | one line per case | block buffer |

Both arrays are indexed by restpoint number.

| measure | Big O |
|---|---|
| time per case | O(N^2 + N M) |
| space per case | O(N + M) |

Scanning every water distribution would be exponential. The monotone ferry cost makes a shortest-need search sufficient.
