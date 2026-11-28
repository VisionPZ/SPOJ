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
  let wireLength = int64(nextInt(inputData, scanPos))
  let sectionCount = int64(nextInt(inputData, scanPos))
  let cutLoss = int64(nextInt(inputData, scanPos))
  var usableLength = wireLength - (sectionCount - 1) * cutLoss
  if usableLength < 0:
    usableLength = 0
  let sectionLength = usableLength div sectionCount
  appendOutput($sectionLength)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
