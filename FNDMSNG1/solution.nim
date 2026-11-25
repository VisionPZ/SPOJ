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

let permutationSize = nextInt(inputData, scanPos)
var observedSum: int64 = 0
var observedCount = 0
while observedCount < permutationSize - 1:
  observedSum = observedSum + int64(nextInt(inputData, scanPos))
  observedCount += 1
let expectedSum = int64(permutationSize) * int64(permutationSize + 1) div 2
appendOutput($(expectedSum - observedSum))
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
