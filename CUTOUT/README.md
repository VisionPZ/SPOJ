# CUTOUT — Cutting out (SPOJ)
<https://www.spoj.com/problems/CUTOUT/>

## Problem

A sheet of paper already has holes cut from it.
The task is to find the largest rectangle of paper that remains.

Read several square sheets with axis-aligned rectangles already removed.
Each dataset gives square side `n` and cut count `r`.
The next line holds `4r` coordinates.
Each cut gives a left, right, bottom, and top distance from the square edges.
The right and left values may arrive in either order.
Print one integer per dataset: the largest area that fits in the remaining paper.

The judge bounds follow.

| Item | Bound |
| --- | --- |
| Datasets | at most 10 |
| Square side `n` | 1 to 40000 |
| Cut rectangles `r` | 0 to 100 |
| Cut coordinates | 0 to `n` |
| Time limit | 5000 ms |
| Memory limit | 1536 MB |

The small cut count keeps the compressed grid tiny.

The sample input and expected output follow verbatim.

```
2
6 2
0 3 0 3 3 6 3 6
10 3
0 5 0 5 0 10 5 10 9 10 0 5
```

```
9
20
```

The two sheets give answers of 9 and 20.

## Idea

Only cut edges and the square border can bound an optimal rectangle, like fence posts around a field.
Coordinate compression (replacing each coordinate by its rank) turns the square into at most 201 by 201 cells.

Mark each compressed cell covered by a cut.
A monotone stack then finds the widest free rectangle ending at each row.
`upHeights` stores the vertical run of free cells in each column.

Cost per cell is constant work in the histogram (column heights) sweep.
A full grid would hold 1.6 billion cells.
Compress first, then sweep once over the small grid.

## Why It Works

Four facts prove the method.

1. If a side sat inside an empty interval, moving it outward would keep the rectangle empty and increase its area.
   So every side touches a cut edge or the square border.
2. Sorting cut coordinates and the two borders gives cells between consecutive values.
   Every cut covers one contiguous block of cells.
3. `blocked[xi * yCellCount + yi]` marks a cell inside a cut.
   `prefixWidths` returns any span width with one subtraction.
4. `upHeights[xi]` stores the free run ending at the current y row.
   The stack pops each bar once, so one row costs linear time.

The terms of the weighted histogram follow.

| Term | Meaning |
| --- | --- |
| `xCoords`, `yCoords` | sorted unique cut edges plus borders 0 and `n` |
| `xCellCount`, `yCellCount` | coordinate count minus one |
| `leftEdge` | first x cell of the popped span |
| `spanWidth` | `prefixWidths[i] - prefixWidths[leftEdge]` |

Height times span width gives the candidate area.

A script expands the first sample dataset and prints one line per row.

```
Square 6 by 6; cuts [0,3]x[0,3] and [3,6]x[3,6].
x edges: 0 3 6   widths: 3 3
y edges: 0 3 6   heights: 3 3
blocked cells: (0,0) (1,1)
row 0 upHeights: 0 3   best area 9
row 1 upHeights: 3 0   best area 9
answer: 9
```

The largest area over all rows is 9, which matches the sample.

## Code

**Integer scanner.**

```nim
const flushBlockBytes = 1 shl 18

proc nextInt(inputData: string, i: var int): int =
  while i < inputData.len and inputData[i] <= ' ':
    i = i + 1
  var value = 0
  while i < inputData.len and inputData[i] >= '0' and inputData[i] <= '9':
    value = value * 10 + int(inputData[i]) - 48
    i = i + 1
  return value
```

The digit loop runs once per digit, at most five here. It skips spaces and newlines, so a short coordinate line causes no error. The scanner allocates no temporary strings.

**Coordinate helpers.**

```nim
proc sortValues(values: var seq[int]) =
  if values.len < 2: return
  for i in 1 ..< values.len:
    var key = values[i]
    var j = i - 1
    while j >= 0 and values[j] > key:
      values[j + 1] = values[j]
      j = j - 1
    values[j + 1] = key

proc uniqueSorted(values: seq[int]): seq[int] =
  var deduped: seq[int]
  for value in values:
    if deduped.len == 0 or deduped[deduped.len - 1] != value:
      deduped.add value
  return deduped

proc findIndex(values: seq[int], target: int): int =
  var low = 0
  var high = values.len - 1
  while low <= high:
    var middle = (low + high) div 2
    if values[middle] == target: return middle
    if values[middle] < target: low = middle + 1
    else: high = middle - 1
  return low
```

sortValues inserts at most 201 values into order. uniqueSorted keeps only distinct boundaries. findIndex binary-searches a coordinate in about eight comparisons. These helpers map each cut onto cell indices.

**Weighted histogram.**

