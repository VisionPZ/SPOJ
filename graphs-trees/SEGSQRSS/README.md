# SEGSQRSS — Sum of Squares with Segment Tree (SPOJ)

<https://www.spoj.com/problems/SEGSQRSS/>

## Problem

Maintain an array under range add and range set, and answer the sum of squares over a range. Report one answer line for each query operation.

Input starts with the test count T. Each case starts with N and Q, then N initial values, then Q operations. Operation 2 gives `st nd` and asks for the square sum on [st, nd]. Operations 0 and 1 give `st nd x` for set and add. Print `Case X:` before each case's answers.

| item | bound |
|---|---|
| test count T | up to 25 |
| array size N | up to 100000 |
| operations Q | up to 100000 per case |
| initial value | at most 1000 |
| update value x | −1000 to 1000 |
| judge limit | 1106 ms, 1536 MB |

Sample input:

```
2
4 5
1 2 3 4
2 1 4
0 3 4 1
2 1 4
1 3 4 1
2 1 4
1 1
1
2 1 1
```

Sample output:

```
Case 1:
30
7
13
Case 2:
1
```

## Idea

Store a sum and a square sum at each tree node, like keeping both a running total and a tally of squared scores for a class. A pending add and a pending set travel down only when a child is touched.

Adding x to every value in a node changes its square sum by 2x times the old sum plus x squared times the length. Setting values replaces both statistics at once. A plain array would rescan the whole range on every operation, costing O(N) per update; the tree keeps each operation near O(log N).

## Why It Works

1. The value sum after adding x is the old sum plus x times the segment length.
2. The square sum after adding x is the old square sum plus 2x times the old sum plus x² times the length.
3. A set operation fixes both statistics from the assigned value and length.
4. A set cancels any earlier pending add at the same node.
5. Pushing pending work to children before descending keeps every subtree correct.

| term | meaning |
|---|---|
| `segmentSum` | sum of values stored at a node |
| `segmentSquareSum` | sum of squared values at a node |
| `hasPendingSet` | flag for a pending set on a node |
| `pendingSetValue` | value used by a pending set |
| `pendingAddValue` | value used by a pending add |

For the first sample case, the table tracks the array after each operation.

| operation | array | square sum |
|---|---|---|
| initial | 1, 2, 3, 4 | 30 |
| set [3,4] to 1 | 1, 2, 1, 1 | 7 |
| add 1 to [3,4] | 1, 2, 2, 2 | 13 |

The add step uses old sum 2 and length 2: 7 + 2·1·2 + 1²·2 = 13.

`nextInt` accepts a minus sign because x can be negative. Products use `int64` so the square sums fit throughout.

## Code

**Input and scanner.** The scanner handles negative values and the output buffer flushes in blocks.

```nim
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and data[pos] != '-' and (data[pos] < '0' or data[pos] > '9'):
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

The minus branch only triggers for update values.
`appendOutput` writes when the buffer passes `flushBlockBytes`.
One final write flushes the remaining lines.

**Tree state and lazy rules.** Each node keeps two sums and two pending markers.

```nim
var initialValues = newSeq[int64](0)
var segmentSum = newSeq[int64](0)
var segmentSquareSum = newSeq[int64](0)
var hasPendingSet = newSeq[bool](0)
var pendingSetValue = newSeq[int64](0)
var pendingAddValue = newSeq[int64](0)

proc applySet(nodeIndex: int, leftBound: int, rightBound: int, setValue: int64) {.inline.} =
  let segmentLength = int64(rightBound - leftBound + 1)
  segmentSum[nodeIndex] = setValue * segmentLength
  segmentSquareSum[nodeIndex] = setValue * setValue * segmentLength
  hasPendingSet[nodeIndex] = true
  pendingSetValue[nodeIndex] = setValue
  pendingAddValue[nodeIndex] = 0

proc applyAdd(nodeIndex: int, leftBound: int, rightBound: int, addValue: int64) {.inline.} =
  let segmentLength = int64(rightBound - leftBound + 1)
  let previousSum = segmentSum[nodeIndex]
  segmentSum[nodeIndex] = previousSum + addValue * segmentLength
  segmentSquareSum[nodeIndex] = segmentSquareSum[nodeIndex] + 2'i64 * addValue * previousSum + addValue * addValue * segmentLength
  if hasPendingSet[nodeIndex]:
    pendingSetValue[nodeIndex] = pendingSetValue[nodeIndex] + addValue
  else:
    pendingAddValue[nodeIndex] = pendingAddValue[nodeIndex] + addValue

proc pushDown(nodeIndex: int, leftBound: int, rightBound: int) {.inline.} =
  if leftBound == rightBound:
    return
  let middleIndex = (leftBound + rightBound) div 2
  let leftChild = nodeIndex * 2
  let rightChild = nodeIndex * 2 + 1
  if hasPendingSet[nodeIndex]:
    applySet(leftChild, leftBound, middleIndex, pendingSetValue[nodeIndex])
    applySet(rightChild, middleIndex + 1, rightBound, pendingSetValue[nodeIndex])
    hasPendingSet[nodeIndex] = false
  if pendingAddValue[nodeIndex] != 0:
    applyAdd(leftChild, leftBound, middleIndex, pendingAddValue[nodeIndex])
    applyAdd(rightChild, middleIndex + 1, rightBound, pendingAddValue[nodeIndex])
    pendingAddValue[nodeIndex] = 0
