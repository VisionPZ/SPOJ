# GSS3 — Can you answer these queries III (SPOJ)

<https://www.spoj.com/problems/GSS3/>

## Problem

An array holds N integers, some negative. Process M operations: set one position to a new value, or report the largest sum of any nonempty contiguous block inside a queried range.

Input gives N, then N array values, then M, then M operation lines. Operation `0 x y` sets position x to y. Operation `1 x y` asks for the best subarray sum between x and y, both included. Print one answer per query.

| item | bound |
|---|---|
| array size N | at most 50000 |
| operations M | at most 50000 |
| array and update values | -10000 to 10000 |
| judge limit | 1000 ms, 1536 MB |

Both size bounds reach 50000, so a linear rescan per query cannot fit the limit.

Sample input:

```
4
1 2 3 4
4
1 1 3
0 3 -3
1 2 4
1 3 3
```

Sample output:

```
6
4
-3
```

## Idea

Store four numbers at each segment-tree node, like keeping a receipt for each shop segment: total, best prefix, best suffix, and best inside block. Joining two neighboring segments is one fixed formula, so both updates and range queries follow the tree path. Each operation costs logarithmic time. Rescanning a whole queried range costs linear time per query and disappears at 50000 operations. Takeaway: make the merge rule rich enough that one tree walk answers the whole question.

## Why It Works

1. Every node describes one contiguous slice of the array.
2. The best prefix either stays in the left child or crosses into the right child.
3. The best suffix is symmetric, and the best inside block either lies in one child or crosses the join.
4. Combining child states needs only the four stored values, so a parent stays correct after any leaf change.
5. A range query joins the covered nodes in order, applying the same rule repeatedly.

| term | meaning |
|---|---|
| `totalSum` | sum of every value in the node |
| `prefixBest` | largest sum starting at the node's left edge |
| `suffixBest` | largest sum ending at the node's right edge |
| `subarrayBest` | largest sum of any block inside the node |
| `combineNodes` | rule that merges two adjacent node states |

The generator checks every query with an independent linear scan, so negative and crossing blocks are covered.

## Code

**Input and scanning.** One buffer holds the whole input, and the scanner accepts minus signs.

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
```

The minus branch is needed for array values and updates.
The scanner tracks one position in the input buffer.
No token list is materialised.

**Node merge.** Four fields capture everything needed to join two slices.

```nim
type
  SegmentData = object
    totalSum: int64
    prefixBest: int64
    suffixBest: int64
    subarrayBest: int64

var sumTree: seq[int64]
var prefixTree: seq[int64]
var suffixTree: seq[int64]
var subarrayTree: seq[int64]
var values: seq[int64]

proc combineNodes(leftData, rightData: SegmentData): SegmentData =
  result.totalSum = leftData.totalSum + rightData.totalSum
  result.prefixBest = max(leftData.prefixBest, leftData.totalSum + rightData.prefixBest)
  result.suffixBest = max(rightData.suffixBest, rightData.totalSum + leftData.suffixBest)
  result.subarrayBest = max(max(leftData.subarrayBest, rightData.subarrayBest),
                            leftData.suffixBest + rightData.prefixBest)
```

Sums use int64 to leave room beyond the stated value range.
A crossing block uses the left suffix plus the right prefix.
The merge runs in constant time.

**Tree build, update, and query.** Recursion keeps each operation on one root-to-leaf path.

```nim
proc readNode(nodeIndex: int): SegmentData =
  result.totalSum = sumTree[nodeIndex]
  result.prefixBest = prefixTree[nodeIndex]
  result.suffixBest = suffixTree[nodeIndex]
  result.subarrayBest = subarrayTree[nodeIndex]

proc storeNode(nodeIndex: int, nodeData: SegmentData) =
  sumTree[nodeIndex] = nodeData.totalSum
  prefixTree[nodeIndex] = nodeData.prefixBest
  suffixTree[nodeIndex] = nodeData.suffixBest
  subarrayTree[nodeIndex] = nodeData.subarrayBest

