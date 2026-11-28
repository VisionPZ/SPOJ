# CPTTRN5 — Character Patterns (Act 5) (SPOJ)

<https://www.spoj.com/problems/CPTTRN5/>

## Problem

Print a grid of `l` rows and `c` columns, where each cell is a square of size `s` with one diagonal. The diagonal slopes down-right in the first cell and alternates with up-right across the grid.

The input starts with a test count. Each case gives three positive integers: `l`, `c`, and `s`. A star border row precedes the first cell row and follows every cell row. A blank line follows each case, including the last.

| Item | Bound |
|---|---|
| Test cases | fewer than 100 |
| Rows `l` | positive integer, below 100 |
| Columns `c` | positive integer, below 100 |
| Square size `s` | positive integer, below 100 |
| Judge limit | 1000 ms, 1536 MB |

The sample from the statement:

```
3
3 1 2
4 4 1
2 5 2
```

```
****
*\.*
*.\*
****
*./*
*/.*
****
*\.*
*.\*
****

*********
*\*/*\*/*
*********
*/*\*/*\*
*********
*\*/*\*/*
*********
*/*\*/*\*
*********

****************
*\.*./*\.*./*\.*
*.\*/.*.\*/.*.\*
****************
*./*\.*./*\.*./*
*/.*.\*/.*.\*/.*
****************

```

## Idea

Picture a tiled floor where every tile holds a diagonal stripe and the stripe turns the other way in the next tile.

The program prints a star border row first. For each square row it prints `s` content rows and then another border row. Star columns sit at multiples of `s + 1`. Inside a tile, the parity of square row plus square column selects backslash for even and slash for odd. A backslash sits where local row equals local column; a slash sits where local row plus local column equals `s - 1`.

Each character takes one comparison, so the work follows the printed size.

## Why It Works

1. Star columns at multiples of `s + 1` form the shared borders between neighboring squares.
2. A star row is printed before and after every square row, giving `l * (s + 1) + 1` rows per case.
3. Moving one tile right or down flips the parity, so the diagonals alternate in both directions.
4. A backslash follows local cells from `(0,0)` to `(s-1,s-1)`; a slash follows `(0,s-1)` to `(s-1,0)`.
5. The blank line after each case matches the sample byte shape, including the final case.

| Term | Meaning |
|---|---|
| `squareSize` | the height and width of one tile |
| `stride` | `squareSize + 1`, the step from one tile to the next |
| `localRow` | the row inside the current tile, from zero |
| `outputBuffer` | the single string that collects all pattern bytes |

A traced run of the sample case `2 5 2` from `gen.py`:

```
border row 0: ****************
row 1 (local 0): *\.*./*\.*./*\.*
row 2 (local 1): *.\*/.*.\*/.*.\*
border row 3, content rows 4 and 5, border row 6, then a blank line
```

The traced rows match the last pattern of the sample.

## Code

**Tile loop.** One character decision per printed position.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18

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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 ..< caseCount:
  let lineCount = nextInt(inputData, scanPos)
  let columnCount = nextInt(inputData, scanPos)
  let squareSize = nextInt(inputData, scanPos)
  let stride = squareSize + 1
  let totalColumns = columnCount * stride + 1
  for columnIndex in 0 ..< totalColumns:
    appendOutput("*")
  outputBuffer.add '\n'
  for squareRow in 0 ..< lineCount:
    for localRow in 0 ..< squareSize:
      for columnIndex in 0 ..< totalColumns:
        if columnIndex mod stride == 0:
          appendOutput("*")
        elif (squareRow + columnIndex div stride) mod 2 == 0:
          if localRow == columnIndex mod stride - 1:
            appendOutput("\\")
          else:
            appendOutput(".")
        elif localRow + columnIndex mod stride - 1 == squareSize - 1:
          appendOutput("/")
        else:
          appendOutput(".")
      outputBuffer.add '\n'
    for columnIndex in 0 ..< totalColumns:
      appendOutput("*")
    outputBuffer.add '\n'
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Each case prints `l * (s + 1) + 1` rows. Nim 0.19.4 has no `%` operator, so the code uses `mod`. One buffer collects the bytes before a block write.

## Complexity

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over the input bytes | input bytes |
| Pattern build | one decision per printed character | one output buffer |
| Output | one write per full block | one block |

The printed character count bounds the middle phase.

| Measure | Big O |
|---|---|
| Time | O(total printed characters) |
| Space | O(input bytes) |

A fresh string per row would add copying on top of the character work. One buffer keeps the cost on the pattern itself.
