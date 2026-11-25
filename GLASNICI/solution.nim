import strutils

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

proc nextReal(data: string, pos: var int): float64 =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '.':
    pos += 1
  var whole = 0.0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    whole = whole * 10.0 + float64(int(data[pos]) - 48)
    pos += 1
  if pos < data.len and data[pos] == '.':
    pos += 1
    var fraction = 0.0
    var scale = 10.0
    while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
      fraction = fraction + float64(int(data[pos]) - 48) / scale
      scale = scale * 10.0
      pos += 1
    whole = whole + fraction
  return whole

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let hearingRange = nextReal(inputData, scanPos)
  let messengerCount = nextInt(inputData, scanPos)
  var positions = newSeq[float64](messengerCount)
  for messengerIndex in 0 .. messengerCount - 1:
    positions[messengerIndex] = nextReal(inputData, scanPos)
  var minimumTime = 0.0
  var smallestPast = positions[0]
  for messengerIndex in 1 .. messengerCount - 1:
    let shiftedPosition = positions[messengerIndex] - float64(messengerIndex) * hearingRange
    let reachNeeded = shiftedPosition - smallestPast
    if reachNeeded > 0.0 and reachNeeded / 2.0 > minimumTime:
      minimumTime = reachNeeded / 2.0
    if shiftedPosition < smallestPast:
      smallestPast = shiftedPosition
  appendOutput(formatFloat(minimumTime + 1e-9, ffDecimal, 3))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
