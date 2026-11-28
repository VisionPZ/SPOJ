const firstDigitValue = 48
const flushBlockBytes = 1 shl 16

proc nextInt(inputData: string, scanPos: var int): int =
  while scanPos < inputData.len and (inputData[scanPos] < '0' or inputData[scanPos] > '9'):
    scanPos += 1
  var value = 0
  while scanPos < inputData.len and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    value = value * 10 + int(inputData[scanPos]) - firstDigitValue
    scanPos += 1
  return value

proc lastBallWinner(inputData: string, scanPos: var int): char =
  while scanPos < inputData.len and (inputData[scanPos] < 'A' or inputData[scanPos] > 'Z'):
    scanPos += 1
  var winnerLetter = inputData[scanPos]
  while scanPos < inputData.len and inputData[scanPos] >= 'A' and inputData[scanPos] <= 'Z':
    winnerLetter = inputData[scanPos]
    scanPos += 1
  return winnerLetter

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
let caseCount = nextInt(inputData, scanPos)
var outputBuffer = ""
for _ in 0 ..< caseCount:
  discard nextInt(inputData, scanPos)
  outputBuffer.add lastBallWinner(inputData, scanPos)
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
stdout.write outputBuffer
outputBuffer.setLen 0
