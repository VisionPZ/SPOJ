const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-':
    pos += 1
  var sign = 1
  if pos < data.len and data[pos] == '-':
    sign = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return sign * value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let rowCount = nextInt(inputData, scanPos)
var leftColumn = newSeq[int](rowCount)
var middleColumn = newSeq[int](rowCount)
var rightColumn = newSeq[int](rowCount)
for rowIndex in 0 .. rowCount - 1:
  leftColumn[rowIndex] = nextInt(inputData, scanPos)
  middleColumn[rowIndex] = nextInt(inputData, scanPos)
  rightColumn[rowIndex] = nextInt(inputData, scanPos)
var skipNext: int64 = 0
var takeNext: int64 = 0
var stepRow = rowCount - 2
while stepRow >= 0:
  var leftPair = int64(leftColumn[stepRow]) + int64(middleColumn[stepRow]) + int64(leftColumn[stepRow + 1]) + int64(middleColumn[stepRow + 1])
  var rightPair = int64(middleColumn[stepRow]) + int64(rightColumn[stepRow]) + int64(middleColumn[stepRow + 1]) + int64(rightColumn[stepRow + 1])
  if rightPair > leftPair:
    leftPair = rightPair
  var withStep = leftPair + skipNext
  if withStep < takeNext:
    withStep = takeNext
  skipNext = takeNext
  takeNext = withStep
  stepRow -= 1
appendOutput($takeNext)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
