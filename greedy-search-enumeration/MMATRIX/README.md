# MMATRIX — SHIFT Operator on Matrix (SPOJ)

<https://www.spoj.com/problems/MMATRIX/>

## Problem

Rotate each row of a square matrix by any number of positions, then make the largest column sum as small as possible. The SHIFT operator moves one row one step right and wraps the rightmost value to the left.

Input contract: each case starts with n, followed by n rows of n integers, and a line -1 ends the file. Output contract: print one integer per case, the smallest achievable maximum of all column sums.

The bounds from the statement:

| item | bound |
|---|---|
| matrix order n | 1 to 7 |
| entry magnitude | below 10000 |
| judge limit | 1000 ms, 1536 MB |

The total of all entries is fixed, so the smallest maximum cannot fall below that total divided by n.

Sample input:

```
2
4 6
3 7
3
1 2 3
4 5 6
7 8 9
-1
```

Sample output:

```
11
15
```

## Idea

Pin the first row and try every rotation of the rest, like turning dials until the busiest column is quietest. The algorithm enumerates all row rotation choices with a depth-first walk and tracks the running column sums. Each complete assignment costs n comparisons, and there are n^(n-1) assignments. Searching all n^n choices would repeat the same answer for every global column shift. Pinning the first row removes that duplication.

## Why It Works

1. Shifting every row by the same amount only permutes the columns.
2. A column permutation leaves the maximum column sum unchanged, so fixing the first row loses no solution.
3. A SHIFT produces one of the n cyclic rotations of that row.
4. Running column sums update by adding one rotated row and undo by subtracting it on return.
5. The smallest maximum over all remaining choices is the required answer.

The terms used in the search:

| term | meaning |
|---|---|
| `matrixSize` | order of the square matrix |
| `rotatedValues` | all cyclic rotations of every row |
| `columnSums` | running sum for each column during the walk |
| `bestColumnMax` | smallest maximum found so far |

The undo step keeps the search stack free of stale sums.

A traced search of the first sample case:

```
row 0 fixed    [4, 6]
row 1 shift 0  [3, 7]   sums [7, 13]   max 13
row 1 shift 1  [7, 3]   sums [11, 9]   max 11
answer = 11
```

The smaller maximum comes from putting 7 under the first column.

## Code

**Input and rotation table.** The reader builds every cyclic rotation of every row.

```nim
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-':
    pos += 1
  var sign = 1
  if pos < data.len and data[pos] == '-':
    sign = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return sign * value

proc hasMoreNumbers(data: string, pos: int): bool =
  var index = pos
  while index < data.len:
    if data[index] >= '0' and data[index] <= '9':
      return true
    index += 1
  return false

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The minus branch reads the -1 terminator and negative entries.
The rotation index uses modulo arithmetic, so wraparound is exact.
All rotations are stored once, before the search starts.

**Depth-first enumeration.** The walk fixes row zero and updates sums in place.

```nim
var matrixSize = 0
var rotatedValues: seq[seq[seq[int]]]
var columnSums: seq[int]
var bestColumnMax = 0

proc evaluateRemainingRows(rowIndex: int) =
  if rowIndex == matrixSize:
    var currentMax = columnSums[0]
    for colIndex in 1 .. matrixSize - 1:
      if columnSums[colIndex] > currentMax:
        currentMax = columnSums[colIndex]
    if currentMax < bestColumnMax:
      bestColumnMax = currentMax
    return
  for shiftAmount in 0 .. matrixSize - 1:
    for colIndex in 0 .. matrixSize - 1:
      columnSums[colIndex] += rotatedValues[rowIndex][shiftAmount][colIndex]
    evaluateRemainingRows(rowIndex + 1)
    for colIndex in 0 .. matrixSize - 1:
      columnSums[colIndex] -= rotatedValues[rowIndex][shiftAmount][colIndex]
```

Each recursive level represents one row choice.
The subtraction restores the previous sums before the next choice.
The leaf scans n sums to update the best maximum.

**Driver.** Each case is solved and written to the shared buffer.

```nim
while hasMoreNumbers(inputData, scanPos):
  matrixSize = nextInt(inputData, scanPos)
  if matrixSize == -1:
    break
  var matrixRows = newSeq[seq[int]](matrixSize)
  for rowIndex in 0 .. matrixSize - 1:
    matrixRows[rowIndex] = newSeq[int](matrixSize)
    for colIndex in 0 .. matrixSize - 1:
      matrixRows[rowIndex][colIndex] = nextInt(inputData, scanPos)
  rotatedValues = newSeq[seq[seq[int]]](matrixSize)
  for rowIndex in 0 .. matrixSize - 1:
    rotatedValues[rowIndex] = newSeq[seq[int]](matrixSize)
    for shiftAmount in 0 .. matrixSize - 1:
      rotatedValues[rowIndex][shiftAmount] = newSeq[int](matrixSize)
      for colIndex in 0 .. matrixSize - 1:
        rotatedValues[rowIndex][shiftAmount][colIndex] =
          matrixRows[rowIndex][(colIndex + shiftAmount) mod matrixSize]
  columnSums = newSeq[int](matrixSize)
  for colIndex in 0 .. matrixSize - 1:
    columnSums[colIndex] = rotatedValues[0][0][colIndex]
  bestColumnMax = 1 shl 50
  evaluateRemainingRows(1)
  appendOutput($(bestColumnMax))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

The first row is fixed at rotation zero.
A large sentinel starts the minimum search.
One line is written per case.

## Complexity

The search dominates, and n is at most seven.

| phase | time | space |
|---|---|---|
| input read | one pass over all entries | matrix and input string |
| rotation table | n squared values | n cubed integers |
| enumeration | n^(n-1) leaves, n work per leaf | column sums and stack |
| output | one line per case | block buffer |

The n cubed table is tiny for the given bound.

The overall asymptotic bounds:

| measure | Big O |
|---|---|
| time | O(n^(n-1) times n) per case |
| space | O(n^3) |

Trying all n^n assignments would multiply the work by n for no gain.
Pinning the first row keeps every case inside the judge limit.
