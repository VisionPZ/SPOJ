## Problem

Read a clockwise orthogonal polygon drawn on an integer grid. Its wall is a list of signed section lengths. Choose the fewest streets, where a street is a maximal straight grid line inside the city, so that every street sees a patrolled street and each patrolled street meets another one. Print the count for each test case.

| Quantity | Bound |
| --- | --- |
| Test cases | not bounded in the statement |
| Wall sections per case | 4 to 2000 |
| Section length | 1 to 100000 |
| Time limit | 2125 ms |
| Memory limit | 1536 MB |

The section count drives the grid construction, and each answer stays small.

## Idea

Compress the wall coordinates into a grid and flood the outside to find the maximal streets. A chosen street covers every perpendicular street it crosses. The minimum set of patrolled streets splits into two independent parts: vertical streets that cross every horizontal street, and horizontal streets that cross every vertical street. Each part is a set cover over crossing streets, solved by branch and bound.

Each grid cell costs one flood step, and each cover search costs a small branch tree.

## Why It Works

A street sees another street exactly when they cross inside the city. A point on an unpatrolled street sees a patrolled point at the crossing, so crossing a chosen street covers the whole unchosen street.

The chosen vertical set must cross every horizontal street. The chosen horizontal set must cross every vertical street. Let A be the first set and B the second. Each chosen vertical street crosses a member of B, and each chosen horizontal street crosses a member of A. Therefore no chosen street is isolated, and every street is covered. The two covers are independent, so their sizes add.

The worked sample has 6 vertical streets and 7 horizontal streets after compression. Vertical streets at x=2 and x=6 cross all 7 horizontal streets. Horizontal streets at y=-4 and y=0 cross all 6 vertical streets. The answer is 2 + 2 = 4.

A script in gen.py prints 6 7 4 for this polygon.

## Code

```nim
var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextSigned(data: string, pos: var int): int =
  while pos < data.len and data[pos] != '-' and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var signValue = 1
  if pos < data.len and data[pos] == '-':
    signValue = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return signValue * value
```

The loop reads every line into one buffer. The scanner skips separators and keeps the minus sign, since section lengths can be negative. Reading and scanning touch the whole input once.

```nim
  var vWall = newSeq[bool](width * height)
  var hWall = newSeq[bool](width * height)
  var x = 0
  var y = 0
  for i in 0..<lengths.len:
    let step = lengths[i]
    let vertical = ((i mod 2) == 0) == startVertical
    let oldX = x
    let oldY = y
    if vertical:
      y += step
    else:
      x += step
    if vertical:
      let ix = indexOf(xCoords, x)
      let lo = min(oldY, y)
      let hi = max(oldY, y)
      for j in 0..<height - 1:
        if yCoords[j] >= lo and yCoords[j + 1] <= hi:
          vWall[ix * height + j] = true
    else:
      let jy = indexOf(yCoords, y)
      let lo = min(oldX, x)
      let hi = max(oldX, x)
      for k in 0..<width - 1:
        if xCoords[k] >= lo and xCoords[k + 1] <= hi:
          hWall[k * height + jy] = true
  var reached = newSeq[bool](width * height)
  floodFill(reached, vWall, hWall, width, height)
```

The loop marks each wall section on the compressed grid. Taking min and max handles sections that go south or west. The flood marks outside cells, so unmarked cells are inside. The cost is one pass over the wall sections plus one pass over the grid.

```nim
  for ix in 1..<width - 1:
    var runStart = -1
    for j in 0..<height - 1:
      let present = (not reached[(ix - 1) * height + j]) or (not reached[ix * height + j])
      if present:
        if runStart == -1:
          runStart = j
      else:
        if runStart != -1:
          vSegX.add xCoords[ix]
          vSegLow.add yCoords[runStart]
          vSegHigh.add yCoords[j]
          runStart = -1
```

A vertical street exists where a cell on either side is inside. A maximal run of such strips becomes one street with low and high y values. The same scan handles horizontal streets. Each grid line is visited once.

```nim
  proc search(uncovered: seq[bool], depth: int) =
    if depth + packingBound(uncovered) >= bestGlobal:
      return
    var pivot = -1
    var pivotSize = 999999
    for i in 0..<universeCount:
      if uncovered[i] and universe[i].len < pivotSize:
        pivotSize = universe[i].len
        pivot = i
```

The search picks the uncovered street with the fewest crossing partners. The packing bound counts streets with disjoint partner sets and prunes branches that cannot beat the best cover. A greedy run gives the first upper bound.

```nim
  let firstPart = minCoverCount(coverByV, coverByH, vSpans, vCount)
  let secondPart = minCoverCount(coverByH, coverByV, hSpans, hCount)
  appendOutput($(firstPart + secondPart))
  outputBuffer.add '\n'
```

The two covers are computed on swapped crossing lists, then added. One buffer holds all answers and flushes in large blocks. The two searches dominate the work per case.

## Complexity

Grid construction marks O(n) sections over O(n^2) compressed cells, and the flood visits each cell once. Street extraction visits O(n^2) cells. The crossing lists take O(v * h) time, with v and h both at most O(n). Each cover search explores a small branch tree with a packing bound, bounded by O(2^k) for an answer of k. Total time is O(n^2 + 2^k), and total space is O(n^2).

A naive trial over every subset of streets would cost O(2^(v+h)) time per case.
