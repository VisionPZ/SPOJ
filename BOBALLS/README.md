# BOBALLS — Bouncing Balls (SPOJ)

<https://www.spoj.com/problems/BOBALLS/>

## Problem

Two balls fall through a grid of digits and platforms, and the player picks their starting columns. Each ball scores the digits on its path, but a digit crossed by both balls scores once, so the goal is the largest expected combined score.

The first input line holds the test count. Each test starts with `N` and `M`, followed by `N` rows of `M` characters. A character is a digit from 0 to 9 or `P` for a platform. Print the maximum expected score with four digits after the decimal point.

The bounds from the statement:

| item | bound |
|---|---|
| tests | 1 to 100 |
| rows N and columns M | 3 to 100 |
| cell symbols | digits 0 to 9 or P |
| judge limit | 1000 ms |

Platforms never touch a grid boundary, and a ball never rebounds along a row.

Sample input:

```
4
5 5
53214
53214
53214
54214
53214
5 5
00000
0P0P0
00000
01P20
00000
5 5
09090
0P0P0
00000
01P20
00000
6 6
112214
211243
30PPP2
423378
1P9753
220102
```

Sample output:

```
45.0000
2.2500
19.3125
35.5000
```

## Idea

Think of the two balls as raindrops on a tiled roof: each tile pays once even when both drops cross it. The trick is to compute each ball's chance of visiting every cell, then subtract the chance that both visit it.

The algorithm runs a forward probability pass for each starting column. A ball either drops one row or rolls across a contiguous run of platforms beneath it, taking a fair coin only for the roll direction. After all starts are processed, one weighted inner product over cells gives the overlap for every pair of columns.

Enumerating every pair of complete random paths would grow exponentially with the row count. The probability pass keeps one number per cell and start instead.

All probabilities are sums of powers of one half, so the final score is exact in binary floating point before rounding.

Taking the best pair after the overlap step gives the required maximum.

## Why It Works

1. A ball drops straight down while the cell below has no platform.
2. When the cell below is a platform, the ball picks left or right with equal chance and keeps that direction across consecutive platforms.
3. The forward pass adds the ball's probability to each cell it visits, so the sum for one cell is the chance that start reaches it.
4. The two balls move independently, so the chance both reach a cell is the product of their two cell probabilities.
5. Expected union score equals the sum of both single scores minus the expected double count at every cell.
6. Rounding the best score to four decimals gives the printed answer.

The main terms and formulas:

| term | meaning |
|---|---|
| `cellProbability` | chance that a start column visits a cell |
| `singleExpected` | expected score of one ball for one start |
| `overlap` | expected score counted twice by the two balls |
| `directionSign` | minus one when rolling left, plus one when rolling right |

The table names the arrays that drive the pass and the pair scan.

The gen.py oracle enumerates complete paths with exact fractions. On a platform-free 3 by 3 grid it produces this trace:

```
column sums: 1+4+7 = 12, 2+5+8 = 15, 3+6+9 = 18
best pair uses columns 1 and 2 -> 15 + 18 = 33
overlap is zero because the columns differ -> 33.0000
```

The trace shows why the shared starting row costs nothing when the columns differ.

## Code

**Input and scanner.** One read loads the tests, and fields keep digit strings intact.

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

proc nextField(data: string, pos: var int): string =
  while pos < data.len and (data[pos] == ' ' or data[pos] == '\n' or data[pos] == '\r' or data[pos] == '\t'):
    pos += 1
  var field = ""
  while pos < data.len and data[pos] != ' ' and data[pos] != '\n' and data[pos] != '\r' and data[pos] != '\t':
    field.add data[pos]
    pos += 1
  return field

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

Grid rows are read as whole fields.
Platform cells store a zero score.
The scanner ignores line breaks between rows.

**Probability pass.** Each start spreads its chance over the cells it may visit.

