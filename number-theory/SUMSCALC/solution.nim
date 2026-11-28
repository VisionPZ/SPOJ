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

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let numberValue = int64(nextInt(inputData, scanPos))
  let sumFirst = numberValue * (numberValue + 1) div 2
  let sumEven = numberValue * (numberValue + 1)
  let sumOdd = numberValue * numberValue
  let sumSquares = numberValue * (numberValue + 1) * (2 * numberValue + 1) div 6
  let sumCubes = sumFirst * sumFirst
  appendOutput($sumFirst)
  outputBuffer.add ' '
  appendOutput($sumEven)
  outputBuffer.add ' '
  appendOutput($sumOdd)
  outputBuffer.add ' '
  appendOutput($sumSquares)
  outputBuffer.add ' '
  appendOutput($sumCubes)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
