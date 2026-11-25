# GSS5 — Can you answer these queries V (SPOJ)

<https://www.spoj.com/problems/GSS5/>

## Problem

Given a sequence of signed integers, answer queries that ask for the largest subarray sum whose start and end lie in two overlapping index ranges. Each query gives start range `[x1,y1]` and end range `[x2,y2]` with `x1 <= x2` and `y1 <= y2`.

Input starts with the number of test cases. Each case gives N, the N sequence values, M, then M lines of four integers `x1 y1 x2 y2`. Output one answer per query, in order.

| item | bound |
|---|---|
| test cases | up to 5 |
| sequence length N | 1 to 10000 |
| queries M | 1 to 10000 |
| value magnitude | at most 10000 |
| judge limit | 1000 ms, 1536 MB |

Both N and M reach 10000, so each query needs logarithmic work.

Sample input:

```
2
6 3 -2 1 -4 5 2
2
1 1 2 3
1 3 2 5
1 1
1
1 1 1 1
```

Sample output:

```
2
3
1
```

## Idea

Think of each range as a bucket holding candidate start and end points, like picking a doorway and an exit in two neighbouring halls. A segment tree reports four numbers for any interval: total sum, best prefix, best suffix, and best subarray. Three cleverly chosen combinations cover every legal start and end pair.

A scan over all start and end pairs would cost quadratic time per query, which is too slow at M = 10000.

## Why It Works

1. A segment node stores sum, best prefix, best suffix, and best subarray for its interval.
2. Joining two nodes combines prefix, suffix, and subarray with one formula each.
3. When `y1 < x2`, every legal subarray spans the gap, so suffix plus gap sum plus prefix is exact.
4. When the ranges overlap, a subarray starts before `x2`, lies inside the overlap, or ends after `y1`.
5. Those three cases cover every legal start and end pair, and the largest value among them is the answer.

| term | meaning |
|---|---|
| `SegNode` | the four aggregate values of one interval |
| `joinNodes` | merge of two adjacent interval nodes |
| `suffixBest` | largest sum of a suffix of an interval |
| `prefixBest` | largest sum of a prefix of an interval |
| `overlapRight` | later of the two right bounds that still allows `i <= j` |

The first sample query has `y1 < x2`, so the gap sum is added once:

```
suffix [1,1] = 3
gap [2,1] = 0
prefix [2,3] = -1
answer = 3 + 0 - 1 = 2
```

The second query overlaps, so the three candidates are 3, 1, and 3, giving answer 3.

## Code

**Input and node join.** The scanner handles negative values, and the node merge keeps four aggregates.

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
  var signValue = 1
  if pos < data.len and data[pos] == '-':
    signValue = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return signValue * value

type SegNode = tuple[sumValue: int64, prefixBest: int64, suffixBest: int64, subBest: int64]

proc joinNodes(leftNode, rightNode: SegNode): SegNode =
  result.sumValue = leftNode.sumValue + rightNode.sumValue
  if leftNode.prefixBest > leftNode.sumValue + rightNode.prefixBest:
    result.prefixBest = leftNode.prefixBest
  else:
    result.prefixBest = leftNode.sumValue + rightNode.prefixBest
  if rightNode.suffixBest > rightNode.sumValue + leftNode.suffixBest:
    result.suffixBest = rightNode.suffixBest
  else:
    result.suffixBest = rightNode.sumValue + leftNode.suffixBest
  result.subBest = leftNode.subBest
  if rightNode.subBest > result.subBest:
    result.subBest = rightNode.subBest
  if leftNode.suffixBest + rightNode.prefixBest > result.subBest:
    result.subBest = leftNode.suffixBest + rightNode.prefixBest
```

The minus branch is needed because values are signed.
All aggregates use int64 to avoid overflow across long intervals.
The merge runs in constant time.

**Tree construction and range query.** Build once per case, then split each query at the segment boundary.

```nim
var inputValues = newSeq[int](0)
var treeNodes: seq[SegNode]
var treeSize = 0

