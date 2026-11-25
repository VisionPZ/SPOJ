# SDF4E — Praktikum 4 SDF E (SPOJ)

<https://www.spoj.com/problems/SDF4E/>

## Problem

Geraldz drives from city 0 to city N-1 on one-way roads, and he wants to know whether a proposed new road would shorten that trip. Each query gives a start city, an end city, and the length of a hypothetical one-way road between them.

Input starts with N and M, followed by M lines of u, v, w. A query count Q follows, then Q lines of a, b, c. For each query print `Boleh juga: P km` when the new trip is shorter, where P is the new distance; otherwise print `Tidaakkk...`.

| item | bound |
|---|---|
| cities N | greater than 2, at most 20000 |
| roads M | greater than 2, at most 20000 |
| road lengths w and c | 1 to 1000000 |
| queries Q | 1 to 50000 |
| judge limit | 0.019 s to 1 s, 1536 MB |

The tight judge limit calls for one shortest-path run per direction, not one run per query.

Sample input:

```
4 3
2 3 5
0 1 1
1 2 2
2
0 2 1
0 2 4
```

Sample output:

```
Boleh juga: 6 km
Tidaakkk...
```

The first new road gives 0+1+5 = 6, below the current best of 8.

## Idea

A new road only helps as a bridge between two known halves of the trip, like adding one rung between a ladder's bottom and top halves. Precompute the cost from city 0 to every city and from every city to city N-1.

The algorithm runs Dijkstra twice, once forward and once on the reversed graph, using a binary heap. Each query then costs one sum and one comparison. Running Dijkstra for every query would multiply the cost by Q and miss the limit.

## Why It Works

1. Any trip using the new road has three parts: 0 to a, the new road a to b, and b to N-1.
2. The first part is the forward shortest distance to a.
3. The last part is a shortest distance to N-1 in the reversed graph.
4. The best trip with the new road is the smallest such three-part sum.
5. That sum beats the current best only when it is strictly smaller.

| term | meaning |
|---|---|
| `fromStart` | shortest distance from city 0 to each city |
| `toFinish` | shortest distance from each city to city N-1 |
| `bestDistance` | distance of the original shortest trip |
| `entry` | heap item holding a key and a node |

Stale heap entries are skipped by comparing the key with the stored distance.

The sample trace from the generator is:

```
fromStart: [0, 1, 3, 8]
toFinish: [8, 7, 5, 0]
bestDistance: 8
query 0 2 1 -> 0 + 1 + 5 = 6 -> Boleh juga: 6 km
query 0 2 4 -> 0 + 4 + 5 = 9 -> Tidaakkk...
```

The trace reproduces both sample output lines.

## Code

**Input and heap.** The reader loads stdin once, then defines the sift operations for the min heap.

```nim
const flushBlockBytes = 1 shl 17
const infinity: int64 = 1 shl 60

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

proc heapPush(nodeHeap: var seq[int], keyHeap: var seq[int64], heapSize: var int, node: int, key: int64) =
  var child = heapSize
  heapSize += 1
  while child > 0:
    let parent = (child - 1) div 2
    if keyHeap[parent] <= key:
      break
    nodeHeap[child] = nodeHeap[parent]
    keyHeap[child] = keyHeap[parent]
    child = parent
  nodeHeap[child] = node
  keyHeap[child] = key

proc heapPop(nodeHeap: var seq[int], keyHeap: var seq[int64], heapSize: var int): tuple[key: int64, node: int] =
  let smallestKey = keyHeap[0]
  let smallestNode = nodeHeap[0]
  heapSize -= 1
  if heapSize > 0:
    let lastNode = nodeHeap[heapSize]
    let lastKey = keyHeap[heapSize]
    var parent = 0
    while true:
      let leftChild = 2 * parent + 1
      if leftChild >= heapSize:
        break
      let rightChild = leftChild + 1
      var smallerChild = leftChild
      if rightChild < heapSize and keyHeap[rightChild] < keyHeap[leftChild]:
        smallerChild = rightChild
      if lastKey <= keyHeap[smallerChild]:
        break
      nodeHeap[parent] = nodeHeap[smallerChild]
      keyHeap[parent] = keyHeap[smallerChild]
      parent = smallerChild
    nodeHeap[parent] = lastNode
    keyHeap[parent] = lastKey
  return (smallestKey, smallestNode)
```

`heapPush` sifts a new entry upward.
`heapPop` moves the last entry down along smaller children.
Both keep the smallest key at the root.

**Dijkstra pass.** One call returns distances from a chosen source over one graph.

