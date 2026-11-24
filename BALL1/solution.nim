const zeroDigitValue = 48
const flushBlockBytes = 1 shl 18

var inputData = ""
var lineBuffer = ""
while readLine(stdin, lineBuffer):
  inputData.add lineBuffer
  inputData.add '\n'

var i = 0

proc nextInteger(sourceData: string, i: var int): int64 =
  while i < sourceData.len and sourceData[i] < '0':
    i += 1
  var parsedValue: int64 = 0
  while i < sourceData.len and sourceData[i] >= '0':
    parsedValue = parsedValue * 10 + int64(int(sourceData[i]) - zeroDigitValue)
    i += 1
  return parsedValue

proc greatestCommonDivisor(firstValue: int64, secondValue: int64): int64 =
  var leftValue = firstValue
  var rightValue = secondValue
  while rightValue != 0:
    let remainder = leftValue mod rightValue
    leftValue = rightValue
    rightValue = remainder
  return leftValue

var outputBuffer = ""

let dataSetCount = nextInteger(inputData, i)
var j: int64 = 0
while j < dataSetCount:
  var boardWidth = nextInteger(inputData, i) - 1
  var boardHeight = nextInteger(inputData, i) - 1
  var startColumn = nextInteger(inputData, i) - 1
  var startRow = nextInteger(inputData, i) - 1
  if startRow != 0 and startRow != boardHeight:
    swap(boardWidth, boardHeight)
    swap(startColumn, startRow)
  let commonDivisor = greatestCommonDivisor(boardWidth, boardHeight)
  var oddFieldCount: int64
  if startColumn mod commonDivisor == 0:
    oddFieldCount = 2
  else:
    let widthSegments = boardWidth div commonDivisor
    let heightSegments = boardHeight div commonDivisor
    oddFieldCount = 2 * boardWidth * boardHeight div commonDivisor -
                    4 * widthSegments * heightSegments +
                    2 * widthSegments + 2 * heightSegments
  outputBuffer.add $oddFieldCount
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
  j += 1

if outputBuffer.len > 0:
  stdout.write outputBuffer
