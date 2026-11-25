const firstDigitValue = 48
const flushBlockBytes = 1 shl 17
const dayNames = ["Friday", "Saturday", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday"]

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  if position >= data.len:
    return -1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + ord(data[position]) - firstDigitValue
    position += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while true:
  let dayOffset = nextInt(inputData, scanPos)
  if dayOffset < 0:
    break
  appendOutput(dayNames[dayOffset mod 7] & "\n")

stdout.write outputBuffer
outputBuffer.setLen 0
