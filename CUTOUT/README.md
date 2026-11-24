## Problem

Read several squares with axis-aligned rectangles already cut out. Print the area of the largest axis-aligned rectangle that fits in the remaining paper. One integer per data set goes on its own output line.

| Item | Bound |
| --- | --- |
| Data sets | at most 10 |
| Square side n | 1 to 40000 |
| Cut rectangles r | 0 to 100 |
| Rectangle coordinates | 0 to n |
| Time and memory | 5000 ms, 1536 MB |

The small rectangle count makes coordinate compression possible.

## Idea

An empty rectangle can grow until one side reaches a cut edge or the square border, so only those edges can bound the answer. The program sorts the cut coordinates, removes duplicates, and marks each grid cell covered by a cut. A stack turns one row of free cells into a histogram, and the widest span gives the largest area ending at that row. A full grid would hold up to 1.6 billion cells; compression keeps at most 201 by 201, so each cell costs constant time.

## Why It Works

Every side of an optimal rectangle touches a cut side or the square border. If a side sat inside an empty interval, moving it outward would keep the rectangle empty and increase its area.

Sorting the coordinates turns the square into cells between consecutive x values and y values. Every cut covers a contiguous block of cells because its sides belong to that set. The program stores the row start as `rowStart = xi * yCellCount`.

- `yCellCount = yCoords.len - 1` is the number of y cells.
- `i = findIndex(xCoords, cutLefts[k])` is the first x cell of the cut.
- `j = findIndex(xCoords, cutRights[k])` is the cell past its last x cell.
- `blocked[rowStart + yi] = true` marks each cell inside the cut.

For one row, `upHeights[xi]` stores the vertical length of free cells ending at that row. The stack keeps increasing heights, so each bar is popped once. When a shorter bar appears, the popped bar spans from the next shorter bar to the current column. `prefixWidths` gives that span's width in one subtraction, and height times width is the best area for that bar.

The worked example below comes from the first sample data set.

```
Square 6 by 6, cuts [0,3]x[0,3] and [3,6]x[3,6].
x coordinates: 0 3 6   widths: 3 3
y coordinates: 0 3 6   heights: 3 3
blocked cells: (0,0), (1,1)
row 0 upHeights: 0 3   best area 9
row 1 upHeights: 3 0   best area 9
```

The largest area over all rows is 9, which matches the sample.

## Code

The scanner reads integers from the single input buffer.

```
proc nextInt(inputData: string, i: var int): int =
  while i < inputData.len and inputData[i] <= ' ':
    i = i + 1
  var value = 0
  while i < inputData.len and inputData[i] >= '0' and inputData[i] <= '9':
    value = value * 10 + int(inputData[i]) - 48
    i = i + 1
  return value
```

The digit loop runs once per digit, at most five here. It skips spaces and newlines, so an empty rectangle line causes no error. It allocates no temporary strings.

Sorted boundaries let each cut map to a cell range.

```
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

Insertion sort makes at most 201 passes, one per coordinate after the first. Duplicate removal keeps only distinct boundaries. Binary search takes eight comparisons over 202 values.

The histogram finds the best rectangle ending at one row.

```
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

The column loop runs columnCount times, at most 201. Popping on a height greater than or equal to the current one merges equal bars. Each bar enters and leaves the stack once, so one row costs linear time.

The program reads the whole stream once and starts the case loop.

```
var inputData: string
var line: string
while readLine(stdin, line):
  inputData.add line
  inputData.add "\n"

var i = 0
var caseCount = nextInt(inputData, i)
var outputBuffer: string
```

The read loop appends every line to one buffer. The program scans that buffer once. One output buffer holds all answers until a block is full.

Each case builds the compressed grid and marks the cut cells.

```
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

The rectangle loop runs 4r times, at most 400. The marking loops run rightIndex minus leftIndex and topIndex minus bottomIndex times. They stay inside the compressed grid and never touch the full square.

The sweep takes the best row and writes the answers.

```
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

The row loop runs yCellCount times and the inner loop xCellCount times. Adding the answer to one buffer avoids a write per line. The final write flushes the last partial block.

## Complexity

The table gives the cost of each phase for one data set.

| Phase | Time | Extra space |
| --- | --- | --- |
| Read and sort coordinates | O(r log r) | O(r) |
| Mark blocked cells | O(r²) worst case | O(X·Y) |
| Sweep rows with the stack | O(X·Y) | O(X+Y) |
| Total | O(X·Y + r log r) | O(X·Y) |

At most 202 x coordinates and 202 y coordinates give 40401 cells. A full grid would store up to 1.6 billion cells, and the compressed sweep visits about forty thousand instead.
