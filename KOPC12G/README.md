# KOPC12G — K12-Bored of Suffixes and Prefixes (SPOJ)

<https://www.spoj.com/problems/KOPC12G/>

## Problem

Maintain an `N` by `N` letter grid under row or column replacements. A count query asks for the weighted letter total in a rectangle, with A worth 1 through Z worth 26. Print one total per count query.

Input starts with the test count `T`. Each test gives `N` and the query count `q`, then `N` letter rows, then `q` operations. A replacement line is `0 x y str`, where `x` selects row or column and `y` gives the index. A count line is `1 x1 y1 x2 y2`, giving opposite corners with zero-based indices.

| Item | Bound |
|---|---|
| Test cases `T` | 1 to 10 |
| Grid size `N` | 1 to 500 |
| Queries `q` | 1 to 10000 |
| Judge limit | 100 ms to 1 s, 1536 MB |

Notation: `str` is a replacement string of length `N`, read left to right for a row and top to bottom for a column.

Here is the sample input:

```
1
4 3
ABCD
ABCD
ABCD
ABCD
1 0 0 3 3
0 0 2 PQRS
1 0 2 3 3
```

Here is the sample output:

```
40
58
```

## Idea

A replacement changes `N` cells, while a count query wants one rectangle total, like keeping both a grid of current values and a running ledger of its sums. Store each cell weight in `grid` and keep rectangle totals in a two-dimensional Fenwick tree. A changed cell triggers one tree update; a query combines four tree prefixes. Recomputing the rectangle cell by cell would cost O(N squared) per query.

## Why It Works

1. Each cell holds one weight from 1 to 26, so the current grid fully describes the matrix.
2. A row replacement changes exactly the cells of that row; a column replacement changes one cell in every row.
3. A Fenwick tree stores partial sums indexed by powers of two, so one point change needs O(log N) steps per axis.
4. The rectangle total equals the prefix at the bottom-right corner minus three neighboring prefixes.
5. Applying only non-zero cell differences keeps updates proportional to changed cells.
6. Reading every token from one input string avoids per-query line parsing overhead.

| Term | Meaning |
|---|---|
| `grid` | current letter weight of each cell |
| `bitValues` | flat two-dimensional Fenwick tree |
| `bitWidth` | stride of the flat tree, equal to `N` plus one |
| `bitUpdate` | applies one cell difference to the tree |
| `prefixSum` | total of cells above and left of a corner |
| `regionTotal` | four-prefix rectangle result |
| `replacement` | string read for a replace operation |

The table names the storage and helpers used by the program.

A worked trace of the sample follows.

```
initial grid: four rows of ABCD
first query: 4*(1+2+3+4) = 40
replace row 2 with PQRS, worth 16+17+18+19 = 70
second query rows 0..3 cols 2..3:
  row 0 CD=7, row 1 CD=7, row 2 RS=37, row 3 CD=7
  total 7+7+37+7 = 58
```

Both trace totals match the sample output.

## Code

**Input, token reader, and buffer setup.** The reader loads stdin once and adds a token reader for letters.

```nim
const flushBlockBytes = 1 shl 17
const firstLetterWeight = 64

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
  let tokenStart = pos
  while pos < data.len and data[pos] > ' ':
    pos += 1
  return data[tokenStart .. pos - 1]

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The integer scanner skips separators and reads decimal values. The token reader returns one letter run for a matrix row or replacement. The writer batches all count answers.

**Fenwick helpers.** The two procedures update one cell and sum a prefix rectangle.

```nim
proc bitUpdate(bitValues: var seq[int], bitWidth: int, matrixSize: int,
               rowIndex: int, columnIndex: int, deltaValue: int) =
  var rowCursor = rowIndex + 1
  while rowCursor <= matrixSize:
    var columnCursor = columnIndex + 1
    while columnCursor <= matrixSize:
      bitValues[rowCursor * bitWidth + columnCursor] += deltaValue
      columnCursor += columnCursor and (-columnCursor)
    rowCursor += rowCursor and (-rowCursor)

