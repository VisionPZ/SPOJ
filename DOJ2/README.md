# DOJ2 — DOJO Corridor II (SPOJ)

<https://www.spoj.com/problems/DOJ2/>

## Problem

Cover a 5 by N corridor with 1 by 2 tatamis after one 1 by 1 cell is occupied. Count the coverings modulo 1000000007 for each test case.

The first input line gives the test count T. Each next line gives the column count N, a row letter from A to E, and the occupied column J. Print one count per case, in order.

| item | bound |
|---|---|
| test count T | 1 to 40000 |
| corridor columns N | 1 to 20000 |
| occupied row letter | A to E |
| occupied column J | 1 to N |
| modulus | 1000000007 |
| judge limit | 400 ms, 1536 MB |

Sample input:

```
3
1 C 1
3 B 2
5 A 1
```

Sample output:

```
1
8
192
```

## Idea

A column hands its overhang to the next column, like a row of dominoes falling in a fixed rhythm. The 32 possible overhang masks compress to eight states, and one short recurrence generates every column vector up front.

Each test then reads two stored vectors and combines them with one 8 by 8 hole matrix. That costs 64 products per case instead of a fresh exponentiation. A profile simulation over all N columns for every test would cost O(N) per case and repeat the same work forty thousand times.

## Why It Works

1. A transfer matrix maps the overhang mask of one column to the next column.
2. The subspace reached from an empty overhang has eight dimensions and stays closed under transfer.
3. The eight-state transfer is a companion matrix, so each new vector comes from seven earlier entries and the last entry.
4. Split at column J: the left vector uses J − 1 transfers, the right vector uses N − J transfers.
5. The hole matrix for row A or E, row B or D, and row C joins the two vectors.

| term | meaning |
|---|---|
| `powerVectors` | stored eighth-component state vector for each column count |
| `cornerHoleMatrix` | hole transitions for rows A and E |
| `sideHoleMatrix` | hole transitions for rows B and D |
| `centerHoleMatrix` | hole transitions for row C |
| `lastValue` | eighth component used by the recurrence |

For the third sample case N = 5, row A, J = 1 with modulus 1000000007, the table shows the vectors.

| step | value |
|---|---|
| left exponent J − 1 | 0, vector [1, 0, 0, 0, 0, 0, 0, 0] |
| right exponent N − J | 4, vector [0, 0, 0, 0, 1, 0, 0, 0] |
| hole matrix entry (0, 4) | 192 |
| dot product | 1 · 192 · 1 = 192 |

`positiveModulo` keeps each recurrence value in the range 0 to 1000000006. Products of two stored values stay below 10^18, which fits in `int64`.

## Code

**Input and scanner.** The reader loads all cases, parses the row letter separately, and normalizes remainders.

```nim
const flushBlockBytes = 1 shl 17
const reducedSize = 8
const modulusValue = 1000000007'i64

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

proc nextRowIndex(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < 'A' or data[pos] > 'E'):
    pos += 1
  return int(data[pos]) - 65

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc positiveModulo(value: int64): int64 =
  let remainder = value mod modulusValue
  if remainder < 0:
    return remainder + modulusValue
  return remainder
```

`nextRowIndex` maps A to 0 and E to 4.
The modulus is fixed, so no case carries its own modulus.
`appendOutput` flushes in blocks of `flushBlockBytes`.

**Hole matrices.** Three constants hold the reduced transitions through the occupied cell.

```nim
const cornerHoleMatrix: array[reducedSize, array[reducedSize, int64]] = [
    [1'i64, 0'i64, 15'i64, 0'i64, 192'i64, 0'i64, 2415'i64, 0'i64],
    [0'i64, 0'i64, 0'i64, 0'i64, 0'i64, 0'i64, 0'i64, 0'i64],
    [15'i64, 0'i64, 192'i64, 0'i64, 2415'i64, 0'i64, 30305'i64, 0'i64],
    [0'i64, 0'i64, 0'i64, 0'i64, 0'i64, 0'i64, 0'i64, 0'i64],
    [192'i64, 0'i64, 2415'i64, 0'i64, 30305'i64, 0'i64, 380160'i64, 0'i64],
    [0'i64, 0'i64, 0'i64, 0'i64, 0'i64, 0'i64, 0'i64, 0'i64],
    [2415'i64, 0'i64, 30305'i64, 0'i64, 380160'i64, 0'i64, 4768673'i64, 0'i64],
    [0'i64, 0'i64, 0'i64, 0'i64, 0'i64, 0'i64, 0'i64, 0'i64]]

const sideHoleMatrix: array[reducedSize, array[reducedSize, int64]] = [
    [0'i64, 0'i64, 0'i64, 0'i64, 0'i64, 0'i64, 0'i64, 0'i64],
    [0'i64, 8'i64, 0'i64, 112'i64, 0'i64, 1424'i64, 0'i64, 17896'i64],
    [0'i64, 0'i64, 0'i64, 0'i64, 0'i64, 0'i64, 0'i64, 0'i64],
    [0'i64, 112'i64, 0'i64, 1560'i64, 0'i64, 19824'i64, 0'i64, 249120'i64],
    [0'i64, 0'i64, 0'i64, 0'i64, 0'i64, 0'i64, 0'i64, 0'i64],
    [0'i64, 1424'i64, 0'i64, 19824'i64, 0'i64, 251904'i64, 0'i64, 3165552'i64],
    [0'i64, 0'i64, 0'i64, 0'i64, 0'i64, 0'i64, 0'i64, 0'i64],
    [0'i64, 17896'i64, 0'i64, 249120'i64, 0'i64, 3165552'i64, 0'i64, 39779880'i64]]

const centerHoleMatrix: array[reducedSize, array[reducedSize, int64]] = [
    [1'i64, 0'i64, 15'i64, 0'i64, 192'i64, 0'i64, 2415'i64, 0'i64],
    [0'i64, 0'i64, 0'i64, 0'i64, 0'i64, 0'i64, 0'i64, 0'i64],
    [15'i64, 0'i64, 196'i64, 0'i64, 2479'i64, 0'i64, 31137'i64, 0'i64],
    [0'i64, 0'i64, 0'i64, 0'i64, 0'i64, 0'i64, 0'i64, 0'i64],
    [192'i64, 0'i64, 2479'i64, 0'i64, 31329'i64, 0'i64, 393472'i64, 0'i64],
    [0'i64, 0'i64, 0'i64, 0'i64, 0'i64, 0'i64, 0'i64, 0'i64],
    [2415'i64, 0'i64, 31137'i64, 0'i64, 393472'i64, 0'i64, 4941729'i64, 0'i64],
    [0'i64, 0'i64, 0'i64, 0'i64, 0'i64, 0'i64, 0'i64, 0'i64]]
```

