# SPTTRN2 — Straight Line Spiral Pattern (Act 2) (SPOJ)

<https://www.spoj.com/problems/SPTTRN2/>

## Problem

Draw the straight-line spiral of Act 1, but turned a quarter turn: its first arm runs down the left edge. Print one pattern per test case.

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
*.**
*..*
*..*
****

*.***
*.*.*
*.*.*
*...*
*****

*.*********
*.*.......*
*.*.*****.*
*.*.*...*.*
*.*.*.*.*.*
*.*.*.*.*.*
*.*.***.*.*
*.*.....*.*
*.*******.*
*.........*
***********

*.***********
*.*.........*
*.*.*******.*
*.*.*.....*.*
*.*.*.***.*.*
*.*.*.*.*.*.*
*.*.*.*.*.*.*
*.*.*...*.*.*
*.*.*****.*.*
*.*.......*.*
*.*********.*
*...........*
*************

*.****************************************************************************
*.*..........................................................................*
*.*.************************************************************************.*
*.*.*......................................................................*.*
*.*.*.********************************************************************.*.*
*.*.*.*..................................................................*.*.*
*.*.*.*.****************************************************************.*.*.*
*.*.*.*.*..............................................................*.*.*.*
*.*.*.*.*.************************************************************.*.*.*.*
*.*.*.*.*.*..........................................................*.*.*.*.*
*.*.*.*.*.*.********************************************************.*.*.*.*.*
*.*.*.*.*.*.*......................................................*.*.*.*.*.*
*.*.*.*.*.*.*.****************************************************.*.*.*.*.*.*
*.*.*.*.*.*.*.*..................................................*.*.*.*.*.*.*
*.*.*.*.*.*.*.*.************************************************.*.*.*.*.*.*.*
*.*.*.*.*.*.*.*.*..............................................*.*.*.*.*.*.*.*
*.*.*.*.*.*.*.*.*.********************************************.*.*.*.*.*.*.*.*
*.*.*.*.*.*.*.*.*.*..........................................*.*.*.*.*.*.*.*.*
*.*.*.*.*.*.*.*.*.*.****************************************.*.*.*.*.*.*.*.*.*
*.*.*.*.*.*.*.*.*.*.*......................................*.*.*.*.*.*.*.*.*.*
*.*.*.*.*.*.*.*.*.*.*.************************************.*.*.*.*.*.*.*.*.*.*
*.*.*.*.*.*.*.*.*.*.*.*..................................*.*.*.*.*.*.*.*.*.*.*
*.*.*.*.*.*.*.*.*.*.*.*.********************************.*.*.*.*.*.*.*.*.*.*.*
*.*.*.*.*.*.*.*.*.*.*.*.*..............................*.*.*.*.*.*.*.*.*.*.*.*
*.*.*.*.*.*.*.*.*.*.*.*.*.****************************.*.*.*.*.*.*.*.*.*.*.*.*
*.*.*.*.*.*.*.*.*.*.*.*.*.*..........................*.*.*.*.*.*.*.*.*.*.*.*.*
*.*.*.*.*.*.*.*.*.*.*.*.*.*.************************.*.*.*.*.*.*.*.*.*.*.*.*.*
*.*.*.*.*.*.*.*.*.*.*.*.*.*.*......................*.*.*.*.*.*.*.*.*.*.*.*.*.*
*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.********************.*.*.*.*.*.*.*.*.*.*.*.*.*.*
*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*..................*.*.*.*.*.*.*.*.*.*.*.*.*.*.*
*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.****************.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*
*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*..............*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*
*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.************.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*
*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*..........*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*
*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.********.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*
*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*......*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*
*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.****.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*
*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*..*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*
*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*..*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*
*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.**.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*
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

Picture the Act 1 spiral drawn on a transparent sheet, then viewed after turning the sheet a quarter turn. The stars land in new places but the walk is the same.

The program fills the Act 1 rows, then writes them column by column. That transpose costs one index swap per printed character, so the per-case cost stays O(s²).

## Why It Works

1. Reading row `r`, column `c` of the transpose gives row `c`, column `r` of the original.
2. The first column of the original becomes the first row of the output, so the new pattern starts downward.
3. Every star is visited once, so no character is lost or duplicated.
4. The blank line after every case matches the sample's byte shape.

| Term | Meaning |
|---|---|
| `rows` | the Act 1 pattern stored as text rows |
| `columnIndex` | the output row, taken from a column of `rows` |
| `rowIndex` | the position inside the current output row |

The transpose is a single swap of the two loop indices.

A script-generated trace of the case `s = 5`:

```
column 0 of rows: * * * * *  -> output row 0 "*****"
column 1 of rows: . . . . *  -> output row 1 "....*"
column 2 of rows: * * * . *  -> output row 2 "*.*.*"
column 3 of rows: . . . . *  -> output row 3 "....*"
column 4 of rows: * * * * *  -> output row 4 "*****"
```

The traced row 0 matches the first row of the size five sample pattern.

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

**Layer fill.** Draw each ring of the Act 1 pattern into a list of rows.

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

**Driver.** Write the stored rows as columns, with one blank line each.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 ..< caseCount:
  let size = nextInt(inputData, scanPos)
  let rows = buildPattern(size)
  for columnIndex in 0 ..< size:
    var line = ""
    for rowIndex in 0 ..< size:
      line.add rows[rowIndex][columnIndex]
    appendOutput(line)
    outputBuffer.add '\n'
  outputBuffer.add '\n'
stdout.write outputBuffer

```

The outer loop selects a column. The inner loop stacks its characters into one output row.

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

A second grid for the transpose would double the storage. Writing columns straight into the buffer avoids that copy.
