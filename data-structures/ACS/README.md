# ACS — A concrete simulation (SPOJ)

<https://www.spoj.com/problems/ACS/>

## Problem

A 1234 by 5678 matrix starts with the numbers 1 through 7,006,652 in row-major order. A command stream swaps rows, swaps columns, asks for the number at a position, or asks for the position holding a number.

Input is a list of valid commands, one per line, ending at EOF. The commands are `R x y`, `C x y`, `Q x y`, and `W z`. They swap rows, swap columns, print the value at row x and column y, and print the row and column of value z. Each `Q` or `W` prints one line; swaps print nothing.

The bounds from the statement:

| Item | Bound |
|---|---|
| Rows | 1234 |
| Columns | 5678 |
| Cells | 7,006,652 |
| Indices | 1-based, inside the matrix |
| Input end | EOF, with no case count |
| Judge limit | 7 s, 1536 MB |

Only the number of commands grows, so each command needs constant work.

The sample case from the statement:

```
R 1 2
Q 1 1
Q 2 1
W 1
W 5679
C 1 2
Q 1 1
Q 2 1
W 1
W 5679
```

```
5679
1
2 1
1 1
5680
2
2 2
1 2
```

The first row swap puts 5679 at position (1,1), and the later column swap changes that value to 5680.

## Idea

Track which original row and column sit at each position, like sliding name tags along two fixed rows of chairs. The values stay in place; only the labels move.

The program uses permutation arrays with inverse tables. A swap writes four entries across the label and inverse arrays. A `Q` reads one row label and one column label. A `W` reads two inverse entries. Every command costs O(1).

Copying 5678 cells for each row swap, or scanning all 7,006,652 cells for each `W`, costs far more. The label tables answer both directions with a few array reads.

Both directions stay fast no matter which rows or columns move.

## Why It Works

1. In the original matrix, row r and column c hold (r - 1) times 5678 plus c.
2. Row swaps only change which original row sits at each row position. Column swaps do the same for columns.
3. `rowAtPosition` and `columnAtPosition` store the labels. `rowPositionOfOriginal` and `columnPositionOfOriginal` store the reverse map.
4. Row labels and column labels stay independent, because a row swap never touches a column.

The main terms and formulas:

| Term | Meaning |
|---|---|
| `rowAtPosition[queryRow]` | original row sitting at the queried row position |
| `columnAtPosition[queryColumn]` | original column sitting at the queried column position |
| `(rowAtPosition[queryRow] - 1) * columnCount + columnAtPosition[queryColumn]` | value printed for `Q x y` |
| `(targetValue - 1) div columnCount + 1` | original row decoded from `W z` |
| `(targetValue - 1) mod columnCount + 1` | original column decoded from `W z` |

Each term is one array read or one integer operation.

A script traces both label arrays on the sample, showing only the first two labels:

```
command  row labels     column labels    output
R 1 2    [2, 1]         [1, 2]           -
Q 1 1    [2, 1]         [1, 2]           5679
Q 2 1    [2, 1]         [1, 2]           1
W 1      [2, 1]         [1, 2]           2 1
W 5679   [2, 1]         [1, 2]           1 1
C 1 2    [2, 1]         [2, 1]           -
Q 1 1    [2, 1]         [2, 1]           5680
Q 2 1    [2, 1]         [2, 1]           2
W 1      [2, 1]         [2, 1]           2 2
W 5679   [2, 1]         [2, 1]           1 2
```

After the row swap, row 1 holds original row 2. After the column swap, column 1 holds original column 2. The printed values match the sample.

## Code

**Constants and whole-stream read.** The driver builds one input buffer before parsing.

```nim
const rowCount = 1234
const columnCount = 5678
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
```

The read loop runs until EOF, so the stream needs no case count. `inputData` holds every line, including blank ones. The value 48 turns a digit byte into its numeric value.

**Hand scanners.** Both scanners walk the buffer by index and allocate no token objects.

```nim
proc nextToken(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ': pos += 1
  if pos >= data.len: return ""
  let tokenStart = pos
  while pos < data.len and data[pos] > ' ': pos += 1
  return data[tokenStart ..< pos]

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and data[pos] <= ' ': pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value
```

