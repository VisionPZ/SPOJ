const flushBlockBytes = 1 shl 17
const rootSearchHigh = 1000000

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc powerLimited(baseValue: int64, exponentCount: int, limitValue: int64): int64 =
  result = 1
  for exponentIndex in 1 .. exponentCount:
    result = result * baseValue
    if result > limitValue:
      return result

proc integerRoot(targetValue: int64, exponentCount: int): int64 =
  var lowValue: int64 = 1
  var highValue: int64 = rootSearchHigh
  while lowValue <= highValue:
    let middleValue = (lowValue + highValue) div 2
    if powerLimited(middleValue, exponentCount, targetValue) <= targetValue:
      lowValue = middleValue + 1
    else:
      highValue = middleValue - 1
  return highValue

proc fairnessPrefix(limitValue: int64): int64 =
  if limitValue < 2:
    return 0
  result = 0
  let squareRoot = integerRoot(limitValue, 2)
  result += squareRoot * (squareRoot - 1) div 2
  var baseValue = squareRoot + 1
  while baseValue <= limitValue:
    let quotient = limitValue div baseValue
    let lastBase = min(limitValue div quotient, limitValue)
    result += quotient * (lastBase - baseValue + 1)
    baseValue = lastBase + 1
  var exponentCount = 2
  while true:
    let maxBase = integerRoot(limitValue, exponentCount)
    if maxBase < 2:
      break
    let smallBase = integerRoot(limitValue, exponentCount + 1)
    if smallBase >= 2:
      result += smallBase * (smallBase - 1) div 2
    baseValue = smallBase + 1
    if baseValue < 2:
      baseValue = 2
    while baseValue <= maxBase:
      let powerValue = powerLimited(baseValue, exponentCount, limitValue)
      result += limitValue div powerValue
      baseValue += 1
    exponentCount += 1

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 1 .. caseCount:
  let rangeStart = int64(nextInt(inputData, scanPos))
  let rangeEnd = int64(nextInt(inputData, scanPos))
  let answer = fairnessPrefix(rangeEnd) - fairnessPrefix(rangeStart - 1)
  appendOutput($answer)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
