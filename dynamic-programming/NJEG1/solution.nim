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

proc nextToken(inputData: string, scanPos: var int): string =
  while scanPos < inputData.len and inputData[scanPos] <= ' ':
    scanPos += 1
  let tokenStart = scanPos
  while scanPos < inputData.len and inputData[scanPos] > ' ':
    scanPos += 1
  if tokenStart == scanPos:
    return ""
  return inputData[tokenStart .. scanPos - 1]

proc skipToken(inputData: string, scanPos: var int) =
  while scanPos < inputData.len and inputData[scanPos] <= ' ':
    scanPos += 1
  while scanPos < inputData.len and inputData[scanPos] > ' ':
    scanPos += 1

proc cardValue(cardToken: string): int =
  if cardToken.len == 1:
    if cardToken[0] == 'A':
      return 4
    if cardToken[0] == 'J':
      return 1
    if cardToken[0] == 'Q':
      return 2
    if cardToken[0] == 'K':
      return 3
    return int(cardToken[0]) - firstDigitValue
  return 10

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

let caseCount = int(nextInteger(inputData, scanPos))
for caseIndex in 0 ..< caseCount:
  var predictionToken = ""
  for tokenIndex in 0 .. 6:
    predictionToken = nextToken(inputData, scanPos)
  appendOutput($(cardValue(predictionToken)))
  outputBuffer.add '\n'
  for skippedIndex in 0 ..< 22:
    skipToken(inputData, scanPos)

stdout.write outputBuffer
