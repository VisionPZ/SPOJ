const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and data[pos] != '-' and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var negative = false
  if pos < data.len and data[pos] == '-':
    negative = true
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  if negative:
    return -value
  return value

proc magnitudeOf(value: int64): int64 =
  if value < 0:
    return -value
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let valueCount = nextInt(inputData, scanPos)
var sequenceValues = newSeq[int64](valueCount)
for valueIndex in 0 .. valueCount - 1:
  sequenceValues[valueIndex] = int64(nextInt(inputData, scanPos))
var bestLengths = newSeq[int](valueCount)
var bestLength = 1
for currentIndex in 0 .. valueCount - 1:
  bestLengths[currentIndex] = 1
  let currentValue = sequenceValues[currentIndex]
  let currentMagnitude = magnitudeOf(currentValue)
  var previousIndex = 0
  while previousIndex < currentIndex:
    let previousValue = sequenceValues[previousIndex]
    let oppositeSign = (previousValue > 0 and currentValue < 0) or (previousValue < 0 and currentValue > 0)
    if oppositeSign and magnitudeOf(previousValue) < currentMagnitude:
      if bestLengths[previousIndex] + 1 > bestLengths[currentIndex]:
        bestLengths[currentIndex] = bestLengths[previousIndex] + 1
    previousIndex += 1
  if bestLengths[currentIndex] > bestLength:
    bestLength = bestLengths[currentIndex]
appendOutput($bestLength)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
