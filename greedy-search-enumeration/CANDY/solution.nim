const flushBlockBytes = 1 shl 17
const firstDigitValue = 48
const endMarker = -1

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and data[pos] != '-' and (data[pos] < '0' or data[pos] > '9'):
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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while true:
  let packetCount = nextInt(inputData, scanPos)
  if packetCount == endMarker:
    break
  var candyCounts = newSeq[int](packetCount)
  var candyTotal: int64 = 0
  for packetIndex in 0 .. packetCount - 1:
    candyCounts[packetIndex] = nextInt(inputData, scanPos)
    candyTotal = candyTotal + int64(candyCounts[packetIndex])
  if candyTotal mod int64(packetCount) != 0:
    appendOutput("-1")
  else:
    let targetCount = candyTotal div int64(packetCount)
    var moveCount: int64 = 0
    for packetIndex in 0 .. packetCount - 1:
      if int64(candyCounts[packetIndex]) > targetCount:
        moveCount = moveCount + int64(candyCounts[packetIndex]) - targetCount
    appendOutput($moveCount)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
