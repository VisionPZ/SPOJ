# CAPRICA — Caprica Cities (SPOJ)

<https://www.spoj.com/problems/CAPRICA/>

## Problem

A connected road network has N cities and two disjoint groups of cities. Return the shortest road distance from any city in the first group to any city in the second group.

Input holds several test cases. Each case starts with N, M, A, B, where A is the first group size and B is the second group size. The next two lines list those groups. Each of the next M lines gives u, v, d for one road. A line of four zeros ends input. Output one integer per case.

| item | bound |
|---|---|
| cities N | 2 to 1000 |
| roads M | 1 to 10000 |
| group sizes A, B | 2 to 1000 each, with A + B ≤ N |
| road length d | 1 to 10000 |
| judge limit | 202 ms, 1536 MB |

Road lengths are positive, and a city pair can have several roads.

Sample input:

```
4 4 2 2
0 1
2 3
0 1 10
0 2 20
1 3 10
2 3 100
0 0 0 0
```

Sample output:

```
10
```

## Idea

Treat both groups as one starting point, like pouring water from every tap at once. Multi-source Dijkstra spreads outward from all first-group cities together. The first second-group city reached gives the shortest distance.

Dijkstra costs O((N + M) log M) per case with a binary heap. A single-source run from each city in the first group would repeat the same work A times. Duplicate roads stay harmless because each relaxation keeps the smaller value.

One shared frontier replaces A separate searches.

## Why It Works

1. Every road has a positive length, so Dijkstra settles cities in nondecreasing distance order.
2. Seeding the heap with all first-group cities at distance zero gives the true multi-source frontier.
3. A settled city holds the shortest distance from the whole first group.
4. Relaxing both directions of each road preserves that invariant for connected networks.
5. The minimum distance over the second group is therefore the required answer.

| term | meaning |
|---|---|
| `distances` | best known distance from either group to a city |
| `distHeap` | heap of candidate distances |
| `nodeHeap` | heap city matching each candidate distance |
| `bestLength` | smallest settled distance among second-group cities |

The heap arrays stay aligned because pushes and pops move both entries together.

For the sample, the heap starts with cities 0 and 1 at distance 0. City 1 relaxes city 3 to 10. City 0 relaxes city 2 to 20. City 3 relaxes city 2 to 110, which loses to 20. The answer is min(20, 10) = 10.

The trace reaches a second-group city before any longer route can win.

## Code

**Input and scanner.** All input is read once, and integers are parsed by hand.

```nim
const flushBlockBytes = 1 shl 17
const infinityDistance = int64(1 shl 60)

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

The scanner skips every non-digit, so line breaks and spaces behave alike.

The sentinel is detected after reading four header values.

**Output buffer and heap.** Text is written in blocks, and the heap keeps candidate distances ordered.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc pushHeap(distHeap: var seq[int64], nodeHeap: var seq[int], distance: int64, node: int) =
  distHeap.add distance
  nodeHeap.add node
  var childIndex = distHeap.len - 1
  while childIndex > 0:
    let parentIndex = (childIndex - 1) div 2
    if distHeap[parentIndex] <= distHeap[childIndex]:
      break
    swap distHeap[parentIndex], distHeap[childIndex]
    swap nodeHeap[parentIndex], nodeHeap[childIndex]
    childIndex = parentIndex

proc popHeap(distHeap: var seq[int64], nodeHeap: var seq[int]): tuple[distance: int64, node: int] =
  let topDistance = distHeap[0]
  let topNode = nodeHeap[0]
  let lastDistance = distHeap[distHeap.len - 1]
  let lastNode = nodeHeap[nodeHeap.len - 1]
  distHeap.setLen(distHeap.len - 1)
  nodeHeap.setLen(nodeHeap.len - 1)
  if distHeap.len > 0:
    distHeap[0] = lastDistance
    nodeHeap[0] = lastNode
    var parentIndex = 0
    while true:
      let leftChild = parentIndex * 2 + 1
      if leftChild >= distHeap.len:
        break
      let rightChild = leftChild + 1
      var smallerChild = leftChild
      if rightChild < distHeap.len and distHeap[rightChild] < distHeap[leftChild]:
        smallerChild = rightChild
      if distHeap[parentIndex] <= distHeap[smallerChild]:
        break
      swap distHeap[parentIndex], distHeap[smallerChild]
      swap nodeHeap[parentIndex], nodeHeap[smallerChild]
      parentIndex = smallerChild
  return (topDistance, topNode)
```

