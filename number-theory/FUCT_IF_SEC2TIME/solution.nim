const firstDigitValue = 48
const flushBlockBytes = 1 shl 17
const secondsPerMinute = 60
const secondsPerHour = 3600

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc hasNext(data: string, position: int): bool =
  var cursor = position
  while cursor < data.len and data[cursor] <= ' ':
    cursor += 1
  return cursor < data.len

proc nextInteger(data: string, position: var int): int64 =
  while position < data.len and data[position] <= ' ':
    position += 1
  var negative = false
  if position < data.len and data[position] == '-':
    negative = true
    position += 1
  var value: int64 = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int64(ord(data[position]) - firstDigitValue)
    position += 1
  if negative:
    return -value
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc appendTimePart(part: int64) =
  if part < 10:
    appendOutput("0")
  appendOutput($(part))

while hasNext(inputData, scanPos):
  let totalSeconds = nextInteger(inputData, scanPos)
  if totalSeconds < 0:
    appendOutput("total second must be a positive integer\n")
  else:
    let hours = totalSeconds div int64(secondsPerHour)
    let minutes = (totalSeconds mod int64(secondsPerHour)) div int64(secondsPerMinute)
    let seconds = totalSeconds mod int64(secondsPerMinute)
    appendTimePart(hours)
    appendOutput(":")
    appendTimePart(minutes)
    appendOutput(":")
    appendTimePart(seconds)
    appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0
