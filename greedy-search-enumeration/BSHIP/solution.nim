const flushBlockBytes = 1 shl 17
const decimalPlaces = 1000000

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

let rowCount = nextInt(inputData, scanPos)
let columnCount = nextInt(inputData, scanPos)
let squareSize = nextInt(inputData, scanPos)
let lastRowStart = rowCount - squareSize
let lastColumnStart = columnCount - squareSize
while scanPos < inputData.len and inputData[scanPos] <= ' ':
  scanPos += 1

var shipTotal: int64 = 0
for rowIndex in 0 .. rowCount - 1:
  let firstCoveringRow = max(0, rowIndex - squareSize + 1)
  let lastCoveringRow = min(rowIndex, lastRowStart)
  let rowCoverage = int64(lastCoveringRow - firstCoveringRow + 1)
  for columnIndex in 0 .. columnCount - 1:
    let cellChar = inputData[scanPos]
    scanPos += 1
    if cellChar == 'X':
      let firstCoveringColumn = max(0, columnIndex - squareSize + 1)
      let lastCoveringColumn = min(columnIndex, lastColumnStart)
      let columnCoverage = int64(lastCoveringColumn - firstCoveringColumn + 1)
      shipTotal = shipTotal + rowCoverage * columnCoverage
  while scanPos < inputData.len and inputData[scanPos] <= ' ':
    scanPos += 1

let squareCount = int64(rowCount - squareSize + 1) * int64(columnCount - squareSize + 1)
var wholePart = shipTotal div squareCount
let remainder = shipTotal mod squareCount
var fractionalPart = (2 * remainder * int64(decimalPlaces) + squareCount) div (2 * squareCount)
if fractionalPart >= int64(decimalPlaces):
  fractionalPart = 0
  wholePart += 1

appendOutput($wholePart)
appendOutput(".")
var digitDivisor = decimalPlaces div 10
while digitDivisor > 0:
  appendOutput($(fractionalPart div int64(digitDivisor) mod 10))
  digitDivisor = digitDivisor div 10
appendOutput("\n")
stdout.write outputBuffer
outputBuffer.setLen 0
