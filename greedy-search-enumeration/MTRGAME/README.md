# MTRGAME — Matrix Game (SPOJ)

<https://www.spoj.com/problems/MTRGAME/>

## Problem

Compute the average payoff of a two-player zero-sum matrix game. P1 picks a row to maximize the amount received, P2 picks a column to minimize the amount paid, and both choose at the same time. Random play gives the average.

Input starts with the test count. Each case gives the row count and column count, then the matrix values. Output one real number per case with exactly three digits after the decimal point.

| Item | Bound |
|---|---|
| Rows | 1 to 3 |
| Columns | up to 100000 |
| Matrix magnitude | up to 150000 |
| Test cases | up to 120 |
| Judge limit | 1000 ms, 1536 MB |

The column count drives the design, since a plain lookup over every strategy pair is quadratic.

Sample input:

```
3
1 1
-1
2 2
1 2
3 4
2 2
1 4
4 3
```

The three matrices have one, four, and four entries.

Sample output:

```
-1.000
3.000
3.250
```

The last value comes from mixing rows instead of choosing one.

## Idea

Treat each column as a sloped line showing the payoff for every row mixture, then keep only the lowest line at each point. P1 picks the mixture at the highest point of that lower envelope, like choosing the tallest peak in a valley made of straight walls.

The algorithm generates constraints. It solves the game for a small set of columns, finds the column that most violates that solution, and adds it. With at most three rows, the small game is solved by checking vertices, edge crossings, and triple intersections. A lookup over all row-column pairs costs quadratic time per case, while a few constraint rounds scan all columns each time.

## Why It Works

1. The game value equals the largest guaranteed payoff P1 can secure by mixing rows.
2. Against a fixed mixture, P2 always picks the column with the smallest expected payoff.
3. A solution for a subset of columns gives an upper bound on the full game value.
4. If some column pays less than that bound, adding the column can only lower the bound.
5. When every column pays at least the bound, the bound is the game value by the minimax theorem.

| Term | Meaning |
|---|---|
| `columns` | indices of the currently enforced columns |
| `guardedPayoff` | worst payoff over enforced columns for one mixture |
| `bestValue` | largest guaranteed payoff for the enforced columns |
| `violatingColumn` | column paying less than the current bound |

The terms above name every value kept between rounds.

A trace of the last sample matrix:

```
row mix 1/2, 1/2: column 0 pays 2.5, column 1 pays 3.5
add column 0; best row 1 pays 4 but column 1 pays 3
add column 1; crossing at mix 1/4, 3/4 pays 3.25
both columns pay 3.25, so the value is 3.25
```

The trace matches the last sample answer.

## Code

**Input, scanner, and output.** The reader accepts negative matrix entries.

```nim
import math

const flushBlockBytes = 1 shl 17
const feasibilityMargin = 1.0e-9
const stopMargin = 1.0e-7

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-':
    pos += 1
  var negative = false
  if pos < data.len and data[pos] == '-':
    negative = true
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  if negative:
    return -value
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
```

The minus sign is consumed before the digits.
Every output line waits in the buffer.

**Fixed precision.** Rounding is done in integer arithmetic after scaling by a thousand.

```nim
proc formatPayoff(value: float): string =
  var rounded: int64
  if value >= 0:
    rounded = int64(floor(value * 1000.0 + 0.5))
  else:
    rounded = -int64(floor(-value * 1000.0 + 0.5))
  let negative = rounded < 0
  var magnitude = rounded
  if negative:
    magnitude = -magnitude
  let wholePart = magnitude div 1000
  let fractionPart = magnitude mod 1000
  result = ""
  if negative:
    result.add '-'
  result.add $wholePart
  result.add '.'
  result.add chr(48 + fractionPart div 100)
  result.add chr(48 + (fractionPart div 10) mod 10)
  result.add chr(48 + fractionPart mod 10)
```

Negative results keep their sign.
Three fraction digits always appear.

**Small linear system.** The interior crossing uses a three-by-three solve.

