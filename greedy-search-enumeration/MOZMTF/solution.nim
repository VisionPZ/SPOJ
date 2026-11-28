const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + ord(data[position]) - firstDigitValue
    position += 1
  return value

proc nextToken(data: string, position: var int): string =
  while position < data.len and data[position] <= ' ':
    position += 1
  var tokenEnd = position
  while tokenEnd < data.len and data[tokenEnd] > ' ':
    tokenEnd += 1
  var tokenText = ""
  while position < tokenEnd:
    tokenText.add data[position]
    position += 1
  return tokenText

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while scanPos < inputData.len:
  let writtenNumber = nextToken(inputData, scanPos)
  if writtenNumber.len == 0:
    break
  let targetDigitSum = nextInt(inputData, scanPos)
  var digitSum = 0
  for digitIndex in 0..<writtenNumber.len:
    digitSum += ord(writtenNumber[digitIndex]) - firstDigitValue
  let missingDigitValue = targetDigitSum - digitSum
  var insertPos = writtenNumber.len
  for digitIndex in 0..<writtenNumber.len:
    if ord(writtenNumber[digitIndex]) - firstDigitValue < missingDigitValue:
      insertPos = digitIndex
      break
  var restoredNumber = ""
  for digitIndex in 0..<insertPos:
    restoredNumber.add writtenNumber[digitIndex]
  restoredNumber.add chr(firstDigitValue + missingDigitValue)
  for digitIndex in insertPos..<writtenNumber.len:
    restoredNumber.add writtenNumber[digitIndex]
  appendOutput(restoredNumber)
  appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0
