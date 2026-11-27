# MXSBMTRX — Largest Increasing Sub-Matrix (SPOJ)

<https://www.spoj.com/problems/MXSBMTRX/>

## Problem

Find the largest-area rectangle of a matrix whose rows and columns all strictly increase. A cell must exceed its left and upper neighbors inside the rectangle.

Line 1 holds the test count `T`. Each test starts with `N M`, followed by `N` rows of `M` integers `Xi,j`. Print the maximum rectangle area on its own line per test.

| item | bound |
|---|---|
| tests T | up to 50 |
| product N times M | 1 to 100000 |
| matrix values Xi,j | -1000000000 to 1000000000 |
| judge limit | 1000 ms, 1536 MB |

Area means cell count, so a 2 by 3 rectangle has area 6.

Sample input:

```
2
2 3
2 2 2
2 2 2
3 3
1 2 5
4 6 7
10 8 3
```

Sample output:

```
1
6
```

Those two lines are the exact expected output.

## Idea

Think of the matrix as a staircase: inside the rectangle, each step right and each step down must climb. The diagonal rule follows for free, so only rows and columns need checking.

The algorithm transposes tall matrices, then sweeps every pair of top and bottom rows. For each pair it keeps two flags per column and reads the widest valid suffix in one pass. The sweep costs O(min(N,M) times N times M). Checking every rectangle directly would cost far more.

One sweep over row pairs finds the best rectangle.

## Why It Works

1. A cell inside the rectangle must exceed its left and upper neighbors there.
2. The diagonal rule follows: the cell exceeds its upper neighbor, which exceeds the upper-left neighbor.
3. So a valid rectangle is exactly one whose rows and columns strictly increase.
4. Transposing keeps this property and makes the row count the smaller dimension.
5. `columnUp` records that a column increases from the top row down to the bottom row.
6. `rowRightAll` records that every row in the band increases across that column.
7. A run of columns with both flags true can be the right part of a rectangle.
8. The column before the run may join if it increases downward; it needs no rightward check.
9. Multiplying that width by the band height gives the area.

| term | meaning |
|---|---|
| `rowCount` | rows after any transpose |
| `columnCount` | columns after any transpose |
| `columnUp` | downward increase flag per column |
| `rowRightAll` | rightward increase flag per column |
| `currentRun` | trailing columns with both flags true |
| `bestArea` | largest area found so far |

The labels above match the identifiers in the code.

The second sample matrix gives a concrete run.

| top row | bottom row | trailing run | width | height | area |
|---|---|---|---|---|---|
| 0 | 0 | 3 | 3 | 1 | 3 |
| 0 | 1 | 3 | 3 | 2 | 6 |
| 0 | 2 | 1 | 1 | 3 | 3 |

Rows 0 and 1 form the 2 by 3 rectangle with area 6.

## Code

**Input and scanner.** The reader stores all lines, and the scanner handles negative cell values.

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
  var negative = false
  if pos < data.len and data[pos] == '-':
    negative = true
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  if negative:
    return -value
  return value
```

One newline ends each stored line.
The minus branch reads negative matrix values.
Digits are accumulated one at a time.

**Matrix setup.** Tall matrices are transposed so the outer sweep stays short.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  var rowCount = nextInt(inputData, scanPos)
  var columnCount = nextInt(inputData, scanPos)
  var matrix = newSeq[int](rowCount * columnCount)
  for cellIndex in 0 .. rowCount * columnCount - 1:
    matrix[cellIndex] = nextInt(inputData, scanPos)
  if rowCount > columnCount:
    var transposed = newSeq[int](rowCount * columnCount)
    for originalRow in 0 .. rowCount - 1:
      for originalColumn in 0 .. columnCount - 1:
        transposed[originalColumn * rowCount + originalRow] = matrix[originalRow * columnCount + originalColumn]
    let previousRows = rowCount
    rowCount = columnCount
    columnCount = previousRows
    matrix = transposed
```

Cells are stored in one flat array.
Transposing swaps the two dimension counts.
The increasing property survives the swap.

**Sweep.** Each top and bottom pair updates two flags per column, then reads the widest suffix.

```nim
  var bestArea: int64 = 0
  for topRow in 0 .. rowCount - 1:
    var columnUp = newSeq[bool](columnCount)
    var rowRightAll = newSeq[bool](columnCount)
    for columnIndex in 0 .. columnCount - 1:
      columnUp[columnIndex] = true
      if columnIndex == 0:
        rowRightAll[columnIndex] = true
      else:
        rowRightAll[columnIndex] = matrix[topRow * columnCount + columnIndex] > matrix[topRow * columnCount + columnIndex - 1]
    for bottomRow in topRow .. rowCount - 1:
      if bottomRow > topRow:
        for columnIndex in 0 .. columnCount - 1:
          let currentValue = matrix[bottomRow * columnCount + columnIndex]
          columnUp[columnIndex] = columnUp[columnIndex] and (currentValue > matrix[(bottomRow - 1) * columnCount + columnIndex])
          if columnIndex > 0:
            rowRightAll[columnIndex] = rowRightAll[columnIndex] and (currentValue > matrix[bottomRow * columnCount + columnIndex - 1])
      let height = bottomRow - topRow + 1
      var currentRun = 0
      for columnIndex in 0 .. columnCount - 1:
        if columnUp[columnIndex] and rowRightAll[columnIndex]:
          currentRun += 1
        else:
          currentRun = 0
        var width = 0
        if columnUp[columnIndex]:
          width = 1
        if currentRun > 0:
          let startColumn = columnIndex - currentRun
          var candidateWidth = currentRun
          if startColumn >= 0:
            if columnUp[startColumn]:
              candidateWidth = currentRun + 1
          if candidateWidth > width:
            width = candidateWidth
        let area = int64(height) * int64(width)
        if area > bestArea:
          bestArea = area
  appendOutput($bestArea)
  appendOutput("\n")
stdout.write outputBuffer
outputBuffer.setLen 0
```

Flags are ANDed as the bottom row moves down.
The run plus one optional column gives the width.
Areas use int64, and the final line flushes the answers.

## Complexity

Each test transposes if needed, then sweeps top and bottom rows over all columns.

| phase | time | space |
|---|---|---|
| input scan | one pass over N times M cells | one input string |
| transpose | one pass over N times M cells | flat matrix array |
| row-pair sweep | min(N,M) squared times max(N,M) | two flag arrays |

The table shows a separate cost for each phase.

| measure | Big O |
|---|---|
| time per test | O(min(N,M) times N times M) |
| space per test | O(N times M) |

Testing every rectangle corner would cost far more than the flag sweep.

Transposing keeps the swept dimension small even for tall matrices.
