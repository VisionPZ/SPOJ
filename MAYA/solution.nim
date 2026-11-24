const
  firstDigitValue = 48
  flushBlockBytes = 1 shl 18
  dotSymbol = '.'
  dashSymbol = '-'
  zeroSymbol = 'S'
  dashValue = 5

proc nextDigitCount(inputData: string, i: var int): int =
  let dataLength = inputData.len
  while i < dataLength and (inputData[i] < '0' or inputData[i] > '9'):
    inc i
  result = 0
  while i < dataLength and inputData[i] >= '0' and inputData[i] <= '9':
    result = result * 10 + (int(inputData[i]) - firstDigitValue)
    inc i

proc advanceToNextLine(inputData: string, i: var int) =
  let dataLength = inputData.len
  while i < dataLength and inputData[i] != '\n':
    inc i
  if i < dataLength:
    inc i

proc readSymbolValue(inputData: string, i: var int): int =
  let dataLength = inputData.len
  var dotCount = 0
  var dashCount = 0
  var shellFound = false
  while i < dataLength and inputData[i] != '\n':
    let currentSymbol = inputData[i]
    if currentSymbol == dotSymbol:
      inc dotCount
    elif currentSymbol == dashSymbol:
      inc dashCount
    elif currentSymbol == zeroSymbol:
      shellFound = true
    inc i
  if i < dataLength:
    inc i
  if shellFound:
    return 0
  result = dotCount + dashCount * dashValue

const placeValues = [1'i64, 20, 360, 7200, 144000, 2880000, 57600000]

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var i = 0
var outputBuffer = ""
while true:
  let digitCount = nextDigitCount(inputData, i)
  if digitCount == 0:
    break
  advanceToNextLine(inputData, i)
  var decimalValue = 0'i64
  var j = 0
  while j < digitCount:
    let symbolValue = readSymbolValue(inputData, i)
    decimalValue += int64(symbolValue) * placeValues[digitCount - 1 - j]
    inc j
  outputBuffer.add $decimalValue
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
if outputBuffer.len > 0:
  stdout.write outputBuffer
