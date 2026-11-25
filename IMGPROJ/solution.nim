import algorithm

const flushBlockBytes = 1 shl 17

type DiagonalEvent = object
  position: int64
  delta: int64

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

proc emitRun(length: int64, value: int64, pendingLength: var int64,
             pendingValue: var int64, havePending: var bool, firstPair: var bool) =
  if length <= 0:
    return
  if havePending and value == pendingValue:
    pendingLength += length
    return
  if havePending:
    if not firstPair:
      appendOutput(" ")
    appendOutput($pendingLength)
    appendOutput(" ")
    appendOutput($pendingValue)
    firstPair = false
  pendingLength = length
  pendingValue = value
  havePending = true

let imageCount = nextInt(inputData, scanPos)

for imageIndex in 0 .. imageCount - 1:
  let imageWidth = int64(nextInt(inputData, scanPos))
  let imageHeight = int64(nextInt(inputData, scanPos))
  var events = newSeq[DiagonalEvent]()
  for rowIndex in 0 .. imageHeight - 1:
    var columnIndex: int64 = 0
    while columnIndex < imageWidth:
      let runLength = int64(nextInt(inputData, scanPos))
      let runIntensity = int64(nextInt(inputData, scanPos))
      events.add DiagonalEvent(position: rowIndex + columnIndex,
                               delta: runIntensity)
      events.add DiagonalEvent(position: rowIndex + columnIndex + runLength,
                               delta: -runIntensity)
      columnIndex += runLength
  events.sort(proc(left, right: DiagonalEvent): int =
    if left.position < right.position: -1
    elif left.position > right.position: 1
    else: 0)

  var pendingLength: int64 = 0
  var pendingValue: int64 = 0
  var havePending = false
  var firstPair = true
  var currentPosition: int64 = 0
  var currentValue: int64 = 0
  var eventIndex = 0
  while eventIndex < events.len:
    let eventPosition = events[eventIndex].position
    if eventPosition > currentPosition:
      emitRun(eventPosition - currentPosition, currentValue,
              pendingLength, pendingValue, havePending, firstPair)
    while eventIndex < events.len and events[eventIndex].position == eventPosition:
      currentValue += events[eventIndex].delta
      eventIndex += 1
    currentPosition = eventPosition

  let lastPosition = imageWidth + imageHeight - 1
  if currentPosition < lastPosition:
    emitRun(lastPosition - currentPosition, currentValue,
            pendingLength, pendingValue, havePending, firstPair)
  if havePending:
    if not firstPair:
      appendOutput(" ")
    appendOutput($pendingLength)
    appendOutput(" ")
    appendOutput($pendingValue)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
