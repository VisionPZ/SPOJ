<https://www.spoj.com/problems/PETYABRO/>

## Problem

Some citizens are milkmen. Repair a minimum-cost set of roads so every citizen reaches a milkman, and the milkman reached is one of that citizen's nearest milkmen by shortest road distance. Print the minimum cost, or impossible when some citizen has no reachable milkman.

| item | bound |
|---|---|
| citizens N | 1 to 100000 |
| roads M | up to 200000 |
| road cost c | 1 to 1000000000 |
| judge limit | 2000 ms, 1536 MB |

Milkmen supply themselves, so they need no road of their own.

Sample input:

```
5 7
0 1 0 1 0
1 2 11
1 3 1
1 5 17
2 3 1
3 5 18
4 5 3
2 4 5
```

Sample output:

```
5
```

## Idea

Split the city into one region per milkman, where each citizen belongs to the region of their nearest milkman. Think of postal districts: every house must reach its own district office, and connecting two offices never helps. Multi-source Dijkstra assigns districts, then Kruskal joins only citizens in the same district and charges the cheapest roads that do so.

## Why It Works

1. Multi-source Dijkstra labels each citizen with one nearest milkman and its distance.
2. Any valid repaired network can be split into parts that each contain one such milkman.
3. Splitting removes roads, so an optimum never needs to join two different milkmen.
4. Kruskal processes roads by increasing cost and joins two components with the same milkman label.
5. A component is finished once it contains its own milkman; every citizen then reaches a nearest milkman.

| term | meaning |
|---|---|
| `nearestMilkman` | assigned milkman for each citizen |
| `componentMilkman` | shared milkman label of a DSU component |
| `componentHasMilkman` | whether that component contains the label citizen |
| `totalCost` | sum of repaired road costs |

Unreachable citizens keep a negative label and force the impossible answer.

## Code

**Input and graph storage.** The reader loads flags and both directions of every road.

```nim
import algorithm

const flushBlockBytes = 1 shl 17
const infiniteDistance = 2305843009213693951

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

type Road = object
  firstCity: int
  secondCity: int
  repairCost: int

let cityCount = nextInt(inputData, scanPos)
let roadCount = nextInt(inputData, scanPos)

var isMilkman = newSeq[int](cityCount)
for cityIndex in 0 .. cityCount - 1:
  isMilkman[cityIndex] = nextInt(inputData, scanPos)

var roads = newSeq[Road](roadCount)
var firstNeighbour = newSeq[int](cityCount)
for cityIndex in 0 .. cityCount - 1:
  firstNeighbour[cityIndex] = -1
var neighbourCity = newSeq[int](2 * roadCount)
var neighbourCost = newSeq[int](2 * roadCount)
var nextNeighbour = newSeq[int](2 * roadCount)

for roadIndex in 0 .. roadCount - 1:
  let firstCity = nextInt(inputData, scanPos) - 1
  let secondCity = nextInt(inputData, scanPos) - 1
  let repairCost = nextInt(inputData, scanPos)
  roads[roadIndex] = Road(firstCity: firstCity, secondCity: secondCity, repairCost: repairCost)

  neighbourCity[2 * roadIndex] = secondCity
  neighbourCost[2 * roadIndex] = repairCost
  nextNeighbour[2 * roadIndex] = firstNeighbour[firstCity]
  firstNeighbour[firstCity] = 2 * roadIndex

  neighbourCity[2 * roadIndex + 1] = firstCity
  neighbourCost[2 * roadIndex + 1] = repairCost
  nextNeighbour[2 * roadIndex + 1] = firstNeighbour[secondCity]
  firstNeighbour[secondCity] = 2 * roadIndex + 1
```

Adjacency uses one linked list per city.
Each road appears twice, once from each endpoint.
Costs stay in signed integers during input.

**Heap and shortest paths.** All milkmen enter the heap with distance zero.

```nim
var shortestDistance = newSeq[int64](cityCount)
var nearestMilkman = newSeq[int](cityCount)
for cityIndex in 0 .. cityCount - 1:
  shortestDistance[cityIndex] = infiniteDistance
  nearestMilkman[cityIndex] = -1

var heapCities = newSeq[int]()
var heapDistances = newSeq[int64]()

proc heapPush(cityIndex: int, distanceValue: int64) =
  heapCities.add cityIndex
  heapDistances.add distanceValue
  var childIndex = heapCities.len - 1
  while childIndex > 0:
    let parentIndex = (childIndex - 1) div 2
    if heapDistances[parentIndex] <= heapDistances[childIndex]:
      break
    swap heapDistances[parentIndex], heapDistances[childIndex]
    swap heapCities[parentIndex], heapCities[childIndex]
    childIndex = parentIndex

proc heapPop(): (int, int64) =
  let poppedCity = heapCities[0]
  let poppedDistance = heapDistances[0]
  let lastCity = heapCities[heapCities.len - 1]
  let lastDistance = heapDistances[heapDistances.len - 1]
  heapCities.setLen(heapCities.len - 1)
  heapDistances.setLen(heapDistances.len - 1)
  if heapCities.len > 0:
    heapCities[0] = lastCity
    heapDistances[0] = lastDistance
    var parentIndex = 0
    while true:
      let leftChild = 2 * parentIndex + 1
      if leftChild >= heapCities.len:
        break
      let rightChild = leftChild + 1
      var smallerChild = leftChild
      if rightChild < heapCities.len and heapDistances[rightChild] < heapDistances[leftChild]:
        smallerChild = rightChild
      if heapDistances[parentIndex] <= heapDistances[smallerChild]:
        break
      swap heapDistances[parentIndex], heapDistances[smallerChild]
      swap heapCities[parentIndex], heapCities[smallerChild]
      parentIndex = smallerChild
  return (poppedCity, poppedDistance)
```

