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
  let appendedValue = nextInt(inputData, scanPos)
  let targetAverage = nextInt(inputData, scanPos)
  let sequenceLength = targetAverage - appendedValue
  let totalSum = int64(sequenceLength) * int64(targetAverage + 1)
  let smallestOthers = int64(sequenceLength - 1) * int64(sequenceLength) div 2
  appendOutput($(totalSum - smallestOthers))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
