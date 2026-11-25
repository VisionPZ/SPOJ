const flushBlockBytes = 1 shl 17
const expectedCount = 10

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

var largestValue: int64 = 0
var valueIndex = 0
while valueIndex < expectedCount:
  let candidate = nextInt(inputData, scanPos)
  if candidate > largestValue:
    largestValue = candidate
  valueIndex += 1

appendOutput("Bilangan terbesar: ")
appendOutput($largestValue)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