```nim
proc solveThreeByThree(coefficients: array[3, array[3, float]],
                       rightSides: array[3, float]): seq[float] =
  var matrixValues = coefficients
  var values = rightSides
  for columnIndex in 0 .. 2:
    var pivotRow = columnIndex
    for rowIndex in columnIndex + 1 .. 2:
      if abs(matrixValues[rowIndex][columnIndex]) > abs(matrixValues[pivotRow][columnIndex]):
        pivotRow = rowIndex
    if abs(matrixValues[pivotRow][columnIndex]) < feasibilityMargin:
      return @[]
    if pivotRow != columnIndex:
      swap(matrixValues[pivotRow], matrixValues[columnIndex])
      swap(values[pivotRow], values[columnIndex])
    let divisor = matrixValues[columnIndex][columnIndex]
    for cellIndex in 0 .. 2:
      matrixValues[columnIndex][cellIndex] = matrixValues[columnIndex][cellIndex] / divisor
    values[columnIndex] = values[columnIndex] / divisor
    for rowIndex in 0 .. 2:
      if rowIndex == columnIndex:
        continue
      let factor = matrixValues[rowIndex][columnIndex]
      if abs(factor) < feasibilityMargin:
        continue
      for cellIndex in 0 .. 2:
        matrixValues[rowIndex][cellIndex] = matrixValues[rowIndex][cellIndex] - factor * matrixValues[columnIndex][cellIndex]
      values[rowIndex] = values[rowIndex] - factor * values[columnIndex]
  return @[values[0], values[1], values[2]]
```

A singular system is rejected.
The pivot keeps the division stable.

**Restricted game.** Vertices, edge crossings, and triple crossings are checked.

```nim
proc guardedPayoff(matrix: seq[seq[int]], rowCount: int,
                   probabilities: seq[float], columns: seq[int]): float =
  var minimum = 1.0e30
  for columnIndex in columns:
    var expected = 0.0
    for rowIndex in 0 .. rowCount - 1:
      expected = expected + probabilities[rowIndex] * float(matrix[rowIndex][columnIndex])
    if expected < minimum:
      minimum = expected
  return minimum

proc solveActive(matrix: seq[seq[int]], rowCount: int,
                 columns: seq[int]): (float, seq[float]) =
  var bestValue = -1.0e30
  var bestProbabilities = newSeq[float](rowCount)
  for fixedRow in 0 .. rowCount - 1:
    var probabilities = newSeq[float](rowCount)
    probabilities[fixedRow] = 1.0
    let candidate = guardedPayoff(matrix, rowCount, probabilities, columns)
    if candidate > bestValue:
      bestValue = candidate
      bestProbabilities = probabilities
  for firstRow in 0 .. rowCount - 1:
    for secondRow in firstRow + 1 .. rowCount - 1:
      for firstPosition in 0 .. columns.len - 1:
        for secondPosition in firstPosition + 1 .. columns.len - 1:
          let firstColumn = columns[firstPosition]
          let secondColumn = columns[secondPosition]
          let slopeDifference = float(matrix[firstRow][firstColumn] - matrix[secondRow][firstColumn]) -
                                float(matrix[firstRow][secondColumn] - matrix[secondRow][secondColumn])
          if abs(slopeDifference) < feasibilityMargin:
            continue
          let crossing = float(matrix[secondRow][secondColumn] - matrix[secondRow][firstColumn]) / slopeDifference
          if crossing < -feasibilityMargin or crossing > 1.0 + feasibilityMargin:
            continue
          var shareFirst = crossing
          if shareFirst < 0:
            shareFirst = 0
          if shareFirst > 1:
            shareFirst = 1
          var probabilities = newSeq[float](rowCount)
          probabilities[firstRow] = shareFirst
          probabilities[secondRow] = 1.0 - shareFirst
          let candidate = guardedPayoff(matrix, rowCount, probabilities, columns)
          if candidate > bestValue:
            bestValue = candidate
            bestProbabilities = probabilities
  if rowCount == 3:
    for firstPosition in 0 .. columns.len - 1:
      for secondPosition in firstPosition + 1 .. columns.len - 1:
        for thirdPosition in secondPosition + 1 .. columns.len - 1:
          let firstColumn = columns[firstPosition]
          let secondColumn = columns[secondPosition]
          let thirdColumn = columns[thirdPosition]
          var coefficients: array[3, array[3, float]]
          coefficients[0] = [float(matrix[0][firstColumn] - matrix[0][secondColumn]),
                             float(matrix[1][firstColumn] - matrix[1][secondColumn]),
                             float(matrix[2][firstColumn] - matrix[2][secondColumn])]
          coefficients[1] = [float(matrix[0][firstColumn] - matrix[0][thirdColumn]),
                             float(matrix[1][firstColumn] - matrix[1][thirdColumn]),
                             float(matrix[2][firstColumn] - matrix[2][thirdColumn])]
          coefficients[2] = [1.0, 1.0, 1.0]
          let rightSides = [0.0, 0.0, 1.0]
          let probabilities = solveThreeByThree(coefficients, rightSides)
          if probabilities.len == 0:
            continue
          var feasible = true
          for rowIndex in 0 .. 2:
            if probabilities[rowIndex] < -feasibilityMargin:
              feasible = false
          if not feasible:
            continue
          let candidate = guardedPayoff(matrix, rowCount, probabilities, columns)
          if candidate > bestValue:
            bestValue = candidate
            bestProbabilities = probabilities
  return (bestValue, bestProbabilities)
```

