# SPRING — Spring Loaded (SPOJ)

<https://www.spoj.com/problems/SPRING/>

## Problem

Bars can be placed anywhere between two fixed endpoints, and springs pull along the line. Find the smallest possible value of the largest spring force.

Input holds test cases until end of file. Each case starts with N, M, D: bar count, spring count, and the distance between bar 0 and bar N−1. Each of the next M lines gives A, B, K for a spring between bars A and B with constant K. Output one force per case, rounded to two decimals.

| item | bound |
|---|---|
| bars N | 2 to 100 |
| springs M | 1 to 10000 |
| endpoint distance D | 1 to 100000 |
| spring constant K | 1 to 100000 |
| judge limit | 3418 ms, 1536 MB |

Let F be a candidate force limit. Let S be the smallest sum of 1/K over a path from bar 0 to bar N−1.

Sample input:

```
3 2 5
1 0 1
1 2 1
3 3 5
1 0 1
1 2 1
0 2 2
4 5 100
0 2 1
0 2 1
2 1 1
2 1 1
1 3 2
```

Sample output:

```
2.50
10.00
40.00
```

## Idea

A spring is like a rubber band with zero rest length: force equals constant times stretch. Think of spreading a fixed distance along a chain of bands. The best arrangement shares the distance so no band is stretched too far.

For a force limit F, a spring with constant K allows stretch at most F/K. The tightest bound on the endpoint distance comes from the path with the smallest sum of 1/K. That path must reach distance D, so F times S must be at least D. The minimum force is D/S.

Dijkstra computes S in O(M log N) per case with positive reciprocal weights. Trying force values and testing every spring would repeat the same path search many times.

One shortest path settles the answer directly.

## Why It Works

1. Hooke's law with zero rest length gives force K times the absolute position difference.
2. A limit F allows a spring of constant K to stretch at most F/K.
3. Each path from bar 0 to bar N−1 contributes the bound D ≤ F times the path sum of 1/K.
4. The smallest path sum S gives the strongest bound, so feasibility needs F times S ≥ D.
5. Setting other bars to their shortest-path distances from bar 0 satisfies every spring bound.
6. Therefore the smallest feasible force equals D/S.

| term | meaning |
|---|---|
| `edgeWeight` | reciprocal 1/K stored on a directed spring edge |
| `bestWeights` | shortest reciprocal sum from bar 0 to a bar |
| `maxForce` | target distance divided by the endpoint sum |
| `roundedForce` | force scaled by 100 before printing |

Clamping positions to the interval cannot increase any distance difference.

For the first sample case, springs 0–1 and 1–2 both have K = 1. The path sum is 1/1 + 1/1 = 2. The answer is 5/2 = 2.50.

The second case adds a direct spring with K = 2. The path sum drops to 1/2, so the answer becomes 5/(1/2) = 10.00.

## Code

**Input and scanner.** All input is read once, and integers are parsed by hand.

```nim
const flushBlockBytes = 1 shl 17
const infiniteWeight = 1e100

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

proc atEnd(data: string, pos: int): bool =
  var cursor = pos
  while cursor < data.len and (data[cursor] < '0' or data[cursor] > '9'):
    cursor += 1
  return cursor >= data.len
```

The `atEnd` check handles input ending at EOF without a count line.

The scanner accepts any mix of spaces and line breaks.

**Output buffer and heap.** Buffered text and a float heap support many test cases.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc pushHeap(weightHeap: var seq[float], nodeHeap: var seq[int], weight: float, node: int) =
  weightHeap.add weight
  nodeHeap.add node
  var childIndex = weightHeap.len - 1
  while childIndex > 0:
    let parentIndex = (childIndex - 1) div 2
    if weightHeap[parentIndex] <= weightHeap[childIndex]:
      break
    swap weightHeap[parentIndex], weightHeap[childIndex]
    swap nodeHeap[parentIndex], nodeHeap[childIndex]
    childIndex = parentIndex

proc popHeap(weightHeap: var seq[float], nodeHeap: var seq[int]): tuple[weight: float, node: int] =
  let topWeight = weightHeap[0]
  let topNode = nodeHeap[0]
  let lastWeight = weightHeap[weightHeap.len - 1]
  let lastNode = nodeHeap[nodeHeap.len - 1]
  weightHeap.setLen(weightHeap.len - 1)
  nodeHeap.setLen(nodeHeap.len - 1)
  if weightHeap.len > 0:
    weightHeap[0] = lastWeight
    nodeHeap[0] = lastNode
    var parentIndex = 0
    while true:
      let leftChild = parentIndex * 2 + 1
      if leftChild >= weightHeap.len:
        break
      let rightChild = leftChild + 1
      var smallerChild = leftChild
      if rightChild < weightHeap.len and weightHeap[rightChild] < weightHeap[leftChild]:
        smallerChild = rightChild
      if weightHeap[parentIndex] <= weightHeap[smallerChild]:
        break
      swap weightHeap[parentIndex], weightHeap[smallerChild]
      swap nodeHeap[parentIndex], nodeHeap[smallerChild]
      parentIndex = smallerChild
  return (topWeight, topNode)
