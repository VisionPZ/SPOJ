# DCEPC14A — Another Version of Inversion (SPOJ)

<https://www.spoj.com/problems/DCEPC14A/>

## Problem

Count ordered pairs of grid cells that lie on one right-or-down path, where the first cell holds a larger value than the second. Report the pair count as one integer.

The first input line holds R and C. The next R lines each hold C integers. A pair counts when the first cell is no lower and no further right than the second cell, the cells differ, and the first value is larger. Print the total count.

| Item | Bound |
|---|---|
| Rows R and columns C | 1 to 300 |
| Cell value | 1 to 100000 |
| Judge limit | 500 ms, 1536 MB |

The grid has at most 90000 cells, so the pair count needs 64-bit storage and a fast counting method.

Sample input:

```
4 4
3 4 2 5
1 7 11 16
8 9 6 12
10 13 15 14
```

The sample uses sixteen cells with values between one and sixteen.

Sample output:

```
10
```

The output is the number of valid ordered pairs in that grid.

## Idea

Counting larger cells behind each cell is like tallying taller people standing up-left in a seating chart. Visit values from large to small and mark their cells in a two-dimensional counter.

Two cells share a valid path in the right direction exactly when the first cell has a row and column no greater than the second. Processing values from large to small means every already-marked cell has a strictly larger value. A two-dimensional Fenwick tree answers how many marked cells sit in the up-left rectangle of the current cell. Testing every pair of cells would compare billions of pairs; the tree counts them in a few logarithmic steps per cell.

Takeaway: sort work by value, then query rectangles instead of pairs.

## Why It Works

1. A right-or-down path reaches cell B from cell A only when A has row no greater than B and column no greater than B.
2. Cells with equal coordinates cannot form a pair of different cells.
3. Processing values from large to small marks only cells with a strictly larger value before any query for that value.
4. All cells of one value are queried before any of them is marked, so equal values never count.
5. A two-dimensional Fenwick tree stores marked cells and returns a rectangle count in logarithmic time per dimension.
6. Summing those counts over all cells gives every valid ordered pair once.

| Term | Meaning |
|---|---|
| `buckets` | cell positions grouped by their value |
| `bitGrid` | the two-dimensional Fenwick tree of marked cells |
| `countAboveLeft` | marked cells in the rectangle ending at one cell |
| `addCell` | mark one processed cell in the tree |
| `pairTotal` | the running 64-bit sum of pair counts |

The table links the value groups to the rectangle query that produces the answer.

A script-generated trace of the sample grid:

```
cell (0,2) value 2: 2 larger cells up-left
cell (1,0) value 1: 1 larger cells up-left
cell (2,2) value 6: 4 larger cells up-left
cell (2,3) value 12: 1 larger cells up-left
cell (3,3) value 14: 2 larger cells up-left
total 10
```

The per-cell counts add to the sample answer of ten.

The largest grid can hold 90000 cells, so the number of pairs can exceed a 32-bit integer. The accumulator uses 64-bit arithmetic.

## Code

**Input, scanner, and output helper.** One pass loads the grid and one buffer holds the answer.

```nim
const flushBlockBytes = 1 shl 17
const maxCellValue = 100000

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

`maxCellValue` sizes the value buckets. The scanner skips the spaces between grid entries. This block runs once.

**Fenwick tree and value sweep.** Marked cells are counted by rectangle, one value group at a time.

```nim
var rowCount = 0
var columnCount = 0
var bitGrid = newSeq[int]()

proc addCell(rowIndex: int, columnIndex: int) =
  var bitRow = rowIndex + 1
  while bitRow <= rowCount:
    var bitColumn = columnIndex + 1
    while bitColumn <= columnCount:
      let bitIndex = bitRow * (columnCount + 1) + bitColumn
      bitGrid[bitIndex] = bitGrid[bitIndex] + 1
      bitColumn = bitColumn + (bitColumn and -bitColumn)
    bitRow = bitRow + (bitRow and -bitRow)

proc countAboveLeft(rowIndex: int, columnIndex: int): int =
  var total = 0
  var bitRow = rowIndex + 1
  while bitRow > 0:
    var bitColumn = columnIndex + 1
    while bitColumn > 0:
      let bitIndex = bitRow * (columnCount + 1) + bitColumn
      total = total + bitGrid[bitIndex]
      bitColumn = bitColumn - (bitColumn and -bitColumn)
    bitRow = bitRow - (bitRow and -bitRow)
  return total

rowCount = nextInt(inputData, scanPos)
columnCount = nextInt(inputData, scanPos)
bitGrid = newSeq[int]((rowCount + 1) * (columnCount + 1))
var buckets = newSeq[seq[int]](maxCellValue + 1)
for rowIndex in 0 .. rowCount - 1:
  for columnIndex in 0 .. columnCount - 1:
    let cellValue = nextInt(inputData, scanPos)
    buckets[cellValue].add(rowIndex * columnCount + columnIndex)

var pairTotal: int64 = 0
var cellValue = maxCellValue
while cellValue >= 1:
  for cellIndex in buckets[cellValue]:
    let cellRow = cellIndex div columnCount
    let cellColumn = cellIndex mod columnCount
    pairTotal = pairTotal + int64(countAboveLeft(cellRow, cellColumn))
  for cellIndex in buckets[cellValue]:
    let cellRow = cellIndex div columnCount
    let cellColumn = cellIndex mod columnCount
    addCell(cellRow, cellColumn)
  cellValue -= 1

appendOutput($pairTotal)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Indices shift by one because Fenwick trees start at one. Each value group is queried before it is marked. The 64-bit accumulator holds the full pair count.

## Complexity

The value sweep visits each cell twice, and each visit costs two short tree walks.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over all cells | one input string |
| Value buckets | one append per cell | array of value groups |
| Rectangle counting | two tree walks per cell | two-dimensional tree |
| Output | one line | block buffer |

The phase table shows that value grouping replaces any search over cell pairs.

| Measure | Big O |
|---|---|
| Time | O(R times C times log R times log C plus maxValue) |
| Space | O(R times C plus maxValue) |

Testing every pair of cells would cost O((R times C) squared), which is far beyond the limit. The tree sweep counts the same pairs in logarithmic time per cell.