Push and pop always move a distance with its city.

Stale heap entries are filtered later by comparing with `distances`.

**Search and answer.** Roads are stored once per direction, then relaxed from the shared frontier.

```nim
while true:
  let cityCount = nextInt(inputData, scanPos)
  let roadCount = nextInt(inputData, scanPos)
  let groupXCount = nextInt(inputData, scanPos)
  let groupYCount = nextInt(inputData, scanPos)
  if cityCount == 0 and roadCount == 0:
    break
  var groupX = newSeq[int](groupXCount)
  for cityIndex in 0 .. groupXCount - 1:
    groupX[cityIndex] = nextInt(inputData, scanPos)
  var groupY = newSeq[int](groupYCount)
  for cityIndex in 0 .. groupYCount - 1:
    groupY[cityIndex] = nextInt(inputData, scanPos)
  var adjacencyHead = newSeq[int](cityCount)
  for cityIndex in 0 .. cityCount - 1:
    adjacencyHead[cityIndex] = -1
  var edgeTarget = newSeq[int](roadCount * 2)
  var edgeWeight = newSeq[int](roadCount * 2)
  var edgeNext = newSeq[int](roadCount * 2)
  var edgeCount = 0
  for roadIndex in 0 .. roadCount - 1:
    let fromCity = nextInt(inputData, scanPos)
    let toCity = nextInt(inputData, scanPos)
    let roadLength = nextInt(inputData, scanPos)
    edgeTarget[edgeCount] = toCity
    edgeWeight[edgeCount] = roadLength
    edgeNext[edgeCount] = adjacencyHead[fromCity]
    adjacencyHead[fromCity] = edgeCount
    edgeCount += 1
    edgeTarget[edgeCount] = fromCity
    edgeWeight[edgeCount] = roadLength
    edgeNext[edgeCount] = adjacencyHead[toCity]
    adjacencyHead[toCity] = edgeCount
    edgeCount += 1
  var distances = newSeq[int64](cityCount)
  for cityIndex in 0 .. cityCount - 1:
    distances[cityIndex] = infinityDistance
  var distHeap = newSeq[int64](0)
  var nodeHeap = newSeq[int](0)
  for sourceCity in groupX:
    distances[sourceCity] = 0
    pushHeap(distHeap, nodeHeap, 0, sourceCity)
  while distHeap.len > 0:
    let poppedItem = popHeap(distHeap, nodeHeap)
    if poppedItem.distance != distances[poppedItem.node]:
      continue
    var edgeIndex = adjacencyHead[poppedItem.node]
    while edgeIndex != -1:
      let candidateDistance = poppedItem.distance + int64(edgeWeight[edgeIndex])
      if candidateDistance < distances[edgeTarget[edgeIndex]]:
        distances[edgeTarget[edgeIndex]] = candidateDistance
        pushHeap(distHeap, nodeHeap, candidateDistance, edgeTarget[edgeIndex])
      edgeIndex = edgeNext[edgeIndex]
  var bestLength = infinityDistance
  for targetCity in groupY:
    if distances[targetCity] < bestLength:
      bestLength = distances[targetCity]
  appendOutput($bestLength)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Each road becomes two directed entries, which also handles duplicate roads.

A popped distance that differs from `distances` is skipped before relaxation.

## Complexity

Each case reads the input, builds the graph, then runs one heap-driven search.

| phase | time | space |
|---|---|---|
| input read | one pass over all integers | one input string |
| graph build | O(M) edge inserts | O(N + M) adjacency arrays |
| search | O((N + M) log M) heap work | O(N + M) arrays |
| output | one buffered write per block | block buffer |

The heap keeps the search proportional to the road count, not to the group size.

| measure | Big O |
|---|---|
| time per case | O((N + M) log M) |
| space per case | O(N + M) |

Running Dijkstra once per first-group city would multiply the search cost by A.

A single multi-source search finishes the whole case within the 202 ms limit.
