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