Rows A and E share `cornerHoleMatrix`.
Rows B and D share `sideHoleMatrix`.
Row C uses `centerHoleMatrix`.

**Vector table and case loop.** One pass builds every column vector, then each case reads two of them.

```nim
let caseCount = nextInt(inputData, scanPos)
var caseColumns = newSeq[int](caseCount)
var caseRows = newSeq[int](caseCount)
var caseHoles = newSeq[int](caseCount)
var largestColumns = 0
for caseIndex in 0 .. caseCount - 1:
  let corridorColumns = nextInt(inputData, scanPos)
  let holeRowIndex = nextRowIndex(inputData, scanPos)
  let holeColumn = nextInt(inputData, scanPos)
  caseColumns[caseIndex] = corridorColumns
  caseRows[caseIndex] = holeRowIndex
  caseHoles[caseIndex] = holeColumn
  if corridorColumns > largestColumns:
    largestColumns = corridorColumns

var powerVectors = newSeq[int64]((largestColumns + 1) * reducedSize)
powerVectors[0] = 1'i64
for columnIndex in 1 .. largestColumns:
  let previousOffset = (columnIndex - 1) * reducedSize
  let currentOffset = columnIndex * reducedSize
  let lastValue = powerVectors[previousOffset + reducedSize - 1]
  powerVectors[currentOffset] = positiveModulo(-lastValue)
  powerVectors[currentOffset + 1] = powerVectors[previousOffset]
  powerVectors[currentOffset + 2] = positiveModulo(powerVectors[previousOffset + 1] + 15'i64 * lastValue)
  powerVectors[currentOffset + 3] = powerVectors[previousOffset + 2]
  powerVectors[currentOffset + 4] = positiveModulo(powerVectors[previousOffset + 3] - 32'i64 * lastValue)
  powerVectors[currentOffset + 5] = powerVectors[previousOffset + 4]
  powerVectors[currentOffset + 6] = positiveModulo(powerVectors[previousOffset + 5] + 15'i64 * lastValue)
  powerVectors[currentOffset + 7] = powerVectors[previousOffset + 6]

for caseIndex in 0 .. caseCount - 1:
  let leftOffset = (caseHoles[caseIndex] - 1) * reducedSize
  let rightOffset = (caseColumns[caseIndex] - caseHoles[caseIndex]) * reducedSize
  var holeMatrix = cornerHoleMatrix
  if caseRows[caseIndex] == 1 or caseRows[caseIndex] == 3:
    holeMatrix = sideHoleMatrix
  elif caseRows[caseIndex] == 2:
    holeMatrix = centerHoleMatrix
  var answerValue: int64 = 0
  for rowIndex in 0 .. reducedSize - 1:
    var combined: int64 = 0
    for colIndex in 0 .. reducedSize - 1:
      combined = combined + holeMatrix[rowIndex][colIndex] * powerVectors[rightOffset + colIndex]
    answerValue = answerValue + powerVectors[leftOffset + rowIndex] * positiveModulo(combined)
  answerValue = positiveModulo(answerValue)
  appendOutput($answerValue)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
```

The table stops at the largest column count in the input.
Each case picks one hole matrix from the row letter.
One dot product produces the printed count.

## Complexity

The vector table is built once, so each case only reads stored data.

| phase | time | space |
|---|---|---|
| input read | one pass over 3T values | one input string |
| vector table | O(Nmax) recurrence steps | 8 values per column |
| case answer | 64 products per case | none extra |
| output | T lines | block buffer |

| measure | Big O |
|---|---|
| time | O(Nmax + T) |
| space | O(Nmax) for stored vectors |

A fresh column simulation per case would cost O(Nmax · T) and repeat identical vectors. Sharing one table removes that repetition.
