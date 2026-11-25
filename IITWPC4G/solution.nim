const flushBlockBytes = 1 shl 17
const modulusValue: int64 = 1000000007

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  var negativeValue = false
  if pos < data.len and data[pos] == '-':
    negativeValue = true
    pos += 1
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  if negativeValue:
    return -value
  return value

proc reduceValue(value: int64): int64 =
  var reduced = value mod modulusValue
  if reduced < 0:
    reduced += modulusValue
  return reduced

proc multiplyMatrices(leftMatrix: seq[int64], rightMatrix: seq[int64], size: int): seq[int64] =
  var productMatrix = newSeq[int64](size * size)
  for rowIndex in 0 .. size - 1:
    for middleIndex in 0 .. size - 1:
      let leftValue = leftMatrix[rowIndex * size + middleIndex]
      if leftValue == 0:
        continue
      for columnIndex in 0 .. size - 1:
        let cellIndex = rowIndex * size + columnIndex
        productMatrix[cellIndex] = (productMatrix[cellIndex] +
          leftValue * rightMatrix[middleIndex * size + columnIndex]) mod modulusValue
  return productMatrix

proc applyMatrix(matrix: seq[int64], vector: seq[int64], size: int): seq[int64] =
  var resultVector = newSeq[int64](size)
  for rowIndex in 0 .. size - 1:
    var accumulated: int64 = 0
    for columnIndex in 0 .. size - 1:
      accumulated = (accumulated +
        matrix[rowIndex * size + columnIndex] * vector[columnIndex]) mod modulusValue
    resultVector[rowIndex] = accumulated
  return resultVector

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let sequenceLength = nextInt(inputData, scanPos)
  let windowLength = nextInt(inputData, scanPos)
  let operationCount = int64(nextInt(inputData, scanPos))
  var stateVector = newSeq[int64](sequenceLength)
  for elementIndex in 0 .. sequenceLength - 1:
    stateVector[elementIndex] = reduceValue(int64(nextInt(inputData, scanPos)))
  var transform = newSeq[int64](sequenceLength * sequenceLength)
  for rowIndex in 0 .. sequenceLength - 1:
    let sourceIndex = rowIndex xor 1
    for columnIndex in 0 .. sequenceLength - 1:
      let offset = (columnIndex - sourceIndex + sequenceLength) mod sequenceLength
      if offset < windowLength:
        if offset mod 2 == 0:
          transform[rowIndex * sequenceLength + columnIndex] = 1
        else:
          transform[rowIndex * sequenceLength + columnIndex] = modulusValue - 1
  var exponent = operationCount
  while exponent > 0:
    if exponent mod 2 == 1:
      stateVector = applyMatrix(transform, stateVector, sequenceLength)
    transform = multiplyMatrices(transform, transform, sequenceLength)
    exponent = exponent div 2
  for elementIndex in 0 .. sequenceLength - 1:
    if elementIndex > 0:
      appendOutput(" ")
    appendOutput($stateVector[elementIndex])
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
