# INGRED — Ingredients (SPOJ)
<https://www.spoj.com/problems/INGRED/>

## Problem

Two friends start in different cities of a weighted undirected graph. There are stores in s cities, and each store holds one ingredient. Both friends together must collect every ingredient, and neither needs to return home. Find the smallest total distance they travel.

Input starts with city count n and road count m. The next m lines give the two cities of a road and its length. Then come s, the s store cities, and the two home cities. Output one integer, the minimum total distance.

| item | bound |
|---|---|
| cities n | 2 to 1000 |
| roads m | 1 to n times (n-1) / 2 |
| road length | 0 to 1000 |
| stores s | 1 to 8 |
| judge limit | 1000 ms, 1536 MB |

Only distances between stores and homes matter, so a full all-pairs table wastes work.

Sample input:

```
5 6
0 1 5
1 4 1
0 4 10
0 2 2
1 2 3
2 3 4
2
2 4
0 1
```

The sample has two stores at cities 2 and 4, with homes at 0 and 1.

Sample output:

```
3
```

One friend goes from home 0 to store 2, and the other goes from home 1 to store 4.

## Idea

Think of the two friends as two hands passing ingredients around a table of at most ten relevant seats. Compute shortest walks from each relevant city, then try every collected subset and both hand positions. Adding the next ingredient lets either hand move, so the state keeps both current cities. Trying every assignment of stores to friends would enumerate all orderings; the subset table reuses partial walks. The result is one minimum total for all stores collected.

## Why It Works

1. Dijkstra from each store and each home gives the shortest walk between any two relevant cities.
2. A state is a collected subset plus the current city of each friend.
3. There are at most s+2 relevant cities, so a state table stays small.
4. The initial state has no stores collected and both friends at their homes.
5. Adding an uncollected store costs the moving friend's shortest walk to that store.
6. Updating only that friend's city keeps every earlier plan available.
7. The answer is the smallest cost among states with all stores collected.

| term | meaning |
|---|---|
| `roadGrid` | shortest direct road between each pair of cities |
| `sourceDistances` | shortest walks from each relevant city |
| `bestCosts` | minimum total cost for a subset and two current cities |
| `positionCities` | city behind each relevant position index |
| `fullSubset` | bit mask with every store collected |

The state table holds at most 256 times 100 entries.

The generator script produced this example from the sample. The two stores are at cities 2 and 4.

| collected set | cheapest total | reason |
|---|---|---|
| none | 0 | both friends still at home |
| store 2 | 2 | home 0 walks two units to city 2 |
| store 4 | 1 | home 1 walks one unit to city 4 |
| both stores | 3 | each friend takes one store |

The two single-store walks do not share a friend, so their costs add to three.

Every stored cost stays below 268 million, so plain integers hold all sums.

## Code

**Input and graph.** Read stdin once and keep the cheapest direct road for each pair.

```nim
const flushBlockBytes = 1 shl 17
const infiniteDistance = 1 shl 28

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

let cityCount = nextInt(inputData, scanPos)
let roadCount = nextInt(inputData, scanPos)
var roadGrid = newSeq[seq[int]](cityCount)
for cityIndex in 0 .. cityCount - 1:
  roadGrid[cityIndex] = newSeq[int](cityCount)
  for neighborIndex in 0 .. cityCount - 1:
    roadGrid[cityIndex][neighborIndex] = infiniteDistance
  roadGrid[cityIndex][cityIndex] = 0
for roadIndex in 0 .. roadCount - 1:
  let firstCity = nextInt(inputData, scanPos)
  let secondCity = nextInt(inputData, scanPos)
  let roadLength = nextInt(inputData, scanPos)
  if roadLength < roadGrid[firstCity][secondCity]:
    roadGrid[firstCity][secondCity] = roadLength
    roadGrid[secondCity][firstCity] = roadLength
```

`roadGrid` keeps the shortest direct road for each city pair.
`nextInt` skips line breaks and spaces between road fields.
The output buffer collects the single answer line.

**Relevant cities and shortest walks.** Map stores and homes to positions, then run Dijkstra per position.

