## Problem

The courier starts at home city b, carries one parcel at a time, and must deliver every request before returning home. Read a road graph with lengths, then print the shortest total route length.

| Quantity | Bound |
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

## Idea

Floyd-Warshall fills a distance table for every pair of cities before the search starts. The search keeps a bitmask of finished parcels and the last finished parcel. It adds one parcel per step and tries every unfinished parcel.

Cost per step: O(k) transitions over 2^k masks. Walking the raw roads inside the search repeats the same travel many times, so one table lookup replaces each leg.

## Why It Works

The courier carries one parcel at a time, so pickup comes before drop and no other parcel fits between them. A shortest path already covers every detour between two cities. A parcel is one atomic unit: travel to its source, then carry it to its target.

- `distTable[i][j]` holds the shortest road length from city i to city j.
- `throughCost + beyondCost` is the route length through city k.
- `bestCost[mask * parcelCount + i]` is the cheapest finished cost at parcel i's target.
- `currentCost + approachCost + carryCostOf[j]` adds parcel j to the current route.

The sample gives these shortest legs, and the generator checks the total against 43.

| Step | Length |
| --- | --- |
| home 2 to 5 | 1 |
| 5 to 1, carry parcel C | 2 |
| 1 to 1, start parcel A | 0 |
| 1 to 4, carry parcel A | 8 |
| 4 to 1, start parcel A again | 8 |
| 1 to 4, carry parcel A | 8 |
| 4 to 5, start parcel B | 7 |
| 5 to 3, carry parcel B | 4 |
| 3 to home 2 | 5 |

The nine legs sum to 43, the sample answer verified by the generator.

## Code

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

The read loop runs until stdin ends and holds one input buffer. The scanner skips non-digits, so newlines need no special case. The writer flushes at 256 KiB and costs O(1) per line.

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

The table reset runs over all 101 city indexes. Duplicate roads keep the smaller length. The three loops run cityCount plus one times and cost O(n^3) per case.

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

Each request expands into parcelTotal identical parcels, so the total never exceeds 12. The zero-parcel case returns home with cost 0. Carry costs are computed once and reused in the inner loop.

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

Index i walks finished parcels and index j walks unfinished parcels. The bit test keeps each parcel in exactly one position of the route. The final loop adds the trip home and the last write empties the buffer.

## Complexity

Floyd-Warshall uses O(n^3) time and O(n^2) space. The bitmask search uses O(2^k k^2) time and O(2^k k) space. Input scanning and output writing use O(t) lines.

Total per case: O(n^3 + 2^k k^2) time and O(n^2 + 2^k k) space. Trying every order of the raw road steps is factorial in k.
