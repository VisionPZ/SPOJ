const flushBlockBytes = 1 shl 17
const firstLetterWeight = 64

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

proc nextToken(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  let tokenStart = pos
  while pos < data.len and data[pos] > ' ':
    pos += 1
  return data[tokenStart .. pos - 1]

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc bitUpdate(bitValues: var seq[int], bitWidth: int, matrixSize: int,
               rowIndex: int, columnIndex: int, deltaValue: int) =
  var rowCursor = rowIndex + 1
  while rowCursor <= matrixSize:
    var columnCursor = columnIndex + 1
    while columnCursor <= matrixSize:
      bitValues[rowCursor * bitWidth + columnCursor] += deltaValue
      columnCursor += columnCursor and (-columnCursor)
    rowCursor += rowCursor and (-rowCursor)

proc prefixSum(bitValues: seq[int], bitWidth: int, matrixSize: int,
               rowInclusive: int, columnInclusive: int): int =
  if rowInclusive < 0 or columnInclusive < 0:
    return 0
  result = 0
  var rowCursor = rowInclusive + 1
  while rowCursor > 0:
    var columnCursor = columnInclusive + 1
    while columnCursor > 0:
      result += bitValues[rowCursor * bitWidth + columnCursor]
      columnCursor -= columnCursor and (-columnCursor)
    rowCursor -= rowCursor and (-rowCursor)

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let matrixSize = nextInt(inputData, scanPos)
  let queryCount = nextInt(inputData, scanPos)
  let bitWidth = matrixSize + 1
  var grid = newSeq[int](matrixSize * matrixSize)
  var bitValues = newSeq[int](bitWidth * bitWidth)
  for row in 0 .. matrixSize - 1:
    let rowText = nextToken(inputData, scanPos)
    for column in 0 .. matrixSize - 1:
      let letterWeight = int(rowText[column]) - firstLetterWeight
      grid[row * matrixSize + column] = letterWeight
      bitUpdate(bitValues, bitWidth, matrixSize, row, column, letterWeight)
  for queryIndex in 0 .. queryCount - 1:
    let operationKind = nextInt(inputData, scanPos)
    if operationKind == 0:
      let selector = nextInt(inputData, scanPos)
      let targetIndex = nextInt(inputData, scanPos)
      let replacement = nextToken(inputData, scanPos)
      if selector == 0:
        for column in 0 .. matrixSize - 1:
          let cellIndex = targetIndex * matrixSize + column
          let letterWeight = int(replacement[column]) - firstLetterWeight
          let deltaValue = letterWeight - grid[cellIndex]
          if deltaValue != 0:
            grid[cellIndex] = letterWeight
            bitUpdate(bitValues, bitWidth, matrixSize, targetIndex, column, deltaValue)
      else:
        for row in 0 .. matrixSize - 1:
          let cellIndex = row * matrixSize + targetIndex
          let letterWeight = int(replacement[row]) - firstLetterWeight
          let deltaValue = letterWeight - grid[cellIndex]
          if deltaValue != 0:
            grid[cellIndex] = letterWeight
            bitUpdate(bitValues, bitWidth, matrixSize, row, targetIndex, deltaValue)
    else:
      let topRow = nextInt(inputData, scanPos)
      let leftColumn = nextInt(inputData, scanPos)
      let bottomRow = nextInt(inputData, scanPos)
      let rightColumn = nextInt(inputData, scanPos)
      let regionTotal =
        prefixSum(bitValues, bitWidth, matrixSize, bottomRow, rightColumn) -
        prefixSum(bitValues, bitWidth, matrixSize, topRow - 1, rightColumn) -
        prefixSum(bitValues, bitWidth, matrixSize, bottomRow, leftColumn - 1) +
        prefixSum(bitValues, bitWidth, matrixSize, topRow - 1, leftColumn - 1)
      appendOutput($regionTotal)
      outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
