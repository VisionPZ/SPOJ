const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int64 =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value: int64 = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int64(int(data[pos]) - 48)
    pos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let initialRoos = nextInt(inputData, scanPos)
var hungryRoos = initialRoos
var daysWorked: int64 = 0
while hungryRoos > 0:
  daysWorked += 1
  if hungryRoos == 1:
    hungryRoos = 0
  else:
    hungryRoos = (hungryRoos + 1) div 2

appendOutput($daysWorked)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
