# BSHIP — Battleships (SPOJ)

<https://www.spoj.com/problems/BSHIP/>

## Problem

A random square of fixed size is placed on a grid of single-cell ships. Report the average number of ships inside that square, rounded to six decimal places.

Input starts with `rowCount`, `columnCount`, and `squareSize`. The next `rowCount` lines hold grid characters, with X for a ship and a dot for an empty cell. Output one decimal number with exactly six digits after the point.

The bounds from the statement:

| Item | Bound |
|---|---|
| Rows M | 1 to 2000 |
| Columns N | 1 to 2000 |
| Square side S | 1 to min(M, N) |
| Judge limit | 2000 ms, 1536 MB |

The grid size drives the scan, while the answer needs only integer sums before rounding.

The sample input:

```
3 4 2
XX.X
XX..
.X..
```

The sample output:

```
2.000000
```

Twelve ships counted over six squares give the sample average of two.

## Idea

Linearity of expectation turns the problem into counting how many squares cover each ship, like counting how many camera frames include each tree in a field.

The algorithm is a per-cell coverage count. A cell at row i is covered by `rowCoverage` possible top rows, and a column j is covered by `columnCoverage` possible left columns. Their product is the number of squares containing that ship. Each ship costs two clips and one multiply. Checking every square and every cell inside it costs up to S squared work per square, far more on large grids. The takeaway is to move the sum from squares to cells.

## Why It Works

1. A square with top row r covers cell row i when r is between i - S + 1 and i.
2. Clipping that interval to the legal top rows 0 through M - S gives `rowCoverage`.
3. Columns give `columnCoverage` in the same way.
4. A ship is counted once for each square that contains it, so its contribution is the product of the two coverage counts.
5. Linearity of expectation lets those contributions be summed before dividing by the number of squares.
6. Rounding half up is done with integers, so no floating-point error reaches the answer.

The main terms:

| Term | Meaning |
|---|---|
| `rowCoverage` | number of legal top rows covering a ship row |
| `columnCoverage` | number of legal left columns covering a ship column |
| `shipTotal` | sum of coverage products over all ships |
| `squareCount` | number of legal positions for the square |

The table shows that the numerator and denominator are both exact integers.

The generator trace for the sample uses these visible values:

```
row coverages:      1 2 1
column coverages:   1 2 2 1
ship contributions: 1 + 2 + 1 + 1 + 2 + 2 + 2 = 12
squares:            (3-2+1) * (4-2+1) = 2 * 3 = 6
12 / 6 = 2.000000
```

The trace matches the sample output exactly.

## Code

**Input and scanning.** The reader loads the header, then walks the grid row by row.

```nim
const flushBlockBytes = 1 shl 17
const decimalPlaces = 1000000

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
```

All grid lines enter one input string before parsing.
The scanner ignores line breaks between header values.
Grid characters are read directly from the input string later.

**Output and coverage sum.** The buffer is set up, and each ship adds its product of coverage counts.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let rowCount = nextInt(inputData, scanPos)
let columnCount = nextInt(inputData, scanPos)
let squareSize = nextInt(inputData, scanPos)
let lastRowStart = rowCount - squareSize
let lastColumnStart = columnCount - squareSize
while scanPos < inputData.len and inputData[scanPos] <= ' ':
  scanPos += 1

var shipTotal: int64 = 0
for rowIndex in 0 .. rowCount - 1:
  let firstCoveringRow = max(0, rowIndex - squareSize + 1)
  let lastCoveringRow = min(rowIndex, lastRowStart)
  let rowCoverage = int64(lastCoveringRow - firstCoveringRow + 1)
  for columnIndex in 0 .. columnCount - 1:
    let cellChar = inputData[scanPos]
    scanPos += 1
    if cellChar == 'X':
      let firstCoveringColumn = max(0, columnIndex - squareSize + 1)
      let lastCoveringColumn = min(columnIndex, lastColumnStart)
      let columnCoverage = int64(lastCoveringColumn - firstCoveringColumn + 1)
      shipTotal = shipTotal + rowCoverage * columnCoverage
  while scanPos < inputData.len and inputData[scanPos] <= ' ':
    scanPos += 1
```

Row coverage is computed once per row, outside the column loop.
Each ship adds at most four million, so the total stays in int64.
Whitespace skipping handles line endings between grid rows.

**Rounded output.** The integer quotient and remainder produce six exact decimal digits.

```nim
let squareCount = int64(rowCount - squareSize + 1) * int64(columnCount - squareSize + 1)
var wholePart = shipTotal div squareCount
let remainder = shipTotal mod squareCount
var fractionalPart = (2 * remainder * int64(decimalPlaces) + squareCount) div (2 * squareCount)
if fractionalPart >= int64(decimalPlaces):
  fractionalPart = 0
  wholePart += 1

appendOutput($wholePart)
appendOutput(".")
var digitDivisor = decimalPlaces div 10
while digitDivisor > 0:
  appendOutput($(fractionalPart div int64(digitDivisor) mod 10))
  digitDivisor = digitDivisor div 10
appendOutput("\n")
stdout.write outputBuffer
outputBuffer.setLen 0
```

Doubling before division implements half-up rounding without floats.
A carry from the fractional digits raises the whole part by one.
Leading zeros are written one digit at a time into the buffer.

## Complexity

Each grid cell is visited once, and no work depends on the square side.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over MN characters | input string |
| Coverage sum | one multiply per ship | constant scalars |
| Output | six digits and one line | block buffer |

The table shows that the grid scan is the only input-sized phase.

| Measure | Big O |
|---|---|
| Time | O(MN) |
| Space | O(MN) for the input string |

Scanning every square and its cells would cost O(S squared MN) in the worst case. Per-cell coverage reduces that to one pass with no dependence on S.
