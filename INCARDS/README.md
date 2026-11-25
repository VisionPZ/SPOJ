# INCARDS — Invitation Cards (SPOJ)
<https://www.spoj.com/problems/INCARDS/>

## Problem

Volunteers leave a central bus stop each morning, visit every other stop, and return at night. The bus lines are one-way and have fares, and the troupe wants the smallest total daily fare.

The first line holds a network count. Each network gives a stop count P and a line count Q, then Q lines of origin, destination, and price. Stop 1 is the central checkpoint. Prices are positive and their sum is below 1000000000, and every stop is reachable from every other. Print one line per network, the total fare for all volunteers.

The judge limits are:

| Item | Value |
| --- | --- |
| Stops P | 1 to 1000000 |
| Lines Q | 1 to 1000000 |
| Sum of prices | below 1000000000 |
| Time limit | 1 s |
| Memory limit | 1536 MB |

The stop count drives memory, and the line count drives running time.

The sample input reads:

```text
2
2 2
1 2 13
2 1 33
4 6
1 2 10
2 1 60
1 3 20
3 4 10
2 4 5
4 1 50
```

The sample output reads:

```text
46
210
```

## Idea

Run two delivery rounds, one outbound and one back, like sending a letter and its prepaid return envelope. Dijkstra's algorithm (shortest paths from one source with non-negative weights) gives the outbound fare to each stop. Running it on the reversed network gives each return fare, because reversing every line turns a return trip into an outbound trip. A heap (a priority queue returning the smallest tentative distance) keeps each run fast. Each run touches each line once, costing O(Q log Q). A fresh search for every volunteer would cost O(P times Q). Takeaway: search twice, once per direction, then add the two sums.

## Why It Works

1. The fare from stop 1 to stop v is the shortest path in the given network.
2. The fare from v back to stop 1 is the shortest path in the reversed network.
3. Volunteers travel independently, so the daily fare is the sum of all these shortest paths.
4. Dijkstra's algorithm keeps a tentative distance for each stop and settles the nearest unsettled one next.
5. The heap may hold stale pairs, so a pair is skipped when its distance no longer matches the table.
6. Relaxing line `(u, v, price)` replaces `distance[v]` only when `currentDistance + price` is smaller.
7. Distances use 64 bits, because the sum of paths can exceed a 32-bit integer.

The table defines the terms.

| Term | Meaning |
| --- | --- |
| `forwardHead`, `reverseHead` | first edge slot per stop in each direction |
| `heapNode`, `heapKey` | parallel arrays holding stop and distance |
| `unreachableDistance` | large sentinel for an unvisited stop |
| `candidateDistance` | proposed new distance through one line |

These terms name the search arrays and distances.

A script ran both searches on the first sample network.

| Direction | Distance to stop 1 | Distance to stop 2 | Sum |
| --- | --- | --- | --- |
| Outbound | 0 | 13 | 13 |
| Return | 0 | 33 | 33 |

The printed answer is 13 + 33 = 46, which matches the sample.

## Code

**Input and scanner.** The program reads all input once and walks it with a digit scanner.

```nim
const firstDigitValue = 48
const nullEdgeIndex = -1
const flushBlockBytes = 1 shl 18
const unreachableDistance = high(int64) div 4

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var i = 0

proc nextInt(data: string, i: var int): int =
  while i < data.len and (data[i] < '0' or data[i] > '9'):
    i += 1
  var value = 0
  while i < data.len and data[i] >= '0' and data[i] <= '9':
    value = value * 10 + int(data[i]) - firstDigitValue
    i += 1
  return value
```

The scanner skips line breaks and spaces, so blank lines need no special case. All stop numbers and prices are non-negative. Parsing one number visits each of its digits once.

**Heap operations.** Deleting a stale pair is cheaper than decreasing a key in place.

```nim
proc heapPush(heapNode: var seq[int], heapKey: var seq[int64], heapSize: var int,
              i: int, nodeKey: int64) =
  var j = heapSize
  heapSize += 1
  while j > 0:
    let k = (j - 1) div 2
    if heapKey[k] <= nodeKey:
      break
    heapNode[j] = heapNode[k]
    heapKey[j] = heapKey[k]
    j = k
  heapNode[j] = i
  heapKey[j] = nodeKey

proc heapPop(heapNode: var seq[int], heapKey: var seq[int64], heapSize: var int): tuple[nodeIndex: int, nodeKey: int64] =
  let rootNode = heapNode[0]
  let rootKey = heapKey[0]
  heapSize -= 1
  if heapSize > 0:
    let lastNode = heapNode[heapSize]
    let lastKey = heapKey[heapSize]
    var i = 0
    while true:
      let j = i * 2 + 1
      if j >= heapSize:
        break
      let k = j + 1
      var l = j
      if k < heapSize and heapKey[k] < heapKey[j]:
        l = k
      if heapKey[l] >= lastKey:
        break
      heapNode[i] = heapNode[l]
      heapKey[i] = heapKey[l]
      i = l
    heapNode[i] = lastNode
    heapKey[i] = lastKey
  return (rootNode, rootKey)
```

