# GSS2 — Can you answer these queries II (SPOJ)

<https://www.spoj.com/problems/GSS2/>

## Problem

Answer each range query with the largest sum of a contiguous slice, counting each score only once inside that slice. An empty slice gives zero, so answers are never negative.

Input gives N, then N scores from -100000 to 100000, then Q queries with endpoints X and Y. N and Q are at most 100000.

Output prints one answer per query in the original query order.

| item | bound |
|---|---|
| array length N | 1 to 100000 |
| scores | -100000 to 100000 |
| queries Q | 1 to 100000 |
| judge limit | 1000 ms, 1536 MB |

The large N and Q call for an offline sweep with logarithmic work per item.

Sample input and output:

```
9
4 -2 -2 3 -1 -4 2 2 -6
3
1 2
1 5
4 9
```

```
4
5
3
```

The two blocks come from the statement and drive the checks.

## Idea

Think of a fence post moving right across the array: each new score extends every left endpoint that has not seen that score before. Range additions track those extensions, and a remembered maximum tracks the best slice seen so far.

The program groups queries by their right endpoint and sweeps positions from left to right. At each position it adds the score to one segment-tree range. Each position and each query costs O(log N). A fresh scan per query would cost O(N^2) over all queries.

One sweep answers every query in input order.

## Why It Works

1. Let D[l] be the distinct-score sum of the slice from l to the current right end.
2. A new score v at position r changes only left endpoints after its previous occurrence.
3. Adding v to that range updates every affected D[l] by exactly v.
4. The best slice starting at l can end before r, so the tree stores a historical maximum.
5. A full-cover add updates the range maximum D and the historical maximum together.
6. Pushing both lazy tags down keeps the combined update correct.
7. Querying the historical maximum over [X,Y] answers the question for right end Y.

| term | meaning |
|---|---|
| `treeSum` | maximum current D inside a tree node |
| `treeBest` | maximum historical slice sum inside a node |
| `treeLazy` | pending uniform addition |
| `treeBestLazy` | largest pending addition over time |

The two lazy tags preserve both current values and past maxima.

A traced example uses the sample array:

```
r = 1, score 4:  D[1] = 4
r = 2, score -2: D[1] = 2, D[2] = -2
r = 4, score 3:  D[1] = 5, D[4] = 3
query 1 5 -> max historical sum = 5
query 4 9 -> best slice [4,4] = 3
```

The trace reproduces the three sample answers.

## Code

**Input reader, signed scanner and query buckets.**

```nim
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-':
    pos += 1
  var sign = 1
  if pos < data.len and data[pos] == '-':
    sign = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return sign * value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

```

The scanner accepts minus signs because scores are negative.
Queries are linked by their right endpoint for the sweep.

**Previous occurrence table and tree storage.**

```nim
let elementCount = nextInt(inputData, scanPos)
var scores = newSeq[int](elementCount + 1)
for position in 1 .. elementCount:
  scores[position] = nextInt(inputData, scanPos)
let queryCount = nextInt(inputData, scanPos)
var firstAtRight = newSeq[int](elementCount + 2)
for position in 0 .. elementCount + 1:
  firstAtRight[position] = -1
var nextAtRight = newSeq[int](queryCount)
var leftEnds = newSeq[int](queryCount)
var answers = newSeq[int64](queryCount)
for queryIndex in 0 .. queryCount - 1:
  let leftEnd = nextInt(inputData, scanPos)
  let rightEnd = nextInt(inputData, scanPos)
  leftEnds[queryIndex] = leftEnd
  nextAtRight[queryIndex] = firstAtRight[rightEnd]
  firstAtRight[rightEnd] = queryIndex

const scoreOffset = 100000
var lastSeen = newSeq[int](2 * scoreOffset + 1)

var treeSum = newSeq[int64](4 * elementCount + 5)
var treeBest = newSeq[int64](4 * elementCount + 5)
var treeLazy = newSeq[int64](4 * elementCount + 5)
var treeBestLazy = newSeq[int64](4 * elementCount + 5)

```

lastSeen maps each score to its latest position.
Four parallel arrays hold the tree fields.