```nim
proc largestWeightedRectangle(heights, prefixWidths: seq[int], columnCount: int, stack: var seq[int]): int =
  var bestArea = 0
  stack.setLen 0
  for i in 0 ..< columnCount:
    var currentHeight = heights[i]
    while stack.len > 0 and heights[stack[stack.len - 1]] >= currentHeight:
      var j = stack[stack.len - 1]
      stack.setLen stack.len - 1
      var leftEdge = (if stack.len > 0: stack[stack.len - 1] + 1 else: 0)
      var spanWidth = prefixWidths[i] - prefixWidths[leftEdge]
      var area = heights[j] * spanWidth
      if area > bestArea: bestArea = area
    stack.add i
  while stack.len > 0:
    var j = stack[stack.len - 1]
    stack.setLen stack.len - 1
    var leftEdge = (if stack.len > 0: stack[stack.len - 1] + 1 else: 0)
    var spanWidth = prefixWidths[columnCount] - prefixWidths[leftEdge]
    var area = heights[j] * spanWidth
    if area > bestArea: bestArea = area
  return bestArea
```

The column loop runs at most 201 times. Popping on a height greater than or equal to the current one merges equal bars. Each bar enters and leaves the stack once. One row therefore costs linear time.

**Input setup.**

```nim
var inputData: string
var line: string
while readLine(stdin, line):
  inputData.add line
  inputData.add "\n"

var i = 0
var caseCount = nextInt(inputData, i)
var outputBuffer: string
```

The read loop appends every input line to one buffer. The program scans that buffer once. One output buffer holds answers until a block is full.

**Mark the cut cells.**

```nim
for l in 1 .. caseCount:
  var squareSize = nextInt(inputData, i)
  var rectangleCount = nextInt(inputData, i)
  var cutLefts = newSeq[int](rectangleCount)
  var cutRights = newSeq[int](rectangleCount)
  var cutBottoms = newSeq[int](rectangleCount)
  var cutTops = newSeq[int](rectangleCount)
  var xCoords: seq[int] = @[0, squareSize]
  var yCoords: seq[int] = @[0, squareSize]
  for k in 0 ..< rectangleCount:
    var first = nextInt(inputData, i)
    var second = nextInt(inputData, i)
    var third = nextInt(inputData, i)
    var fourth = nextInt(inputData, i)
    cutLefts[k] = min(first, second)
    cutRights[k] = max(first, second)
    cutBottoms[k] = min(third, fourth)
    cutTops[k] = max(third, fourth)
    xCoords.add cutLefts[k]
    xCoords.add cutRights[k]
    yCoords.add cutBottoms[k]
    yCoords.add cutTops[k]

  sortValues xCoords
  sortValues yCoords
  xCoords = uniqueSorted(xCoords)
  yCoords = uniqueSorted(yCoords)
  var xCellCount = xCoords.len - 1
  var yCellCount = yCoords.len - 1
  var blocked = newSeq[bool](xCellCount * yCellCount)

  for k in 0 ..< rectangleCount:
    var i = findIndex(xCoords, cutLefts[k])
    var j = findIndex(xCoords, cutRights[k])
    var bottomIndex = findIndex(yCoords, cutBottoms[k])
    var topIndex = findIndex(yCoords, cutTops[k])
    for xi in i ..< j:
      var rowStart = xi * yCellCount
      for yi in bottomIndex ..< topIndex:
        blocked[rowStart + yi] = true
```

The rectangle loop reads 4r coordinates and orders each pair. Cut edges join the x and y coordinate lists. The marking loops visit only cells inside the cut. They never touch the full 40000 by 40000 square.

**Sweep rows and write the answer.**

```nim
  var upHeights = newSeq[int](xCellCount)
  var prefixWidths = newSeq[int](xCellCount + 1)
  for xi in 0 ..< xCellCount:
    prefixWidths[xi + 1] = prefixWidths[xi] + (xCoords[xi + 1] - xCoords[xi])
  var histStack: seq[int]
  var bestArea = 0
  for yi in 0 ..< yCellCount:
    var cellHeight = yCoords[yi + 1] - yCoords[yi]
    for xi in 0 ..< xCellCount:
      if blocked[xi * yCellCount + yi]:
        upHeights[xi] = 0
      else:
        upHeights[xi] = upHeights[xi] + cellHeight
    var rowArea = largestWeightedRectangle(upHeights, prefixWidths, xCellCount, histStack)
    if rowArea > bestArea: bestArea = rowArea

  outputBuffer.add $bestArea
  outputBuffer.add "\n"
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

stdout.write outputBuffer
```

The row loop runs yCellCount times and the inner loop xCellCount times. prefixWidths turns a cell span into a width. The final write flushes the last partial output block.

## Complexity

The phases and their costs for one dataset follow.

| Phase | Time | Space |
| --- | --- | --- |
| Read and sort coordinates | O(r log r) | O(r) |
| Mark blocked cells | O(r²) worst case | O(X·Y) |
| Sweep rows with the stack | O(X·Y) | O(X + Y) |
| Total | O(X·Y + r log r) | O(X·Y) |

Here X and Y are the compressed cell counts, at most 201 each.

The Big O summary follows.

| Measure | Big O |
| --- | --- |
| Time | O(X·Y + r log r) per dataset |
| Space | O(X·Y) per dataset |

A full grid would store 1.6 billion cells, while the compressed sweep visits about forty thousand.
