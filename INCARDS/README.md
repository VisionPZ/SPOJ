## Problem

Read several bus networks. Each network has numbered stops and one-way bus lines with a price. Stop 1 is the central checkpoint. A volunteer starts at stop 1 and travels to every other stop; at the end of the day every volunteer returns to stop 1. Print the smallest total fare for one network on one line.

| Quantity | Bound |
| --- | --- |
| Networks per file | not fixed |
| Stops `P` | 1 to 1,000,000 |
| Lines `Q` | 1 to 1,000,000 |
| Sum of prices | below 1,000,000,000 |
| Time limit | 1000 ms |
| Memory limit | 1536 MB |

The stop count drives memory; the line count drives running time.

## Idea

Run Dijkstra's algorithm twice from stop 1. The first run uses the lines as given and sums the distances to all stops. The second run uses the reversed lines and sums the distances back to stop 1. Add the two sums and print the result.

Each run visits every line once, so the cost per line is O(log Q) heap work. A fresh search for every volunteer would cost O(P · Q) instead.

## Why It Works

The fare from stop 1 to stop `v` is the shortest path in the given network. The fare from `v` back to stop 1 is the shortest path in the reversed network, because reversing every line turns a return path into an outbound path. The volunteers travel independently, so the daily fare is the sum of all these shortest paths.

Dijkstra's algorithm keeps a tentative distance for each stop. A heap returns the unsettled stop with the smallest distance. Relaxing one line `(u, v, price)` applies this rule:

- `candidateDistance = currentDistance + price`
- replace `distance[v]` only when `candidateDistance < distance[v]`
- push the new pair into the heap for later processing

Worked example for the first sample network:

| Direction | distance to stop 1 | distance to stop 2 | sum |
| --- | --- | --- | --- |
| Outbound | 0 | 13 | 13 |
| Return | 0 | 33 | 33 |

The printed answer is `13 + 33 = 46`.

## Code

The program reads all input at once and walks it with a digit scanner.

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

The scanner skips line breaks and spaces, so blank lines need no special case. Every stop number and price is non-negative. Parsing one number visits each of its digits once.

The heap holds `(distance, stop)` pairs. Deleting a stale pair is cheaper than decreasing a key in place.

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

Each push or pop climbs at most `log Q` levels. The heap arrays are allocated once per network and reused by both searches.

One search fills the distance table and returns its sum.

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

The stale-pair check skips heap entries that no longer match the distance table. Each line leaves its settled stop exactly once. Distances use 64 bits because the sum can exceed 32 bits.

The driver stores both directions of every line in one flat pair of arrays, then runs the two searches.

```nim
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

Two slots per line hold the forward edge and its reverse. A head array points at the first slot in each stop's chain. The output buffer flushes in blocks, never once per network.

## Complexity

| Phase | Time | Space |
| --- | --- | --- |
| Read and store one network | O(P + Q) | O(P + Q) |
| One Dijkstra search | O(Q log Q) | O(P) |
| Two searches | O(Q log Q) | O(P + Q) |
| Output | O(1) per network | one block |

Total time is O(Q log Q) per network and total space is O(P + Q). A search from every stop would cost O(P · Q log Q) instead.
