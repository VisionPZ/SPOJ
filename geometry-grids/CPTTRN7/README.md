# CPTTRN7 — Character Patterns (Act 7) (SPOJ)

<https://www.spoj.com/problems/CPTTRN7/>

## Problem

Print a grid of diamond outlines built from slashes and backslashes. Dots fill every position outside the diamonds.

The input starts with t, the number of test cases. Each case gives three positive integers: r, c, and s. They count diamond rows, diamond columns, and diamond size. Print 2rs lines, each 2cs characters wide. Follow every case with one blank line, including the last case.

| Item | Bound |
|---|---|
| Test cases | positive integer, no numeric bound stated |
| r, c, s | positive integers, no numeric bounds stated |
| Printed grid | 2rs lines by 2cs characters |
| Judge limit | 1000 ms, 1536 MB |

The sample:

```
3
3 1 2
4 4 1
2 5 2
```

```
./\.
/..\
\../
.\/.
./\.
/..\
\../
.\/.
./\.
/..\
\../
.\/.

/\/\/\/\
\/\/\/\/
/\/\/\/\
\/\/\/\/
/\/\/\/\
\/\/\/\/
/\/\/\/\
\/\/\/\/

./\../\../\../\../\.
/..\/..\/..\/..\/..\
\../\../\../\../\../
.\/..\/..\/..\/..\/.
./\../\../\../\../\.
/..\/..\/..\/..\/..\
\../\../\../\../\../
.\/..\/..\/..\/..\/.

```

## Idea

A tiled floor makes this easy to picture. One diamond tile is stamped across the whole grid.

The tile has side 2s. A slash appears where local row plus local column equals s - 1 modulo 2s. A backslash appears where the row and column differ by s. All other positions are dots. Each printed character costs one sum, one absolute value, and two modulo tests.

The same local test serves every tile in the grid.

## Why It Works

1. Coordinates inside one tile run from 0 to 2s - 1 in both directions.
2. The rising edge sits at sums s - 1 and 3s - 1. A modulo by 2s catches both.
3. The falling edge sits where row and column differ by s. Absolute value catches both slopes.
4. Row and column modulo 2s map each grid cell to its place in the tile.

| Term | Meaning |
|---|---|
| `diamondSize` | s, the size of one diamond |
| `tileSide` | 2s, the repeat period in both directions |
| `slashSum` | s - 1, the rising diagonal sum inside a tile |
| `diagonalGap` | absolute row minus column, marking falling edges |
| `localRow` | row index reduced modulo `tileSide` |

Two diagonal tests describe the whole tile.

A traced run of the s = 3 tile from `gen.py`:

```
size 3, tile side 6, slash sum 2
row 0: ../\..
row 1: ./..\.
row 2: /....\
row 3: \..../
row 4: .\../.
row 5: ..\/..
repeat the tile every 6 rows and columns
```

The trace draws the six rows of one diamond tile.

## Code

**Input and scanner.** Lines are collected into one string before any scanning.

```nim
const firstDigitValue = 48
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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value
```

`readLine` works on the judge compiler. `nextInt` walks the buffer by index without allocating tokens.

**Output helper.** Characters accumulate in one buffer.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The buffer flushes after 128 KiB. Final output is one write at the end.

**Grid driver.** Two modulo coordinates decide each printed character.

```nim
let caseCount = nextInt(inputData, scanPos)
for _ in 0 ..< caseCount:
  let rowCount = nextInt(inputData, scanPos)
  let columnCount = nextInt(inputData, scanPos)
  let diamondSize = nextInt(inputData, scanPos)
  let tileSide = 2 * diamondSize
  let slashSum = diamondSize - 1
  let totalRows = rowCount * tileSide
  let totalColumns = columnCount * tileSide
  for rowIndex in 0 ..< totalRows:
    let localRow = rowIndex mod tileSide
    for columnIndex in 0 ..< totalColumns:
      let localColumn = columnIndex mod tileSide
      let diagonalSum = localRow + localColumn
      let diagonalGap = abs(localRow - localColumn)
      if diagonalSum mod tileSide == slashSum:
        appendOutput("/")
      elif diagonalGap == diamondSize:
        appendOutput("\\")
      else:
        appendOutput(".")
    outputBuffer.add '\n'
  outputBuffer.add '\n'
stdout.write outputBuffer
```

The loop visits exactly 2rs by 2cs positions. The last blank line closes every case.

## Complexity

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Character decision | constant work per cell | no extra storage |
| Output | one write per 128 KiB block | one output buffer |

The printed area bounds the work per case.

| Measure | Big O |
|---|---|
| Time | O(printed characters) |
| Space | O(input bytes) |

Building each row by joining repeated strings would copy tiles many times. Writing each character once keeps the cost proportional to the printed area.
