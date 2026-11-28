# SUDOGOB — Sudoku Goblin (SPOJ)

<https://www.spoj.com/problems/SUDOGOB/>

## Problem

Count the solutions of each 9x9 Sudoku grid and print the unique solution when exactly one exists. A zero marks an empty cell.

Input starts with the test count. Each grid has nine lines of nine numbers separated by spaces. Print the solution count, then its nine solved rows only when the count is one.

| item | bound |
|---|---|
| grid cells | 81 per test |
| cell value | 0 to 9 |
| solution counts | small in the judge data |
| judge limit | 1000 ms, 1536 MB |

The unique-solution branch drives the need to keep the first grid found.

Sample input:

```
3
3 0 6 0 0 2 5 0 0
0 0 0 0 3 8 0 0 0
7 0 8 0 1 6 0 9 0
0 0 7 0 0 3 8 6 0
8 2 0 0 7 0 0 4 5
0 6 3 1 0 0 9 0 0
0 7 0 3 5 0 6 0 2
0 0 0 8 2 0 0 0 0
0 0 2 9 0 0 7 0 4
3 0 6 0 0 2 5 0 3
0 0 0 0 3 8 0 0 0
7 0 8 0 1 6 0 9 0
0 0 7 0 0 3 8 6 0
8 2 0 0 7 0 0 4 5
0 6 3 1 0 0 9 0 0
0 7 0 3 5 0 6 0 2
0 0 0 8 2 0 0 0 0
0 0 2 9 0 0 7 0 4
3 0 6 0 0 2 0 0 0
0 0 0 0 3 8 0 0 0
7 0 8 0 1 6 0 9 0
0 0 7 0 0 3 8 6 0
8 2 0 0 7 0 0 4 5
0 6 3 1 0 0 9 0 0
0 7 0 3 5 0 6 0 2
0 0 0 8 2 0 0 0 0
0 0 2 9 0 0 7 0 4
```

Sample output:

```
1
3 1 6 4 9 2 5 7 8
2 9 5 7 3 8 4 1 6
7 4 8 5 1 6 2 9 3
9 5 7 2 4 3 8 6 1
8 2 1 6 7 9 3 4 5
4 6 3 1 8 5 9 2 7
1 7 9 3 5 4 6 8 2
6 3 4 8 2 7 1 5 9
5 8 2 9 6 1 7 3 4
0
2
```

The three counts are one, zero, and two.

## Idea

Choose the empty cell with the fewest legal digits, like picking the tightest knot first when tying a bundle. Bit masks hold the used digits for each row, column, and box, so candidates come from one bitwise complement. Backtracking visits branches in that minimum-remaining-values order and records the first full grid. Scanning all cells in fixed order explores many dead branches. The mask and ordering prune those branches early.

## Why It Works

1. A digit is legal in a cell when its bit is absent from that row, column, and box.
2. The minimum candidate cell fails fastest, so fewer branches start.
3. A full board contributes one solution and is copied when it is the first.
4. Undoing the three masks after each branch restores the exact parent state.
5. Printing a grid only for count one matches the output contract.

| term | meaning |
|---|---|
| `boardCells` | the 81 current cell values |
| `rowMasks` | used digits per row |
| `columnMasks` | used digits per column |
| `boxMasks` | used digits per 3x3 box |
| `solutionCount` | number of completed boards |

The table names the masks that make candidates cheap.

A script trace for the first sample grid follows:

```
givens include row 1 values 3, 6, 2 at columns 1, 3, 6
first solved row: 3 1 6 4 9 2 5 7 8
completed boards found: 1
```

The trace matches the single-solution output.

The mask complement uses 1022, the ten low bits covering digits one through nine.

## Code

**Input and board state.** The reader ignores line breaks and loads 81 values per grid.

```nim
const flushBlockBytes = 1 shl 17
const fullDigitMask = 1022

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var boardCells = newSeq[int](81)
var rowMasks = newSeq[int](9)
var columnMasks = newSeq[int](9)
var boxMasks = newSeq[int](9)
var recordedSolution = newSeq[int](81)
var solutionCount = 0
```

