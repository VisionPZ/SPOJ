const flushBlockBytes = 1 shl 17
const minutesPerDay = 1440

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int, found: var bool): int =
  found = false
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
    found = true
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while true:
  var hourFound = false
  let hourValue = nextInt(inputData, scanPos, hourFound)
  if not hourFound:
    break
  var minuteFound = false
  let minuteValue = nextInt(inputData, scanPos, minuteFound)
  let minutesSoFar = hourValue * 60 + minuteValue
  if minutesSoFar == 0:
    break
  appendOutput($(minutesPerDay - minutesSoFar))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
