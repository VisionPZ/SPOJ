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
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return value

proc nextDouble(data: string, pos: var int): float64 =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '.':
    pos += 1
  var wholePart = 0.0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    wholePart = wholePart * 10.0 + float64(int(data[pos]) - 48)
    pos += 1
  if pos < data.len and data[pos] == '.':
    pos += 1
    var fractionPart = 0.0
    var scale = 1.0
    while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
      fractionPart = fractionPart * 10.0 + float64(int(data[pos]) - 48)
      scale = scale * 10.0
      pos += 1
    return wholePart + fractionPart / scale
  return wholePart

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc formatFixed(value: float64): string =
  let scaledValue = int64(value * 1000000.0 + 0.5)
  let integerPart = scaledValue div 1000000
  let fractionPart = scaledValue mod 1000000
  var rendered = $integerPart
  rendered.add '.'
  var placeValue: int64 = 100000
  while placeValue >= 1:
    let digitValue = (fractionPart div placeValue) mod 10
    rendered.add chr(48 + int(digitValue))
    placeValue = placeValue div 10
  return rendered

proc advanceDistance(state: seq[float64], stayProbability, growProbability,
                     shrinkProbability: float64, extremumGain: var float64): seq[float64] =
  var nextState = newSeq[float64](state.len)
  for distance in 0 .. state.len - 2:
    let chance = state[distance]
    if chance == 0.0:
      continue
    nextState[distance] += chance * stayProbability
    nextState[distance + 1] += chance * growProbability
    if distance > 0:
      nextState[distance - 1] += chance * shrinkProbability
    else:
      nextState[distance] += chance * shrinkProbability
      extremumGain += chance * shrinkProbability
  return nextState

let moveCount = nextInt(inputData, scanPos)
let probabilityUp = nextDouble(inputData, scanPos)
let probabilityRight = nextDouble(inputData, scanPos)
let probabilityDown = nextDouble(inputData, scanPos)
let probabilityLeft = nextDouble(inputData, scanPos)

let stateCount = moveCount + 2
var belowMaxHorizontal = newSeq[float64](stateCount)
var aboveMinHorizontal = newSeq[float64](stateCount)
var belowMaxVertical = newSeq[float64](stateCount)
var aboveMinVertical = newSeq[float64](stateCount)
belowMaxHorizontal[0] = 1.0
aboveMinHorizontal[0] = 1.0
belowMaxVertical[0] = 1.0
aboveMinVertical[0] = 1.0
var horizontalMaxGain = 0.0
var horizontalMinGain = 0.0
var verticalMaxGain = 0.0
var verticalMinGain = 0.0

let horizontalStay = probabilityUp + probabilityDown
let verticalStay = probabilityRight + probabilityLeft

for stepIndex in 0 .. moveCount - 1:
  belowMaxHorizontal = advanceDistance(belowMaxHorizontal, horizontalStay,
    probabilityLeft, probabilityRight, horizontalMaxGain)
  aboveMinHorizontal = advanceDistance(aboveMinHorizontal, horizontalStay,
    probabilityRight, probabilityLeft, horizontalMinGain)
  belowMaxVertical = advanceDistance(belowMaxVertical, verticalStay,
    probabilityDown, probabilityUp, verticalMaxGain)
  aboveMinVertical = advanceDistance(aboveMinVertical, verticalStay,
    probabilityUp, probabilityDown, verticalMinGain)

let expectedPoints = horizontalMaxGain + horizontalMinGain + verticalMaxGain + verticalMinGain
appendOutput(formatFixed(expectedPoints))
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
