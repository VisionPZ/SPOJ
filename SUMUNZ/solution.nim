const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextSignedInt(data: string, pos: var int, found: var bool): int =
  found = false
  while pos < data.len and data[pos] != '-' and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var sign = 1
  if pos < data.len and data[pos] == '-':
    sign = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
    found = true
  return sign * value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var total: int64 = 0
while true:
  var elementFound = false
  let elementValue = nextSignedInt(inputData, scanPos, elementFound)
  if not elementFound:
    break
  if elementValue == 0:
    break
  total = total + int64(elementValue)

appendOutput($total)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
