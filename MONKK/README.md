# MONKK — Monkey King (SPOJ)

<https://www.spoj.com/problems/MONKK/>

## Problem

A grid cell holds a banana tree, an empty space, or a tax area. Choose one square block of cells and report the largest possible net banana gain.

The first line gives the test count T. Each case gives row count r and column count c, followed by r strings of length c. Print "Case k: answer" for each case.

| item | bound |
|---|---|
| test count T | up to 213 |
| rows r and columns c | 0 to 100 |
| cell symbols | B, ., T |
| judge limit | 1000 ms, 1536 MB |

A B contributes one banana and a T costs one; a dot contributes nothing.

Sample input:

```
2

3 3
BBB
BBB
BBB

5 5
T.BBB
TBBBB
.BBBB
TBBBB
.BBBB
```

Sample output:

```
Case 1: 9
Case 2: 16
```

## Idea

Treat each square as a rectangle whose sum can be read from four corners, like finding the weight of a crate from four scale readings. A cumulative table stores sums from the top-left corner to every cell, so each candidate square costs four lookups.

The algorithm builds a summed-area table, then tests every square once. Building the table costs one pass over the grid; testing squares costs O(r * c * min(r, c)). Recomputing each square cell by cell would multiply that cost by the square side.

The result is printed with the case number, one line per case.

## Why It Works

1. Assign 1 to B, -1 to T, and 0 to a dot.
2. The cumulative table at (row, column) holds the sum above and left of that cell.
3. Four table entries give the sum inside any rectangle in constant time.
4. Every square area has a top-left corner and a side length, so enumerating both covers all choices.
5. Tracking the largest sum found yields the best square.

| term | meaning |
|---|---|
| `cumulative` | summed-area table with one extra top row and left column |
| `stride` | table width, equal to c + 1 |
| `squareTotal` | net bananas in one candidate square |
| `bestTotal` | largest square sum seen in the current case |
| `nextCell` | reader that skips whitespace and returns one grid symbol |

The running row sum fills each table row in a single left-to-right pass.

A script-generated trace for the second sample grid:

```
side 1 best 1
side 2 best 4
side 3 best 9
side 4 best 16
side 5 best 16
answer 16
```

The largest value 16 matches the second sample line.

## Code

**Input and scanning.** The reader loads all lines, then extracts numbers and grid symbols.

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

proc nextCell(data: string, pos: var int): char =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  let cellChar = data[pos]
  pos += 1
  return cellChar

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

Blank lines between cases cause no trouble for the scanners.
The cell reader returns the next B, T, or dot.
Output is buffered for all cases together.

**Table and squares.** A row-wise pass fills `cumulative`, then every square is tested.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 1 .. caseCount:
  let rowCount = nextInt(inputData, scanPos)
  let columnCount = nextInt(inputData, scanPos)
  let stride = columnCount + 1
  var cumulative = newSeq[int]((rowCount + 1) * stride)
  for rowIndex in 0 ..< rowCount:
    var rowTotal = 0
    for columnIndex in 0 ..< columnCount:
      let cellChar = nextCell(inputData, scanPos)
      var cellValue = 0
      if cellChar == 'B':
        cellValue = 1
      elif cellChar == 'T':
        cellValue = -1
      rowTotal = rowTotal + cellValue
      cumulative[(rowIndex + 1) * stride + columnIndex + 1] = cumulative[rowIndex * stride + columnIndex + 1] + rowTotal
  var bestTotal = 0
  for topRow in 0 ..< rowCount:
    for leftColumn in 0 ..< columnCount:
      let largestSide = min(rowCount - topRow, columnCount - leftColumn)
      for sideLength in 1 .. largestSide:
        let bottomRight = (topRow + sideLength) * stride + leftColumn + sideLength
        let topRight = topRow * stride + leftColumn + sideLength
        let bottomLeft = (topRow + sideLength) * stride + leftColumn
        let topLeft = topRow * stride + leftColumn
        let squareTotal = cumulative[bottomRight] - cumulative[topRight] - cumulative[bottomLeft] + cumulative[topLeft]
        if squareTotal > bestTotal:
          bestTotal = squareTotal
  appendOutput("Case " & $caseIndex & ": " & $bestTotal & "\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

Empty grids produce zero without entering either loop.
Sides stop at the grid edge through `largestSide`.
The best total starts at zero, so a grid with no gain reports zero.

## Complexity

The table costs one cell pass; the square scan examines each valid square once.

| phase | time | space |
|---|---|---|
| input read | one pass over input bytes | one input string |
| table build | one visit per grid cell | (r + 1)(c + 1) integers |
| square scan | one look-up per square | block buffer |

Squares dominate the cost when r and c both reach 100.

| measure | Big O |
|---|---|
| time | O(r * c * min(r, c)) per case |
| space | O(r * c) |

Adding every square cell by hand would cost roughly another factor of min(r, c) per case.
