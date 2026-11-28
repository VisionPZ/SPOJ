# DOJ1 — DOJO Corridor I (SPOJ)

<https://www.spoj.com/problems/DOJ1/>

## Problem

Cover an N by M corridor with 1 by 2 tatamis after one 1 by 1 cell is occupied. Count the coverings modulo K for each test case.

The first input line gives the test count T. Each next line gives N, M, the occupied cell row I and column J, then K. Print one count per case, in order.

| item | bound |
|---|---|
| test count T | 1 to 30000 |
| corridor rows N | 1 to 4 |
| corridor columns M | 1 to 1000000000 |
| occupied row I | 1 to N |
| occupied column J | 1 to M |
| modulus K | 1 to 1000000000 |
| judge limit | 200 ms, 1536 MB |

Sample input:

```
3
1 3 1 3 100
2 3 2 2 100
3 7 1 3 100
```

Sample output:

```
1
0
56
```

## Idea

A floor pattern repeats column by column, like laying the same brick course again and again. A matrix records how one column hands its overhang to the next, and fast exponentiation lays many columns at once.

The full profile matrix has 2^N states, at most 16. For N = 3 its reachable states compress to four, so one probe costs 4 by 4 matrix work instead of 16 by 16. Parity removes N = 2 and N = 4 cases at once, since an even row count leaves an odd number of cells. A per-column simulation over all M columns would cost O(M) per case and cannot handle a billion columns.

## Why It Works

1. A domino tiling needs an even cell count, so N even gives no tiling.
2. Color the board like a chessboard starting with black at (1, 1). A removed black cell leaves equal color counts, while a removed white cell does not.
3. The transfer matrix maps the overhang mask of one column to the next column.
4. Split at column J: columns before J use ordinary transfers, column J uses a hole transfer, and columns after J use ordinary transfers again.
5. The four-state subspace reached from an empty overhang is closed under the transfer, so the answer is preserved after compression.

| term | meaning |
|---|---|
| `reducedTransfer` | four-state transfer for one normal column |
| `cornerHoleMatrix` | hole column when I is row 1 or row 3 |
| `middleHoleMatrix` | hole column when I is row 2 |
| `leftExponent` | number of columns before the hole |
| `rightExponent` | number of columns after the hole |

For the third sample case N = 3, M = 7, I = 1, J = 3 with K = 100, the table shows the reduced vectors.

| step | vector | value |
|---|---|---|
| left power exponent 2 | column zero | [0, 0, 1, 0] |
| after corner hole | row vector | [4, 0, 15, 0] |
| right power exponent 4 | column zero | [99, 0, 4, 1] |
| dot product | 4·99 + 15·4 | 456 mod 100 = 56 |

`positiveModulo` keeps every intermediate in the range 0 to K − 1 after Nim's signed remainder. Products stay below 10^18, which fits in `int64`.

## Code

**Input and scanner.** The reader loads every case line and parses five values per case.

```nim
const flushBlockBytes = 1 shl 17
const reducedSize = 4

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
```

All inputs are nonnegative, so the scanner skips separators only.
`appendOutput` flushes after the buffer reaches `flushBlockBytes`.
One final write emits the last block.

**Reduced matrices and helpers.** Three constants hold the compressed transfer and the two hole columns.

