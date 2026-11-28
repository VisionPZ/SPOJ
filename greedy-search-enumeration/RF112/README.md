# RF112 — EQSEL (SPOJ)
<https://www.spoj.com/problems/RF112/>

## Problem

A spreadsheet stores monthly sales for several branches as a matrix.
Each row is one branch, and each column is one month.
Print the total sales for every month across all branches, with comma separators.
The input holds several square matrices, each preceded by its dimension.
A line containing only zero ends the input.

| Item | Bound |
|---|---|
| Matrices | not stated |
| Dimension | not stated |
| Time limit | 1000 ms |
| Memory | 1536 MB |

One running total per column handles each matrix in a single pass.

The sample from the statement:

```
2
0 1
3 0
3
0 1 2
1 0 2
4 2 0
3
1 2 3
1 0 2
4 2 0
2
0 1
1 1
0
```

```
3,1
5,3,4
6,4,5
1,2
```

## Idea

Adding monthly sales is like filling one column total at a time on paper.
The program reads all input once and scans each number by index.
It keeps an array with one running sum per column.
Values are added left to right, so the column index advances with each value.
After the last value, the sums print as comma-separated numbers.
A zero dimension stops the run before any output.

One pass over a matrix produces all of its monthly totals.

## Why It Works

1. Column j collects exactly the entries in position j of every row.
2. Reading a square matrix row by row cycles through the column positions.
3. Advancing the column index after each value keeps that cycle aligned.
4. Initialization clears old sums before the next matrix begins.
5. Inserting a comma only between columns matches the sample byte shape.

The main terms follow.

| Term | Meaning |
|---|---|
| `dimension` | size of the current square matrix |
| `columnSums` | running total for each month |
| `columnIndex` | column receiving the next scanned value |
| `cellCount` | number of values in the matrix |
| `flushIfReady` | writes the buffer once it reaches 131072 bytes |

Each matrix costs one addition per cell and one output line.

A trace from `gen.py --trace` for the second sample matrix:

```
rows: [[0, 1, 2], [1, 0, 2], [4, 2, 0]]
columns: [(0, 1, 4), (1, 0, 2), (2, 2, 0)]
totals: 5,3,4
```

The trace matches the second sample answer exactly.

## Code

**Bulk input and scanner.** This block reads stdin once and parses integers.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int64 =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    inc pos
  if pos >= data.len:
    return 0
  var value: int64 = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int64(int(data[pos]) - firstDigitValue)
    inc pos
  return value
```

Spaces and line breaks are skipped as plain separators.
The scanner builds values without allocating token strings.
Accumulation uses `int64` so large sums stay exact.

**Output buffer.** This block buffers text and flushes in blocks.

```nim
var outputBuffer = ""

proc flushIfReady() =
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc appendOutput(text: string) =
  outputBuffer.add text
  flushIfReady()
```

The buffer leaves after reaching 131072 bytes.
The last partial block is written after the loop.
No write happens per column.

**Column sums loop.** This block adds each value to its column and prints.

```nim
var columnSums: seq[int64] = @[]

while scanPos < inputData.len:
  let dimension = nextInt(inputData, scanPos)
  if dimension == 0:
    break
  if dimension < 0:
    break
  let columnCount = int(dimension)
  columnSums.setLen(columnCount)
  for column in 0..<columnCount:
    columnSums[column] = 0
  var columnIndex = 0
  let cellCount = columnCount * columnCount
  for cell in 0..<cellCount:
    let cellValue = nextInt(inputData, scanPos)
    columnSums[columnIndex] += cellValue
    columnIndex = (columnIndex + 1) mod columnCount
  for column in 0..<columnCount:
    if column > 0:
      outputBuffer.add ','
    outputBuffer.add $(columnSums[column])
  appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

The dimension gives the closed form n squared for the cell count.
Zero terminates the loop, since no matrix is stored.
The modulo keeps the column index inside the running sums.

## Complexity

Cost follows the number of cells in every matrix.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Column sums | one addition per cell | n running sums |
| Output | one write per block | block buffer |

One pass per matrix gives all monthly totals at once.

| Measure | Big O |
|---|---|
| Time | O(I + C) for C cells |
| Space | O(I + n + B) |

Here I is input bytes, n is matrix dimension, and B is block size.

Summing each column in a separate pass would rescan the matrix n times.
A single cycling index gives the same totals in linear time.
