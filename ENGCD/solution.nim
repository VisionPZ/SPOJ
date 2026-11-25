const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int64 =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0'i64
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int64(int(data[pos]) - firstDigitValue)
    pos += 1
  return value

proc greatestCommonDivisor(firstValue, secondValue: int64): int64 =
  var leftValue = firstValue
  var rightValue = secondValue
  if leftValue < 0: leftValue = -leftValue
  if rightValue < 0: rightValue = -rightValue
  while rightValue != 0'i64:
    let remainder = leftValue mod rightValue
    leftValue = rightValue
    rightValue = remainder
  return leftValue

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let firstNumber = nextInt(inputData, scanPos)
let secondNumber = nextInt(inputData, scanPos)
appendOutput($(greatestCommonDivisor(firstNumber, secondNumber)))
outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
