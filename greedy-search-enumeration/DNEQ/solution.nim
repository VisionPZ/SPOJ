const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

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

proc parseScaledDecimal(data: string, pos: var int, divisorValue: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var wholePart = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    wholePart = wholePart * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  var fractionPart = 0
  divisorValue = 1
  if pos < data.len and data[pos] == '.':
    pos += 1
    while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
      fractionPart = fractionPart * 10 + int(data[pos]) - firstDigitValue
      divisorValue = divisorValue * 10
      pos += 1
  return wholePart * divisorValue + fractionPart

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let menCount = nextInt(inputData, scanPos)
  var increaseDivisor = 1
  let increaseScaled = parseScaledDecimal(inputData, scanPos, increaseDivisor)
  let replacedWeight = nextInt(inputData, scanPos)
  let totalIncrease = int64(menCount) * int64(increaseScaled) div int64(increaseDivisor)
  let newWeight = totalIncrease + int64(replacedWeight)
  appendOutput($newWeight)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
