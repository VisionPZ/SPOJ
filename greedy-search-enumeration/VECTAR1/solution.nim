const flushBlockBytes = 1 shl 17
const answerModulus = 1000000007
const transformSize = 1024
const maxDimension = 1000

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

proc forwardTransform(values: var seq[int64]) =
  var blockSize = 1
  while blockSize < transformSize:
    var blockStart = 0
    while blockStart < transformSize:
      for offset in 0 .. blockSize - 1:
        let leftValue = values[blockStart + offset]
        let rightValue = values[blockStart + offset + blockSize]
        values[blockStart + offset] = leftValue + rightValue
        values[blockStart + offset + blockSize] = leftValue - rightValue
      blockStart += blockSize * 2
    blockSize *= 2

var factorials = newSeq[int64](maxDimension + 1)
factorials[0] = 1
for valueIndex in 1 .. maxDimension:
  factorials[valueIndex] = (factorials[valueIndex - 1] * int64(valueIndex)) mod int64(answerModulus)

let testCount = nextInt(inputData, scanPos)
for testIndex in 0 .. testCount - 1:
  let rowCount = nextInt(inputData, scanPos)
  let columnCount = nextInt(inputData, scanPos)
  var rowFlags = newSeq[int64](transformSize)
  var columnFlags = newSeq[int64](transformSize)
  for rowIndex in 1 .. rowCount:
    rowFlags[rowIndex] = 1
  for columnIndex in 1 .. columnCount:
    columnFlags[columnIndex] = 1
  forwardTransform(rowFlags)
  forwardTransform(columnFlags)
  for cellIndex in 0 .. transformSize - 1:
    rowFlags[cellIndex] = rowFlags[cellIndex] * columnFlags[cellIndex]
  forwardTransform(rowFlags)
  var resultValue: int64 = 1
  for cellIndex in 0 .. transformSize - 1:
    let frequency = int(rowFlags[cellIndex] div int64(transformSize))
    if frequency > 0:
      resultValue = (resultValue * factorials[frequency]) mod int64(answerModulus)
  appendOutput($resultValue)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
