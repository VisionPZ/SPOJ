# TLIGHTS — Traffic Lights (SPOJ)

<https://www.spoj.com/problems/TLIGHTS/>

## Problem

A city has K intersections joined by N two-way streets. Each light is green for g minutes, then red for r minutes, and all lights start green when the driver leaves intersection 1. Find the earliest arrival at intersection K, waiting at red lights as needed.

Input gives N and K, then N lines with the two endpoints and travel time, then K lines with g and r. Intersections 1 and K have no light and use zeros. Print one integer, the minimum number of minutes. A route always exists.

| item | bound |
|---|---|
| streets N | 1 to 100000 |
| intersections K | 1 to 1000 |
| travel time t | 1 to 1000 |
| green and red time | 1 to 1000 |
| judge limit | 2000 ms, 1536 MB |

The intersection count allows a simple linear scan for each Dijkstra step.

Sample input:

```
7 6
1 2 4
1 3 1
3 5 2
2 4 2
2 5 6
5 4 2
5 6 10
0 0
5 5
1 20
2 5
10 2
0 0
```

Sample output:

```
19
```

The quickest route is not the one with the fewest streets.

## Idea

Think of each light as a toll booth with a repeating schedule, like a gate that opens on a fixed beat. If you arrive during the green beat you pass at once; otherwise you wait for the next opening. Dijkstra's algorithm still works because leaving earlier can never make you arrive later: you may always wait. The waiting rule turns each street into a time-dependent cost, evaluated only when the tail intersection is settled. Dijkstra with a linear scan costs O(K^2 + N) per case. Trying every possible waiting time would take far longer. The ability to wait is what keeps the shortest-path method valid.

## Why It Works

1. A light with green g and red r repeats every g + r minutes.
2. Arrival at phase p passes immediately when p is less than g, and waits g + r - p otherwise.
3. Arriving exactly when green turns red means p equals g, so the driver waits.
4. Intersections 1 and K have cycle length zero and never cause a wait.
5. For a fixed tail node, a later arrival can be imitated by waiting, so the earliest arrival dominates all later ones.
6. Therefore a settled node never needs another relaxation, which is the Dijkstra invariant.

| term | meaning |
|---|---|
| bestTimes | earliest known arrival at each intersection |
| departureTime | arrival plus any wait at that intersection |
| cycle | green time plus red time |
| settled | marks intersections whose earliest arrival is final |

The table names the values used in each relaxation step.

The generator traces the quickest sample route as follows:

```
1 -> 2: arrive 4, green, leave 4
2 -> 4: arrive 6, red, leave 7
4 -> 5: arrive 9, green, leave 9
5 -> 6: arrive 19
```

The last arrival is 19 minutes, matching the sample output.

All times stay below ten million, so plain integers hold them.

## Code

**Input and waiting rule.** Streets are stored both ways, and the wait uses the arrival phase.

```nim
const flushBlockBytes = 1 shl 17
const impossibleTime = 1000000000

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

proc departureTime(arrival: int, intersection: int, greenTimes: seq[int], redTimes: seq[int]): int =
  let cycle = greenTimes[intersection] + redTimes[intersection]
  if cycle == 0:
    return arrival
  let phase = arrival mod cycle
  if phase < greenTimes[intersection]:
    return arrival
  return arrival + (cycle - phase)
```

Every street is added in both directions.
A zero cycle means the intersection has no light.
The phase comparison uses a strict less-than test.

**Settled-node scan.** The smallest tentative time is picked with a linear pass.

```nim
let streetCount = nextInt(inputData, scanPos)
let intersectionCount = nextInt(inputData, scanPos)
var streets = newSeq[seq[tuple[target: int, travel: int]]](intersectionCount + 1)
for streetIndex in 0 .. streetCount - 1:
  let startPoint = nextInt(inputData, scanPos)
  let endPoint = nextInt(inputData, scanPos)
  let travelTime = nextInt(inputData, scanPos)
  streets[startPoint].add((endPoint, travelTime))
  streets[endPoint].add((startPoint, travelTime))
var greenTimes = newSeq[int](intersectionCount + 1)
var redTimes = newSeq[int](intersectionCount + 1)
for intersection in 1 .. intersectionCount:
  greenTimes[intersection] = nextInt(inputData, scanPos)
  redTimes[intersection] = nextInt(inputData, scanPos)
var bestTimes = newSeq[int](intersectionCount + 1)
var settled = newSeq[bool](intersectionCount + 1)
for intersection in 1 .. intersectionCount:
  bestTimes[intersection] = impossibleTime
  settled[intersection] = false
bestTimes[1] = 0
```

The start time is zero.
All other times begin at a large sentinel.
Light data is stored by intersection index.

**Relaxation.** Each settled node applies its wait rule once, then updates neighbours.

```nim
for step in 0 .. intersectionCount - 1:
  var current = 0
  for intersection in 1 .. intersectionCount:
    if not settled[intersection] and (current == 0 or bestTimes[intersection] < bestTimes[current]):
      current = intersection
  if current == 0 or bestTimes[current] >= impossibleTime:
    break
  settled[current] = true
  let leaveAt = departureTime(bestTimes[current], current, greenTimes, redTimes)
  for edge in streets[current]:
    let arriveAt = leaveAt + edge.travel
    if arriveAt < bestTimes[edge.target]:
      bestTimes[edge.target] = arriveAt
appendOutput($bestTimes[intersectionCount])
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The scan visits at most K intersections.
Each adjacency list is walked once when its node settles.
The destination time is written after the loop.

## Complexity

The linear minimum scan and the street relaxations set the cost.

| phase | time | space |
|---|---|---|
| input read | one pass over streets and lights | one input string |
| minimum scans | O(K^2) comparisons | settled flags |
| relaxations | O(N) edge visits | adjacency lists |
| output | one line | block buffer |

K is at most 1000, so the quadratic scan stays small.

| measure | Big O |
|---|---|
| time | O(K^2 + N) |
| space | O(N + K) |

A search over every possible departure moment would explore far more states than one relaxation per street.

The fixed cycle rule keeps each relaxation constant time.
