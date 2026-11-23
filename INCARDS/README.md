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

var scanPos = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int(data[position]) - firstDigitValue
    position += 1
  return value
```

The scanner skips line breaks and spaces, so blank lines need no special case. Every stop number and price is non-negative. Parsing one number visits each of its digits once.

The heap holds `(distance, stop)` pairs. Deleting a stale pair is cheaper than decreasing a key in place.

```nim
proc heapPush(heapNode: var seq[int], heapKey: var seq[int64], heapSize: var int,
              nodeIndex: int, nodeKey: int64) =
  var childPos = heapSize
  heapSize += 1
  while childPos > 0:
    let parentPos = (childPos - 1) div 2
    if heapKey[parentPos] <= nodeKey:
      break
    heapNode[childPos] = heapNode[parentPos]
    heapKey[childPos] = heapKey[parentPos]
    childPos = parentPos
  heapNode[childPos] = nodeIndex
  heapKey[childPos] = nodeKey

proc heapPop(heapNode: var seq[int], heapKey: var seq[int64], heapSize: var int): tuple[nodeIndex: int, nodeKey: int64] =
  let rootNode = heapNode[0]
  let rootKey = heapKey[0]
  heapSize -= 1
  if heapSize > 0:
    let lastNode = heapNode[heapSize]
    let lastKey = heapKey[heapSize]
    var parentPos = 0
    while true:
      let leftPos = parentPos * 2 + 1
      if leftPos >= heapSize:
        break
      let rightPos = leftPos + 1
      var childPos = leftPos
      if rightPos < heapSize and heapKey[rightPos] < heapKey[leftPos]:
        childPos = rightPos
      if heapKey[childPos] >= lastKey:
        break
      heapNode[parentPos] = heapNode[childPos]
      heapKey[parentPos] = heapKey[childPos]
      parentPos = childPos
    heapNode[parentPos] = lastNode
    heapKey[parentPos] = lastKey
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
  for nodeIndex in 1..nodeCount:
    distance[nodeIndex] = unreachableDistance
  var heapSize = 0
  distance[sourceNode] = 0
  heapPush(heapNode, heapKey, heapSize, sourceNode, 0)
  while heapSize > 0:
    let entry = heapPop(heapNode, heapKey, heapSize)
    let currentNode = entry.nodeIndex
    let currentDistance = entry.nodeKey
    if currentDistance != distance[currentNode]:
      continue
    var edgeIndex = edgeHead[currentNode]
    while edgeIndex != nullEdgeIndex:
      let neighborNode = edgeTo[edgeIndex]
      let candidateDistance = currentDistance + int64(edgeWeight[edgeIndex])
      if candidateDistance < distance[neighborNode]:
        distance[neighborNode] = candidateDistance
        heapPush(heapNode, heapKey, heapSize, neighborNode, candidateDistance)
      edgeIndex = edgeNext[edgeIndex]
  var total: int64 = 0
  for nodeIndex in 1..nodeCount:
    total += distance[nodeIndex]
  return total
```

The stale-pair check skips heap entries that no longer match the distance table. Each line leaves its settled stop exactly once. Distances use 64 bits because the sum can exceed 32 bits.

The driver stores both directions of every line in one flat pair of arrays, then runs the two searches.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 1..caseCount:
  let nodeCount = nextInt(inputData, scanPos)
  let edgeCount = nextInt(inputData, scanPos)
  var forwardHead = newSeq[int](nodeCount + 1)
  var reverseHead = newSeq[int](nodeCount + 1)
  for nodeIndex in 0..nodeCount:
    forwardHead[nodeIndex] = nullEdgeIndex
    reverseHead[nodeIndex] = nullEdgeIndex
  var edgeTo = newSeq[int](edgeCount * 2 + 5)
  var edgeWeight = newSeq[int](edgeCount * 2 + 5)
  var edgeNext = newSeq[int](edgeCount * 2 + 5)
  for edgeIndex in 0..<edgeCount:
    let originNode = nextInt(inputData, scanPos)
    let targetNode = nextInt(inputData, scanPos)
    let ticketPrice = nextInt(inputData, scanPos)
    let forwardIndex = edgeIndex * 2
    edgeTo[forwardIndex] = targetNode
    edgeWeight[forwardIndex] = ticketPrice
    edgeNext[forwardIndex] = forwardHead[originNode]
    forwardHead[originNode] = forwardIndex
    let reverseIndex = forwardIndex + 1
    edgeTo[reverseIndex] = originNode
    edgeWeight[reverseIndex] = ticketPrice
    edgeNext[reverseIndex] = reverseHead[targetNode]
    reverseHead[targetNode] = reverseIndex
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