Nine values per row give 81 tokens.
The digit mask covers bits one through nine.
Output is buffered across all test cases.

**Constrained search.** Minimum candidate count picks the branch cell.

```nim
proc searchSolutions() =
  var bestCell = -1
  var bestMask = 0
  var bestOptions = 10
  for cellIndex in 0 .. 80:
    if boardCells[cellIndex] == 0:
      let rowIndex = cellIndex div 9
      let columnIndex = cellIndex mod 9
      let boxIndex = (rowIndex div 3) * 3 + columnIndex div 3
      let forbiddenMask = rowMasks[rowIndex] or columnMasks[columnIndex] or boxMasks[boxIndex]
      let candidateMask = fullDigitMask and (not forbiddenMask)
      var optionCount = 0
      for digitValue in 1 .. 9:
        if (candidateMask and (1 shl digitValue)) != 0:
          optionCount += 1
      if optionCount < bestOptions:
        bestOptions = optionCount
        bestCell = cellIndex
        bestMask = candidateMask
        if optionCount == 0:
          break
  if bestCell == -1:
    solutionCount += 1
    if solutionCount == 1:
      for cellIndex in 0 .. 80:
        recordedSolution[cellIndex] = boardCells[cellIndex]
    return
  if bestOptions == 0:
    return
  let rowIndex = bestCell div 9
  let columnIndex = bestCell mod 9
  let boxIndex = (rowIndex div 3) * 3 + columnIndex div 3
  for digitValue in 1 .. 9:
    let digitBit = 1 shl digitValue
    if (bestMask and digitBit) != 0:
      boardCells[bestCell] = digitValue
      rowMasks[rowIndex] = rowMasks[rowIndex] or digitBit
      columnMasks[columnIndex] = columnMasks[columnIndex] or digitBit
      boxMasks[boxIndex] = boxMasks[boxIndex] or digitBit
      searchSolutions()
      rowMasks[rowIndex] = rowMasks[rowIndex] and (not digitBit)
      columnMasks[columnIndex] = columnMasks[columnIndex] and (not digitBit)
      boxMasks[boxIndex] = boxMasks[boxIndex] and (not digitBit)
      boardCells[bestCell] = 0
```

A zero candidate cell stops that branch.
A full board increments the count once.
Each mask is cleared with a bitwise and of the complement.

**Case output.** Each grid resets masks, counts, then writes its answer.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  for rowIndex in 0 .. 8:
    rowMasks[rowIndex] = 0
    columnMasks[rowIndex] = 0
    boxMasks[rowIndex] = 0
  for cellIndex in 0 .. 80:
    let givenValue = nextInt(inputData, scanPos)
    boardCells[cellIndex] = givenValue
    if givenValue != 0:
      let rowIndex = cellIndex div 9
      let columnIndex = cellIndex mod 9
      let boxIndex = (rowIndex div 3) * 3 + columnIndex div 3
      let digitBit = 1 shl givenValue
      rowMasks[rowIndex] = rowMasks[rowIndex] or digitBit
      columnMasks[columnIndex] = columnMasks[columnIndex] or digitBit
      boxMasks[boxIndex] = boxMasks[boxIndex] or digitBit
  solutionCount = 0
  searchSolutions()
  appendOutput($solutionCount)
  outputBuffer.add '\n'
  if solutionCount == 1:
    for rowIndex in 0 .. 8:
      for columnIndex in 0 .. 8:
        if columnIndex > 0:
          outputBuffer.add ' '
        outputBuffer.add char(48 + recordedSolution[rowIndex * 9 + columnIndex])
      outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Givens set their three mask bits.
The count line comes before any grid.
Solved rows mirror the input spacing.

## Complexity

Backtracking dominates each grid.

| phase | time | space |
|---|---|---|
| input read | one pass over 81 tokens | one input string |
| mask setup | one bit per given | three mask arrays |
| search | one branch per legal digit | recursion over 81 cells |
| output | one buffered write | block buffer |

The phase table shows that search dominates setup.

| measure | Big O |
|---|---|
| time | O(9 to the number of empty cells) worst case |
| space | O(81) |

Fixed-order scanning explores more dead branches. Minimum remaining values cuts that search with the same mask data.
