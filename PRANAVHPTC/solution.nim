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

let testCount = nextInt(inputData, scanPos)
for testIndex in 0 .. testCount - 1:
  let totalSeats = int64(nextInt(inputData, scanPos))
  let firstSeat = int64(nextInt(inputData, scanPos))
  let secondSeat = int64(nextInt(inputData, scanPos))
  var forwardGap = (secondSeat - firstSeat) mod totalSeats
  if forwardGap < 0:
    forwardGap += totalSeats
  var backwardGap = (firstSeat - secondSeat) mod totalSeats
  if backwardGap < 0:
    backwardGap += totalSeats
  var directDistance = forwardGap
  if backwardGap < directDistance:
    directDistance = backwardGap
  appendOutput($directDistance)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
