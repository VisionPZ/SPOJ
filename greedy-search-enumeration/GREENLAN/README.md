# GREENLAN — Greens Land (SPOJ)

<https://www.spoj.com/problems/GREENLAN/>

## Problem

A square field has field cells and lake cells. Count the rectangular fences whose edges touch no lake cell.

Input starts with the test count. Each case gives N, then N rows of N characters. A dot marks a field cell, and an X marks a lake. Output one count per case.

| item | bound |
|---|---|
| test cases | up to 100 |
| land size N | 1 to 300 |
| cell character | `.` or `X` |
| judge limit | 1000 ms, 1536 MB |

A lake inside a rectangle is allowed when no fence edge touches it. A lake diagonally outside a corner is also allowed.

Sample input:

```
4
3
...
.X.
...
3
X..
...
X..
6
......
......
......
......
......
......
5
.....
....X
.X...
.....
...XX
```

Sample output:

```
5
8
441
23
```

## Idea

A fence edge lies between two cells, so a lake blocks it only when that lake sits beside the edge. Think of sliding a rectangular frame over a grid of tiles. You reject a position when the frame rests against a marked tile.

Fix the top and bottom rows, then sweep left columns. Column prefix sums tell whether a column has a lake inside the band. Binary searches find the last legal right column for each left column.

Checking every row pair, column pair, and border cell would cost O(N^4). Prefix sums and binary search reduce that to O(N² log N).

Each row band uses two binary searches per left column.

## Why It Works

1. A fence edge is shared by one cell inside and one cell outside the rectangle.
2. A lake on the rectangle border shares an edge with the fence, so it is blocked.
3. A lake directly outside a side shares an edge with the fence, so it is blocked.
4. A lake strictly inside the rectangle touches no fence edge, so it is allowed.
5. A lake diagonally outside a corner touches only a corner point, so it is allowed.
6. Prefix sums over columns find the last legal right column by binary search.

| term | meaning |
|---|---|
| `columnPrefix` | lake count in a column above a given row |
| `topBottomBad` | columns with a lake in the top or bottom row |
| `outsideBad` | columns with a lake directly beyond the top or bottom |
| `anyColumn` | column has a lake within the chosen row band |
| `innerColumn` | column has a lake strictly between the chosen rows |

The prefix arrays turn side checks into two array lookups.

For the 3×3 case with one lake at the center, the row pair 0–2 has no lake in its top or bottom row. Column 1 has an inner lake, so rectangles with left or right edge beside column 1 fail. The five surviving rectangles cover the other positions.

The count matches the sample answer of 5.

## Code

**Input and scanner.** Hand readers load integers and grid rows as whole tokens.

```nim
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

proc nextToken(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  var token = ""
  while pos < data.len and data[pos] > ' ':
    token.add data[pos]
    pos += 1
  return token```

Grid rows contain no spaces, so one token represents one row.

The integer scanner ignores the newlines between test cases.

**Output buffer and column prefixes.** Buffered output and column counts are shared across cases.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0```

The helper finds the last prefix index that keeps a side clear.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let landSize = nextInt(inputData, scanPos)
  var lakeFlags = newSeq[int](landSize * landSize)
  for rowIndex in 0 .. landSize - 1:
    let rowText = nextToken(inputData, scanPos)
    for colIndex in 0 .. landSize - 1:
      if rowText[colIndex] == 'X':
        lakeFlags[rowIndex * landSize + colIndex] = 1
  var columnPrefix = newSeq[int]((landSize + 1) * landSize)
  for colIndex in 0 .. landSize - 1:
    columnPrefix[colIndex] = 0
  for rowIndex in 0 .. landSize - 1:
    for colIndex in 0 .. landSize - 1:
      columnPrefix[(rowIndex + 1) * landSize + colIndex] =
        columnPrefix[rowIndex * landSize + colIndex] + lakeFlags[rowIndex * landSize + colIndex]```

Column prefix values give lake counts for any row band.

The grid is stored as a flat flag array for fast indexing.

**Row-band sweep.** Each row band builds column arrays, then binary-searches right limits.

