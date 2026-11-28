# LIFEGAME — Life Game (SPOJ)

<https://www.spoj.com/problems/LIFEGAME/>

## Problem

 viruses spread on a hexagon of hexagonal colonies, and each colony keeps its own count. Report the total virus count after `L` periods, with each colony reduced modulo `M` after every period.

Each case starts with `N M L`, then `2N-1` rows of virus counts. Row widths grow from `N` to `2N-1` and shrink back to `N`. A line `0 0 0` ends the input. Print `Case X: total`.

| item | bound |
|---|---|
| grid edge N | 1 to 6 |
| modulus M | 2 to 1000000000 |
| periods L | 1 to 1000000000 |
| judge limit | 6796 ms, 1536 MB |

The huge period count drives the design.

Sample input:

```
3 3 1
1 0 0
0 0 0 0
0 0 0 0 0
0 0 0 0
0 0 1
3 3 2
1 0 0
0 0 0 0
0 0 0 0 0
0 0 0 0
0 0 1
0 0 0
```

Sample output:

```
Case 1: 8
Case 2: 18
```

## Idea

self-propagation is a fixed linear map, like repeatedly multiplying a vector by one matrix. Fast exponentiation applies that map `log L` times instead of `L` times. Each colony keeps its own viruses and sends one copy to each neighbor, so the matrix has a one on the diagonal and ones at neighbor positions. Take matrix exponentiation as the engine.

## Why It Works

1. A colony with `v` viruses keeps `v` and sends `v` to each neighbor.
2. The new count at a colony is its old count plus the old counts of its neighbors.
3. Reduction modulo `M` commutes with this linear map, so each step may reduce.
4. The total is the sum of vector entries after `L` applications, without a final reduction.
5. Binary exponentiation applies powers `A`, `A^2`, `A^4`, and so on.

| term | meaning |
|---|---|
| `transition` | matrix with self and neighbor contributions |
| `stateVector` | virus count in each colony |
| `cellCount` | number of colonies, at most 91 |
| `rowLength` | colony count in one grid row |

A trace for `N = 3`, `M = 3` starts with two corner colonies holding one virus. After one period eight colonies hold one virus each, giving total `8`. After two periods the colony counts sum to `18`, matching the sample.

## Code

**Reader and arithmetic helpers.** The scanner loads all cases and the helpers do the linear algebra.

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc rowLength(gridSize: int, rowIndex: int): int =
  let distanceFromEdge = rowIndex
  let distanceFromBottom = 2 * gridSize - 2 - rowIndex
  if distanceFromEdge < distanceFromBottom:
    return gridSize + distanceFromEdge
  return gridSize + distanceFromBottom

proc multiplyMatrices(leftMatrix: seq[seq[int64]], rightMatrix: seq[seq[int64]], modulus: int64, sizeValue: int): seq[seq[int64]] =
  var resultMatrix = newSeq[seq[int64]](sizeValue)
  for rowIndex in 0 .. sizeValue - 1:
    resultMatrix[rowIndex] = newSeq[int64](sizeValue)
  for rowIndex in 0 .. sizeValue - 1:
    for midIndex in 0 .. sizeValue - 1:
      let leftValue = leftMatrix[rowIndex][midIndex]
      if leftValue == 0:
        continue
      for columnIndex in 0 .. sizeValue - 1:
        let rightValue = rightMatrix[midIndex][columnIndex]
        if rightValue == 0:
          continue
        resultMatrix[rowIndex][columnIndex] = (resultMatrix[rowIndex][columnIndex] + leftValue * rightValue) mod modulus
  return resultMatrix

proc applyVector(vectorValue: seq[int64], matrixValue: seq[seq[int64]], modulus: int64, sizeValue: int): seq[int64] =
  var resultVector = newSeq[int64](sizeValue)
  for midIndex in 0 .. sizeValue - 1:
    let sourceValue = vectorValue[midIndex]
    if sourceValue == 0:
      continue
    for columnIndex in 0 .. sizeValue - 1:
      let factorValue = matrixValue[midIndex][columnIndex]
      if factorValue == 0:
        continue
      resultVector[columnIndex] = (resultVector[columnIndex] + sourceValue * factorValue) mod modulus
  return resultVector
