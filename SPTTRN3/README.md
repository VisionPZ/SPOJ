# SPTTRN3 — Straight Line Spiral Pattern (Act 3) (SPOJ)

<https://www.spoj.com/problems/SPTTRN3/>

## Problem

Draw a straight-line spiral of stars and dots whose turn direction changes as it moves inward. Print one pattern per test case.

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
***.*****.*
*.*.*...*.*
*.*.***.*.*
*.*...*.*.*
*.*.***.*.*
*.*.....*.*
*.*******.*
*.........*
***********

*************
............*
***.*******.*
*.*.*.....*.*
*.*.*****.*.*
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
***.************************************************************************.*
*.*.*......................................................................*.*
*.*.**********************************************************************.*.*
*.*......................................................................*.*.*
*.*.***.****************************************************************.*.*.*
*.*.*.*.*..............................................................*.*.*.*
*.*.*.*.**************************************************************.*.*.*.*
*.*.*.*..............................................................*.*.*.*.*
*.*.*.*.***.********************************************************.*.*.*.*.*
*.*.*.*.*.*.*......................................................*.*.*.*.*.*
*.*.*.*.*.*.******************************************************.*.*.*.*.*.*
*.*.*.*.*.*......................................................*.*.*.*.*.*.*
*.*.*.*.*.*.***.************************************************.*.*.*.*.*.*.*
*.*.*.*.*.*.*.*.*..............................................*.*.*.*.*.*.*.*
*.*.*.*.*.*.*.*.**********************************************.*.*.*.*.*.*.*.*
*.*.*.*.*.*.*.*..............................................*.*.*.*.*.*.*.*.*
*.*.*.*.*.*.*.*.***.****************************************.*.*.*.*.*.*.*.*.*
*.*.*.*.*.*.*.*.*.*.*......................................*.*.*.*.*.*.*.*.*.*
*.*.*.*.*.*.*.*.*.*.**************************************.*.*.*.*.*.*.*.*.*.*
*.*.*.*.*.*.*.*.*.*......................................*.*.*.*.*.*.*.*.*.*.*
*.*.*.*.*.*.*.*.*.*.***.********************************.*.*.*.*.*.*.*.*.*.*.*
*.*.*.*.*.*.*.*.*.*.*.*.*..............................*.*.*.*.*.*.*.*.*.*.*.*
*.*.*.*.*.*.*.*.*.*.*.*.******************************.*.*.*.*.*.*.*.*.*.*.*.*
*.*.*.*.*.*.*.*.*.*.*.*..............................*.*.*.*.*.*.*.*.*.*.*.*.*
*.*.*.*.*.*.*.*.*.*.*.*.***.************************.*.*.*.*.*.*.*.*.*.*.*.*.*
*.*.*.*.*.*.*.*.*.*.*.*.*.*.*......................*.*.*.*.*.*.*.*.*.*.*.*.*.*
*.*.*.*.*.*.*.*.*.*.*.*.*.*.**********************.*.*.*.*.*.*.*.*.*.*.*.*.*.*
*.*.*.*.*.*.*.*.*.*.*.*.*.*......................*.*.*.*.*.*.*.*.*.*.*.*.*.*.*
*.*.*.*.*.*.*.*.*.*.*.*.*.*.***.****************.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*
*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*..............*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*
*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.**************.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*
*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*..............*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*
*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.***.********.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*
*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*......*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*
*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.******.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*
*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*......*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*
*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.***..*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*.*
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

Imagine a walker who circles a lawn clockwise, then switches to anticlockwise on the next smaller lawn. It keeps switching direction at every inward step.

The program draws five arms per group. Even groups turn clockwise, odd groups turn anticlockwise, and each group spans four fewer cells. The cost is O(L) per group and O(s²) per case.

## Why It Works

1. Group `k` starts at cell `(2k, 2k)`, so every group begins on the main diagonal.
2. Group `k` spans from row `2k` to row `s-1-2k`, leaving a one-dot gap to the next group.
3. Alternating the handedness makes the arms meet the next group at its diagonal start.
4. Short arms are skipped when the span is too small, which keeps the centre open.

| Term | Meaning |
|---|---|
| `group` | the current inward ring, counting from zero |
| `groupSize` | the span of the current ring |
| `rowSteps` | row moves for the five arms |
| `colSteps` | column moves for the five arms |
| `armLengths` | the five planned arm lengths |

The five arm lengths and the two step tables decide the whole pattern.

A script-generated trace of the case `s = 6`:

```
group 0: size 5, clockwise, from (0,0)
  right 5, down 5, left 5, up 3, right 2
group 1: size 1, anticlockwise, from (2,2)
  down 1, right 1, then stop
row 0: ******
row 1: .....*
row 2: ***..*
row 3: *.**.*
row 4: *....*
row 5: ******
```

The traced row 2 matches the third row of a size six spiral.

## Code

**Constants and scanner.** Hold the step tables, read all lines, and scan integers.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 17
const clockwiseRows = [0, 1, 0, -1, 0]
const clockwiseCols = [1, 0, -1, 0, 1]
const counterRows = [1, 0, -1, 0, 1]
const counterCols = [0, 1, 0, -1, 0]

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

The step tables replace a turn calculation. The scanner turns digit bytes into values without any parse call.

**Group walk.** Draw the five arms of every group into a list of rows.

```nim
proc buildPattern(size: int): seq[string] =
  var rows = newSeq[string](size)
  for rowIndex in 0 ..< size:
    var line = ""
    for columnIndex in 0 ..< size:
      line.add '.'
    rows[rowIndex] = line
  var currentRow = 0
  var currentCol = 0
  rows[currentRow][currentCol] = '*'
  var group = 0
  while true:
    let groupSize = size - 1 - 4 * group
    if groupSize <= 0:
      break
    var rowSteps = clockwiseRows
    var colSteps = clockwiseCols
    if group mod 2 == 1:
      rowSteps = counterRows
      colSteps = counterCols
    var armLengths = [groupSize, groupSize, groupSize, groupSize - 2, 2]
    for armIndex in 0 .. 4:
      if armIndex == 2 and groupSize < 2:
        break
      if armIndex == 3 and groupSize < 3:
        break
      if armIndex == 4 and groupSize < 4:
        break
      var stepIndex = 0
      while stepIndex < armLengths[armIndex]:
        let nextRow = currentRow + rowSteps[armIndex]
        let nextCol = currentCol + colSteps[armIndex]
        if nextRow < 0 or nextRow >= size or nextCol < 0 or nextCol >= size:
          break
        currentRow = nextRow
        currentCol = nextCol
        rows[currentRow][currentCol] = '*'
        stepIndex += 1
    group += 1
  return rows
```

The loop stops when the span reaches zero. The three guards skip arms that do not fit in a thin group.

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

A fresh grid for every arm would add allocation overhead. Writing stars straight into the rows avoids that cost.
