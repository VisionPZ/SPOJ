const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

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

let orangeCount = int(nextInteger(inputData, scanPos))
let largestFittingSize = nextInteger(inputData, scanPos)
let wasteCapacity = nextInteger(inputData, scanPos)
var emptyCount = 0'i64
var wasteSum = 0'i64
for orangeIndex in 0 ..< orangeCount:
  let orangeSize = nextInteger(inputData, scanPos)
  if orangeSize > largestFittingSize:
    continue
  wasteSum += orangeSize
  if wasteSum > wasteCapacity:
    emptyCount += 1
    wasteSum = 0
if wasteSum > 0'i64:
  emptyCount += 1

appendOutput($emptyCount)
outputBuffer.add '\n'
stdout.write outputBuffer