Each push or pop climbs at most log Q levels. The node and its distance live in parallel arrays. The heap arrays are allocated once per network and reused by both searches.

**One search.** The procedure fills the distance table and returns its sum.

```nim
proc totalShortestDistance(nodeCount: int, edgeHead: seq[int], edgeTo: seq[int],
                           edgeWeight: seq[int], edgeNext: seq[int],
                           sourceNode: int, heapNode: var seq[int],
                           heapKey: var seq[int64]): int64 =
  var distance = newSeq[int64](nodeCount + 1)
  for i in 1..nodeCount:
    distance[i] = unreachableDistance
  var heapSize = 0
  distance[sourceNode] = 0
  heapPush(heapNode, heapKey, heapSize, sourceNode, 0)
  while heapSize > 0:
    let entry = heapPop(heapNode, heapKey, heapSize)
    let currentNode = entry.nodeIndex
    let currentDistance = entry.nodeKey
    if currentDistance != distance[currentNode]:
      continue
    var j = edgeHead[currentNode]
    while j != nullEdgeIndex:
      let neighborNode = edgeTo[j]
      let candidateDistance = currentDistance + int64(edgeWeight[j])
      if candidateDistance < distance[neighborNode]:
        distance[neighborNode] = candidateDistance
        heapPush(heapNode, heapKey, heapSize, neighborNode, candidateDistance)
      j = edgeNext[j]
  var total: int64 = 0
  for i in 1..nodeCount:
    total += distance[i]
  return total
```

The stale-pair check skips entries that no longer match the table. Each line leaves its settled stop exactly once. The final loop sums distances to all stops, including zero for the source.

**Driver.** Two edge arrays store both directions, then the two searches run.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, i)
for j in 1..caseCount:
  let nodeCount = nextInt(inputData, i)
  let edgeCount = nextInt(inputData, i)
  var forwardHead = newSeq[int](nodeCount + 1)
  var reverseHead = newSeq[int](nodeCount + 1)
  for k in 0..nodeCount:
    forwardHead[k] = nullEdgeIndex
    reverseHead[k] = nullEdgeIndex
  var edgeTo = newSeq[int](edgeCount * 2 + 5)
  var edgeWeight = newSeq[int](edgeCount * 2 + 5)
  var edgeNext = newSeq[int](edgeCount * 2 + 5)
  for k in 0..<edgeCount:
    let originNode = nextInt(inputData, i)
    let targetNode = nextInt(inputData, i)
    let ticketPrice = nextInt(inputData, i)
    let l = k * 2
    edgeTo[l] = targetNode
    edgeWeight[l] = ticketPrice
    edgeNext[l] = forwardHead[originNode]
    forwardHead[originNode] = l
    let i = l + 1
    edgeTo[i] = originNode
    edgeWeight[i] = ticketPrice
    edgeNext[i] = reverseHead[targetNode]
    reverseHead[targetNode] = i
  var heapNode = newSeq[int](edgeCount + 5)
  var heapKey = newSeq[int64](edgeCount + 5)
  let outbound = totalShortestDistance(nodeCount, forwardHead, edgeTo, edgeWeight,
                                       edgeNext, 1, heapNode, heapKey)
  let inbound = totalShortestDistance(nodeCount, reverseHead, edgeTo, edgeWeight,
                                      edgeNext, 1, heapNode, heapKey)
  appendOutput($(outbound + inbound))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Two slots per line hold the forward edge and its reverse. A head array points to the first slot in each stop's chain. The output buffer flushes in blocks, never once per network.

## Complexity

| Phase | Time | Space |
| --- | --- | --- |
| Read and store a network | O(P + Q) | O(P + Q) |
| One Dijkstra search | O(Q log Q) | O(P) |
| Two searches | O(Q log Q) | O(P + Q) |
| Output | O(1) per network | one block |

The two searches do equal work.

Both searches share the same edge arrays.

| Measure | Bound |
| --- | --- |
| Per network | O(Q log Q) time |
| Per network | O(P + Q) space |
| Heap operations | O(log Q) each |

A search from every stop would cost O(P times Q log Q) per network.
