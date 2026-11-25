# COURIER — The Courier (SPOJ)

<https://www.spoj.com/problems/COURIER/>

## Problem

A courier collects and delivers parcels one at a time before returning home. The road network offers many routes, so the courier needs the shortest total tour.

Input: one integer for the case count, then n, m, and home city b. Then come m roads as `u v length` and z requests as `a b k`. Each request adds k identical parcels from a to b.

Output: the shortest total route length for each case.

The statement and judge give these bounds:

| Item | Bound |
| --- | --- |
| Test cases | not bounded by the statement |
| Cities n | 1 to 100 |
| Roads m | 1 to 10000 |
| Requests z | 1 to 5 |
| Total parcels k | at most 12 |
| Road length | 1 to 10000 |
| Time limit | 7000 ms |
| Memory limit | 1536 MB |

The parcel count k, not the city count n, drives the search.

The sample input and output:

```
1
5 7 2
1 2 7
1 3 5
1 5 2
2 4 10
2 5 1
3 4 3
3 5 4
3
1 4 2
5 3 1
5 1 1
```

```
43
```

## Idea

Fill a timetable of shortest legs before planning the route, like checking train times before booking a tour. Each parcel then becomes one atomic step: travel to its source, carry it to its target.

The program runs Floyd-Warshall to fill an all-pairs distance table. A bitmask dynamic program (a table of best costs per state) tracks the finished parcels and the last delivery city.

The table costs O(n³) time and O(n²) space. Each search state tries k next parcels, so the search costs O(2^k k²) time. Walking raw roads inside the search would repeat the same travel many times.

One table lookup replaces each leg.

## Why It Works

The courier carries one parcel at a time, so pickup always comes before drop.

1. A shortest path already covers every detour between two cities, so the search needs only pairwise legs.
2. A bitmask records which parcels are finished, and the last finished parcel gives the current city.
3. Adding a parcel costs the approach leg plus that parcel's carry leg.
4. The final answer adds the trip from the last target back home and takes the smallest candidate.

The tables use the following terms:

| Term | Meaning |
| --- | --- |
| `distTable[i][j]` | shortest road length from city i to city j |
| `carryCostOf[i]` | `distTable[source][target]` for parcel i |
| `bestCost[mask × k + i]` | cheapest cost after mask, ending at parcel i's target |
| `approachCost` | leg from the previous target to the next source |
| `infinite` | `2^60`, used for unreachable states |

A script scores the sample tour, which delivers parcels C, A, A, B:

| Step | Leg | Length |
| --- | --- | --- |
| 1 | home 2 to 5 | 1 |
| 2 | carry C, 5 to 1 | 2 |
| 3 | start A, 1 to 1 | 0 |
| 4 | carry A, 1 to 4 | 8 |
| 5 | start A, 4 to 1 | 8 |
| 6 | carry A, 1 to 4 | 8 |
| 7 | start B, 4 to 5 | 7 |
| 8 | carry B, 5 to 3 | 4 |
| 9 | return, 3 to home 2 | 5 |

The nine legs sum to 43, the sample answer.

## Code

**Input helpers.** One buffer holds the stream, and the output flushes in blocks.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const maxCity = 100
const maxParcel = 12
const infinite = int64(1) shl 60

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int(data[position]) - firstDigitValue
    position += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The read loop visits stdin once. The scanner skips non-digits, so newlines need no special case. The writer flushes at 256 KiB.

**Distance table.** Duplicate roads keep the smaller length, and three nested loops fill all pairs.

```nim
var distTable: array[0..maxCity, array[0..maxCity, int64]]
var parcelSource: array[0..maxParcel - 1, int]
var parcelTarget: array[0..maxParcel - 1, int]
var carryCostOf: array[0..maxParcel - 1, int64]
var bestCost = newSeq[int64]((1 shl maxParcel) * maxParcel)

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let cityCount = nextInt(inputData, scanPos)
  let roadCount = nextInt(inputData, scanPos)
  let homeCity = nextInt(inputData, scanPos)
  for i in 0..maxCity:
    for j in 0..maxCity:
      distTable[i][j] = if i == j: int64(0) else: infinite
  for i in 0..<roadCount:
    let fromCity = nextInt(inputData, scanPos)
    let toCity = nextInt(inputData, scanPos)
    let roadLength = int64(nextInt(inputData, scanPos))
    if roadLength < distTable[fromCity][toCity]:
      distTable[fromCity][toCity] = roadLength
      distTable[toCity][fromCity] = roadLength
  for k in 0..cityCount:
    for i in 1..cityCount:
      let throughCost = distTable[i][k]
      if throughCost >= infinite: continue
      for j in 1..cityCount:
        let beyondCost = distTable[k][j]
        if beyondCost >= infinite: continue
        let candidate = throughCost + beyondCost
        if candidate < distTable[i][j]:
          distTable[i][j] = candidate
```