```

`applySet` clears an earlier pending add.
`applyAdd` folds into a pending set when one exists.
`pushDown` sends pending work to both children before a split.

**Build, update, and query.** Recursion follows only the branches that overlap the requested range.

```nim
proc buildTree(nodeIndex: int, leftBound: int, rightBound: int) =
  if leftBound == rightBound:
    let currentValue = initialValues[leftBound]
    segmentSum[nodeIndex] = currentValue
    segmentSquareSum[nodeIndex] = currentValue * currentValue
    return
  let middleIndex = (leftBound + rightBound) div 2
  buildTree(nodeIndex * 2, leftBound, middleIndex)
  buildTree(nodeIndex * 2 + 1, middleIndex + 1, rightBound)
  segmentSum[nodeIndex] = segmentSum[nodeIndex * 2] + segmentSum[nodeIndex * 2 + 1]
  segmentSquareSum[nodeIndex] = segmentSquareSum[nodeIndex * 2] + segmentSquareSum[nodeIndex * 2 + 1]

proc updateRange(nodeIndex: int, leftBound: int, rightBound: int, updateLeft: int, updateRight: int, operationType: int, updateValue: int64) =
  if updateLeft <= leftBound and rightBound <= updateRight:
    if operationType == 0:
      applySet(nodeIndex, leftBound, rightBound, updateValue)
    else:
      applyAdd(nodeIndex, leftBound, rightBound, updateValue)
    return
  if hasPendingSet[nodeIndex] or pendingAddValue[nodeIndex] != 0:
    pushDown(nodeIndex, leftBound, rightBound)
  let middleIndex = (leftBound + rightBound) div 2
  if updateLeft <= middleIndex:
    updateRange(nodeIndex * 2, leftBound, middleIndex, updateLeft, updateRight, operationType, updateValue)
  if updateRight > middleIndex:
    updateRange(nodeIndex * 2 + 1, middleIndex + 1, rightBound, updateLeft, updateRight, operationType, updateValue)
  segmentSum[nodeIndex] = segmentSum[nodeIndex * 2] + segmentSum[nodeIndex * 2 + 1]
  segmentSquareSum[nodeIndex] = segmentSquareSum[nodeIndex * 2] + segmentSquareSum[nodeIndex * 2 + 1]

proc queryRange(nodeIndex: int, leftBound: int, rightBound: int, queryLeft: int, queryRight: int): int64 =
  if queryLeft <= leftBound and rightBound <= queryRight:
    return segmentSquareSum[nodeIndex]
  if hasPendingSet[nodeIndex] or pendingAddValue[nodeIndex] != 0:
    pushDown(nodeIndex, leftBound, rightBound)
  let middleIndex = (leftBound + rightBound) div 2
  var total: int64 = 0
  if queryLeft <= middleIndex:
    total = total + queryRange(nodeIndex * 2, leftBound, middleIndex, queryLeft, queryRight)
  if queryRight > middleIndex:
    total = total + queryRange(nodeIndex * 2 + 1, middleIndex + 1, rightBound, queryLeft, queryRight)
  return total
```

A fully covered node stops immediately.
A split pushes pending work only when markers are set.
Parent sums are rebuilt from both children after each update.

**Case driver.** The driver reads each case, builds its tree, and emits answers.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let elementCount = nextInt(inputData, scanPos)
  let operationCount = nextInt(inputData, scanPos)
  initialValues = newSeq[int64](elementCount + 1)
  for elementIndex in 1 .. elementCount:
    initialValues[elementIndex] = int64(nextInt(inputData, scanPos))
  let nodeCapacity = 4 * elementCount + 5
  segmentSum = newSeq[int64](nodeCapacity)
  segmentSquareSum = newSeq[int64](nodeCapacity)
  hasPendingSet = newSeq[bool](nodeCapacity)
  pendingSetValue = newSeq[int64](nodeCapacity)
  pendingAddValue = newSeq[int64](nodeCapacity)
  buildTree(1, 1, elementCount)
  appendOutput("Case " & $(caseIndex + 1) & ":\n")
  for operationIndex in 0 .. operationCount - 1:
    let operationType = nextInt(inputData, scanPos)
    let updateLeft = nextInt(inputData, scanPos)
    let updateRight = nextInt(inputData, scanPos)
    if operationType == 2:
      appendOutput($queryRange(1, 1, elementCount, updateLeft, updateRight))
      outputBuffer.add '\n'
    else:
      let updateValue = int64(nextInt(inputData, scanPos))
      updateRange(1, 1, elementCount, updateLeft, updateRight, operationType, updateValue)
stdout.write outputBuffer
outputBuffer.setLen 0
```

Each case allocates fresh tree arrays of size 4N + 5.
The case header is written before its answers.
Query lines are buffered with every other output line.

## Complexity

Building is linear, and each operation touches one root-to-leaf path per side.

| phase | time | space |
|---|---|---|
| input read | one pass over all tokens | one input string |
| tree build | O(N) | 4N nodes |
| each operation | O(log N) | recursion stack |
| output | one line per query | block buffer |

| measure | Big O |
|---|---|
| time | O(N + Q log N) per case |
| space | O(N) |

A plain array would rescan the range on every operation and cost O(N · Q) per case. Lazy propagation keeps both updates and queries near logarithmic cost.
