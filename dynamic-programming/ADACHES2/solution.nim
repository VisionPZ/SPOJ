const flushBlockBytes = 1 shl 17
const answerModulus = 1000000007

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

let testCount = nextInt(inputData, scanPos)
var requestedSizes = newSeq[int](testCount)
var largestSize = 0
for caseIndex in 0 .. testCount - 1:
  let boardSize = nextInt(inputData, scanPos)
  requestedSizes[caseIndex] = boardSize
  if boardSize > largestSize:
    largestSize = boardSize

var answerBySize = newSeq[int32](largestSize + 1)
if largestSize >= 1:
  answerBySize[1] = 1
if largestSize >= 4:
  answerBySize[4] = 2
  var previousOne: int64 = 2
  var previousTwo: int64 = 0
  var previousThree: int64 = 0
  var previousFour: int64 = 1
  for boardSize in 5 .. largestSize:
    var nextValue = int64(boardSize + 1) * previousOne - int64(boardSize - 2) * previousTwo - int64(boardSize - 5) * previousThree + int64(boardSize - 3) * previousFour
    nextValue = nextValue mod int64(answerModulus)
    if nextValue < 0:
      nextValue += int64(answerModulus)
    answerBySize[boardSize] = int32(nextValue)
    previousFour = previousThree
    previousThree = previousTwo
    previousTwo = previousOne
    previousOne = nextValue

for caseIndex in 0 .. testCount - 1:
  appendOutput($answerBySize[requestedSizes[caseIndex]])
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
