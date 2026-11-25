const flushBlockBytes = 1 shl 17
const coefficientDenominators = [1, 4, 5, 6]
const coefficientValues = [4.0, -2.0, -1.0, -1.0]
const tailTerms = 30

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
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return value

proc powerMod(baseValue: int64, exponentValue: int, modulusValue: int64): int64 =
  if modulusValue == 1:
    return 0
  var result: int64 = 1
  var factor = baseValue mod modulusValue
  var remaining = exponentValue
  while remaining > 0:
    if (remaining and 1) == 1:
      result = result * factor mod modulusValue
    factor = factor * factor mod modulusValue
    remaining = remaining shr 1
  return result

proc piHexDigit(position: int): char =
  if position == 0:
    return '3'
  let exponentValue = position - 1
  var coefficientSums: array[4, float64]
  for step in 0 .. exponentValue:
    let remainingPower = exponentValue - step
    for slot in 0 .. 3:
      let modulusValue = int64(8 * step + coefficientDenominators[slot])
      let modularValue = powerMod(16, remainingPower, modulusValue)
      coefficientSums[slot] = coefficientSums[slot] + coefficientValues[slot] * float64(modularValue) / float64(modulusValue)
  var tailFactor = 1.0 / 16.0
  for tailStep in exponentValue + 1 .. exponentValue + tailTerms:
    for slot in 0 .. 3:
      let denominatorValue = float64(8 * tailStep + coefficientDenominators[slot])
      coefficientSums[slot] = coefficientSums[slot] + coefficientValues[slot] * tailFactor / denominatorValue
    tailFactor = tailFactor / 16.0
  var fractionalPart = 0.0
  for slot in 0 .. 3:
    fractionalPart = fractionalPart + coefficientSums[slot]
  while fractionalPart < 0.0:
    fractionalPart = fractionalPart + 1.0
  while fractionalPart >= 1.0:
    fractionalPart = fractionalPart - 1.0
  var digitValue = int(fractionalPart * 16.0)
  if digitValue > 15:
    digitValue = 15
  if digitValue < 10:
    return char(ord('0') + digitValue)
  return char(ord('A') + digitValue - 10)

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let testCaseCount = nextInt(inputData, scanPos)
for testCase in 0 .. testCaseCount - 1:
  let requestedPosition = nextInt(inputData, scanPos)
  appendOutput($piHexDigit(requestedPosition))
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
