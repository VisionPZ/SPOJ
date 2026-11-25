# CATER — Catering Contracts (SPOJ)

<https://www.spoj.com/problems/CATER/>

## Problem

A rail network is a tree of stations. Count the sets of exactly K stations whose induced subgraph is connected, and report the count modulo 10243.

The first line gives stationCount and groupSize. The next N minus one lines give the tracks. Output one integer, the legal count modulo 10243.

| item | bound |
|---|---|
| stations N | 1 to 2500 |
| group size K | 1 to 90 |
| modulo | 10243 |
| judge limit | 2000 ms, 1536 MB |

The small K bound drives the design, not the size of the tree.

Sample input:

```
6 3
1 2
2 5
3 2
4 5
6 5
```

Sample output:

```
6
```

## Idea

Count connected groups at their highest station, like counting family reunions by the eldest relative present. Root the tree, then combine child polynomials at each station with a knapsack convolution. Each station costs O(K squared) work. A naive scan checks every subset of size K and grows far faster. Root ownership turns each legal group into one unique count.

## Why It Works

1. Rooting the tree gives every station one parent and an ordered set of children.
2. Every connected group has exactly one station nearest the root; call it the top station.
3. `combinationCounts` at a station counts groups of each size that contain that station and lie in its subtree.
4. A child attaches by taking any connected group containing the child, or nothing.
5. Multiplying by one plus the child's polynomial enumerates every attachment once.
6. Summing `totalGroups` over all stations counts each legal group at its top station only.

| term | meaning |
|---|---|
| `groupSize` | required size K of a group |
| `combinationCounts` | ways to build a group of each size at one station |
| `updatedCounts` | temporary product while one child attaches |
| `traversalOrder` | stations ordered parent before child |
| `totalGroups` | sum of all contributions modulo `moduloValue` |

The polynomials encode the whole tree with one row per station.

A script trace of the sample tree splits the six triples by their top station:

| top station | connected triples |
|---|---|
| 1 | 1-2-3, 1-2-5 |
| 2 | 2-3-5, 2-4-5, 2-5-6 |
| 5 | 4-5-6 |

The rows add to two plus three plus one, which equals the sample answer six.

Every product stays below 10243 squared, so int arithmetic is safe before the final mod.

## Code

**Input and scanning.** The reader loads the tree, and an iterative walk orders the stations.

```nim
const flushBlockBytes = 1 shl 17
const moduloValue = 10243

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

let stationCount = nextInt(inputData, scanPos)
let groupSize = nextInt(inputData, scanPos)
var adjacency = newSeq[seq[int]](stationCount + 1)
for edgeIndex in 0 .. stationCount - 2:
  let endpointOne = nextInt(inputData, scanPos)
  let endpointTwo = nextInt(inputData, scanPos)
  adjacency[endpointOne].add endpointTwo
  adjacency[endpointTwo].add endpointOne

var parentNode = newSeq[int](stationCount + 1)
var traversalOrder = newSeq[int](stationCount)
var stackNodes = newSeq[int](stationCount + 1)
var stackTop = 0
stackNodes[stackTop] = 1
stackTop = 1
parentNode[1] = -1
var orderCount = 0
while stackTop > 0:
  stackTop -= 1
  let currentNode = stackNodes[stackTop]
  traversalOrder[orderCount] = currentNode
  orderCount += 1
  for neighborNode in adjacency[currentNode]:
    if neighborNode != parentNode[currentNode]:
      parentNode[neighborNode] = currentNode
      stackNodes[stackTop] = neighborNode
      stackTop += 1
```

The stack visits every station once.
Each child is recorded after its parent.
The order lets one reverse pass finish all children.

**Child convolution.** Each child multiplies the current polynomial by one plus its own polynomial.

```nim
var combinationCounts = newSeq[int]((stationCount + 1) * (groupSize + 1))
var updatedCounts = newSeq[int](groupSize + 1)
var totalGroups: int64 = 0
for orderIndex in 0 .. orderCount - 1:
  let currentNode = traversalOrder[orderCount - 1 - orderIndex]
  let baseIndex = currentNode * (groupSize + 1)
  combinationCounts[baseIndex + 1] = 1
  for neighborNode in adjacency[currentNode]:
    if parentNode[neighborNode] == currentNode:
      let childIndex = neighborNode * (groupSize + 1)
      for sizeIndex in 0 .. groupSize:
        updatedCounts[sizeIndex] = 0
      for usedCount in 1 .. groupSize:
        let currentWays = combinationCounts[baseIndex + usedCount]
        if currentWays == 0:
          continue
        for extraCount in 0 .. groupSize - usedCount:
          let childWays = if extraCount == 0: 1 else: combinationCounts[childIndex + extraCount]
          if childWays == 0:
            continue
          let targetIndex = usedCount + extraCount
          updatedCounts[targetIndex] = (updatedCounts[targetIndex] + currentWays * childWays) mod moduloValue
      for sizeIndex in 0 .. groupSize:
        combinationCounts[baseIndex + sizeIndex] = updatedCounts[sizeIndex]
  totalGroups = (totalGroups + int64(combinationCounts[baseIndex + groupSize])) mod moduloValue

appendOutput($totalGroups)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The inner loops stop at `groupSize`.
The zero case adds the choice of taking nothing from the child.
The final output is flushed once after all stations.

## Complexity

The work splits between reading the tree, the knapsack products, and one output line.

| phase | time | space |
|---|---|---|
| input read | one pass over N minus one edges | two arrays of N |
| child convolution | N children times K squared steps | N times K counts |
| output | one line | block buffer |

Each child costs one product of two short polynomials.

| measure | Big O |
|---|---|
| time | O(N times K squared) |
| space | O(N times K) |

Testing every subset of size K costs far more than these bounded convolutions.

Root ownership gives one count per legal group and keeps the answer exact.