proc buildTree(nodeIndex, leftEdge, rightEdge: int) =
  if rightEdge - leftEdge == 1:
    let leafValue = values[leftEdge]
    storeNode(nodeIndex, SegmentData(totalSum: leafValue, prefixBest: leafValue,
                                     suffixBest: leafValue, subarrayBest: leafValue))
    return
  let middle = (leftEdge + rightEdge) div 2
  buildTree(nodeIndex * 2, leftEdge, middle)
  buildTree(nodeIndex * 2 + 1, middle, rightEdge)
  storeNode(nodeIndex, combineNodes(readNode(nodeIndex * 2), readNode(nodeIndex * 2 + 1)))

proc updateTree(nodeIndex, leftEdge, rightEdge, changedIndex: int, newValue: int64) =
  if rightEdge - leftEdge == 1:
    storeNode(nodeIndex, SegmentData(totalSum: newValue, prefixBest: newValue,
                                     suffixBest: newValue, subarrayBest: newValue))
    return
  let middle = (leftEdge + rightEdge) div 2
  if changedIndex < middle:
    updateTree(nodeIndex * 2, leftEdge, middle, changedIndex, newValue)
  else:
    updateTree(nodeIndex * 2 + 1, middle, rightEdge, changedIndex, newValue)
  storeNode(nodeIndex, combineNodes(readNode(nodeIndex * 2), readNode(nodeIndex * 2 + 1)))

proc queryTree(nodeIndex, leftEdge, rightEdge, queryLeft, queryRight: int): SegmentData =
  if queryLeft <= leftEdge and rightEdge <= queryRight:
    return readNode(nodeIndex)
  let middle = (leftEdge + rightEdge) div 2
  if queryRight <= middle:
    return queryTree(nodeIndex * 2, leftEdge, middle, queryLeft, queryRight)
  if queryLeft >= middle:
    return queryTree(nodeIndex * 2 + 1, middle, rightEdge, queryLeft, queryRight)
  let leftData = queryTree(nodeIndex * 2, leftEdge, middle, queryLeft, queryRight)
  let rightData = queryTree(nodeIndex * 2 + 1, middle, rightEdge, queryLeft, queryRight)
  return combineNodes(leftData, rightData)
```

The build visits every leaf once.
An update recomputes only nodes on its path.
A query joins the covered nodes in left-to-right order.

**Driver and output.** Operations are decoded and answers are buffered.

```nim
let elementCount = nextInt(inputData, scanPos)
values = newSeq[int64](elementCount)
for elementIndex in 0 .. elementCount - 1:
  values[elementIndex] = int64(nextInt(inputData, scanPos))
let treeCapacity = 4 * elementCount + 5
sumTree = newSeq[int64](treeCapacity)
prefixTree = newSeq[int64](treeCapacity)
suffixTree = newSeq[int64](treeCapacity)
subarrayTree = newSeq[int64](treeCapacity)
buildTree(1, 0, elementCount)

let operationCount = nextInt(inputData, scanPos)
for operationIndex in 0 .. operationCount - 1:
  let operationType = nextInt(inputData, scanPos)
  let firstIndex = nextInt(inputData, scanPos) - 1
  let secondValue = nextInt(inputData, scanPos)
  if operationType == 0:
    values[firstIndex] = int64(secondValue)
    updateTree(1, 0, elementCount, firstIndex, int64(secondValue))
  else:
    let answer = queryTree(1, 0, elementCount, firstIndex, secondValue).subarrayBest
    appendOutput($answer)
    outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Indices from the input are converted to zero-based positions.
Updates change the leaf and its ancestors.
The output buffer flushes once after all operations.

## Complexity

Each tree operation follows at most a logarithmic number of nodes.

| phase | time | space |
|---|---|---|
| input read | one pass over input bytes | one input string |
| tree build | one merge per internal node | four arrays of size 4N |
| point update | one path of merges | constant extra |
| range query | covered nodes joined in order | recursion stack |
| output | one line per query | block buffer |

| measure | Big O |
|---|---|
| time | O(N + M log N) |
| space | O(N) |

A linear rescan for each query would cost O(MN), far above the tree cost at the upper bounds.
