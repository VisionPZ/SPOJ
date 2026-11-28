# RF115 — CAOS GRADO 11 (SPOJ)

<https://www.spoj.com/problems/RF115/>

## Problem

Build a d by d matrix of values i + j - k, then print the matrix, its total, largest entry, and smallest entry.

The input holds two integers, the dimension d and the category k. The output holds d rows of d space-separated entries, followed by three lines with the sum, maximum, and minimum.

The statement and judge give these bounds:

| item | bound |
|---|---|
| dimension d | given by the first input value |
| category k | signed integer, negative values allowed |
| judge limit | 1000 ms, 1536 MB |

The matrix size drives both time and output volume.

Sample input:

```
5 1
```

Sample output:

```
-1 0 1 2 3
0 1 2 3 4
1 2 3 4 5
2 3 4 5 6
3 4 5 6 7
75
7
-1
```

## Idea

Compute each cell by adding its row and column and subtracting the category, like counting grid steps from a fixed offset.

The nested loops visit every cell once in constant time. Each visit also updates a running total, maximum, and minimum. Storing the matrix first would need a second pass and extra memory. Computing and printing in one pass avoids both costs.

One pass fills the matrix and collects all three statistics.

## Why It Works

1. Cell (i, j) equals i + j - k by the statement formula.
2. Row and column indices run from 0 through d - 1.
3. Adding every cell to a running total gives the matrix sum at the end.
4. Comparing each cell with the running maximum keeps the largest value.
5. Comparing each cell with the running minimum keeps the smallest value.
6. Writing cells as they are computed removes the need to store the matrix.

The main terms are these:

| term | meaning |
|---|---|
| `dimension` | the side length of the square matrix |
| `categoryValue` | the value subtracted from every cell |
| `cellValue` | the value computed for one row and column |
| `totalSum` | the running sum of all cells |
| `largestValue` | the largest cell seen so far |
| `smallestValue` | the smallest cell seen so far |

The three running statistics need no second pass.

A script-traced example from `gen.py`:

```
n=5 k=1 closed form sum=75
loop sum=75
corners: min=-1 max=7
```

The trace matches the sample: sum 75, maximum 7, and minimum -1.

## Code

**Bulk input and hand scanner.** This block loads stdin and reads signed integers.

```nim
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int64 =
  while pos < data.len and data[pos] != '-' and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  if pos >= data.len:
    return 0
  var negative = false
  if data[pos] == '-':
    negative = true
    pos += 1
  var value: int64 = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int64(int(data[pos]) - 48)
    pos += 1
  if negative:
    value = -value
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The scanner accepts minus signs because the category can be negative.
Values stay in 64-bit integers for the arithmetic below.
The buffer flushes after about 128 KiB of text.
Each token costs one pass over its digits.

**Matrix driver.** This block computes cells and the three statistics together.

```nim
let dimensionValue = nextInt(inputData, scanPos)
let categoryValue = nextInt(inputData, scanPos)
let dimension = int(dimensionValue)
var totalSum: int64 = 0
var largestValue: int64 = -1000000000000
var smallestValue: int64 = 1000000000000
for rowIndex in 0 .. dimension - 1:
  for columnIndex in 0 .. dimension - 1:
    if columnIndex != 0:
      appendOutput(" ")
    let cellValue = int64(rowIndex) + int64(columnIndex) - categoryValue
    appendOutput($cellValue)
    totalSum += cellValue
    if cellValue > largestValue:
      largestValue = cellValue
    if cellValue < smallestValue:
      smallestValue = cellValue
  appendOutput("\n")
if dimension > 0:
  appendOutput($totalSum)
  appendOutput("\n")
  appendOutput($largestValue)
  appendOutput("\n")
  appendOutput($smallestValue)
  appendOutput("\n")
stdout.write outputBuffer
outputBuffer.setLen 0
```

A leading space is written only for columns after the first.
Indices are cast to 64-bit values before subtraction.
The three trailing lines appear only for a nonempty matrix.
One final write flushes the remaining text.

## Complexity

The cost splits into input, the matrix loop, and output.

| phase | time | space |
|---|---|---|
| input read | one pass over two integers | one input string |
| matrix loop | one visit per cell | three running values |
| output | one line per row plus three lines | block buffer |

The matrix loop and the output dominate for any useful dimension.

The asymptotic costs are these:

| measure | Big O |
|---|---|
| time | O(d × d) |
| space | O(input bytes) |

Storing the matrix would add O(d × d) space and a second pass.
Computing each cell once keeps the program lean.