Each candidate is checked against every enforced column.
Only valid mixtures can raise the bound.
The row count limits this solver to three rows.

**Constraint generation and driver.** The most violated column joins the enforced set.

```nim
proc gameValue(matrix: seq[seq[int]], rowCount: int, columnCount: int): float =
  if rowCount == 1:
    var minimum = 1.0e30
    for columnIndex in 0 .. columnCount - 1:
      let candidate = float(matrix[0][columnIndex])
      if candidate < minimum:
        minimum = candidate
    return minimum
  var columns = @[0]
  for iteration in 0 .. columnCount + 1:
    let solution = solveActive(matrix, rowCount, columns)
    let probabilities = solution[1]
    var minimumValue = 1.0e30
    var violatingColumn = 0
    for columnIndex in 0 .. columnCount - 1:
      var expected = 0.0
      for rowIndex in 0 .. rowCount - 1:
        expected = expected + probabilities[rowIndex] * float(matrix[rowIndex][columnIndex])
      if expected < minimumValue:
        minimumValue = expected
        violatingColumn = columnIndex
    if minimumValue >= solution[0] - stopMargin:
      return solution[0]
    if violatingColumn in columns:
      return solution[0]
    columns.add violatingColumn
  return solveActive(matrix, rowCount, columns)[0]

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let rowCount = nextInt(inputData, scanPos)
  let columnCount = nextInt(inputData, scanPos)
  var matrix = newSeq[seq[int]](rowCount)
  for rowIndex in 0 .. rowCount - 1:
    matrix[rowIndex] = newSeq[int](columnCount)
    for columnIndex in 0 .. columnCount - 1:
      matrix[rowIndex][columnIndex] = nextInt(inputData, scanPos)
  let payoff = gameValue(matrix, rowCount, columnCount)
  appendOutput(formatPayoff(payoff) & "\n")

stdout.write outputBuffer
outputBuffer.setLen 0
```

A single row needs only a column minimum.
The loop stops when no column violates the bound.
One formatted line is written per case.

## Complexity

Each constraint round solves a small game and scans every column once.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over matrix entries | one input string |
| Restricted game | constant work for three rows | a few candidate mixtures |
| Column scan | one pass over all columns | enforced column indices |
| Output | one write per block | block buffer |

The phase table shows that column scans dominate the cost.

| Measure | Big O |
|---|---|
| Time | O(rounds times columns) per case |
| Space | O(columns) for enforced indices |

Checking every row-column strategy pair costs quadratic time, while only a handful of constraint rounds are normally needed.