```

Row widths follow the hexagon outline.
Sparse entries are skipped in both multiply routines.
Products fit 64 bits because the modulus is at most one billion.

**Transition build and exponentiation.** One matrix captures one propagation period.

```nim
proc totalViruses(gridSize: int, modulus: int64, periods: int64, initialValues: seq[int64]): int64 =
  let lastRow = 2 * gridSize - 2
  var cellIndices = newSeq[seq[int]](lastRow + 1)
  var cellCount = 0
  for rowIndex in 0 .. lastRow:
    let width = rowLength(gridSize, rowIndex)
    cellIndices[rowIndex] = newSeq[int](width)
    for columnIndex in 0 .. width - 1:
      cellIndices[rowIndex][columnIndex] = cellCount
      cellCount += 1
  var transition = newSeq[seq[int64]](cellCount)
  for rowIndex in 0 .. cellCount - 1:
    transition[rowIndex] = newSeq[int64](cellCount)
  for rowIndex in 0 .. lastRow:
    let width = rowLength(gridSize, rowIndex)
    for columnIndex in 0 .. width - 1:
      let targetIndex = cellIndices[rowIndex][columnIndex]
      transition[targetIndex][targetIndex] = (transition[targetIndex][targetIndex] + 1) mod modulus
      var sourceIndices = newSeq[int]()
      if columnIndex > 0:
        sourceIndices.add cellIndices[rowIndex][columnIndex - 1]
      if columnIndex + 1 < width:
        sourceIndices.add cellIndices[rowIndex][columnIndex + 1]
      if rowIndex > 0:
        let aboveWidth = rowLength(gridSize, rowIndex - 1)
        if aboveWidth == width + 1:
          sourceIndices.add cellIndices[rowIndex - 1][columnIndex]
          if columnIndex + 1 < aboveWidth:
            sourceIndices.add cellIndices[rowIndex - 1][columnIndex + 1]
        else:
          if columnIndex > 0:
            sourceIndices.add cellIndices[rowIndex - 1][columnIndex - 1]
          if columnIndex < aboveWidth:
            sourceIndices.add cellIndices[rowIndex - 1][columnIndex]
      if rowIndex < lastRow:
        let belowWidth = rowLength(gridSize, rowIndex + 1)
        if belowWidth == width + 1:
          sourceIndices.add cellIndices[rowIndex + 1][columnIndex]
          if columnIndex + 1 < belowWidth:
            sourceIndices.add cellIndices[rowIndex + 1][columnIndex + 1]
        else:
          if columnIndex > 0:
            sourceIndices.add cellIndices[rowIndex + 1][columnIndex - 1]
          if columnIndex < belowWidth:
            sourceIndices.add cellIndices[rowIndex + 1][columnIndex]
      for sourceIndex in sourceIndices:
        transition[targetIndex][sourceIndex] = (transition[targetIndex][sourceIndex] + 1) mod modulus
  var stateVector = newSeq[int64](cellCount)
  for cellIndex in 0 .. cellCount - 1:
    stateVector[cellIndex] = initialValues[cellIndex] mod modulus
  var exponentLeft = periods
  while exponentLeft > 0:
    if (exponentLeft and 1) == 1:
      stateVector = applyVector(stateVector, transition, modulus, cellCount)
    exponentLeft = exponentLeft div 2
    if exponentLeft > 0:
      transition = multiplyMatrices(transition, transition, modulus, cellCount)
  var answerValue: int64 = 0
  for cellIndex in 0 .. cellCount - 1:
    answerValue = answerValue + stateVector[cellIndex]
  return answerValue
```

Neighbor lists follow the row-width changes.
The diagonal records viruses that stay at home.
The final sum is not reduced, since it asks for a total.

**Case loop.** The driver parses each grid and writes one answer.

```nim
var caseNumber = 1
while true:
  let gridSize = nextInt(inputData, scanPos)
  let modulusValue = int64(nextInt(inputData, scanPos))
  let periods = int64(nextInt(inputData, scanPos))
  if gridSize == 0 and modulusValue == 0 and periods == 0:
    break
  let lastRow = 2 * gridSize - 2
  var initialValues = newSeq[int64]()
  for rowIndex in 0 .. lastRow:
    let width = rowLength(gridSize, rowIndex)
    for columnIndex in 0 .. width - 1:
      initialValues.add int64(nextInt(inputData, scanPos))
  let answer = totalViruses(gridSize, modulusValue, periods, initialValues)
  appendOutput("Case " & $caseNumber & ": " & $answer)
  outputBuffer.add '\n'
  caseNumber += 1

stdout.write outputBuffer
outputBuffer.setLen 0
```

The zero header stops the loop.
Row widths decide how many counts to read.
The buffered writer flushes once at the end.

## Complexity

Each case builds one matrix and squares it once per exponent bit.

| phase | time | space |
|---|---|---|
| input read | one pass over all counts | one input string |
| matrix build | one pass over colonies and neighbors | two 91-by-91 matrices |
| exponentiation | about 30 matrix squarings | one vector per set bit |
| output | one buffered line per case | block buffer |

Matrix size stays small because `N` never exceeds six.

| measure | Big O |
|---|---|
| time per case | O(T^3 log L), with T at most 91 |
| space | O(T^2 + total input bytes) |

Simulating all `L` periods would take `L` full grid passes.
Exponentiation finishes in about thirty matrix products.