```nim
proc computeDistances(nodeCount: int, head: seq[int], target: seq[int], weight: seq[int64], nextEdge: seq[int], capacity: int, source: int): seq[int64] =
  var distances = newSeq[int64](nodeCount)
  for nodeIndex in 0 .. nodeCount - 1:
    distances[nodeIndex] = infinity
  var nodeHeap = newSeq[int](capacity + 1)
  var keyHeap = newSeq[int64](capacity + 1)
  var heapSize = 0
  distances[source] = 0
  heapPush(nodeHeap, keyHeap, heapSize, source, 0)
  while heapSize > 0:
    let entry = heapPop(nodeHeap, keyHeap, heapSize)
    if entry.key != distances[entry.node]:
      continue
    var edgeIndex = head[entry.node]
    while edgeIndex != -1:
      let neighbour = target[edgeIndex]
      let candidate = entry.key + weight[edgeIndex]
      if candidate < distances[neighbour]:
        distances[neighbour] = candidate
        heapPush(nodeHeap, keyHeap, heapSize, neighbour, candidate)
      edgeIndex = nextEdge[edgeIndex]
  return distances
```

Heap arrays use the edge capacity, which bounds pending entries.
Unreachable cities keep `infinity`, so no query adds a false candidate.
Each city is settled once, and stale entries are discarded.

**Graph build and queries.** The program stores both directions, runs two passes, then answers queries in order.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let cityCount = nextInt(inputData, scanPos)
let roadCount = nextInt(inputData, scanPos)
let edgeCapacity = 2 * roadCount
var forwardHead = newSeq[int](cityCount)
var reverseHead = newSeq[int](cityCount)
for cityIndex in 0 .. cityCount - 1:
  forwardHead[cityIndex] = -1
  reverseHead[cityIndex] = -1
var forwardTarget = newSeq[int](edgeCapacity)
var reverseTarget = newSeq[int](edgeCapacity)
var forwardWeight = newSeq[int64](edgeCapacity)
var reverseWeight = newSeq[int64](edgeCapacity)
var forwardNext = newSeq[int](edgeCapacity)
var reverseNext = newSeq[int](edgeCapacity)
var edgeIndex = 0
for roadIndex in 0 .. roadCount - 1:
  let fromCity = nextInt(inputData, scanPos)
  let toCity = nextInt(inputData, scanPos)
  let roadLength = int64(nextInt(inputData, scanPos))
  forwardTarget[edgeIndex] = toCity
  forwardWeight[edgeIndex] = roadLength
  forwardNext[edgeIndex] = forwardHead[fromCity]
  forwardHead[fromCity] = edgeIndex
  reverseTarget[edgeIndex] = fromCity
  reverseWeight[edgeIndex] = roadLength
  reverseNext[edgeIndex] = reverseHead[toCity]
  reverseHead[toCity] = edgeIndex
  edgeIndex += 1
let fromStart = computeDistances(cityCount, forwardHead, forwardTarget, forwardWeight, forwardNext, edgeCapacity, 0)
let toFinish = computeDistances(cityCount, reverseHead, reverseTarget, reverseWeight, reverseNext, edgeCapacity, cityCount - 1)
let bestDistance = fromStart[cityCount - 1]
let queryCount = nextInt(inputData, scanPos)
for queryIndex in 0 .. queryCount - 1:
  let roadFrom = nextInt(inputData, scanPos)
  let roadTo = nextInt(inputData, scanPos)
  let roadCost = int64(nextInt(inputData, scanPos))
  if fromStart[roadFrom] < infinity and toFinish[roadTo] < infinity:
    let newDistance = fromStart[roadFrom] + roadCost + toFinish[roadTo]
    if newDistance < bestDistance:
      appendOutput("Boleh juga: " & $newDistance & " km")
      outputBuffer.add '\n'
      continue
  appendOutput("Tidaakkk...")
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Each road is stored once forward and once reversed.
The two distance arrays make every query a constant-time check.
All answers go through one block-buffered output path.

## Complexity

The work splits into graph build, two shortest-path runs, and query handling.

| phase | time | space |
|---|---|---|
| input read | one pass over tokens | one input string |
| graph build | one forward and one reverse edge per road | adjacency arrays |
| shortest paths | two Dijkstra runs with a heap | two distance arrays |
| queries | one sum and compare per query | block buffer |

Graph build and queries are linear; the two Dijkstra runs dominate.

| measure | Big O |
|---|---|
| time | O(M log M + Q) |
| space | O(N + M) |

Running a fresh shortest-path search per query would cost O(Q M log M). Precompute twice, then answer each query in constant time.
