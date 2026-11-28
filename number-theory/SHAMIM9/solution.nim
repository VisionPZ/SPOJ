const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

proc nextLastDigit(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var digitValue = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    digitValue = int(data[pos]) - firstDigitValue
    pos += 1
  return digitValue

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var scanPos = 0

while true:
  while scanPos < inputData.len and inputData[scanPos] <= ' ':
    scanPos += 1
  if scanPos >= inputData.len:
    break
  let lastDigit = nextLastDigit(inputData, scanPos)
  let resultDigit = (9 * lastDigit) mod 10
  appendOutput($(resultDigit))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
