# PCROSS1 — Cross Pattern, Act 1 (SPOJ)

<https://www.spoj.com/problems/PCROSS1/>

## Problem

Draw a plus sign on grid paper for each test case. Stars fill the center row and the center column; dots fill everything else.

Input: a case count `t`, then `t` lines with `m n ci cj`. Output: `m` lines of `n` characters per case, then one blank line after every case.

| Item | Bound |
|---|---|
| Test cases `t` | 1 to 100 |
| Rows `m` | 1 to 100 |
| Columns `n` | 1 to 100 |
| Center | `ci <= m`, `cj <= n` |
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

..*..
..*..
*****
..*..
..*..

....*........
....*........
*************
....*........
....*........
....*........
....*........
....*........

```

## Idea

Think of drawing a plus sign on squared paper by filling one whole row and one whole column. The cell-membership test writes each character directly.

The code converts the given center to zero-based indices, then tests every cell. Each cell costs two comparisons and one append. Building rows separately would add a copy step.

The direct test needs no grid storage.

## Why It Works

1. Subtracting one from `ci` and `cj` aligns them with zero-based loop indices.
2. A cell is a star when its row equals the center row or its column equals the center column.
3. Each finished row ends with a newline, so the block has exactly `m` lines.
4. One extra newline after the grid gives the blank line after every case, including the last.

| Term | Meaning |
|---|---|
| `caseCount` | the number of grids |
| `rowCount`, `columnCount` | the `m` and `n` of one case |
| `centerRow`, `centerColumn` | zero-based center indices |
| `rowIndex`, `columnIndex` | the current cell |

The membership test decides every character.

A traced run of the second sample case, produced by the generator:

```
case 5 by 5, center row 3, column 3
row 3 is the full row *****
every other row is ..*..
then one blank line
```

The trace matches the middle pattern of the sample.

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

**Grid loop.** One membership test per cell and one blank line per case.

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
      if rowIndex == centerRow or columnIndex == centerColumn:
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
| Grid loop | one membership test per cell | one buffer |
| Output | one write per block | one buffer |

The total printed area bounds the work.

| Measure | Big O |
|---|---|
| Time | O(sum of m times n over all cases) |
| Space | O(input bytes) plus one output block |

Storing each grid before printing would add O(m times n) space per case.
