const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextSignedInt64(data: string, position: var int, found: var bool): int64 =
  while position < data.len and data[position] != '-' and (data[position] < '0' or data[position] > '9'):
    position += 1
  if position >= data.len:
    found = false
    return 0
  var signValue = 1
  if data[position] == '-':
    signValue = -1
    position += 1
  var value: int64 = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int64(ord(data[position]) - firstDigitValue)
    position += 1
  found = true
  if signValue < 0:
    return -value
  return value

proc absoluteValue(value: int64): int64 =
  if value < 0:
    return -value
  return value

proc gcdPositive(firstValue, secondValue: int64): int64 =
  var currentValue = absoluteValue(firstValue)
  var nextValue = absoluteValue(secondValue)
  while nextValue != 0:
    let remainderValue = currentValue mod nextValue
    currentValue = nextValue
    nextValue = remainderValue
  return currentValue

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var tokenFound = false
let caseCount = nextSignedInt64(inputData, scanPos, tokenFound)
for caseIndex in 0 ..< caseCount:
  let numeratorValue = nextSignedInt64(inputData, scanPos, tokenFound)
  let denominatorValue = nextSignedInt64(inputData, scanPos, tokenFound)
  if denominatorValue == 0:
    appendOutput("the denominator can not be zero\n")
  else:
    let divisorValue = gcdPositive(numeratorValue, denominatorValue)
    var reducedNumerator = numeratorValue div divisorValue
    var reducedDenominator = denominatorValue div divisorValue
    if reducedDenominator < 0:
      reducedNumerator = -reducedNumerator
      reducedDenominator = -reducedDenominator
    if reducedDenominator == 1:
      appendOutput($reducedNumerator & "\n")
    else:
      appendOutput($reducedNumerator & " " & $reducedDenominator & "\n")

stdout.write outputBuffer
outputBuffer.setLen 0