```nim
const reducedTransfer: array[reducedSize, array[reducedSize, int64]] = [
    [0'i64, 0'i64, 0'i64, -1'i64],
    [1'i64, 0'i64, 0'i64, 0'i64],
    [0'i64, 1'i64, 0'i64, 4'i64],
    [0'i64, 0'i64, 1'i64, 0'i64]]

const cornerHoleMatrix: array[reducedSize, array[reducedSize, int64]] = [
    [1'i64, 0'i64, 4'i64, 0'i64],
    [0'i64, 0'i64, 0'i64, 0'i64],
    [4'i64, 0'i64, 15'i64, 0'i64],
    [0'i64, 0'i64, 0'i64, 0'i64]]

const middleHoleMatrix: array[reducedSize, array[reducedSize, int64]] = [
    [0'i64, 0'i64, 0'i64, 0'i64],
    [0'i64, 2'i64, 0'i64, 8'i64],
    [0'i64, 0'i64, 0'i64, 0'i64],
    [0'i64, 8'i64, 0'i64, 32'i64]]

proc positiveModulo(value: int64, modulus: int64): int64 =
  let remainder = value mod modulus
  if remainder < 0:
    return remainder + modulus
  return remainder

proc multiplyMatrices(leftMatrix, rightMatrix: array[reducedSize, array[reducedSize, int64]], modulus: int64): array[reducedSize, array[reducedSize, int64]] =
  for rowIndex in 0 .. reducedSize - 1:
    for colIndex in 0 .. reducedSize - 1:
      var total: int64 = 0
      for innerIndex in 0 .. reducedSize - 1:
        total = total + leftMatrix[rowIndex][innerIndex] * rightMatrix[innerIndex][colIndex]
      result[rowIndex][colIndex] = positiveModulo(total, modulus)

proc applyToColumn(vector: array[reducedSize, int64], matrix: array[reducedSize, array[reducedSize, int64]], modulus: int64): array[reducedSize, int64] =
  for rowIndex in 0 .. reducedSize - 1:
    var total: int64 = 0
    for colIndex in 0 .. reducedSize - 1:
      total = total + matrix[rowIndex][colIndex] * vector[colIndex]
    result[rowIndex] = positiveModulo(total, modulus)

proc applyToRow(vector: array[reducedSize, int64], matrix: array[reducedSize, array[reducedSize, int64]], modulus: int64): array[reducedSize, int64] =
  for colIndex in 0 .. reducedSize - 1:
    var total: int64 = 0
    for rowIndex in 0 .. reducedSize - 1:
      total = total + vector[rowIndex] * matrix[rowIndex][colIndex]
    result[colIndex] = positiveModulo(total, modulus)

proc dotProduct(leftVector, rightVector: array[reducedSize, int64], modulus: int64): int64 =
  var total: int64 = 0
  for index in 0 .. reducedSize - 1:
    total = total + leftVector[index] * rightVector[index]
  return positiveModulo(total, modulus)
```

`reducedTransfer` advances one ordinary column.
The hole matrices depend only on whether I is a corner row or the middle row.
`positiveModulo` corrects Nim's signed remainder for the −1 entry.

**Case loop.** Parity filters impossible cases, then two powers meet at the hole column.

```nim
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let corridorRows = nextInt(inputData, scanPos)
  let corridorColumns = nextInt(inputData, scanPos)
  let holeRow = nextInt(inputData, scanPos)
  let holeColumn = nextInt(inputData, scanPos)
  let modulusBase = int64(nextInt(inputData, scanPos))
  var answerValue: int64 = 0
  if (int64(corridorRows) * int64(corridorColumns) - 1) mod 2 == 0 and (holeRow + holeColumn) mod 2 == 0:
    if corridorRows == 1:
      answerValue = 1 mod modulusBase
    elif corridorRows == 3:
      let leftExponent = holeColumn - 1
      let rightExponent = corridorColumns - holeColumn
      var leftVector: array[reducedSize, int64] = [1'i64, 0'i64, 0'i64, 0'i64]
      var rightVector: array[reducedSize, int64] = [1'i64, 0'i64, 0'i64, 0'i64]
      var basePower = reducedTransfer
      for rowIndex in 0 .. reducedSize - 1:
        for colIndex in 0 .. reducedSize - 1:
          basePower[rowIndex][colIndex] = positiveModulo(basePower[rowIndex][colIndex], modulusBase)
      var remainingLeft = leftExponent
      var remainingRight = rightExponent
      while remainingLeft > 0 or remainingRight > 0:
        if (remainingLeft and 1) != 0:
          leftVector = applyToColumn(leftVector, basePower, modulusBase)
        if (remainingRight and 1) != 0:
          rightVector = applyToColumn(rightVector, basePower, modulusBase)
        basePower = multiplyMatrices(basePower, basePower, modulusBase)
        remainingLeft = remainingLeft shr 1
        remainingRight = remainingRight shr 1
      if holeRow == 2:
        leftVector = applyToRow(leftVector, middleHoleMatrix, modulusBase)
      else:
        leftVector = applyToRow(leftVector, cornerHoleMatrix, modulusBase)
      answerValue = dotProduct(leftVector, rightVector, modulusBase)
  appendOutput($answerValue)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

Both exponents share one squaring chain.
The hole matrix joins the left vector to the right vector.
Every case writes exactly one line.

## Complexity

Each case uses a few dozen 4 by 4 operations, and trivial cases stop sooner.

| phase | time | space |
|---|---|---|
| input read | one pass over 5T values | one input string |
| parity filter | constant per case | none extra |
| three-row case | O(log M) matrix work | four-state vectors |
| output | T lines | block buffer |

| measure | Big O |
|---|---|
| time | O(T log M) worst case |
| space | O(T) for input text |

A column-by-column simulation would cost O(M) per case and fail for a billion columns. Exponentiation replaces that walk with about thirty squarings.