The reset covers all 101 indexes, so stale values never leak. The table stores roads in both directions. The three loops cost O(n³) per case.

**Parcels and start states.** Each request expands into its parcel count, and the first parcel sets each start cost.

```nim
  let requestCount = nextInt(inputData, scanPos)
  var parcelCount = 0
  for i in 0..<requestCount:
    let fromCity = nextInt(inputData, scanPos)
    let toCity = nextInt(inputData, scanPos)
    let parcelTotal = nextInt(inputData, scanPos)
    for j in 0..<parcelTotal:
      parcelSource[parcelCount] = fromCity
      parcelTarget[parcelCount] = toCity
      parcelCount += 1
  if parcelCount == 0:
    appendOutput("0")
    outputBuffer.add '\n'
    continue
  for i in 0..<parcelCount:
    carryCostOf[i] = distTable[parcelSource[i]][parcelTarget[i]]
  let stateCount = 1 shl parcelCount
  for stateIndex in 0..<(stateCount * parcelCount):
    bestCost[stateIndex] = infinite
  for i in 0..<parcelCount:
    let entryCost = distTable[homeCity][parcelSource[i]]
    if entryCost >= infinite or carryCostOf[i] >= infinite: continue
    bestCost[(1 shl i) * parcelCount + i] = entryCost + carryCostOf[i]
```

The parcel count never exceeds 12. A case with no parcels returns home with cost 0. Carry costs are computed once and reused inside the search.

**Bitmask search.** Each state adds one unfinished parcel, and the last loop adds the trip home.

```nim
  for mask in 1..<stateCount:
    for i in 0..<parcelCount:
      if (mask and (1 shl i)) == 0: continue
      let currentCost = bestCost[mask * parcelCount + i]
      if currentCost >= infinite: continue
      for j in 0..<parcelCount:
        if (mask and (1 shl j)) != 0: continue
        let approachCost = distTable[parcelTarget[i]][parcelSource[j]]
        if approachCost >= infinite or carryCostOf[j] >= infinite: continue
        let candidate = currentCost + approachCost + carryCostOf[j]
        let stateIndex = (mask or (1 shl j)) * parcelCount + j
        if candidate < bestCost[stateIndex]:
          bestCost[stateIndex] = candidate
  let fullMask = stateCount - 1
  var answer = infinite
  for i in 0..<parcelCount:
    let returnCost = distTable[parcelTarget[i]][homeCity]
    if returnCost >= infinite: continue
    let candidate = bestCost[fullMask * parcelCount + i] + returnCost
    if candidate < answer:
      answer = candidate
  appendOutput($answer)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Index i walks finished parcels and index j walks unfinished ones. The bit test keeps each parcel in exactly one route position. The final write empties the buffer.

## Complexity

Floyd-Warshall dominates the city work, and the bitmask search dominates the parcel work.

| Phase | Time | Space |
| --- | --- | --- |
| Input read | one pass over input bytes | input bytes |
| All-pairs table | O(n³) per case | O(n²) |
| Parcel setup | O(k²) per case | O(2^k k) |
| Bitmask search | O(2^k k²) per case | O(2^k k) |
| Output | one write per 256 KiB block | 256 KiB |
| Total per case | O(n³ + 2^k k²) | O(n² + 2^k k) |

At k = 12, the search holds about 49152 cost cells.

The asymptotic bounds are as follows:

| Measure | Big O |
| --- | --- |
| Time | O(n³ + 2^k k²) per case |
| Space | O(n² + 2^k k) per case |

Trying every order of the raw road steps would be factorial in k.
