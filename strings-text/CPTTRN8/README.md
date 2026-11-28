# CPTTRN8 — Character Patterns (Act 8) (SPOJ)

<https://www.spoj.com/problems/CPTTRN8/>

## Problem

Print a grid of diamonds with slash and backslash borders. Asterisks fill each diamond interior, and dots fill the space between diamonds.

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
/**\
\**/
.\/.
./\.
/**\
\**/
.\/.
./\.
/**\
\**/
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
/**\/**\/**\/**\/**\
\**/\**/\**/\**/\**/
.\/..\/..\/..\/..\/.
./\../\../\../\../\.
/**\/**\/**\/**\/**\
\**/\**/\**/\**/\**/
.\/..\/..\/..\/..\/.

```

## Idea

Think of outlining a rug and then coloring its middle. The outline uses the same diagonals as Act 7.

The tile has side 2s. Slashes sit where local row plus local column is s - 1 modulo 2s. Backslashes sit where the row and column differ by s. An asterisk appears strictly between the two diagonal bands. Dots fill all remaining cells. Each character costs a few integer tests.

One tile design covers both the outline and the fill.

## Why It Works

1. Tile coordinates run from 0 to 2s - 1 in each direction.
2. Slashes mark sums s - 1 and 3s - 1, which one modulo catches.
3. Backslashes mark positions where the row and column differ by s.
4. Interior cells have a sum above s - 1, a sum below 3s - 1, and a gap below s.

| Term | Meaning |
|---|---|
| `diamondSize` | s, the size of one diamond |
| `tileSide` | 2s, the repeat period in both directions |
| `innerSumLimit` | 3s - 1, the outer bound for interior sums |
| `diagonalGap` | absolute row minus column, marking borders |
| `slashSum` | s - 1, the inner bound for interior sums |

Three tests sort every cell into border, fill, or background.

A traced tile of size 2 from `gen.py`:

```
size 2, tile side 4
./\.
/**\
\**/
.\/.
flood fill from (2, 2) turns four dots into asterisks
```

The trace shows the four border marks and the four filled cells.

## Code

**Input and scanner.** The whole input is read once, then scanned by index.

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

`nextInt` skips whitespace directly in the buffer. No token list is built.

**Output helper.** Each character goes into one growing buffer.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

A flush occurs every 128 KiB. The final write emits any remainder.

**Grid driver.** Border tests come first, then the interior test.

```nim
let caseCount = nextInt(inputData, scanPos)
for _ in 0 ..< caseCount:
  let rowCount = nextInt(inputData, scanPos)
  let columnCount = nextInt(inputData, scanPos)
  let diamondSize = nextInt(inputData, scanPos)
  let tileSide = 2 * diamondSize
  let slashSum = diamondSize - 1
  let innerSumLimit = 3 * diamondSize - 1
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
      elif diagonalSum > slashSum and diagonalSum < innerSumLimit and diagonalGap < diamondSize:
        appendOutput("*")
      else:
        appendOutput(".")
    outputBuffer.add '\n'
  outputBuffer.add '\n'
stdout.write outputBuffer
```

The branch order keeps borders distinct from fill. The trailing blank line closes each case.

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

Drawing each diamond separately would repeat the same border work. Testing each tile cell once keeps the cost linear in the printed area.
