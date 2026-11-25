# PCROSS2 — Cross Pattern, Act 2 (SPOJ)

<https://www.spoj.com/problems/PCROSS2/>

## Problem

Draw an X on grid paper for each test case. Stars fill the two diagonals through the given centre; dots fill everything else. No whole row or column is filled.

Input: a case count `t`, then `t` lines with `m n ci cj`. Output: `m` lines of `n` characters per case, then one blank line after every case.

| Item | Bound |
|---|---|
| Test cases `t` | 1 to 100 |
| Rows `m` | 1 to 100 |
| Columns `n` | 1 to 100 |
| Centre | `ci <= m`, `cj <= n` |
| Judge limit | 1000 ms, 1536 MB |

The sample, verbatim:

```
3
1 1 1 1
5 5 3 3
8 13 3 5
```

```
*

*...*
.*.*.
..*..
.*.*.
*...*

..*...*......
...*.*.......
....*........
...*.*.......
..*...*......
.*.....*.....
*.......*....
.........*...

```

## Idea

Think of drawing two diagonal strokes through one point on squared paper. The distance-equality test writes each character directly.

The code converts the centre to zero-based indices, then compares the row distance with the column distance. Equal distances mark both diagonal strokes. Each cell costs two subtractions, one absolute value and one comparison.

The test needs no grid storage and no separate ray walk.

## Why It Works

1. A cell lies on a diagonal through the centre when its two distances from the centre match.
2. The centre cell has both distances zero, so it becomes a star.
3. Loop bounds keep every cell inside the grid, which clips the strokes at the edges.
4. One extra newline after the grid gives the blank line after every case, including the last.

| Term | Meaning |
|---|---|
| `caseCount` | the number of grids |
| `rowCount`, `columnCount` | the `m` and `n` of one case |
| `centerRow`, `centerColumn` | zero-based centre indices |
| `rowDistance`, `columnDistance` | distances from the centre |

Equal distances describe both diagonal strokes at once.

A traced run of the second sample case, produced by the generator:

```
case 5 by 5, center row 3, column 3
paint both diagonals through row 3, column 3
step (-1,-1) paints (2,2), (1,1)
step (-1,1) paints (2,4), (1,5)
step (1,-1) paints (4,2), (5,1)
step (1,1) paints (4,4), (5,5)
then one blank line
```

The traced ray cells match the middle pattern of the sample.

## Code

**Constants and input read.** One string holds every input line.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'
```

The digit offset is the byte of `0`. The block size bounds the output buffer.

**Digit scanner.** Each call advances the shared scan position past one integer.

```nim
var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value
```

The `var` parameter keeps the position between calls. All pattern values are nonnegative.

**Output buffer.** Appends collect bytes and write one block at a time.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

`setLen 0` reuses the storage after a write. Large grids span several blocks.

**Grid loop.** One distance test per cell and one blank line per case.

```nim
let caseCount = nextInt(inputData, scanPos)
var caseIndex = 0
while caseIndex < caseCount:
  let rowCount = nextInt(inputData, scanPos)
  let columnCount = nextInt(inputData, scanPos)
  let centerRow = nextInt(inputData, scanPos) - 1
  let centerColumn = nextInt(inputData, scanPos) - 1
  var rowIndex = 0
  while rowIndex < rowCount:
    var columnIndex = 0
    while columnIndex < columnCount:
      let rowDistance = abs(rowIndex - centerRow)
      let columnDistance = abs(columnIndex - centerColumn)
      if rowDistance == columnDistance:
        appendOutput("*")
      else:
        appendOutput(".")
      columnIndex += 1
    outputBuffer.add '\n'
    rowIndex += 1
  outputBuffer.add '\n'
  caseIndex += 1
stdout.write outputBuffer
outputBuffer.setLen 0
```

The loops visit `m` times `n` cells. The final write covers the tail.

## Complexity

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over the lines | input bytes |
| Digit scan | one pass over `4t+1` integers | constant |
| Grid loop | one distance test per cell | one buffer |
| Output | one write per block | one buffer |

The total printed area bounds the work.

| Measure | Big O |
|---|---|
| Time | O(sum of m times n over all cases) |
| Space | O(input bytes) plus one output block |

Painting a grid and walking four rays would also cost O(m times n) but needs O(m times n) storage.
