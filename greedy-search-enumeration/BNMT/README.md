# BNMT — Binary Matrix (SPOJ)
<https://www.spoj.com/problems/BNMT/>

## Problem

Flip the fewest cells so every row holds the same count of ones and every column holds the same count of ones. Report that minimum, or minus one when no target exists.

Input starts with the test count. Each case gives row count and column count, then one binary row per line. Output uses the form `Case X: R` with a one-based case number.

| item | bound |
|---|---|
| test cases T | about 1000 |
| rows r | 1 to 40 |
| columns c | 1 to 40 |
| judge limit | 1000 ms, 1536 MB |

A row may be written with spaces between bits or as one compact string.

Sample input:

```
3
2 3
111
111
3 3
011
011
011
2 3
001
000
```

Sample output:

```
Case 1: 0
Case 2: 3
Case 3: 1
```

## Idea

Try each legal common row count, then send ones through a cheapest-path network, like routing parcels along toll roads where some roads are free. A cell that already holds one has cost zero; a cell holding zero costs one flip. The cheapest flow tells us how many zeros must become ones, and the total flip count follows. Choose the best target among the few that balance rows against columns.

Only targets with r times the row count divisible by c can work.

## Why It Works

1. Equal row counts R and equal column counts C force r times R to equal c times C.
2. The divisor of r and c fixes the step between legal row counts.
3. Flips equal `lowerBound + 2 * zeroCells`, where `lowerBound` compares the current and target one counts.
4. A zero-cost edge keeps an existing one, and a one-cost edge creates a new one.
5. Shortest augmenting paths give the smallest possible number of created ones for each target.

| term | meaning |
|---|---|
| `rowTarget` | common number of ones in each row |
| `columnTarget` | common number of ones in each column |
| `zeroCells` | number of zeros that must become ones |
| `lowerBound` | difference between existing and target one counts |

The second sample case has six existing ones and a target of nine.

| step | visible value |
|---|---|
| row count and column count | 3 and 3 |
| chosen row target | 3 |
| existing ones kept | 6 |
| zeros turned into ones | 3 |
| flips | 6 - 9 + 2 times 3 = 3 |

Candidates are visited near the current one count first, so weak targets are skipped.

## Code

**Input and scanners.** `nextBit` accepts both spaced bits and compact binary rows.

```nim
const flushBlockBytes = 1 shl 17
const infiniteDistance = 1000000000

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

proc nextBit(data: string, pos: var int): int =
  while pos < data.len and data[pos] != '0' and data[pos] != '1':
    pos += 1
  let value = int(data[pos]) - 48
  pos += 1
  return value

```

**Output helper.** Buffered writes collect the case lines.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

```

**Edge type and divisor.** Each residual edge stores its reverse position.

```nim
type
  FlowEdge = object
    targetNode: int
    capacity: int
    cost: int
    reverseIndex: int

proc greatestCommonDivisor(leftValue, rightValue: int): int =
  var firstValue = leftValue
  var secondValue = rightValue
  while secondValue != 0:
    let remainder = firstValue mod secondValue
    firstValue = secondValue
    secondValue = remainder
  return firstValue

