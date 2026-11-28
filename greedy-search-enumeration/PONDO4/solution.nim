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

let targetNumber = int64(nextInt(inputData, scanPos))
var remaining = targetNumber
var wordCount: int64 = 0
while remaining > 0:
  var remainder = remaining mod 3
  if remainder == 0:
    remaining = remaining div 3
    wordCount += 1
  else:
    remaining -= remainder
    wordCount += remainder
appendOutput($wordCount)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
