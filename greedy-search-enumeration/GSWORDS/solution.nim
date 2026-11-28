const flushBlockBytes = 1 shl 17
const modulusValue = 1000000007'i64
const matrixSize = 3

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

type
  SquareMatrix = array[matrixSize, array[matrixSize, int64]]

proc multiplyMatrices(leftMatrix: SquareMatrix, rightMatrix: SquareMatrix): SquareMatrix =
  for rowIndex in 0 .. matrixSize - 1:
    for colIndex in 0 .. matrixSize - 1:
      var cellValue: int64 = 0
      for innerIndex in 0 .. matrixSize - 1:
        cellValue = (cellValue + leftMatrix[rowIndex][innerIndex] * rightMatrix[innerIndex][colIndex]) mod modulusValue
      result[rowIndex][colIndex] = cellValue

proc powerMatrix(baseMatrix: SquareMatrix, exponentValue: int64): SquareMatrix =
  var accumulated: SquareMatrix
  for rowIndex in 0 .. matrixSize - 1:
    for colIndex in 0 .. matrixSize - 1:
      if rowIndex == colIndex:
        accumulated[rowIndex][colIndex] = 1
      else:
        accumulated[rowIndex][colIndex] = 0
  var runningBase = baseMatrix
  var remainingExponent = exponentValue
  while remainingExponent > 0:
    if (remainingExponent and 1'i64) != 0:
      accumulated = multiplyMatrices(accumulated, runningBase)
    remainingExponent = remainingExponent div 2
    if remainingExponent > 0:
      runningBase = multiplyMatrices(runningBase, runningBase)
  return accumulated

proc countWords(lengthValue: int64): int64 =
  if lengthValue == 0:
    return 1
  if lengthValue == 1:
    return 2
  if lengthValue == 2:
    return 3
  var transitionMatrix: SquareMatrix
  transitionMatrix[0][0] = 1
  transitionMatrix[0][1] = 0
  transitionMatrix[0][2] = 1
  transitionMatrix[1][0] = 1
  transitionMatrix[1][1] = 0
  transitionMatrix[1][2] = 0
  transitionMatrix[2][0] = 0
  transitionMatrix[2][1] = 1
  transitionMatrix[2][2] = 0
  let poweredMatrix = powerMatrix(transitionMatrix, lengthValue - 2)
  return (poweredMatrix[0][0] * 3 + poweredMatrix[0][1] * 2 + poweredMatrix[0][2]) mod modulusValue

let wordLength = nextInt(inputData, scanPos)
appendOutput($countWords(int64(wordLength)))
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