```

**Cheapest flow.** Shortest augmenting paths minimise the number of zero cells used.

```nim
proc minimumZeroCells(rowCount, colCount: int, cells: seq[int],
                      targetOnes, rowTarget, columnTarget: int): int =
  let sourceNode = rowCount + colCount
  let sinkNode = sourceNode + 1
  let nodeCount = sinkNode + 1
  var graph = newSeq[seq[FlowEdge]](nodeCount)
  proc addEdge(fromNode, toNode, capacity, cost: int) =
    let forwardIndex = graph[fromNode].len
    graph[fromNode].add FlowEdge(targetNode: toNode, capacity: capacity,
                                  cost: cost, reverseIndex: graph[toNode].len)
    graph[toNode].add FlowEdge(targetNode: fromNode, capacity: 0,
                                cost: -cost, reverseIndex: forwardIndex)
  for rowIndex in 0 .. rowCount - 1:
    addEdge(sourceNode, rowIndex, rowTarget, 0)
  for columnIndex in 0 .. colCount - 1:
    addEdge(rowCount + columnIndex, sinkNode, columnTarget, 0)
  for rowIndex in 0 .. rowCount - 1:
    for columnIndex in 0 .. colCount - 1:
      let cellValue = cells[rowIndex * colCount + columnIndex]
      addEdge(rowIndex, rowCount + columnIndex, 1, if cellValue == 1: 0 else: 1)
  var sentFlow = 0
  var totalCost = 0
  while sentFlow < targetOnes:
    var distance = newSeq[int](nodeCount)
    var inQueue = newSeq[bool](nodeCount)
    var parentNode = newSeq[int](nodeCount)
    var parentEdge = newSeq[int](nodeCount)
    for nodeIndex in 0 .. nodeCount - 1:
      distance[nodeIndex] = infiniteDistance
    var queue = newSeq[int](0)
    queue.add sourceNode
    distance[sourceNode] = 0
    inQueue[sourceNode] = true
    var queueHead = 0
    while queueHead < queue.len:
      let currentNode = queue[queueHead]
      queueHead += 1
      inQueue[currentNode] = false
      for edgeIndex in 0 .. graph[currentNode].len - 1:
        let edge = graph[currentNode][edgeIndex]
        if edge.capacity > 0 and distance[currentNode] + edge.cost < distance[edge.targetNode]:
          distance[edge.targetNode] = distance[currentNode] + edge.cost
          parentNode[edge.targetNode] = currentNode
          parentEdge[edge.targetNode] = edgeIndex
          if not inQueue[edge.targetNode]:
            inQueue[edge.targetNode] = true
            queue.add edge.targetNode
    if distance[sinkNode] == infiniteDistance:
      return -1
    var augment = targetOnes - sentFlow
    var cursor = sinkNode
    while cursor != sourceNode:
      let previousNode = parentNode[cursor]
      let edgeCapacity = graph[previousNode][parentEdge[cursor]].capacity
      if edgeCapacity < augment:
        augment = edgeCapacity
      cursor = previousNode
    cursor = sinkNode
    while cursor != sourceNode:
      let previousNode = parentNode[cursor]
      let edgeIndex = parentEdge[cursor]
      let reverseIndex = graph[previousNode][edgeIndex].reverseIndex
      graph[previousNode][edgeIndex].capacity -= augment
      graph[cursor][reverseIndex].capacity += augment
      cursor = previousNode
    sentFlow += augment
    totalCost += augment * distance[sinkNode]
  return totalCost

```

Each pass finds a shortest path from source to sink through residual edges.
The bottleneck along that path is sent at once, and reverse capacities are restored.
Path costs stay nonnegative, so queue-based relaxation finds the minimum.

**Target search.** Legal row counts are sorted by distance from the current one count.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let rowCount = nextInt(inputData, scanPos)
  let colCount = nextInt(inputData, scanPos)
  var cells = newSeq[int](rowCount * colCount)
  var oneCount = 0
  for cellIndex in 0 .. rowCount * colCount - 1:
    cells[cellIndex] = nextBit(inputData, scanPos)
    oneCount += cells[cellIndex]
  let divisor = greatestCommonDivisor(rowCount, colCount)
  let stepSize = colCount div divisor
  var candidates = newSeq[int](0)
  var rowTarget = 0
  while rowTarget <= colCount:
    candidates.add rowTarget
    rowTarget += stepSize
  for candidateIndex in 1 .. candidates.len - 1:
    let candidate = candidates[candidateIndex]
    let candidateGap = abs(oneCount - candidate * rowCount)
    var previousIndex = candidateIndex - 1
    while previousIndex >= 0 and abs(oneCount - candidates[previousIndex] * rowCount) > candidateGap:
      candidates[previousIndex + 1] = candidates[previousIndex]
      previousIndex -= 1
    candidates[previousIndex + 1] = candidate
  var answer = oneCount
  for candidateIndex in 0 .. candidates.len - 1:
    let candidate = candidates[candidateIndex]
    let targetOnes = candidate * rowCount
    let columnTarget = targetOnes div colCount
    let lowerBound = oneCount - targetOnes
    if abs(lowerBound) >= answer:
      continue
    let zeroCells = minimumZeroCells(rowCount, colCount, cells,
                                     targetOnes, candidate, columnTarget)
    if zeroCells >= 0:
      let flips = lowerBound + 2 * zeroCells
      if flips < answer:
        answer = flips
  appendOutput("Case " & $(caseIndex + 1) & ": " & $answer)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

A target whose basic lower bound already exceeds the best answer is skipped.
The all-zero target seeds a valid answer before any flow runs.

## Complexity

Each flow augments once per chosen cell in the worst case.

| phase | time | space |
|---|---|---|
| input read | r times c bits | one input string |
| target list | at most 41 values | one small array |
| one flow | F augmentations over r plus c nodes | residual graph |
| output | one line per case | block buffer |

| measure | Big O |
|---|---|
| targets | O(g) with g = gcd(r, c) |
| one flow | O(F E) worst case |
| space per case | O(r c) |

Brute force would enumerate every binary matrix with the required margins.

The flow replaces that enumeration with a short sequence of cheapest paths.