```

The heap stores weights and bar indices in matching arrays.

Old entries are ignored when their weight no longer matches `bestWeights`.

**Search and formatting.** Reciprocal constants are relaxed, then the force is printed with two decimals.

```nim
while not atEnd(inputData, scanPos):
  let barCount = nextInt(inputData, scanPos)
  let springCount = nextInt(inputData, scanPos)
  let targetDistance = nextInt(inputData, scanPos)
  var springLeft = newSeq[int](springCount)
  var springRight = newSeq[int](springCount)
  var springConstant = newSeq[int](springCount)
  var nodeLimit = barCount - 1
  for springIndex in 0 .. springCount - 1:
    springLeft[springIndex] = nextInt(inputData, scanPos)
    springRight[springIndex] = nextInt(inputData, scanPos)
    springConstant[springIndex] = nextInt(inputData, scanPos)
    if springLeft[springIndex] > nodeLimit:
      nodeLimit = springLeft[springIndex]
    if springRight[springIndex] > nodeLimit:
      nodeLimit = springRight[springIndex]
  var adjacencyHead = newSeq[int](nodeLimit + 1)
  for nodeIndex in 0 .. nodeLimit:
    adjacencyHead[nodeIndex] = -1
  var edgeTarget = newSeq[int](springCount * 2)
  var edgeWeight = newSeq[float](springCount * 2)
  var edgeNext = newSeq[int](springCount * 2)
  var edgeCount = 0
  for springIndex in 0 .. springCount - 1:
    let firstBar = springLeft[springIndex]
    let secondBar = springRight[springIndex]
    let reciprocalWeight = 1.0 / float(springConstant[springIndex])
    edgeTarget[edgeCount] = secondBar
    edgeWeight[edgeCount] = reciprocalWeight
    edgeNext[edgeCount] = adjacencyHead[firstBar]
    adjacencyHead[firstBar] = edgeCount
    edgeCount += 1
    edgeTarget[edgeCount] = firstBar
    edgeWeight[edgeCount] = reciprocalWeight
    edgeNext[edgeCount] = adjacencyHead[secondBar]
    adjacencyHead[secondBar] = edgeCount
    edgeCount += 1
  var bestWeights = newSeq[float](nodeLimit + 1)
  for nodeIndex in 0 .. nodeLimit:
    bestWeights[nodeIndex] = infiniteWeight
  bestWeights[0] = 0.0
  var weightHeap = newSeq[float](0)
  var nodeHeap = newSeq[int](0)
  pushHeap(weightHeap, nodeHeap, 0.0, 0)
  while weightHeap.len > 0:
    let poppedItem = popHeap(weightHeap, nodeHeap)
    if poppedItem.weight != bestWeights[poppedItem.node]:
      continue
    var edgeIndex = adjacencyHead[poppedItem.node]
    while edgeIndex != -1:
      let candidateWeight = poppedItem.weight + edgeWeight[edgeIndex]
      if candidateWeight < bestWeights[edgeTarget[edgeIndex]]:
        bestWeights[edgeTarget[edgeIndex]] = candidateWeight
        pushHeap(weightHeap, nodeHeap, candidateWeight, edgeTarget[edgeIndex])
      edgeIndex = edgeNext[edgeIndex]
  let maxForce = float(targetDistance) / bestWeights[barCount - 1]
  let roundedForce = int64(maxForce * 100.0 + 0.5)
  appendOutput($(roundedForce div 100))
  outputBuffer.add '.'
  let fractionDigits = roundedForce mod 100
  if fractionDigits < 10:
    outputBuffer.add '0'
  appendOutput($(fractionDigits))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Node limits grow to cover spring endpoints outside the stated bar range.

Adding 0.5 before truncating gives the required two-decimal rounding.

## Complexity

Each case reads springs, stores two directed edges per spring, and runs one Dijkstra search.

| phase | time | space |
|---|---|---|
| input read | one pass over spring triples | one input string |
| graph build | O(M) edge inserts | O(N + M) arrays |
| search | O(M log N) heap work | O(N) distance array |
| output | one buffered write per block | block buffer |

Reciprocal weights are positive, so Dijkstra needs no negative-cycle checks.

| measure | Big O |
|---|---|
| time per case | O(M log N) |
| space per case | O(N + M) |

Testing force values by rerunning shortest paths would multiply the search cost.

The reciprocal-path formula gives the exact minimum in one pass.
