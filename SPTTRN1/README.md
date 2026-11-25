# SPTTRN1 — Straight Line Spiral Pattern (Act 1) (SPOJ)

<https://www.spoj.com/problems/SPTTRN1/>

## Problem

Draw a square spiral of stars and dots that starts at the top-left corner and runs clockwise inward. Print one pattern per test case.

The input starts with a test count. Each case gives one integer `s`, the side length. Every output case is followed by a blank line.

| Item | Bound |
|---|---|
| Test cases | not stated |
| Side length `s` | 4 to 99 |
| Judge limit | 1000 ms, 1536 MB |

The sample input:

```
5
4
5
11
13
78
```

The sample output:

```
****
...*
*..*
****

*****
....*
***.*
*...*
*****

***********
..........*
*********.*
*.......*.*
*.*****.*.*
*.*...*.*.*
*.*.***.*.*
*.*.....*.*
*.*******.*
*.........*
***********

*************
............*
***********.*
*.........*.*
*.*******.*.*
*.*.....*.*.*
*.*.***.*.*.*
*.*.*...*.*.*
*.*.*****.*.*
*.*.......*.*
*.*********.*
*...........*
*************

******************************************************************************
.............................................................................*
****************************************************************************.*
*..........................................................................*.*
*.************************************************************************.*.*
*.*......................................................................*.*.*
*.*.********************************************************************.*.*.*
*.*.*..................................................................*.*.*.*
*.*.*.****************************************************************.*.*.*.*
*.*.*.*..............................................................*.*.*.*.*
*.*.*.*.************************************************************.*.*.*.*.*
*.*.*.*.*..........................................................*.*.*.*.*.*
*.*.*.*.*.********************************************************.*.*.*.*.*.*
*.*.*.*.*.*......................................................*.*.*.*.*.*.*
*.*.*.*.*.*.****************************************************.*.*.*.*.*.*.*
*.*.*.*.*.*.*..................................................*.*.*.*.*.*.*.*
*.*.*.*.*.*.*.************************************************.*.*.*.*.*.*.*.*
*.*.*.*.*.*.*.*..............................................*.*.*.*.*.*.*.*.*
*.*.*.*.*.*.*.*.********************************************.*.*.*.*.*.*.*.*.*
*.*.*.*.*.*.*.*.*..........................................*.*.*.*.*.*.*.*.*.*
*.*.*.*.*.*.*.*.*.****************************************.*.*.*.*.*.*.*.*.*.*
*.*.*.*.*.*.*.*.*.*......................................*.*.*.*.*.*.*.*.*.*.*
*.*.*.*.*.*.*.*.*.*.************************************.*.*.*.*.*.*.*.*.*.*.*
*.*.*.*.*.*.*.*.*.*.*..................................*.*.*.*.*.*.*.*.*.*.*.*
*.*.*.*.*.*.*.*.*.*.*.********************************.*.*.*.*.*.*.*.*.*.*.*.*
*.*.*.*.*.*.*.*.*.*.*.*..............................*.*.*.*.*.*.*.*.*.*.*.*.*
*.*.*.*.*.*.*.*.*.*.*.*.****************************.*.*.*.*.*.*.*.*.*.*.*.*.*
*.*.*.*.*.*.*.*.*.*.*.*.*..........................*.*.*.*.*.*.*.*.*.*.*.*.*.*
*.*.*.*.*.*.*.*.*.*.*.*.*.************************.*.*.*.*.*.*.*.*.*.*.*.*.*.*
*.*.*.*.*.*.*.*.*.*.*.*.*.*......................*.*.*.*.*.*.*.*.*.*.*.*.*.*.*
*.*.*.*.*.*.*.*.*.*.*.*.*.*.********************.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*
*.*.*.*.*.*.*.*.*.*.*.*.*.*.*..................*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*
*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.****************.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*
*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*..............*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*
*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.************.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*
*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*..........*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*
*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.********.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*
*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*......*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*
*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.****.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*
*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*..*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*
*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*....*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*
*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.******.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*
*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*........*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*
*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.**********.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*
*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*............*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*
*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.**************.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*
*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*................*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*
*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.******************.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*
*.*.*.*.*.*.*.*.*.*.*.*.*.*.*....................*.*.*.*.*.*.*.*.*.*.*.*.*.*.*
*.*.*.*.*.*.*.*.*.*.*.*.*.*.**********************.*.*.*.*.*.*.*.*.*.*.*.*.*.*
*.*.*.*.*.*.*.*.*.*.*.*.*.*........................*.*.*.*.*.*.*.*.*.*.*.*.*.*
*.*.*.*.*.*.*.*.*.*.*.*.*.**************************.*.*.*.*.*.*.*.*.*.*.*.*.*
*.*.*.*.*.*.*.*.*.*.*.*.*............................*.*.*.*.*.*.*.*.*.*.*.*.*
*.*.*.*.*.*.*.*.*.*.*.*.******************************.*.*.*.*.*.*.*.*.*.*.*.*
*.*.*.*.*.*.*.*.*.*.*.*................................*.*.*.*.*.*.*.*.*.*.*.*
*.*.*.*.*.*.*.*.*.*.*.**********************************.*.*.*.*.*.*.*.*.*.*.*
*.*.*.*.*.*.*.*.*.*.*....................................*.*.*.*.*.*.*.*.*.*.*
*.*.*.*.*.*.*.*.*.*.**************************************.*.*.*.*.*.*.*.*.*.*
*.*.*.*.*.*.*.*.*.*........................................*.*.*.*.*.*.*.*.*.*
*.*.*.*.*.*.*.*.*.******************************************.*.*.*.*.*.*.*.*.*
*.*.*.*.*.*.*.*.*............................................*.*.*.*.*.*.*.*.*
*.*.*.*.*.*.*.*.**********************************************.*.*.*.*.*.*.*.*
*.*.*.*.*.*.*.*................................................*.*.*.*.*.*.*.*
*.*.*.*.*.*.*.**************************************************.*.*.*.*.*.*.*
*.*.*.*.*.*.*....................................................*.*.*.*.*.*.*
*.*.*.*.*.*.******************************************************.*.*.*.*.*.*
*.*.*.*.*.*........................................................*.*.*.*.*.*
*.*.*.*.*.**********************************************************.*.*.*.*.*
*.*.*.*.*............................................................*.*.*.*.*
*.*.*.*.**************************************************************.*.*.*.*
*.*.*.*................................................................*.*.*.*
*.*.*.******************************************************************.*.*.*
*.*.*....................................................................*.*.*
*.*.**********************************************************************.*.*
*.*........................................................................*.*
*.**************************************************************************.*
*............................................................................*
******************************************************************************

```

