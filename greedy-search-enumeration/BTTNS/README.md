# BTTNS — Buttons (SPOJ)
<https://www.spoj.com/problems/BTTNS/>

## Problem

A board starts all white, and pressing a button flips every cell within Manhattan distance K. Given the final board and the promise that exactly one set of buttons produces it, report how many buttons were pressed.

Input starts with the case count t. Each case gives N, M, K, followed by N rows of M digits. Output one line per case with the number of pressed buttons.

| item | bound |
|---|---|
| cases t | 1 to 10 |
| board size N, M | 1 to 20 each |
| reach K | 0 to 20 |
| judge limit | 1000 ms, 1536 MB |

Each cell holds 0 for white or 1 for black. No button is pressed twice.

Sample input:

```
2
2 2 0
1 0
0 1
2 2 1
1 1
1 1
```

Sample output:

```
2
4
```

## Idea

Treat each button like a light switch with two positions, so pressing twice cancels out and only parity matters.

The algorithm builds one GF(2) equation per cell. The variables are the buttons, and a variable appears in an equation when its diamond covers that cell. Gaussian elimination over bitset rows solves the system, and the count of true variables is the answer.

Trying all 2^(NM) press sets costs exponential time. Elimination costs O((NM)^3 / 64) word operations and fits the 400-variable limit.

The promised unique solution means every column has a pivot, so the reduced right-hand side reads off the answer directly.

## Why It Works

1. Pressing a button twice returns every affected cell to its old color.
2. So only the parity of each press matters, which is arithmetic modulo 2.
3. The final color of a cell is the XOR of all covering button variables.
4. A diamond of reach K covers a cell when the Manhattan distance is at most K.
5. The unique solution gives full column rank, so elimination exposes one value per column.

| term | meaning |
|---|---|
| `buttonCount` | number of cells, also number of variables |
| `equations` | bitset rows, one per cell |
| `pivotColumn` | column used to eliminate other rows |
| `pressedCount` | number of true variables in the solution |

Each bitset row stores one equation coefficient bit per button plus one right-hand-side bit.

For the second sample case, name the buttons a, b in the top row and c, d in the bottom row. With K = 1 each cell sees three buttons.

| cell | coefficient row | right side |
|---|---|---|
| top left | 1 1 1 0 | 1 |
| top right | 1 1 0 1 | 1 |
| bottom left | 1 0 1 1 | 1 |
| bottom right | 0 1 1 1 | 1 |

Adding all four equations gives a + b + c + d = 0, and each pair difference forces a = b = c = d = 1. All four buttons were pressed, so the answer is 4.

The 64-bit words hold 64 coefficients each. The shift amount uses `mod 64`, and the right-hand bit sits at index `buttonCount`.

## Code

**Input and output setup.** The reader loads all tokens, and the writer flushes in blocks.

```nim
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
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return value
```

The scanner reads only nonnegative integers.
Line breaks and spaces need no special handling.
One input string holds the whole file.

**Equation building.** Every cell records which button diamonds cover it.

```nim
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let rowCount = nextInt(inputData, scanPos)
  let columnCount = nextInt(inputData, scanPos)
  let reach = nextInt(inputData, scanPos)
  let buttonCount = rowCount * columnCount
  let wordCount = (buttonCount + 64) div 64
  let resultWord = buttonCount div 64
  let resultMask = 1'u64 shl (buttonCount mod 64)
  var equations = newSeq[seq[uint64]](buttonCount)
  for cellRow in 0 .. rowCount - 1:
    for cellColumn in 0 .. columnCount - 1:
      var equationRow = newSeq[uint64](wordCount)
      for buttonRow in 0 .. rowCount - 1:
        for buttonColumn in 0 .. columnCount - 1:
          let buttonDistance = abs(cellRow - buttonRow) + abs(cellColumn - buttonColumn)
          if buttonDistance <= reach:
            let variableIndex = buttonRow * columnCount + buttonColumn
            let variableWord = variableIndex div 64
            equationRow[variableWord] = equationRow[variableWord] or (1'u64 shl (variableIndex mod 64))
      let cellValue = nextInt(inputData, scanPos)
      if cellValue == 1:
        equationRow[resultWord] = equationRow[resultWord] or resultMask
      equations[cellRow * columnCount + cellColumn] = equationRow
```

Manhattan distance decides each coefficient.
The right-hand bit comes from the final cell color.
Bit words make each row compact.

**Elimination and answer.** Pivots reduce the system to one value per button.

```nim
  var pivotRow = 0
  for pivotColumn in 0 .. buttonCount - 1:
    let pivotWord = pivotColumn div 64
    let pivotMask = 1'u64 shl (pivotColumn mod 64)
    var selectedRow = -1
    for equationIndex in pivotRow .. buttonCount - 1:
      if (equations[equationIndex][pivotWord] and pivotMask) != 0'u64:
        selectedRow = equationIndex
        break
    if selectedRow < 0:
      continue
    swap equations[pivotRow], equations[selectedRow]
    for equationIndex in 0 .. buttonCount - 1:
      if equationIndex != pivotRow and (equations[equationIndex][pivotWord] and pivotMask) != 0'u64:
        for currentWord in 0 .. wordCount - 1:
          equations[equationIndex][currentWord] = equations[equationIndex][currentWord] xor equations[pivotRow][currentWord]
    pivotRow += 1
  var pressedCount = 0
  for solutionIndex in 0 .. buttonCount - 1:
    if (equations[solutionIndex][resultWord] and resultMask) != 0'u64:
      pressedCount += 1
  appendOutput($pressedCount)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Each pivot XORs into every row that has that bit set.
The right-hand bits of pivot rows form the solution.
Counting true bits gives the pressed button total.

## Complexity

Equation building checks every button for every cell, and elimination works on a few machine words per row.

| phase | time | space |
|---|---|---|
| equation build | NM pair checks per case | (NM) bitset rows |
| elimination | (NM)^3 / 64 word XORs | same rows |
| answer count | NM bit tests | constant |
| output | one line per case | block buffer |

At most 400 variables need seven 64-bit words per row.

| measure | Big O |
|---|---|
| time per case | O((NM)^3 / 64) |
| space per case | O((NM)^2 / 64) |

Enumerating all press sets would take O(2^(NM)) time and fail for full boards.

The bitset system keeps the solved board well inside the judge limit.