```nim
let testCount = nextInt(inputData, scanPos)
for testIndex in 0 .. testCount - 1:
  let rowCount = nextInt(inputData, scanPos)
  let columnCount = nextInt(inputData, scanPos)
  var grid = newSeq[string](rowCount)
  for rowIndex in 0 .. rowCount - 1:
    grid[rowIndex] = nextField(inputData, scanPos)
  let cellCount = rowCount * columnCount
  var cellValues = newSeq[int](cellCount)
  for rowIndex in 0 .. rowCount - 1:
    for columnIndex in 0 .. columnCount - 1:
      let cellChar = grid[rowIndex][columnIndex]
      if cellChar != 'P':
        cellValues[rowIndex * columnCount + columnIndex] = int(cellChar) - 48
  var cellProbability = newSeq[float](cellCount * columnCount)
  var singleExpected = newSeq[float](columnCount)
  for startColumn in 0 .. columnCount - 1:
    var currentProb = newSeq[float](columnCount)
    currentProb[startColumn] = 1.0
    for rowIndex in 0 .. rowCount - 1:
      var nextProb = newSeq[float](columnCount)
      for columnIndex in 0 .. columnCount - 1:
        let probability = currentProb[columnIndex]
        if probability == 0.0:
          continue
        let cellIndex = rowIndex * columnCount + columnIndex
        cellProbability[cellIndex * columnCount + startColumn] += probability
        singleExpected[startColumn] += probability * float(cellValues[cellIndex])
        if rowIndex == rowCount - 1:
          continue
        if grid[rowIndex + 1][columnIndex] != 'P':
          nextProb[columnIndex] += probability
        else:
          for directionIndex in 0 .. 1:
            var directionSign = 1
            if directionIndex == 0:
              directionSign = -1
            var stepColumn = columnIndex + directionSign
            while stepColumn >= 0 and stepColumn < columnCount and grid[rowIndex + 1][stepColumn] == 'P':
              let stepCell = rowIndex * columnCount + stepColumn
              cellProbability[stepCell * columnCount + startColumn] += probability * 0.5
              singleExpected[startColumn] += probability * 0.5 * float(cellValues[stepCell])
              stepColumn += directionSign
            let exitCell = rowIndex * columnCount + stepColumn
            cellProbability[exitCell * columnCount + startColumn] += probability * 0.5
            singleExpected[startColumn] += probability * 0.5 * float(cellValues[exitCell])
            nextProb[stepColumn] += probability * 0.5
      currentProb = nextProb
```

A clear cell below sends the ball straight down.
A platform below splits the chance in half.
The roll keeps one direction across a platform run.

**Pair scan and output.** Overlap is removed once per cell, then the best pair is rounded.

```nim
  var overlap = newSeq[float](columnCount * columnCount)
  for cellIndex in 0 .. cellCount - 1:
    let cellValue = float(cellValues[cellIndex])
    if cellValue == 0.0:
      continue
    let cellOffset = cellIndex * columnCount
    for firstColumn in 0 .. columnCount - 1:
      let firstProbability = cellProbability[cellOffset + firstColumn]
      if firstProbability == 0.0:
        continue
      for secondColumn in firstColumn .. columnCount - 1:
        let secondProbability = cellProbability[cellOffset + secondColumn]
        if secondProbability == 0.0:
          continue
        let overlapIndex = firstColumn * columnCount + secondColumn
        overlap[overlapIndex] += cellValue * firstProbability * secondProbability

  var bestExpected = 0.0
  for firstColumn in 0 .. columnCount - 1:
    for secondColumn in firstColumn .. columnCount - 1:
      let candidate = singleExpected[firstColumn] + singleExpected[secondColumn] - overlap[firstColumn * columnCount + secondColumn]
      if candidate > bestExpected:
        bestExpected = candidate
  let scaledScore = int(bestExpected * 10000.0 + 0.5)
  let wholePart = scaledScore div 10000
  let fractionPart = scaledScore mod 10000
  var fractionText = $(fractionPart)
  while fractionText.len < 4:
    fractionText = "0" & fractionText
  appendOutput($(wholePart) & "." & fractionText)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
```

Only upper-triangle pairs are stored.
Zero-value cells skip the overlap loop.
Adding one half before truncation rounds to four decimals.

## Complexity

The probability pass touches every cell for every start, and the pair scan visits each cell once for every column pair.

| phase | time | space |
|---|---|---|
| input read | one pass over grid rows | grid strings |
| probability pass | N times M starts over each row | M values per row |
| pair scan | N times M cells times M squared pairs | M squared overlaps |
| output | one line per test | block buffer |

The pair scan dominates when both grid sides are large.

The overall asymptotic bounds:

| measure | Big O |
|---|---|
| time | O(N times M cubed) |
| space | O(N times M squared) |

Enumerating all random path pairs for all starts would grow exponentially in the row count.

The cell-probability matrix turns that exponential work into one bounded pair scan.
