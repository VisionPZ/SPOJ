const flushBlockBytes = 1 shl 17
const firstDigitValue = 48

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

let dosaCount = nextInt(inputData, scanPos)
var keptValues = newSeq[int64](0)
for positionIndex in 0 .. dosaCount - 1:
  let priceValue = int64(nextInt(inputData, scanPos))
  let adjustedPrice = priceValue - int64(positionIndex + 1)
  if adjustedPrice < 0:
    continue
  var lowerIndex = 0
  var upperIndex = keptValues.len
  while lowerIndex < upperIndex:
    let middleIndex = (lowerIndex + upperIndex) div 2
    if keptValues[middleIndex] > adjustedPrice:
      upperIndex = middleIndex
    else:
      lowerIndex = middleIndex + 1
  if lowerIndex == keptValues.len:
    keptValues.add adjustedPrice
  else:
    keptValues[lowerIndex] = adjustedPrice

let replacementCount = dosaCount - keptValues.len
appendOutput($replacementCount)
appendOutput("\n")
stdout.write outputBuffer
outputBuffer.setLen 0
