const flushBlockBytes = 1 shl 17
const firstLowerLetter = 97
const lastLowerLetter = 122
const alphabetHeading = "alphabet"
const letterSeparator = ", "

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

appendOutput(alphabetHeading)
outputBuffer.add '\n'
for letterCode in firstLowerLetter .. lastLowerLetter:
  if letterCode > firstLowerLetter:
    appendOutput(letterSeparator)
  appendOutput($char(letterCode))
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
