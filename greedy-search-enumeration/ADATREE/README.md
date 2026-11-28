# ADATREE — Ada and Trees (SPOJ)

<https://www.spoj.com/problems/ADATREE/>

## Problem

For each range of trees, report the tallest tree inside it whose height does not exceed a given limit. Report zero when no tree in the range qualifies.

The input starts with `N` trees and `Q` questions. The next line holds `N` heights. Each question line holds a left index, a right index, and a height limit. Both indexes are inclusive and start at zero. Print one answer per question in input order.

| Item | Bound |
|---|---|
| Trees N | 1 to 300000 |
| Questions Q | 1 to 300000 |
| Tree height | 0 to 1000000 |
| Height limit | 0 to 1000000 |
| Judge limit | 3000 ms, 1536 MB |

A zero-height tree never beats the required zero answer.

The sample case has nine trees:

```
9 8
1 5 9 11 9 7 6 2 1
1 6 4
1 6 10
0 8 97
0 8 4
1 4 5
2 6 8
2 8 5
3 3 12
```

The expected output is:

```
0
9
11
2
5
7
2
11
```

## Idea

Raise a height dial from zero upward and pin each tree onto a shelf the moment its height becomes allowed, like filing cards when their label turns green. Use an offline sweep with buckets and a segment tree over tree positions. Each insertion updates one leaf, and each question reads one range maximum. Sorting by height is replaced by buckets, because heights and limits fit in a million slots.

## Why It Works

1. At dial value `H`, the segment tree stores each tree's height only when that height is at most `H`.
2. Every tree with height `H` is inserted before questions with limit `H` are answered.
3. A range maximum over the tree returns the tallest allowed tree in that range.
4. A tree above the limit stays absent and cannot win the maximum.
5. Answers are stored by question index, so output order matches input order.

| Term | Meaning |
|---|---|
| `pointHead` | first tree of each height, using index plus one as a sentinel |
| `questionHead` | first question of each height limit |
| `tree` | iterative segment tree holding current allowed heights |
| `queryTree` | range maximum over inclusive positions |

The segment tree keeps one leaf per tree position.

A short trace with the sample questions:

```
dial 4, range 1..6: allowed heights 1 only, answer 0
dial 10, range 1..6: allowed 1,5,9,9,7, answer 9
dial 97, range 0..8: allowed all nine, answer 11
dial 4, range 0..8: allowed 1,2,1, answer 2
dial 5, range 1..4: allowed 1,5, answer 5
```

The trace reproduces the first five sample outputs.

## Code

**Input and scanning.** The reader loads all lines, and the sentinel supports more than one case.

```nim
const flushBlockBytes = 1 shl 17
const maxHeight = 1000000

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

proc hasNextNumber(data: string, pos: int): bool =
  var cursor = pos
  while cursor < data.len and (data[cursor] < '0' or data[cursor] > '9'):
    cursor += 1
  return cursor < data.len

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The scanner skips line breaks in any input layout.
One output buffer serves all answer lines.
Large outputs are flushed in blocks.

**Segment tree.** A leaf change is pushed up to every covering node.

```nim
proc updateTree(tree: var seq[int], treeSize: int, position: int, value: int) =
  var index = position + treeSize
  tree[index] = value
  index = index div 2
  while index >= 1:
    let leftValue = tree[index * 2]
    let rightValue = tree[index * 2 + 1]
    if leftValue > rightValue:
      tree[index] = leftValue
    else:
      tree[index] = rightValue
    index = index div 2

proc queryTree(tree: seq[int], treeSize: int, leftEnd: int, rightEnd: int): int =
  var leftIndex = leftEnd + treeSize
  var rightIndex = rightEnd + treeSize
  var bestValue = 0
  while leftIndex <= rightIndex:
    if (leftIndex and 1) == 1:
      if tree[leftIndex] > bestValue:
        bestValue = tree[leftIndex]
      leftIndex += 1
    if (rightIndex and 1) == 0:
      if tree[rightIndex] > bestValue:
        bestValue = tree[rightIndex]
      rightIndex -= 1
    leftIndex = leftIndex div 2
    rightIndex = rightIndex div 2
  return bestValue
```

The tree size is the next power of two.
Both walks touch only logarithmically many nodes.
An empty or zero-only range returns zero.

**Bucket build.** Trees and questions are grouped by their height value.

```nim
while hasNextNumber(inputData, scanPos):
  let treeLength = nextInt(inputData, scanPos)
  let questionCount = nextInt(inputData, scanPos)
  var pointHead = newSeq[int](maxHeight + 1)
  var pointNext = newSeq[int](treeLength)
  for position in 0 .. treeLength - 1:
    let height = nextInt(inputData, scanPos)
    pointNext[position] = pointHead[height]
    pointHead[height] = position + 1
  var questionHead = newSeq[int](maxHeight + 1)
  var questionNext = newSeq[int](questionCount)
  var leftEnd = newSeq[int](questionCount)
  var rightEnd = newSeq[int](questionCount)
  for questionIndex in 0 .. questionCount - 1:
    let leftPosition = nextInt(inputData, scanPos)
    let rightPosition = nextInt(inputData, scanPos)
    let heightLimit = nextInt(inputData, scanPos)
    leftEnd[questionIndex] = leftPosition
    rightEnd[questionIndex] = rightPosition
    questionNext[questionIndex] = questionHead[heightLimit]
    questionHead[heightLimit] = questionIndex + 1
  var treeSize = 1
  while treeSize < treeLength:
    treeSize = treeSize * 2
  var tree = newSeq[int](treeSize * 2)
  var answer = newSeq[int](questionCount)
```

Index plus one keeps zero as the list terminator.
Question arrays preserve both ends and the original order.
The tree starts empty, so every leaf value is zero.

**Height sweep.** Insertions come before questions of the same dial value.

```nim
  for height in 0 .. maxHeight:
    var pointLink = pointHead[height]
    while pointLink != 0:
      let position = pointLink - 1
      updateTree(tree, treeSize, position, height)
      pointLink = pointNext[position]
    var questionLink = questionHead[height]
    while questionLink != 0:
      let questionIndex = questionLink - 1
      answer[questionIndex] = queryTree(tree, treeSize, leftEnd[questionIndex], rightEnd[questionIndex])
      questionLink = questionNext[questionIndex]
  for questionIndex in 0 .. questionCount - 1:
    appendOutput($answer[questionIndex])
    outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

A tree of height zero adds no visible value.
All questions of one limit see the same tree state.
The final flush writes every buffered answer line.

## Complexity

The height dial scans a fixed limit, and each tree or question moves once.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over trees and questions | one input string |
| Bucket build | O(N + Q) | one link per item |
| Height sweep | O(V + (N + Q) log N) | segment tree of 2S nodes |
| Output | one buffered pass over Q lines | block buffer |

`V` is one million and `S` is the next power of two above `N`.

| Measure | Big O |
|---|---|
| Time | O(V + (N + Q) log N) |
| Space | O(V + N + Q + S) |

Scanning all heights costs a fixed million steps for any input size.
A brute scan of the range for every question would cost O(Q × N) instead.
