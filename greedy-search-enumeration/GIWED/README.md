# GIWED — The Great Indian Wedding (SPOJ)

<https://www.spoj.com/problems/GIWED/>

## Problem

Find the largest area reachable by up to L water pipes placed anywhere in a park with K blocking carpets. Water crosses free cells that share an edge, never a corner.

Input starts with T cases. Each case gives M, N, K and L, then K lines with lower-left and upper-right carpet corners. M and N measure at most 10000 units, K is at most 50, and L is at most 10.

Output prints one maximum area per case on its own line.

| item | bound |
|---|---|
| test cases T | 1 to 30 |
| park size M, N | 1 to 10000 each |
| carpets K | 0 to 50 |
| pipes L | 1 to 10 |
| judge limit | 100 ms, 1536 MB |

The small carpet count drives a compressed grid instead of a full park scan.

Sample input and output:

```
2
10 10 0 1
10 10 1 1
3 3 4 4
```

```
100
99
```

The two blocks come from the statement and drive the checks.

## Idea

Think of the free park as rooms in a building: one tap floods a whole room, so choose the largest rooms. Compress carpet edges into a small grid, flood-fill each room, then add the L largest areas.

The program collects all carpet corner coordinates, sorts them, and works on the rectangles between consecutive coordinates. Each rectangle costs one flood-fill step. A full scan of M times N cells would visit up to 100 million cells per case.

Compression turns a huge park into at most about 100 rows and columns.

## Why It Works

1. A carpet edge divides the park, so adding every edge coordinate preserves all boundaries.
2. Every small rectangle between consecutive coordinates is either fully covered or fully free.
3. Two free rectangles connect only when they share an edge segment of positive length.
4. This rule matches the statement note about carpets that touch at a corner.
5. A flood fill from a free rectangle finds one whole room; its area sums the small rectangles.
6. Placing pipes in the L largest rooms maximizes the watered area.

| term | meaning |
|---|---|
| `xCoordinates` | compressed vertical grid lines |
| `cellCovered` | covered flag for each small rectangle |
| `componentAreas` | area of each free room |
| `bestTotal` | sum of the largest room areas |

The room areas give a direct answer once every room has one flood fill.

A traced example uses the second sample case:

```
M = 10, N = 10, carpet = (3, 3, 4, 4), L = 1
x coordinates: 0, 3, 4, 10   widths: 3, 1, 6
y coordinates: 0, 3, 4, 10   heights: 3, 1, 6
covered rectangle area = 1 * 1 = 1
free room = 100 - 1 = 99, one pipe -> print 99
```

The trace matches the second sample answer exactly.

## Code

**Input reader and output buffer.**

```nim
import algorithm

const flushBlockBytes = 1 shl 17

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

```

All input is read once with readLine.
appendOutput flushes only when the block fills.

**Coordinate helpers.**

```nim
proc ascending(left: int, right: int): int =
  if left < right:
    return -1
  if left > right:
    return 1
  return 0

proc lowerBound(values: seq[int], target: int): int =
  var low = 0
  var high = values.len
  while low < high:
    let middle = (low + high) div 2
    if values[middle] < target:
      low = middle + 1
    else:
      high = middle
  return low

proc uniqueSorted(values: seq[int]): seq[int] =
  var sortedValues = values
  sortedValues.sort(ascending)
  var uniqueValues = newSeq[int]()
  for value in sortedValues:
    if uniqueValues.len == 0 or uniqueValues[uniqueValues.len - 1] != value:
      uniqueValues.add value
  return uniqueValues

```

ascending sorts coordinates to build the compressed grid.
lowerBound maps carpet corners to grid lines.
uniqueSorted removes duplicate grid lines.

