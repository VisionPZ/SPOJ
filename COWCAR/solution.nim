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

proc sortSpeeds(values: var seq[int]) =
  let valueCount = values.len
  if valueCount < 2:
    return
  var buffer = newSeq[int](valueCount)
  var span = 1
  while span < valueCount:
    var start = 0
    while start < valueCount:
      var middle = start + span
      if middle > valueCount:
        middle = valueCount
      var finish = start + 2 * span
      if finish > valueCount:
        finish = valueCount
      var leftCursor = start
      var rightCursor = middle
      var writeCursor = start
      while leftCursor < middle and rightCursor < finish:
        if values[leftCursor] <= values[rightCursor]:
          buffer[writeCursor] = values[leftCursor]
          leftCursor += 1
        else:
          buffer[writeCursor] = values[rightCursor]
          rightCursor += 1
        writeCursor += 1
      while leftCursor < middle:
        buffer[writeCursor] = values[leftCursor]
        leftCursor += 1
        writeCursor += 1
      while rightCursor < finish:
        buffer[writeCursor] = values[rightCursor]
        rightCursor += 1
        writeCursor += 1
      start = finish
    swap values, buffer
    span = span * 2

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let cowCount = nextInt(inputData, scanPos)
let laneCount = nextInt(inputData, scanPos)
let slowdown = nextInt(inputData, scanPos)
let limitSpeed = nextInt(inputData, scanPos)
var speeds = newSeq[int](cowCount)
for cowIndex in 0 .. cowCount - 1:
  speeds[cowIndex] = nextInt(inputData, scanPos)
sortSpeeds(speeds)
var admittedCows = 0
for speedIndex in 0 .. cowCount - 1:
  let laneRank = admittedCows div laneCount
  let reducedSpeed = int64(speeds[speedIndex]) - int64(slowdown) * int64(laneRank)
  if reducedSpeed >= int64(limitSpeed):
    admittedCows += 1
appendOutput($admittedCows)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
