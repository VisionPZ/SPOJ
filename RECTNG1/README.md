## Problem

Each test case gives n axis-aligned rectangles with integer corners. Two rectangles join one block when their closed regions share a segment of positive length. Print one line per case with the number of separate blocks.

The statement fixes two bounds and leaves the test count open.

| Quantity | Bound |
| --- | --- |
| Rectangles per case | 7000 |
| Corner coordinates | 0 to 10000 |
| Test cases | not bounded |
| Time limit | 1279 ms |
| Memory limit | 1536 MB |

The rectangle count drives the pair scan; the coordinate bound keeps each value small.

## Idea

Sort rectangles by their left x edge and scan pairs in that order. A union-find table (parent links that track groups) merges pairs that share a segment. Each pair costs a few comparisons and at most one union, while an unordered scan tests every pair.

## Why It Works

The shared region of two rectangles is a closed box with integer corners. It holds a segment when both spans meet and one span overlap is positive. A pair that meets at one point only stays separate, because a point is not a segment.

The shared span uses four edge values:

xlo = max of the left x edges
xhi = min of the right x edges
ylo = max of the bottom y edges
yhi = min of the top y edges

The code checks `verticalOverlap` and `horizontalOverlap`. `verticalOverlap` is yhi minus ylo, and `horizontalOverlap` is xhi minus xlo. A pair merges when both spans meet and at least one of those values is positive.

The sample produces these shared spans.

| Pair | Shared span |
| --- | --- |
| 1-7 | x 1..2, y 4..6 |
| 1-8 | x 0..1, y 3..4 |
| 2-7 | x 4..4, y 5..7 |
| 3-5 | x 5..6, y 3..4 |
| 3-6 | x 4..5, y 2..3 |
| 4-9 | x 2..3, y 0..1 |
| 8-9 | x 0..1, y 0..1 |

They form two groups, 1-2-4-7-8-9 and 3-5-6, so the answer is 2.

## Code

```nim
import algorithm

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The read loop ends at EOF and keeps one input buffer. The scanner skips the blank line between cases, so the sample shape is safe. The output buffer flushes at `flushBlockBytes`, which caps memory use.

```nim
type Rectangle = object
  x1: int
  y1: int
  x2: int
  y2: int

proc compareRect(left, right: Rectangle): int =
  if left.x1 < right.x1: result = -1
  elif left.x1 > right.x1: result = 1
  else: result = 0

var parents: seq[int]
var ranks: seq[int]

proc findRoot(node: int): int =
  var root = node
  while parents[root] != root:
    root = parents[root]
  var cursor = node
  while parents[cursor] != cursor:
    let nextNode = parents[cursor]
    parents[cursor] = root
    cursor = nextNode
  return root

proc unite(left, right: int) =
  var rootLeft = findRoot(left)
  var rootRight = findRoot(right)
  if rootLeft == rootRight: return
  if ranks[rootLeft] < ranks[rootRight]: swap(rootLeft, rootRight)
  parents[rootRight] = rootLeft
  if ranks[rootLeft] == ranks[rootRight]: ranks[rootLeft] += 1
```

The rectangle loop reads exactly four integers per rectangle. `findRoot` shortens each path it walks, which keeps chains short. `unite` uses rank to keep trees shallow.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let rectCount = nextInt(inputData, scanPos)
  var rects = newSeq[Rectangle](rectCount)
  for i in 0..<rectCount:
    rects[i].x1 = nextInt(inputData, scanPos)
    rects[i].y1 = nextInt(inputData, scanPos)
    rects[i].x2 = nextInt(inputData, scanPos)
    rects[i].y2 = nextInt(inputData, scanPos)
  parents.setLen(rectCount)
  ranks.setLen(rectCount)
  for i in 0..<rectCount:
    parents[i] = i
    ranks[i] = 0
  rects.sort(compareRect)
  for i in 0..<rectCount:
    if i + 1 >= rectCount: break
    for j in i + 1..<rectCount:
      if rects[j].x1 > rects[i].x2: break
      if rects[j].y1 <= rects[i].y2 and rects[i].y1 <= rects[j].y2:
        let verticalOverlap = min(rects[i].y2, rects[j].y2) - max(rects[i].y1, rects[j].y1)
        let horizontalOverlap = min(rects[i].x2, rects[j].x2) - max(rects[i].x1, rects[j].x1)
        if verticalOverlap > 0 or horizontalOverlap > 0:
          unite(i, j)
  var blockCount = 0
  for i in 0..<rectCount:
    if parents[i] == i: blockCount += 1
  appendOutput($blockCount)

stdout.write outputBuffer
outputBuffer.setLen 0
```

The outer loop runs once per test case. The break ends a row once the next left edge passes the current right edge. Counting roots in `parents` gives the block count in one pass.

## Complexity

Reading costs O(total input bytes) time and the same space. Sorting costs O(n log n) time and O(n) space. The pair scan costs O(n²) time in the worst case and O(1) extra space. Counting roots costs O(n) time. The total is O(n²) time and O(n) space per case.

A full connectivity matrix would use O(n²) space and O(n³) time to close. Union-find keeps only parent links.
