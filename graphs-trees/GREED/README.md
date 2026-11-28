# GREED — Greedy island (SPOJ)

<https://www.spoj.com/problems/GREED/>

## Problem

Each test gives N cards and allowed one-gold exchanges between card labels. Turn the cards into the exact set 1..N using the fewest exchanges.

Input: `t`, then for each case `N`, N card labels, `e`, and e pairs of labels, followed by a blank line. Output: one line per case with the minimum cost.

| Item | Bound |
|---|---|
| Test cases `t` | 1 to 10 |
| Cards `N` | 2 to 500 |
| Exchanges `e` | no stated bound; large counts occur |
| Card labels | no stated bound; 99 999 occurs |
| Judge limit | 50 s, 1536 MB |

The exchange graph, not the card count, drives the design.

The sample case uses this input and output.

```
1
4
1
2
2
2
2
2 3
3 4

```

```
3
```

The sample asks for four cards and returns one cost line.

## Idea

Turn each exchange into one step on a map of labels, then pair cards with targets like matching couriers to addresses for the shortest total walk.

For a card starting at label u and a target v, the cheapest walk is the shortest path length `dist(u, v)`. A breadth-first search finds every needed distance in one pass over the graph. The cards then form a cost matrix of size N by N. The Hungarian algorithm picks one target for each card with the smallest total cost, in O(N^3) steps.

Listing all assignments costs N! choices and fails at N = 500. A flow run repeats a shortest-path search N times, while this method pays one search per distinct card label and one matching pass.

Distances first, matching second: that split is the whole solution.

## Why It Works

Four facts prove the method.

1. One exchange replaces one card label along one graph edge. Moving a card from u to v therefore costs exactly `dist(u, v)`.
2. Cards move independently, and each target from 1 to N must hold one card. The answer is a minimum-cost perfect matching between cards and targets.
3. Breadth-first search reaches nodes in nondecreasing distance. The first visit to a target fixes its final distance, so the search stops once every target has one.
4. The Hungarian algorithm grows a partial matching by repeatedly taking the cheapest available step. After N rounds the matching is complete and minimum.

The main terms:

| Term | Meaning |
|---|---|
| `dist(u, v)` | number of exchange edges on a shortest path from label u to target v |
| `rowData` | one distance row per distinct card label, with N entries |
| `costData` | N by N costs, one row per card |
| `hungarianV[0]` | the negative of the minimum total matching cost |
| `unreachableCost` | a large stand-in used when no path reaches a target |

The table shows how graph distances become matching costs.

A script trace of the sample case:

```
cards: [1, 2, 2, 2]
edges: [(2, 3), (3, 4)]
label 1 distances to targets [1, 2, 3, 4] = [0, 1000000000, 1000000000, 1000000000]
label 2 distances to targets [1, 2, 3, 4] = [1000000000, 0, 1, 2]
card 1 row [0, 1000000000, 1000000000, 1000000000]
card 2 row [1000000000, 0, 1, 2]
card 2 row [1000000000, 0, 1, 2]
card 2 row [1000000000, 0, 1, 2]
best assignment costs: 0, 0, 1, 2 -> total 3
```

The card holding 1 stays, and the three cards holding 2 take targets 2, 3 and 4. Their costs add to 0 + 0 + 1 + 2, which is the sample answer 3.

## Code

**Constants and number reader.** These lines set the buffers and scan one integer.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 16
const unreachableCost = 1 shl 28

proc nextInt(inputData: string, scanPos: var int): int =
  while scanPos < inputData.len and inputData[scanPos] <= ' ':
    scanPos += 1
  var parsedValue = 0
  while scanPos < inputData.len and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    parsedValue = parsedValue * 10 + int(inputData[scanPos]) - firstDigitValue
    scanPos += 1
  return parsedValue
```

The digit loop copies one character at a time and builds the value in place. `scanPos` survives across calls, so blank lines and spaces need no special case. The scan reads each input byte once.

**Label table.** These lines map arbitrary card labels to compact node numbers.

```nim
var labelKeys: seq[int]
var labelIds: seq[int]
var nodeCount = 0
var hashMask = 0

proc prepareLabelTable(expectedLabels: int) =
  var tableSize = 1024
  while tableSize < expectedLabels * 2:
    tableSize = tableSize * 2
  hashMask = tableSize - 1
  labelKeys = newSeq[int](tableSize)
  labelIds = newSeq[int](tableSize)
  for slot in 0..<tableSize:
    labelKeys[slot] = -1
    labelIds[slot] = -1
  nodeCount = 0

proc idForLabel(label: int): int =
  var slot = (label * 1000003) and hashMask
  while true:
    if labelKeys[slot] == -1:
      nodeCount += 1
      labelKeys[slot] = label
      labelIds[slot] = nodeCount - 1
      return nodeCount - 1
    if labelKeys[slot] == label:
      return labelIds[slot]
    slot = (slot + 1) and hashMask
```

The table doubles until it has room for twice the expected labels. Linear probing resolves collisions without a tree or a sort. Each label gets one small integer index, so later arrays stay flat.

**Adjacency layout.** These lines build one contiguous arc array per node.

```nim
  adjacencyStart = newSeq[int](nodeCount + 1)
  for node in 0..<nodeCount:
    adjacencyStart[node] = 0
  for k in 0..<edgeCount:
    adjacencyStart[edgeFrom[k] + 1] += 1
    adjacencyStart[edgeTo[k] + 1] += 1
  for node in 0..<nodeCount:
    adjacencyStart[node + 1] += adjacencyStart[node]
  var adjacencyFill = newSeq[int](nodeCount)
  for node in 0..<nodeCount:
    adjacencyFill[node] = adjacencyStart[node]
  adjacencyTo = newSeq[int](edgeCount * 2)
  for k in 0..<edgeCount:
    let leftNode = edgeFrom[k]
    let rightNode = edgeTo[k]
    adjacencyTo[adjacencyFill[leftNode]] = rightNode
    adjacencyFill[leftNode] += 1
    adjacencyTo[adjacencyFill[rightNode]] = leftNode
    adjacencyFill[rightNode] += 1
