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

let numberCount = nextInt(inputData, scanPos)
var evenSeen: int64 = 0
var oddSeen: int64 = 0
var pairTotal: int64 = 0
for numberIndex in 0 .. numberCount - 1:
  let currentNumber = nextInt(inputData, scanPos)
  if currentNumber mod 2 == 0:
    pairTotal += evenSeen
    evenSeen += 1
  else:
    pairTotal += oddSeen
    oddSeen += 1
appendOutput($pairTotal)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
