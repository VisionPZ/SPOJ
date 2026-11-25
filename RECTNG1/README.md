# RECTNG1 — Rectangles (SPOJ)

<https://www.spoj.com/problems/RECTNG1/>

## Problem

Axis-aligned rectangles form one group when they share a segment of positive length. Count the separate groups formed by the given rectangles.

Input: `t` cases separated by blank lines. Each starts with `n`, then `n` lines `x1 y1 x2 y2`, the bottom-left and top-right corners. Output: one integer per case, the number of separate blocks.

The bounds from the statement:

| Item | Bound |
|---|---|
| Rectangles `n` | 1 ≤ n ≤ 7000 |
| Coordinates | non-negative integers ≤ 10000 |
| Judge limit | 1279 ms, 1536 MB |

A shared point does not join two rectangles; a shared segment does.

The sample input and output:

```
1
9
0 3 2 6
4 5 5 7
4 2 6 4
2 0 3 2
5 3 6 4
3 2 5 3
1 4 4 7
0 0 1 4
0 0 4 1
```

```
2
```

## Idea

Group rectangles like overlapping rubber stamps, then count the distinct ink islands. Sort by left edge so neighbours sit next to each other in the scan.

For rectangle `i`, walk later rectangles `j` while `rects[j].x1 ≤ rects[i].x2`. Unite `i` and `j` when their y-intervals overlap with positive length, or their x-intervals overlap with positive length. A union-find table (a structure that merges groups and finds their representative) tracks the groups.

Sorting costs O(n log n). The inner scan stops as soon as a rectangle starts right of `i`, so it skips most pairs.

Sorting by left edge gives the overlap search an early exit.

## Why It Works

Four facts carry the grouping.

1. Two axis-aligned rectangles share a segment when they overlap in one axis and touch or overlap in the other.
2. `verticalOverlap = min(y2) − max(y1)` and `horizontalOverlap = min(x2) − max(x1)`. A positive value in either quantity means a shared segment.
3. Sorting by `x1` makes the inner loop stop once `rects[j].x1 > rects[i].x2`. Rectangles further right cannot meet `i`.
4. Union-find merges groups in near-constant time. Counting roots after all unions gives the block count.

The fields and helpers:

| Term | Meaning |
|---|---|
| `Rectangle` | four integer coordinates of one box |
| `compareRect` | ordering by bottom-left x |
| `findRoot` | union-find representative of a group |
| `blockCount` | number of distinct roots |

A positive overlap in either axis is enough to merge two rectangles.

A script-traced example with three rectangles:

```
A: 0 0 2 2
B: 2 0 4 2   verticalOverlap = 2, horizontalOverlap = 0 -> shared edge -> unite
C: 6 0 7 2   B.x2 = 4 < C.x1 = 6 -> inner loop breaks

distinct roots = 2 blocks
```

The nine sample rectangles form two separate blocks in the same way.

## Code

**Setup and scanner.** The input is read once into one buffer.

```nim
{.passC: "-O3".}
{.push checks: off.}

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
```

The header lines set up fast execution. `nextInt` scans the buffer by index and skips blank lines between cases.

**Output helper and rectangle order.** Results buffer, and rectangles sort by left edge.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

type Rectangle = object
  x1: int
  y1: int
  x2: int
  y2: int

proc compareRect(left, right: Rectangle): int =
  if left.x1 < right.x1: result = -1
  elif left.x1 > right.x1: result = 1
  else: result = 0
```

`appendOutput` adds a newline and flushes at 256 KiB. `compareRect` orders rectangles by `x1`, which drives the early break.

**Union-find.** `findRoot` compresses paths, and `unite` merges by rank.

```nim
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

Ranks keep the trees shallow. The first loop in `findRoot` climbs to the root, and the second rewrites visited pointers. Merging groups costs near-constant time.

**Case loop.** Rectangles are read, sorted, compared, then counted.

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

The inner loop breaks when `rects[j].x1 > rects[i].x2`. Either positive overlap calls `unite(i, j)`. The final pass counts one block per root.

## Complexity

Each case sorts rectangles, then scans nearby pairs and counts roots.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Sort | O(n log n) | O(n) |
| Overlap scan | up to O(n²) pairs, cut by x break | O(n) |
| Union-find | near-constant per merge | O(n) |
| Output | one write per 256 KiB block | 256 KiB |
| Total per case | O(n log n + n²) worst case | O(n) |

At `n = 7000` the worst-case scan still fits the limit.

| Measure | Big O |
|---|---|
| Time | O(n²) worst case, O(n log n) when overlaps are sparse |
| Space | O(n) for rectangles and union-find arrays |

Skipping the sort keeps the same O(n²) bound but removes the early exit.

Checking every pair without sorting touches all n² pairs. Sorting lets most scans stop after a few rectangles.
