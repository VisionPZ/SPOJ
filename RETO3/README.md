# RETO3 — Magic Grid (SPOJ)

<https://www.spoj.com/problems/RETO3/>

## Problem

One cell of a square grid is empty. Fill it with a positive integer so all rows, columns, and both diagonals share one sum.

The input starts with the grid order. The next lines hold the grid values. Print the missing positive integer, or -1 when no such integer exists. Several valid answers are allowed.

| Item | Bound |
|---|---|
| Grid order | 1 to 500 |
| Grid value | 1 to 10^9, or 0 for the empty cell |
| Empty cells | exactly one |
| Valid answer | 1 to 10^18 |
| Judge limit | 1000 ms, 1536 MB |

A complete line fixes the common sum.

The statement shows three samples:

```
3
4 0 2
3 5 7
8 1 6
```

```
9
```

```
4
1 1 1 1
1 1 0 1
1 1 1 1
1 1 1 1
```

```
1
```

```
4
1 1 1 1
1 1 0 1
1 1 2 1
1 1 1 1
```

```
-1
```

The third grid cannot become magic with one positive number.

## Idea

Think of balancing a set of scales with one missing weight. A finished row tells you the exact weight needed.

For an order above one, a row without the empty cell gives the target sum. The empty row needs the difference between that target and its current sum. Add this candidate in every line and compare each total with the target. An order of one accepts 1.

Each line check costs constant time, so the whole grid costs O(n^2) time. Trying candidate values one at a time repeats that work many times over. One candidate and one verification sweep finish the task.

## Why It Works

1. With one zero, some row avoids it and fixes the target sum.
2. Any magic grid must make that row's total the shared total.
3. The empty row then determines the missing value uniquely.
4. A positive candidate that fails one line cannot fix the grid.

The main terms and their meanings:

| Term | Meaning |
|---|---|
| `targetTotal` | sum of a complete row, shared by all lines |
| `candidateValue` | target minus the sum of the empty row |
| `emptyRow` | row holding the zero cell |
| `completedTotal` | line total after inserting the candidate |
| `mainDiagonalTotal` | sum of the top-left to bottom-right diagonal |

The terms name the only values needed for the decision.

A trace from `gen.py` on the first sample:

```
grid order 3, empty cell row 1, column 2
reference column 1 total 15
empty row total 6, candidate 9
filled rows [15, 15, 15]
filled columns [15, 15, 15]
filled diagonals [15, 15]
```

Every filled line reaches 15, matching the printed answer 9.

## Code

**Input and output helpers.** The program reads all lines, then scans digits by index.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

proc nextInteger(inputData: string, scanPos: var int): int64 =
  while scanPos < inputData.len and inputData[scanPos] != '-' and
        (inputData[scanPos] < '0' or inputData[scanPos] > '9'):
    scanPos += 1
  var signValue = 1'i64
  if scanPos < inputData.len and inputData[scanPos] == '-':
    signValue = -1'i64
    scanPos += 1
  var parsedValue = 0'i64
  while scanPos < inputData.len and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    parsedValue = parsedValue * 10 + int64(int(inputData[scanPos]) - firstDigitValue)
    scanPos += 1
  return signValue * parsedValue

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The scanner handles both digits and a minus sign. The buffer flushes every 128 KiB.

**Grid and line totals.** Two passes collect the cell values and their line sums.

```nim
let gridOrder = int(nextInteger(inputData, scanPos))
let cellCount = gridOrder * gridOrder
var cellValues = newSeq[int64](cellCount)
var emptyRow = -1
var emptyColumn = -1
var cellIndex = 0
for rowIndex in 0 ..< gridOrder:
  for columnIndex in 0 ..< gridOrder:
    let currentValue = nextInteger(inputData, scanPos)
    cellValues[cellIndex] = currentValue
    if currentValue == 0:
      emptyRow = rowIndex
      emptyColumn = columnIndex
    cellIndex += 1

var rowTotals = newSeq[int64](gridOrder)
var columnTotals = newSeq[int64](gridOrder)
var mainDiagonalTotal = 0'i64
var otherDiagonalTotal = 0'i64
cellIndex = 0
for rowIndex in 0 ..< gridOrder:
  for columnIndex in 0 ..< gridOrder:
    let currentValue = cellValues[cellIndex]
    rowTotals[rowIndex] += currentValue
    columnTotals[columnIndex] += currentValue
    if rowIndex == columnIndex:
      mainDiagonalTotal += currentValue
    if rowIndex + columnIndex == gridOrder - 1:
      otherDiagonalTotal += currentValue
    cellIndex += 1
```

The grid is stored flat, so row and column access stays contiguous. Both loops run n^2 times.

**Candidate and verification.** One difference gives the value, then every line is checked.

```nim
if gridOrder == 1:
  appendOutput("1\n")
else:
  let referenceRow = if emptyRow == 0: 1 else: 0
  let targetTotal = rowTotals[referenceRow]
  let candidateValue = targetTotal - rowTotals[emptyRow]
  var isMagic = candidateValue >= 1'i64
  if isMagic:
    for rowIndex in 0 ..< gridOrder:
      let completedTotal = rowTotals[rowIndex] + (if rowIndex == emptyRow: candidateValue else: 0'i64)
      if completedTotal != targetTotal:
        isMagic = false
    for columnIndex in 0 ..< gridOrder:
      let completedTotal = columnTotals[columnIndex] + (if columnIndex == emptyColumn: candidateValue else: 0'i64)
      if completedTotal != targetTotal:
        isMagic = false
    let mainCompleted = mainDiagonalTotal + (if emptyRow == emptyColumn: candidateValue else: 0'i64)
    let otherCompleted = otherDiagonalTotal + (if emptyRow + emptyColumn == gridOrder - 1: candidateValue else: 0'i64)
    if mainCompleted != targetTotal or otherCompleted != targetTotal:
      isMagic = false
  if isMagic:
    appendOutput($candidateValue)
    outputBuffer.add '\n'
  else:
    appendOutput("-1\n")

stdout.write outputBuffer
```

The second row serves as target when the first row holds the zero. A zero candidate fails the positivity test.

## Complexity

The program scans the grid twice and then verifies each line once.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input buffer |
| Line totals | two passes over n^2 cells | three total arrays |
| Verification | one pass over rows and columns | no extra storage |

The cell count drives every phase.

The asymptotic bounds are:

| Measure | Big O |
|---|---|
| Time | O(n^2) |
| Space | O(n^2) |

Searching for the answer by trial could take many verification sweeps. Computing it from one row takes a single sweep.
