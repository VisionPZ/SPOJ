import math

const flushBlockBytes = 1 shl 17
const firstDigitValue = 48
const decimalPlaces = 1000
const doubled = 2

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let horizontalReach = nextInt(inputData, scanPos)
  let verticalReach = nextInt(inputData, scanPos)
  var squaredDifference = horizontalReach * horizontalReach - verticalReach * verticalReach
  if squaredDifference < 0:
    squaredDifference = 0
  let separation = float(doubled) * sqrt(float(squaredDifference))
  let scaledValue = int64(round(separation * float(decimalPlaces)))
  let wholePart = scaledValue div int64(decimalPlaces)
  let fractionPart = scaledValue mod int64(decimalPlaces)
  var fractionText = $fractionPart
  while fractionText.len < 3:
    fractionText = "0" & fractionText
  appendOutput($wholePart & "." & fractionText)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