`nextToken` skips whitespace and returns an empty string at EOF. `nextInt` starts at `scanPos` and consumes digits only. Both run once per token, so their total cost tracks the input bytes.

**Label tables.** Four arrays start as identity maps, once at program start.

```nim
var rowAtPosition = newSeq[int](rowCount + 1)
var rowPositionOfOriginal = newSeq[int](rowCount + 1)
var columnAtPosition = newSeq[int](columnCount + 1)
var columnPositionOfOriginal = newSeq[int](columnCount + 1)
for index in 1 .. rowCount:
  rowAtPosition[index] = index
  rowPositionOfOriginal[index] = index
for index in 1 .. columnCount:
  columnAtPosition[index] = index
  columnPositionOfOriginal[index] = index
```

The loops run 1234 and 5678 times. Index 0 stays unused, so positions remain 1-based. Setup is one pass, never repeated per command.

**Block output.** Answers collect in one buffer and leave in large blocks.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

`appendOutput` adds one newline per answer. `flushBlockBytes` is `1 shl 18`, or 256 KiB. `stdout.write outputBuffer` moves one block at a time, and `setLen 0` reuses its allocation.

**Command loop.** One branch per command letter handles the whole stream.

```nim
while true:
  let commandToken = nextToken(inputData, scanPos)
  if commandToken.len == 0: break
  let commandLetter = commandToken[0]
  if commandLetter == 'R':
    let firstRow = nextInt(inputData, scanPos)
    let secondRow = nextInt(inputData, scanPos)
    let originalFirstRow = rowAtPosition[firstRow]
    let originalSecondRow = rowAtPosition[secondRow]
    rowAtPosition[firstRow] = originalSecondRow
    rowAtPosition[secondRow] = originalFirstRow
    rowPositionOfOriginal[originalFirstRow] = secondRow
    rowPositionOfOriginal[originalSecondRow] = firstRow
  elif commandLetter == 'C':
    let firstColumn = nextInt(inputData, scanPos)
    let secondColumn = nextInt(inputData, scanPos)
    let originalFirstColumn = columnAtPosition[firstColumn]
    let originalSecondColumn = columnAtPosition[secondColumn]
    columnAtPosition[firstColumn] = originalSecondColumn
    columnAtPosition[secondColumn] = originalFirstColumn
    columnPositionOfOriginal[originalFirstColumn] = secondColumn
    columnPositionOfOriginal[originalSecondColumn] = firstColumn
  elif commandLetter == 'Q':
    let queryRow = nextInt(inputData, scanPos)
    let queryColumn = nextInt(inputData, scanPos)
    let storedValue = (rowAtPosition[queryRow] - 1) * columnCount + columnAtPosition[queryColumn]
    appendOutput($storedValue)
  elif commandLetter == 'W':
    let targetValue = nextInt(inputData, scanPos)
    let originalRow = (targetValue - 1) div columnCount + 1
    let originalColumn = (targetValue - 1) mod columnCount + 1
    let currentRow = rowPositionOfOriginal[originalRow]
    let currentColumn = columnPositionOfOriginal[originalColumn]
    appendOutput($(currentRow) & " " & $(currentColumn))
```

The loop ends when `commandToken.len == 0` at EOF. A swap writes four entries, and each inverse entry keeps `W` constant. `Q` uses one multiplication, while `W` uses `div` and `mod`.

**Tail flush.** The last write emits any bytes below the block size.

```nim
stdout.write outputBuffer
outputBuffer.setLen 0
```

An empty buffer writes nothing, so a stream without queries is valid. Total writes stay at one per block.

## Complexity

The cost separates into one-time setup and constant work per command.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Table setup | 1234 + 5678 assignments | four integer arrays |
| Command loop | O(1) per command | label tables |
| Output | one write per 256 KiB block | 256 KiB block |

Setup runs once, and command cost does not depend on matrix size.

The asymptotic bounds follow from the label arrays:

| Measure | Big O |
|---|---|
| Time | O(k) for k commands |
| Space | O(rows + columns) plus I/O buffers |

Both bounds grow with the command stream, not with the 7,006,652 cells. Moving cells costs 5678 copies per row swap and a full scan of 7,006,652 cells per `W` query; labels keep both constant.
