const
  firstDigitValue = 48
  flushBlockBytes = 1 shl 18
  dotSymbol = '.'
  dashSymbol = '-'
  zeroSymbol = 'S'
  dashValue = 5

proc nextDigitCount(inputData: string, scanPos: var int): int =
  let dataLength = inputData.len
  while scanPos < dataLength and (inputData[scanPos] < '0' or inputData[scanPos] > '9'):
    inc scanPos
  result = 0
  while scanPos < dataLength and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    result = result * 10 + (int(inputData[scanPos]) - firstDigitValue)
    inc scanPos

proc advanceToNextLine(inputData: string, scanPos: var int) =
  let dataLength = inputData.len
  while scanPos < dataLength and inputData[scanPos] != '\n':
    inc scanPos
  if scanPos < dataLength:
    inc scanPos

proc readSymbolValue(inputData: string, scanPos: var int): int =
  let dataLength = inputData.len
  var dotCount = 0
  var dashCount = 0
  var shellFound = false
  while scanPos < dataLength and inputData[scanPos] != '\n':
    let currentSymbol = inputData[scanPos]
    if currentSymbol == dotSymbol:
      inc dotCount
    elif currentSymbol == dashSymbol:
      inc dashCount
    elif currentSymbol == zeroSymbol:
      shellFound = true
    inc scanPos
  if scanPos < dataLength:
    inc scanPos
  if shellFound:
    return 0
  result = dotCount + dashCount * dashValue

const placeValues = [1'i64, 20, 360, 7200, 144000, 2880000, 57600000]

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
var outputBuffer = ""
while true:
  let digitCount = nextDigitCount(inputData, scanPos)
  if digitCount == 0:
    break
  advanceToNextLine(inputData, scanPos)
  var decimalValue = 0'i64
  var digitIndex = 0
  while digitIndex < digitCount:
    let symbolValue = readSymbolValue(inputData, scanPos)
    decimalValue += int64(symbolValue) * placeValues[digitCount - 1 - digitIndex]
    inc digitIndex
  outputBuffer.add $decimalValue
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
if outputBuffer.len > 0:
  stdout.write outputBuffer
