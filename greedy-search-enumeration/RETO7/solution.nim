const firstDigitValue = 48
const flushBlockBytes = 1 shl 17
const searchUpperBound = 1000000000'i64

proc nextInteger(inputData: string, scanPos: var int): int64 =
  while scanPos < inputData.len and inputData[scanPos] != '-' and
        (inputData[scanPos] < '0' or inputData[scanPos] > '9'):
    scanPos += 1
  var signValue = 1'i64
  if scanPos < inputData.len and inputData[scanPos] == '-':
    signValue = -1'i64
    scanPos += 1
  var parsedValue = 0'i64
  while scanPos < inputData.len and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    parsedValue = parsedValue * 10 + int64(int(inputData[scanPos]) - firstDigitValue)
    scanPos += 1
  return signValue * parsedValue

proc hasMorePairs(inputData: string, scanPos: var int): bool =
  while scanPos < inputData.len and inputData[scanPos] <= ' ':
    scanPos += 1
  return scanPos < inputData.len

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while hasMorePairs(inputData, scanPos):
  let initialGroupSize = nextInteger(inputData, scanPos)
  let requestedDay = nextInteger(inputData, scanPos)
  var lowerGroupCount = 0'i64
  var upperGroupCount = searchUpperBound
  while lowerGroupCount < upperGroupCount:
    let middleGroupCount = (lowerGroupCount + upperGroupCount + 1'i64) div 2'i64
    let elapsedDays = middleGroupCount * (2'i64 * initialGroupSize + middleGroupCount - 1'i64) div 2'i64
    if elapsedDays < requestedDay:
      lowerGroupCount = middleGroupCount
    else:
      upperGroupCount = middleGroupCount - 1'i64
  appendOutput($(initialGroupSize + lowerGroupCount))
  outputBuffer.add '\n'

stdout.write outputBuffer
