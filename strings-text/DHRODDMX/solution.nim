const flushBlockBytes = 1 shl 17
const firstDigitValue = 48

proc nextInt64(data: string, pos: var int): int64 =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value: int64 = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int64(int(data[pos]) - firstDigitValue)
    pos += 1
  return value

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var scanPos = 0
let caseCount = nextInt64(inputData, scanPos)
for _ in 0..<caseCount:
  let leftBound = nextInt64(inputData, scanPos)
  let rightBound = nextInt64(inputData, scanPos)
  let oddCount = (rightBound + 1) div 2 - leftBound div 2
  appendOutput($(oddCount))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