```nim
  var topBottomBad = newSeq[int](landSize)
  var outsideBad = newSeq[int](landSize)
  var anyColumn = newSeq[int](landSize)
  var innerColumn = newSeq[int](landSize)
  var badEnd = newSeq[int](landSize)
  var prefixTopBottom = newSeq[int](landSize + 3)
  var prefixOutside = newSeq[int](landSize + 3)
  var prefixEnd = newSeq[int](landSize + 1)
  var rectangleCount: int64 = 0
  for topRow in 0 .. landSize - 1:
    for bottomRow in topRow .. landSize - 1:
      for colIndex in 0 .. landSize - 1:
        topBottomBad[colIndex] = lakeFlags[topRow * landSize + colIndex] +
          lakeFlags[bottomRow * landSize + colIndex]
        var outsideTotal = 0
        if topRow > 0:
          outsideTotal += lakeFlags[(topRow - 1) * landSize + colIndex]
        if bottomRow + 1 < landSize:
          outsideTotal += lakeFlags[(bottomRow + 1) * landSize + colIndex]
        outsideBad[colIndex] = outsideTotal
        if columnPrefix[(bottomRow + 1) * landSize + colIndex] -
            columnPrefix[topRow * landSize + colIndex] > 0:
          anyColumn[colIndex] = 1
        else:
          anyColumn[colIndex] = 0
        if columnPrefix[bottomRow * landSize + colIndex] -
            columnPrefix[(topRow + 1) * landSize + colIndex] > 0:
          innerColumn[colIndex] = 1
        else:
          innerColumn[colIndex] = 0
      for colIndex in 0 .. landSize - 1:
        if anyColumn[colIndex] == 1 or
            (colIndex + 1 < landSize and innerColumn[colIndex + 1] == 1):
          badEnd[colIndex] = 1
        else:
          badEnd[colIndex] = 0
      prefixEnd[0] = 0
      for colIndex in 0 .. landSize - 1:
        prefixEnd[colIndex + 1] = prefixEnd[colIndex] + badEnd[colIndex]
      for fillIndex in 0 .. landSize + 2:
        prefixTopBottom[fillIndex] = 0
        prefixOutside[fillIndex] = 0
      for colIndex in 0 .. landSize + 1:
        if colIndex < landSize:
          prefixTopBottom[colIndex + 1] = prefixTopBottom[colIndex] + topBottomBad[colIndex]
          prefixOutside[colIndex + 1] = prefixOutside[colIndex] + outsideBad[colIndex]
        else:
          prefixTopBottom[colIndex + 1] = prefixTopBottom[colIndex]
          prefixOutside[colIndex + 1] = prefixOutside[colIndex]
      for leftCol in 0 .. landSize - 1:
        if anyColumn[leftCol] == 1 or
            (leftCol > 0 and innerColumn[leftCol - 1] == 1):
          continue
        let lowerCol = if leftCol > 0: leftCol - 1 else: 0
        let topBase = prefixTopBottom[lowerCol]
        let topLast = lastPrefixIndex(prefixTopBottom, topBase, lowerCol, landSize + 1)
        let topLimit = topLast - 2
        let outsideBase = prefixOutside[leftCol]
        let outsideLast = lastPrefixIndex(prefixOutside, outsideBase, leftCol, landSize + 1)
        let rightLimit = min(topLimit, outsideLast - 1)
        if rightLimit < leftCol:
          continue
        rectangleCount += int64(rightLimit - leftCol + 1) -
          int64(prefixEnd[rightLimit + 1] - prefixEnd[leftCol])```

Binary searches skip right columns that put a lake beside a fence.

The total uses int64 because a 300×300 field has over two billion rectangles.

## Complexity

Each case builds column prefixes, then sweeps every row band and column pair.

| phase | time | space |
|---|---|---|
| input read | one pass over N grid rows | one input string |
| prefix build | O(N²) cells | O(N²) flag and prefix arrays |
| band sweep | O(N² log N) searches | O(N) work arrays |
| output | one buffered write per block | block buffer |

Work arrays are reused for every row band to avoid repeated allocation.

| measure | Big O |
|---|---|
| time per case | O(N² log N) |
| space per case | O(N²) |

Checking every border cell for every rectangle would cost O(N⁴).

The prefix sweep counts the same rectangles in O(N² log N).