A strict distance improvement also copies the milkman label.
Stale heap entries are ignored by comparing their distance.
Distances use int64 so long paths cannot wrap.

**Dijkstra and union-find setup.** The sweep labels every reachable citizen.

```nim
for cityIndex in 0 .. cityCount - 1:
  if isMilkman[cityIndex] == 1:
    shortestDistance[cityIndex] = 0
    nearestMilkman[cityIndex] = cityIndex
    heapPush(cityIndex, 0)

while heapCities.len > 0:
  let (cityIndex, distanceValue) = heapPop()
  if distanceValue != shortestDistance[cityIndex]:
    continue
  var edgeIndex = firstNeighbour[cityIndex]
  while edgeIndex != -1:
    let neighbour = neighbourCity[edgeIndex]
    let candidate = distanceValue + int64(neighbourCost[edgeIndex])
    if candidate < shortestDistance[neighbour]:
      shortestDistance[neighbour] = candidate
      nearestMilkman[neighbour] = nearestMilkman[cityIndex]
      heapPush(neighbour, candidate)
    edgeIndex = nextNeighbour[edgeIndex]

roads.sort(proc(leftRoad, rightRoad: Road): int = cmp(leftRoad.repairCost, rightRoad.repairCost))

var parentCity = newSeq[int](cityCount)
var componentSize = newSeq[int](cityCount)
var componentMilkman = newSeq[int](cityCount)
var componentHasMilkman = newSeq[bool](cityCount)
for cityIndex in 0 .. cityCount - 1:
  parentCity[cityIndex] = cityIndex
  componentSize[cityIndex] = 1
  componentMilkman[cityIndex] = nearestMilkman[cityIndex]
  componentHasMilkman[cityIndex] = nearestMilkman[cityIndex] == cityIndex

proc findRoot(cityIndex: int): int =
  var current = cityIndex
  while parentCity[current] != current:
    parentCity[current] = parentCity[parentCity[current]]
    current = parentCity[current]
  return current
```

Sorting puts the cheapest roads first.
Union by size keeps find chains short.
A milkman starts as a complete component.

**Kruskal and final check.** Only same-label components are joined.

```nim
var totalCost: int64 = 0
for roadIndex in 0 .. roadCount - 1:
  let firstRoot = findRoot(roads[roadIndex].firstCity)
  let secondRoot = findRoot(roads[roadIndex].secondCity)
  if firstRoot == secondRoot:
    continue
  if componentMilkman[firstRoot] < 0 or componentMilkman[secondRoot] < 0:
    continue
  if componentMilkman[firstRoot] != componentMilkman[secondRoot]:
    continue
  var largerRoot = firstRoot
  var smallerRoot = secondRoot
  if componentSize[largerRoot] < componentSize[smallerRoot]:
    swap largerRoot, smallerRoot
  parentCity[smallerRoot] = largerRoot
  componentSize[largerRoot] += componentSize[smallerRoot]
  componentHasMilkman[largerRoot] = componentHasMilkman[largerRoot] or componentHasMilkman[smallerRoot]
  totalCost += int64(roads[roadIndex].repairCost)

var impossible = false
for cityIndex in 0 .. cityCount - 1:
  if nearestMilkman[cityIndex] < 0:
    impossible = true
    break
  let rootIndex = findRoot(cityIndex)
  if not componentHasMilkman[rootIndex]:
    impossible = true
    break

if impossible:
  appendOutput("impossible\n")
else:
  appendOutput($totalCost)
  appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

Each accepted road lowers the total number of components.
A final scan detects any component lacking its milkman.
The answer is written once through the shared buffer.

## Complexity

The graph stores two directed records per road.

| phase | time | space |
|---|---|---|
| input read | one pass over roads | adjacency arrays |
| Dijkstra | one heap pass over roads | distance and label arrays |
| road sort | one sort of M roads | one road array |
| Kruskal | one pass with union-find | parent and size arrays |
| output | one line | block buffer |

| measure | Big O |
|---|---|
| time | O(M log M + M log N) |
| space | O(N + M) |

Trying every subset of roads would take exponential time.