**Lazy propagation, range add and range maximum.**

```nim
proc pushDown(node: int, low: int, high: int) =
  if low == high:
    treeLazy[node] = 0
    treeBestLazy[node] = 0
    return
  let leftChild = node * 2
  let rightChild = node * 2 + 1
  treeBestLazy[leftChild] = max(treeBestLazy[leftChild], treeLazy[leftChild] + treeBestLazy[node])
  treeLazy[leftChild] = treeLazy[leftChild] + treeLazy[node]
  treeBest[leftChild] = max(treeBest[leftChild], treeSum[leftChild] + treeBestLazy[node])
  treeSum[leftChild] = treeSum[leftChild] + treeLazy[node]
  treeBestLazy[rightChild] = max(treeBestLazy[rightChild], treeLazy[rightChild] + treeBestLazy[node])
  treeLazy[rightChild] = treeLazy[rightChild] + treeLazy[node]
  treeBest[rightChild] = max(treeBest[rightChild], treeSum[rightChild] + treeBestLazy[node])
  treeSum[rightChild] = treeSum[rightChild] + treeLazy[node]
  treeLazy[node] = 0
  treeBestLazy[node] = 0

proc addRange(node: int, low: int, high: int, left: int, right: int, delta: int64) =
  if left <= low and high <= right:
    treeBestLazy[node] = max(treeBestLazy[node], treeLazy[node] + delta)
    treeLazy[node] = treeLazy[node] + delta
    treeBest[node] = max(treeBest[node], treeSum[node] + delta)
    treeSum[node] = treeSum[node] + delta
    return
  pushDown(node, low, high)
  let middle = (low + high) div 2
  if left <= middle:
    addRange(node * 2, low, middle, left, right, delta)
  if right > middle:
    addRange(node * 2 + 1, middle + 1, high, left, right, delta)
  treeBest[node] = max(treeBest[node * 2], treeBest[node * 2 + 1])
  treeSum[node] = max(treeSum[node * 2], treeSum[node * 2 + 1])

proc queryBest(node: int, low: int, high: int, left: int, right: int): int64 =
  if left <= low and high <= right:
    return treeBest[node]
  pushDown(node, low, high)
  let middle = (low + high) div 2
  if right <= middle:
    return queryBest(node * 2, low, middle, left, right)
  if left > middle:
    return queryBest(node * 2 + 1, middle + 1, high, left, right)
  let leftBest = queryBest(node * 2, low, middle, left, right)
  let rightBest = queryBest(node * 2 + 1, middle + 1, high, left, right)
  return max(leftBest, rightBest)

for rightPosition in 1 .. elementCount:
```

pushDown transfers both pending tags to the children.
A full-cover add raises D and the historical best together.
queryBest merges the two child ranges with max.

**Sweep and output.**

```nim
  let scoreIndex = scores[rightPosition] + scoreOffset
  let firstAffected = lastSeen[scoreIndex] + 1
  addRange(1, 1, elementCount, firstAffected, rightPosition, int64(scores[rightPosition]))
  lastSeen[scoreIndex] = rightPosition
  var queryIndex = firstAtRight[rightPosition]
  while queryIndex != -1:
    answers[queryIndex] = queryBest(1, 1, elementCount, leftEnds[queryIndex], rightPosition)
    queryIndex = nextAtRight[queryIndex]

for queryIndex in 0 .. queryCount - 1:
  appendOutput($answers[queryIndex])
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Each right endpoint adds one score range.
Answers are written in the original query order.

## Complexity

The sweep touches each position once and each query once.

| phase | time | space |
|---|---|---|
| input read | one pass over array and queries | one input string |
| occurrence table | one right-to-left pass | 200001 slots |
| sweep updates | N range additions | four tree arrays |
| query answers | Q range maximum queries | answer array |
| output | one buffered write per answer | block buffer |

The tree operations dominate the phase table.

| measure | Big O |
|---|---|
| time | O((N + Q) log N) |
| space | O(N + Q) |

Scanning every slice for every query would cost O(N*Q) time.
