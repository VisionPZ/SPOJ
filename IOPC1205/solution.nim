import math

const flushBlockBytes = 1 shl 17
const harmonicTableLimit = 100000

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

var harmonicTable = newSeq[float](harmonicTableLimit + 1)
for indexValue in 1 .. harmonicTableLimit:
  harmonicTable[indexValue] = harmonicTable[indexValue - 1] + 1.0 / float(indexValue)

proc harmonicSum(value: int64): float =
  if value <= int64(harmonicTableLimit):
    return harmonicTable[int(value)]
  let largeValue = float(value)
  let tableValue = float(harmonicTableLimit)
  let correction = 1.0 / (2.0 * largeValue) - 1.0 / (2.0 * tableValue) -
    1.0 / (12.0 * largeValue * largeValue) + 1.0 / (12.0 * tableValue * tableValue)
  return harmonicTable[harmonicTableLimit] + ln(largeValue) - ln(tableValue) + correction

proc smallGapDays(prisonerCount: int64, magicianCount: int64, outsiderCount: int64): float =
  let rowLength = int(outsiderCount) + 1
  var offState = newSeq[float](int(magicianCount + 1) * rowLength)
  var onState = newSeq[float](int(magicianCount + 1) * rowLength)
  for magicians in 1 .. magicianCount:
    offState[int(magicians) * rowLength] = harmonicSum(magicians)
    onState[int(magicians) * rowLength] = offState[int(magicians) * rowLength]
  onState[0] = 1.0 / float(magicianCount)
  for outsiders in 1 .. outsiderCount:
    offState[int(outsiders)] = 1.0 / float(outsiders) + onState[int(outsiders - 1)]
    onState[int(outsiders)] = 1.0 / float(magicianCount) + offState[int(outsiders)]
  for magicians in 1 .. magicianCount:
    for outsiders in 1 .. outsiderCount:
      let stateIndex = int(magicians) * rowLength + int(outsiders)
      let previousIndex = int(magicians - 1) * rowLength + int(outsiders)
      offState[stateIndex] = (1.0 + float(magicians) * offState[previousIndex] +
        float(outsiders) * onState[stateIndex - 1]) /
        float(magicians + outsiders)
      onState[stateIndex] = (1.0 + float(magicians) * offState[previousIndex] +
        float(magicianCount - magicians) * offState[stateIndex]) /
        float(magicianCount)
  return float(prisonerCount) * offState[int(magicianCount) * rowLength + int(outsiderCount)]

proc expectedDays(prisonerCount: int64, magicianCount: int64): float =
  let outsiderCount = prisonerCount - magicianCount
  if outsiderCount == 0:
    return float(prisonerCount) * harmonicSum(magicianCount)
  if outsiderCount <= magicianCount:
    return smallGapDays(prisonerCount, magicianCount, outsiderCount)
  var correction = 0.0
  var combination: float = 1.0
  var previousFactorial: float = 1.0
  for signalIndex in 1 .. magicianCount - 1:
    combination = combination * float(magicianCount - signalIndex + 1) /
      float(signalIndex)
    let ratio = float(magicianCount - signalIndex) / float(magicianCount)
    var term = combination * previousFactorial * pow(ratio, float(outsiderCount))
    var divisor = 1.0
    for offset in 1 .. signalIndex:
      divisor = divisor * float(outsiderCount + offset)
    term = term / divisor
    if (signalIndex mod 2) == 1:
      correction += term
    else:
      correction -= term
    previousFactorial = previousFactorial * float(signalIndex)
  let baseSum = harmonicSum(outsiderCount) + float(outsiderCount) /
    float(magicianCount)
  return float(prisonerCount) * (baseSum + correction)

proc appendScientific(value: float) =
  var exponentValue = int(floor(ln(value) / ln(10.0)))
  var mantissa = value / pow(10.0, float(exponentValue))
  if mantissa >= 10.0:
    mantissa = mantissa / 10.0
    exponentValue += 1
  let scaledValue = int64(mantissa * 1000000.0 + 0.5)
  let wholePart = scaledValue div 1000000
  let fractionPart = scaledValue mod 1000000
  appendOutput($(wholePart))
  outputBuffer.add '.'
  if fractionPart < 10:
    outputBuffer.add '0'
  if fractionPart < 100:
    outputBuffer.add '0'
  if fractionPart < 1000:
    outputBuffer.add '0'
  if fractionPart < 10000:
    outputBuffer.add '0'
  if fractionPart < 100000:
    outputBuffer.add '0'
  appendOutput($(fractionPart))
  outputBuffer.add 'E'
  outputBuffer.add '+'
  if exponentValue < 10:
    outputBuffer.add '0'
  appendOutput($(exponentValue))
  outputBuffer.add '\n'

let testCount = nextInt(inputData, scanPos)
for testIndex in 0 .. testCount - 1:
  let prisonerCount = int64(nextInt(inputData, scanPos))
  let magicianCount = int64(nextInt(inputData, scanPos))
  appendScientific(expectedDays(prisonerCount, magicianCount))

stdout.write outputBuffer
outputBuffer.setLen 0