```

Two passes count degrees, then fill arcs. Each undirected exchange becomes two arcs. The prefix offsets let a search walk one node's neighbors in a single tight loop.

**Distance rows.** These lines run one breadth-first search per distinct card label.

```nim
  for rowIndex in 0..<distinctNodes.len:
    currentStamp += 1
    rowOffset = rowIndex * cardCount
    remainingTargets = cardCount
    var queueHead = 0
    var queueTail = 0
    let startNode = distinctNodes[rowIndex]
    searchQueue[0] = startNode
    queueTail = 1
    seenStamp[startNode] = currentStamp
    seenDist[startNode] = 0
    while queueHead < queueTail:
      let node = searchQueue[queueHead]
      queueHead += 1
      let nodeDistance = seenDist[node]
      let slot = targetSlot[node]
      if slot >= 0 and rowData[rowOffset + slot] == unreachableCost:
        rowData[rowOffset + slot] = nodeDistance
        remainingTargets -= 1
        if remainingTargets == 0: break
      for arcIndex in adjacencyStart[node]..<adjacencyStart[node + 1]:
        let neighbor = adjacencyTo[arcIndex]
        if seenStamp[neighbor] != currentStamp:
          seenStamp[neighbor] = currentStamp
          seenDist[neighbor] = nodeDistance + 1
          searchQueue[queueTail] = neighbor
          queueTail += 1
```

A stamp avoids clearing the visited array before each search. The counter stops a search as soon as all N targets have distances. One row of N costs is written per distinct card label.

**Assignment.** These lines copy the rows into a square matrix and run Hungarian matching.

```nim
  costData = newSeq[int](cardCount * cardCount)
  for rowIndex in 0..<cardCount:
    let sourceOffset = cardRows[rowIndex] * cardCount
    let destinationOffset = rowIndex * cardCount
    for k in 0..<cardCount:
      costData[destinationOffset + k] = rowData[sourceOffset + k]

  hungarianU = newSeq[int](cardCount + 1)
  hungarianV = newSeq[int](cardCount + 1)
  hungarianMatch = newSeq[int](cardCount + 1)
  hungarianWay = newSeq[int](cardCount + 1)
  hungarianMin = newSeq[int](cardCount + 1)
  hungarianUsed = newSeq[bool](cardCount + 1)
  for rowIndex in 1..cardCount:
    hungarianMatch[0] = rowIndex
    var columnZero = 0
    for k in 0..cardCount:
      hungarianMin[k] = unreachableCost
      hungarianUsed[k] = false
    while true:
      hungarianUsed[columnZero] = true
      let rowZero = hungarianMatch[columnZero]
      var delta = unreachableCost
      var columnOne = 0
      for column in 1..cardCount:
        if not hungarianUsed[column]:
          let directCost = costData[(rowZero - 1) * cardCount + (column - 1)]
          let reducedCost = directCost - hungarianU[rowZero] - hungarianV[column]
          if reducedCost < hungarianMin[column]:
            hungarianMin[column] = reducedCost
            hungarianWay[column] = columnZero
          if hungarianMin[column] < delta:
            delta = hungarianMin[column]
            columnOne = column
      for column in 0..cardCount:
        if hungarianUsed[column]:
          hungarianU[hungarianMatch[column]] += delta
          hungarianV[column] -= delta
        else:
          hungarianMin[column] -= delta
      columnZero = columnOne
      if hungarianMatch[columnZero] == 0: break
    while true:
      let previousColumn = hungarianWay[columnZero]
      hungarianMatch[columnZero] = hungarianMatch[previousColumn]
      columnZero = previousColumn
      if columnZero == 0: break
```

Cards with the same label reuse one row, which removes duplicate searches. Potentials keep reduced costs non-negative during the N augmentations. The loop runs N^3 reduced-cost comparisons in total.

**Output.** These lines append the answer and flush the buffer.

```nim
  let bestCost = -hungarianV[0]
  outputBuffer.add $bestCost
  outputBuffer.add "\n"
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

stdout.write outputBuffer
outputBuffer.setLen 0
```

The potential at column zero holds the negated optimum, so one sign gives the answer. Flushing by block keeps writes rare. The final write covers the tail after the last case.

## Complexity

The costs split into graph searches, matching and streaming IO.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Label table | one hash insert per label and endpoint | two hash arrays |
| Adjacency build | two passes over the edges | 2e arcs |
| Distance rows | one search per distinct label, O(V + E) each | V integers |
| Cost matrix | N^2 copies | N^2 integers |
| Hungarian matching | O(N^3) | O(N) integers |
| Output | one write per 64 KiB block | block buffer |

The search width and the square matching matrix dominate memory.

| Measure | Big O |
|---|---|
| Time per case | O(d(V + E) + N^3), where d is the number of distinct labels |
| Space per case | O(V + E + N^2) |

Here V counts distinct labels and E counts directed arcs. Listing all N! assignments takes factorial time and is impossible at N = 500. Distances plus Hungarian matching finish well inside the 50 s limit.
