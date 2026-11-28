const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextLineBounds(data: string, pos: var int): tuple[first, last: int] =
  var lineStart = pos
  while lineStart < data.len and (data[lineStart] == '\n' or data[lineStart] == '\r'):
    inc lineStart
  var lineEnd = lineStart
  while lineEnd < data.len and data[lineEnd] != '\n' and data[lineEnd] != '\r':
    inc lineEnd
  pos = lineEnd
  while pos < data.len and (data[pos] == '\n' or data[pos] == '\r'):
    inc pos
  result = (lineStart, lineEnd)

proc nextNumberInLine(data: string, pos: var int, lineEnd: int): int =
  var value = 0
  while pos < lineEnd and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    inc pos
  return value

proc gcdValues(leftValue: int, rightValue: int): int =
  var leftSide = leftValue
  var rightSide = rightValue
  while rightSide != 0:
    let remainder = leftSide mod rightSide
    leftSide = rightSide
    rightSide = remainder
  return leftSide

var outputBuffer = ""

proc flushIfReady() =
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc appendOutput(text: string) =
  outputBuffer.add text
  flushIfReady()

while scanPos < inputData.len:
  let lineBounds = nextLineBounds(inputData, scanPos)
  let lineStart = lineBounds.first
  let lineEnd = lineBounds.last
  if lineStart == lineEnd:
    continue
  var onlyZero = true
  for position in lineStart..<lineEnd:
    if inputData[position] > ' ' and inputData[position] != '0':
      onlyZero = false
      break
  if onlyZero:
    break
  var valueCursor = lineStart
  var haveValue = false
  var gcdValue = 0
  while valueCursor < lineEnd:
    while valueCursor < lineEnd and (inputData[valueCursor] < '0' or
                                     inputData[valueCursor] > '9'):
      inc valueCursor
    if valueCursor >= lineEnd:
      break
    let currentValue = nextNumberInLine(inputData, valueCursor, lineEnd)
    if not haveValue:
      gcdValue = currentValue
      haveValue = true
    else:
      gcdValue = gcdValues(gcdValue, currentValue)
  if haveValue:
    appendOutput($(gcdValue))
    appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0
