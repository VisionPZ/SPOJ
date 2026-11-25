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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var deltaX: array[6, int] = [-1, -1, 0, 1, 1, 0]
var deltaY: array[6, int] = [1, 0, -1, -1, 0, 1]

while scanPos < inputData.len:
  let honeyNumber = nextInt(inputData, scanPos)
  if honeyNumber == 0:
    break
  if honeyNumber == 1:
    appendOutput("0 0")
    outputBuffer.add '\n'
    continue
  var ringIndex = 1
  while honeyNumber > 3 * ringIndex * (ringIndex + 1) + 1:
    ringIndex += 1
  let ringStart = 3 * ringIndex * (ringIndex - 1) + 2
  var stepsRemaining = honeyNumber - ringStart
  var coordX = ringIndex - 1
  var coordY = 1
  var segmentLength = ringIndex - 1
  for segmentIndex in 0 .. 5:
    var applied = segmentLength
    if applied > stepsRemaining:
      applied = stepsRemaining
    coordX += deltaX[segmentIndex] * applied
    coordY += deltaY[segmentIndex] * applied
    stepsRemaining -= applied
    segmentLength = ringIndex
  appendOutput($coordX)
  appendOutput(" ")
  appendOutput($coordY)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