**Grid marking, flood fill and pipe choice.**

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let parkWidth = nextInt(inputData, scanPos)
  let parkHeight = nextInt(inputData, scanPos)
  let carpetCount = nextInt(inputData, scanPos)
  let pipeCount = nextInt(inputData, scanPos)
  var rawX = newSeq[int]()
  var rawY = newSeq[int]()
  rawX.add 0
  rawX.add parkWidth
  rawY.add 0
  rawY.add parkHeight
  var carpetX1 = newSeq[int](carpetCount)
  var carpetY1 = newSeq[int](carpetCount)
  var carpetX2 = newSeq[int](carpetCount)
  var carpetY2 = newSeq[int](carpetCount)
  for carpetIndex in 0 .. carpetCount - 1:
    carpetX1[carpetIndex] = nextInt(inputData, scanPos)
    carpetY1[carpetIndex] = nextInt(inputData, scanPos)
    carpetX2[carpetIndex] = nextInt(inputData, scanPos)
    carpetY2[carpetIndex] = nextInt(inputData, scanPos)
    rawX.add carpetX1[carpetIndex]
    rawX.add carpetX2[carpetIndex]
    rawY.add carpetY1[carpetIndex]
    rawY.add carpetY2[carpetIndex]
  let xCoordinates = uniqueSorted(rawX)
  let yCoordinates = uniqueSorted(rawY)
  let columns = xCoordinates.len - 1
  let rows = yCoordinates.len - 1
  var cellCovered = newSeq[bool](columns * rows)
  for carpetIndex in 0 .. carpetCount - 1:
    let firstColumn = lowerBound(xCoordinates, carpetX1[carpetIndex])
    let lastColumn = lowerBound(xCoordinates, carpetX2[carpetIndex]) - 1
    let firstRow = lowerBound(yCoordinates, carpetY1[carpetIndex])
    let lastRow = lowerBound(yCoordinates, carpetY2[carpetIndex]) - 1
    for column in firstColumn .. lastColumn:
      for row in firstRow .. lastRow:
        cellCovered[column * rows + row] = true
  var cellVisited = newSeq[bool](columns * rows)
  var componentAreas = newSeq[int]()
  for column in 0 .. columns - 1:
    for row in 0 .. rows - 1:
      let startCell = column * rows + row
      if cellVisited[startCell] or cellCovered[startCell]:
        continue
      cellVisited[startCell] = true
      var pending = newSeq[int]()
      pending.add startCell
      var componentArea: int64 = 0
      while pending.len > 0:
        let currentCell = pending[pending.len - 1]
        pending.setLen pending.len - 1
        let currentColumn = currentCell div rows
        let currentRow = currentCell mod rows
        let cellWidth = xCoordinates[currentColumn + 1] - xCoordinates[currentColumn]
        let cellHeight = yCoordinates[currentRow + 1] - yCoordinates[currentRow]
        componentArea = componentArea + int64(cellWidth) * int64(cellHeight)
        var neighborColumn = currentColumn - 1
        if neighborColumn >= 0:
          let neighborCell = neighborColumn * rows + currentRow
          if not cellVisited[neighborCell] and not cellCovered[neighborCell]:
            cellVisited[neighborCell] = true
            pending.add neighborCell
        neighborColumn = currentColumn + 1
        if neighborColumn < columns:
          let neighborCell = neighborColumn * rows + currentRow
          if not cellVisited[neighborCell] and not cellCovered[neighborCell]:
            cellVisited[neighborCell] = true
            pending.add neighborCell
        var neighborRow = currentRow - 1
        if neighborRow >= 0:
          let neighborCell = currentColumn * rows + neighborRow
          if not cellVisited[neighborCell] and not cellCovered[neighborCell]:
            cellVisited[neighborCell] = true
            pending.add neighborCell
        neighborRow = currentRow + 1
        if neighborRow < rows:
          let neighborCell = currentColumn * rows + neighborRow
          if not cellVisited[neighborCell] and not cellCovered[neighborCell]:
            cellVisited[neighborCell] = true
            pending.add neighborCell
      componentAreas.add int(componentArea)
  var bestTotal: int64 = 0
  var pipesLeft = pipeCount
  while pipesLeft > 0:
    var largestIndex = -1
    for areaIndex in 0 .. componentAreas.len - 1:
      if largestIndex < 0 or componentAreas[areaIndex] > componentAreas[largestIndex]:
        largestIndex = areaIndex
    if largestIndex < 0 or componentAreas[largestIndex] <= 0:
      break
    bestTotal = bestTotal + int64(componentAreas[largestIndex])
    componentAreas[largestIndex] = -1
    pipesLeft -= 1
  appendOutput($bestTotal)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Each carpet marks the small rectangles inside its corners.
The stack visits only edge-adjacent free rectangles.
The last loop picks the largest room at most L times.

## Complexity

Compression bounds each case by the carpet count, not the park area.

| phase | time | space |
|---|---|---|
| input read | one pass over case tokens | one input string |
| grid build | up to 2K coordinates per axis | O(K) coordinates |
| carpet marking | K times the small grid size | O(K^2) flags |
| flood fill | one visit per small rectangle | one stack and visit flags |
| pipe choice | L scans of room areas | room area list |

Flood fill dominates the phase table.

| measure | Big O |
|---|---|
| time | O(K^2) per case |
| space | O(K^2) per case |

A direct cell scan would cost O(M*N) per case and overflow the time limit on large parks.
