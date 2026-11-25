# PG1118 — Cuadrado Magico Grado 11 (SPOJ)
<https://www.spoj.com/problems/PG1118/>

## Problem

Given an odd order n, print the magic square made by the stated placing rule and its magic constant.
Start with 1 in the middle row of the last column. Place each next number up and right, wrapping around the edges. When that cell is taken, place the number to the left of the current cell.
Print the constant M = n(n² + 1)/2 first, then n rows with n space-separated numbers each.

| Item | Bound |
|---|---|
| Order | odd natural number |
| Time limit | 1000 ms |
| Memory | not stated |

The output has n² numbers, so one output buffer keeps the writes rare.

The first example in the statement is exact.

```
3
```

```
15
2 7 6
9 5 1
4 3 8
```

The statement also shows order five.

```
5
```

```
65
9 3 22 16 15
2 21 20 14 8
25 19 13 7 1
18 12 6 5 24
11 10 4 23 17
```

## Idea

Filling the square is like walking a circular staircase: step up and right, and step sideways when the next landing is taken.
The program keeps one grid of n² cells, all initially empty.
It writes each value in the current cell, then finds the next cell.
The next cell is one row up and one column right, with both edges wrapping.
If that cell already holds a value, the program moves one column left instead.
After all values are placed, it prints the grid row by row.
A direct placement avoids trying every permutation of the numbers.

One pass over n² cells builds the square, and one pass prints it.

## Why It Works

1. The grid starts empty, so a zero marks a cell with no value.
2. Value 1 goes in the middle row of the last column, as required.
3. Wrapping rows and columns keeps every step inside the grid.
4. Moving left when the target is occupied matches the stated rule.
5. Every row, column, and diagonal then sums to n(n² + 1)/2.

The main terms follow.

| Term | Meaning |
|---|---|
| `order` | number of rows and columns |
| `cells` | flat grid holding one value per cell |
| `currentRow` | row of the latest placement |
| `currentCol` | column of the latest placement |
| `magicConstant` | common sum of every line |

The flat grid uses `currentRow * order + currentCol` as a cell address.

A trace from `gen.py --trace` for order three:

```
place 1 at row 1 col 2
place 2 at row 0 col 0
place 3 at row 2 col 1
  next step sideways to col 0
place 4 at row 2 col 0
place 5 at row 1 col 1
place 6 at row 0 col 2
  next step sideways to col 1
place 7 at row 0 col 1
place 8 at row 2 col 2
place 9 at row 1 col 0
```

The trace reproduces the first sample square exactly.

## Code

**Bulk input and integer scanner.** This block reads stdin once and parses the order.

```nim
const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInteger(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value
```

The read loop ends at end of input.
The scanner skips every byte that is not a digit.
The digit value comes from the character code.

**Output buffer.** This block buffers all answer text and flushes it in blocks.

```nim
var outputBuffer = ""

proc flushIfReady() =
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc appendOutput(text: string) =
  outputBuffer.add text
  flushIfReady()
```

The buffer leaves after reaching 131072 bytes.
`appendOutput` adds text and then checks the size.
The last partial block is written after the loops.

**Placement loop.** This block fills the flat grid one value at a time.

```nim
let order = nextInteger(inputData, scanPos)
let magicConstant = order * (order * order + 1) div 2
appendOutput($(magicConstant))
appendOutput("\n")

var cells = newSeq[int](order * order)
var currentRow = order div 2
var currentCol = order - 1
for placedValue in 1..(order * order):
  cells[currentRow * order + currentCol] = placedValue
  var nextRow = currentRow - 1
  if nextRow < 0:
    nextRow = order - 1
  var nextCol = currentCol + 1
  if nextCol == order:
    nextCol = 0
  if cells[nextRow * order + nextCol] != 0:
    currentCol = currentCol - 1
    if currentCol < 0:
      currentCol = order - 1
  else:
    currentRow = nextRow
    currentCol = nextCol
```

The constant uses integer division, so it stays exact.
A zero cell means the target is still free.
Both wraparounds use the order, never a fixed size.

**Row printing and final write.** This block writes one space-separated row at a time.

```nim
for rowIndex in 0..<order:
  for colIndex in 0..<order:
    if colIndex > 0:
      appendOutput(" ")
    appendOutput($(cells[rowIndex * order + colIndex]))
  appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

A space precedes every value except the first in a row.
Each row ends with one newline.
The final write flushes the last partial block.

## Complexity

Cost follows the number of cells and printed digits.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Placement | one step per cell | n² cells |
| Output | one write per 128 KiB block | block buffer |

Both loops visit each cell exactly once.

| Measure | Big O |
|---|---|
| Time | O(n²) |
| Space | O(n²) |

Trying every ordering of the numbers would cost O(n²!) time.
The stated placing rule gives the square directly.
