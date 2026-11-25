const flushBlockBytes = 1 shl 17
const firstDigitValue = 48
const stateMultiplier = 31
const stateAddend = 78901
const stateModulus = 699037
const otherMultiplier = 64
const otherAddend = 23456
const otherModulus = 2097151
const dayModulus = 100

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-':
    pos += 1
  var signValue = 1
  if pos < data.len and data[pos] == '-':
    signValue = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return signValue * value

proc positiveModulo(dividend: int64, divisor: int64): int64 =
  let remainderValue = dividend mod divisor
  if remainderValue < 0:
    return remainderValue + divisor
  return remainderValue

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let blockCount = nextInt(inputData, scanPos)
for blockIndex in 0 ..< blockCount:
  let initialState = nextInt(inputData, scanPos)
  let initialOther = nextInt(inputData, scanPos)
  let dayCount = nextInt(inputData, scanPos)
  let allowedSum = int64(nextInt(inputData, scanPos))
  var stateValue = int64(initialState)
  var otherValue = int64(initialOther)
  var predictions = newSeq[int](dayCount)
  var leftDay = 0
  var windowTotal: int64 = 0
  var shortestViolation = dayCount + 1
  for rightDay in 0 ..< dayCount:
    stateValue = positiveModulo(stateAddend + stateMultiplier * stateValue, stateModulus)
    otherValue = positiveModulo(otherAddend + otherMultiplier * otherValue, otherModulus)
    let rainfall = int((stateValue mod dayModulus + 1) * (otherValue mod dayModulus + 1))
    predictions[rightDay] = rainfall
    windowTotal = windowTotal + int64(rainfall)
    while windowTotal > allowedSum:
      let violationLength = rightDay - leftDay + 1
      if violationLength < shortestViolation:
        shortestViolation = violationLength
      windowTotal = windowTotal - int64(predictions[leftDay])
      leftDay += 1
  var safeDays = dayCount
  if shortestViolation <= dayCount:
    safeDays = shortestViolation - 1
  appendOutput($safeDays)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