proc buildTree(nodeIndex, leftBound, rightBound: int) =
  if leftBound == rightBound:
    let singleValue = int64(inputValues[leftBound])
    treeNodes[nodeIndex].sumValue = singleValue
    treeNodes[nodeIndex].prefixBest = singleValue
    treeNodes[nodeIndex].suffixBest = singleValue
    treeNodes[nodeIndex].subBest = singleValue
    return
  let middle = (leftBound + rightBound) div 2
  buildTree(nodeIndex * 2, leftBound, middle)
  buildTree(nodeIndex * 2 + 1, middle + 1, rightBound)
  treeNodes[nodeIndex] = joinNodes(treeNodes[nodeIndex * 2], treeNodes[nodeIndex * 2 + 1])

proc queryTree(nodeIndex, leftBound, rightBound, queryLeft, queryRight: int): SegNode =
  if queryLeft <= leftBound and rightBound <= queryRight:
    return treeNodes[nodeIndex]
  let middle = (leftBound + rightBound) div 2
  if queryRight <= middle:
    return queryTree(nodeIndex * 2, leftBound, middle, queryLeft, queryRight)
  if queryLeft > middle:
    return queryTree(nodeIndex * 2 + 1, middle + 1, rightBound, queryLeft, queryRight)
  let leftPart = queryTree(nodeIndex * 2, leftBound, middle, queryLeft, queryRight)
  let rightPart = queryTree(nodeIndex * 2 + 1, middle + 1, rightBound, queryLeft, queryRight)
  return joinNodes(leftPart, rightPart)
```

Leaves hold one value each.
A full cover returns the stored node directly.
A split query joins two partial results.

**Answer loop.** Three candidates handle disjoint ranges and the two overlap shapes.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  treeSize = nextInt(inputData, scanPos)
  inputValues = newSeq[int](treeSize + 1)
  for position in 1 .. treeSize:
    inputValues[position] = nextInt(inputData, scanPos)
  treeNodes = newSeq[SegNode](4 * treeSize + 5)
  buildTree(1, 1, treeSize)
  let queryCount = nextInt(inputData, scanPos)
  for queryIndex in 0 .. queryCount - 1:
    let firstLeft = nextInt(inputData, scanPos)
    let firstRight = nextInt(inputData, scanPos)
    let secondLeft = nextInt(inputData, scanPos)
    let secondRight = nextInt(inputData, scanPos)
    var answer: int64 = -(1 shl 60)
    if firstRight < secondLeft:
      let leftPart = queryTree(1, 1, treeSize, firstLeft, firstRight)
      let rightPart = queryTree(1, 1, treeSize, secondLeft, secondRight)
      answer = leftPart.suffixBest + rightPart.prefixBest
      if firstRight + 1 <= secondLeft - 1:
        answer = answer + queryTree(1, 1, treeSize, firstRight + 1, secondLeft - 1).sumValue
    else:
      if firstLeft <= secondLeft - 1:
        let leftPart = queryTree(1, 1, treeSize, firstLeft, secondLeft - 1)
        let rightPart = queryTree(1, 1, treeSize, secondLeft, secondRight)
        let candidate = leftPart.suffixBest + rightPart.prefixBest
        if candidate > answer:
          answer = candidate
      var overlapRight = firstRight
      if secondRight < overlapRight:
        overlapRight = secondRight
      let middlePart = queryTree(1, 1, treeSize, secondLeft, overlapRight)
      if middlePart.subBest > answer:
        answer = middlePart.subBest
      if firstRight + 1 <= secondRight:
        let leftPart = queryTree(1, 1, treeSize, firstLeft, firstRight)
        let rightPart = queryTree(1, 1, treeSize, firstRight + 1, secondRight)
        let candidate = leftPart.suffixBest + rightPart.prefixBest
        if candidate > answer:
          answer = candidate
    appendOutput($answer)
    outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The gap sum is added only when a gap exists.
`overlapRight` keeps every subarray end within both ranges.
Output is buffered and flushed once at the end.

## Complexity

Building the tree once per case prepares every query.

| phase | time | space |
|---|---|---|
| input read | one pass over values and queries | one input string |
| tree build | one merge per internal node | four arrays of about 4N nodes |
| query answer | a few O(log N) range queries | block buffer |

The query phase dominates because M reaches 10000.

| measure | Big O |
|---|---|
| time | O((N + M) log N) per case |
| space | O(N) |

A direct scan of all start and end pairs would cost O(N²) per query.
