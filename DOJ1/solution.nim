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