```nim
let storeCount = nextInt(inputData, scanPos)
var storeCities = newSeq[int](storeCount)
for storeIndex in 0 .. storeCount - 1:
  storeCities[storeIndex] = nextInt(inputData, scanPos)
let firstHome = nextInt(inputData, scanPos)
let secondHome = nextInt(inputData, scanPos)
let positionCount = storeCount + 2
var positionCities = newSeq[int](positionCount)
for storeIndex in 0 .. storeCount - 1:
  positionCities[storeIndex] = storeCities[storeIndex]
positionCities[storeCount] = firstHome
positionCities[storeCount + 1] = secondHome

var sourceDistances = newSeq[seq[int]](positionCount)
for sourceIndex in 0 .. positionCount - 1:
  var distances = newSeq[int](cityCount)
  var settled = newSeq[bool](cityCount)
  for cityIndex in 0 .. cityCount - 1:
    distances[cityIndex] = infiniteDistance
    settled[cityIndex] = false
  distances[positionCities[sourceIndex]] = 0
  for searchStep in 0 .. cityCount - 1:
    var nearestCity = -1
    var nearestDistance = infiniteDistance
    for cityIndex in 0 .. cityCount - 1:
      if not settled[cityIndex] and distances[cityIndex] < nearestDistance:
        nearestDistance = distances[cityIndex]
        nearestCity = cityIndex
    if nearestCity < 0:
      break
    settled[nearestCity] = true
    for neighborIndex in 0 .. cityCount - 1:
      let edgeLength = roadGrid[nearestCity][neighborIndex]
      if edgeLength < infiniteDistance and nearestDistance + edgeLength < distances[neighborIndex]:
        distances[neighborIndex] = nearestDistance + edgeLength
  sourceDistances[sourceIndex] = distances
```

`positionCities` gives the city behind each state position.
`settled` marks the cities already fixed by Dijkstra.
Only s+2 sources run, not all n cities.

**Subset DP.** Grow the collected set one store at a time and report the minimum.

```nim
let subsetCount = 1 shl storeCount
var bestCosts = newSeq[int](subsetCount * positionCount * positionCount)
for costIndex in 0 .. bestCosts.len - 1:
  bestCosts[costIndex] = infiniteDistance
bestCosts[(0 * positionCount + storeCount) * positionCount + storeCount + 1] = 0
for subset in 0 .. subsetCount - 1:
  for firstPosition in 0 .. positionCount - 1:
    for secondPosition in 0 .. positionCount - 1:
      let currentCost = bestCosts[(subset * positionCount + firstPosition) * positionCount + secondPosition]
      if currentCost >= infiniteDistance:
        continue
      for storeIndex in 0 .. storeCount - 1:
        if (subset and (1 shl storeIndex)) != 0:
          continue
        let nextSubset = subset or (1 shl storeIndex)
        let storeCity = storeCities[storeIndex]
        let firstMove = sourceDistances[firstPosition][storeCity]
        if firstMove < infiniteDistance:
          let nextCost = currentCost + firstMove
          let nextIndex = (nextSubset * positionCount + storeIndex) * positionCount + secondPosition
          if nextCost < bestCosts[nextIndex]:
            bestCosts[nextIndex] = nextCost
        let secondMove = sourceDistances[secondPosition][storeCity]
        if secondMove < infiniteDistance:
          let nextCost = currentCost + secondMove
          let nextIndex = (nextSubset * positionCount + firstPosition) * positionCount + storeIndex
          if nextCost < bestCosts[nextIndex]:
            bestCosts[nextIndex] = nextCost

let fullSubset = subsetCount - 1
var minimumDistance = infiniteDistance
for firstPosition in 0 .. positionCount - 1:
  for secondPosition in 0 .. positionCount - 1:
    let candidateDistance = bestCosts[(fullSubset * positionCount + firstPosition) * positionCount + secondPosition]
    if candidateDistance < minimumDistance:
      minimumDistance = candidateDistance
appendOutput($minimumDistance)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

`bestCosts` packs the subset and two positions into one index.
Each transition moves one friend to the newly collected store.
The final write sends the minimum total as one line.

## Complexity

Shortest walks use at most s+2 sources over the city graph.

| phase | time | space |
|---|---|---|
| input read | one pass over all roads | road grid |
| shortest walks | one Dijkstra per relevant city | s+2 distance rows |
| subset DP | subsets times positions squared times stores | one packed cost table |

The DP table is small because s never exceeds eight.

| measure | Big O |
|---|---|
| shortest walks | O((s+2) n^2) |
| subset DP | O(2^s (s+2)^2 s) |
| space | O(n^2 + 2^s (s+2)^2) |

All phases stay fast for the stated bounds.

Trying every assignment and every visiting order would take factorial time in s.

The subset table keeps both friends' positions without enumerating orders.
