const firstDigitValue = 48
const flushBlockBytes = 1 shl 17
const caseLabel = "Case "

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
    value = value * 10 + int64(int(data[pos]) - firstDigitValue)
    pos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = int(nextInt(inputData, scanPos))
for caseIndex in 1..caseCount:
  let givenValue = nextInt(inputData, scanPos)
  appendOutput(caseLabel)
  appendOutput($(caseIndex))
  appendOutput(": ")
  appendOutput($(givenValue div 2))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