proc prefixSum(bitValues: seq[int], bitWidth: int, matrixSize: int,
               rowInclusive: int, columnInclusive: int): int =
  if rowInclusive < 0 or columnInclusive < 0:
    return 0
  result = 0
  var rowCursor = rowInclusive + 1
  while rowCursor > 0:
    var columnCursor = columnInclusive + 1
    while columnCursor > 0:
      result += bitValues[rowCursor * bitWidth + columnCursor]
      columnCursor -= columnCursor and (-columnCursor)
    rowCursor -= rowCursor and (-rowCursor)
```

Low-bit jumps walk the tree without recursion. Out-of-range corners return zero, which lets the query use four plain prefixes.

**Query processing.** The main loop loads the grid, applies replacements, and writes rectangle totals.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let matrixSize = nextInt(inputData, scanPos)
  let queryCount = nextInt(inputData, scanPos)
  let bitWidth = matrixSize + 1
  var grid = newSeq[int](matrixSize * matrixSize)
  var bitValues = newSeq[int](bitWidth * bitWidth)
  for row in 0 .. matrixSize - 1:
    let rowText = nextToken(inputData, scanPos)
    for column in 0 .. matrixSize - 1:
      let letterWeight = int(rowText[column]) - firstLetterWeight
      grid[row * matrixSize + column] = letterWeight
      bitUpdate(bitValues, bitWidth, matrixSize, row, column, letterWeight)
  for queryIndex in 0 .. queryCount - 1:
    let operationKind = nextInt(inputData, scanPos)
    if operationKind == 0:
      let selector = nextInt(inputData, scanPos)
      let targetIndex = nextInt(inputData, scanPos)
      let replacement = nextToken(inputData, scanPos)
      if selector == 0:
        for column in 0 .. matrixSize - 1:
          let cellIndex = targetIndex * matrixSize + column
          let letterWeight = int(replacement[column]) - firstLetterWeight
          let deltaValue = letterWeight - grid[cellIndex]
          if deltaValue != 0:
            grid[cellIndex] = letterWeight
            bitUpdate(bitValues, bitWidth, matrixSize, targetIndex, column, deltaValue)
      else:
        for row in 0 .. matrixSize - 1:
          let cellIndex = row * matrixSize + targetIndex
          let letterWeight = int(replacement[row]) - firstLetterWeight
          let deltaValue = letterWeight - grid[cellIndex]
          if deltaValue != 0:
            grid[cellIndex] = letterWeight
            bitUpdate(bitValues, bitWidth, matrixSize, row, targetIndex, deltaValue)
    else:
      let topRow = nextInt(inputData, scanPos)
      let leftColumn = nextInt(inputData, scanPos)
      let bottomRow = nextInt(inputData, scanPos)
      let rightColumn = nextInt(inputData, scanPos)
      let regionTotal =
        prefixSum(bitValues, bitWidth, matrixSize, bottomRow, rightColumn) -
        prefixSum(bitValues, bitWidth, matrixSize, topRow - 1, rightColumn) -
        prefixSum(bitValues, bitWidth, matrixSize, bottomRow, leftColumn - 1) +
        prefixSum(bitValues, bitWidth, matrixSize, topRow - 1, leftColumn - 1)
      appendOutput($regionTotal)
      outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Initial letters are inserted as point updates. Each replacement walks one row or column and skips unchanged cells. Four prefix calls produce each answer.

## Complexity

Building inserts every cell once, and each later operation touches one line or four prefixes.

| Phase | Time | Space |
|---|---|---|
| Grid load | O(N squared times log squared N) | grid and tree |
| Row or column replace | O(N times log squared N) | unchanged |
| Count query | O(log squared N) | unchanged |
| Output | one line per count query | block buffer |

The tree keeps rectangle queries independent of the rectangle area.

| Measure | Big O |
|---|---|
| Time | O(N squared plus q times N times log squared N) |
| Space | O(N squared) |

Scanning the rectangle cell by cell would cost O(N squared) per query; the tree removes that factor.