## Idea

Think of a gardener walking a square hedge, then stepping two paces inward to repeat the job. The program walks the same clockwise spiral, leaving one dot of space between parallel arms.

Each layer draws four arms around a shrinking square. It costs O(s) cells per layer and O(s²) cells per case. Writing rows into one buffer keeps the output path simple.

## Why It Works

1. The first arm fills the top row, so the pattern starts with stars.
2. Each new layer sits two rows and two columns inside the previous one, leaving a dot gap.
3. The bottom arm shortens when the layer is only two rows tall, so the centre stays open.
4. The blank line after every case matches the sample's byte shape.

| Term | Meaning |
|---|---|
| `layer` | the current ring of the spiral, counting from zero |
| `topRow` | the first row of the current ring |
| `bottomRow` | the last row of the current ring |
| `leftCol` | the first column of the current ring |
| `rightCol` | the last column of the current ring |

The four bounds of a layer decide every star in that ring.

A script-generated trace of the case `s = 6`:

```
layer 0: top row 0, right col 5, bottom row 5, left col 0 from row 2
layer 1: top row 2, right col 3, bottom row 3 shortened to col 3
row 0: ******
row 1: .....*
row 2: ****.*
row 3: *..*.*
row 4: *....*
row 5: ******
```

The traced row 2 matches the second row of a size six spiral.

## Code

**Input and scanner.** Read all lines into one string, then scan integers by index.

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The loop uses `readLine`, which the judge compiler provides. The scanner turns digit bytes into values without any parse call.

**Layer fill.** Draw each ring of the spiral into a list of rows.

```nim
proc buildPattern(size: int): seq[string] =
  var rows = newSeq[string](size)
  for rowIndex in 0 ..< size:
    var line = ""
    for columnIndex in 0 ..< size:
      line.add '.'
    rows[rowIndex] = line
  var layer = 0
  while true:
    let topRow = 2 * layer
    let bottomRow = size - 1 - 2 * layer
    let leftCol = 2 * layer
    let rightCol = size - 1 - 2 * layer
    if topRow > bottomRow or leftCol > rightCol:
      break
    var startCol = 2 * layer - 2
    if startCol < 0:
      startCol = 0
    var columnIndex = startCol
    while columnIndex <= rightCol:
      rows[topRow][columnIndex] = '*'
      columnIndex += 1
    var rowIndex = topRow
    while rowIndex <= bottomRow:
      rows[rowIndex][rightCol] = '*'
      rowIndex += 1
    if topRow + 2 <= bottomRow:
      columnIndex = leftCol
      while columnIndex <= rightCol:
        rows[bottomRow][columnIndex] = '*'
        columnIndex += 1
    else:
      rows[bottomRow][rightCol] = '*'
    rowIndex = topRow + 2
    while rowIndex <= bottomRow:
      rows[rowIndex][leftCol] = '*'
      rowIndex += 1
    layer += 1
  return rows
```

The loop stops when the bounds cross. The special case keeps a two-row layer from drawing a full bottom arm.

**Driver.** Read the cases and write the rows with one blank line each.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 ..< caseCount:
  let size = nextInt(inputData, scanPos)
  let rows = buildPattern(size)
  for rowIndex in 0 ..< size:
    appendOutput(rows[rowIndex])
    outputBuffer.add '\n'
  outputBuffer.add '\n'
stdout.write outputBuffer

```

Each row is appended whole, then a newline. One final write flushes the remaining buffer.

## Complexity

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| One pattern | O(s²) cell writes | s rows |
| Output | one write per buffer block | one buffer |

The side length bounds the work in each case.

| Measure | Big O |
|---|---|
| Time | O(total printed characters) |
| Space | O(s²) for one pattern |

A per-character stream write would add call overhead to every cell. Filling rows first keeps the cost on the characters themselves.
