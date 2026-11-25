const flushBlockBytes = 1 shl 17
const entryPrompt = "Please enter the positive integer N:"
const invalidMessage = "N must be greater than 0!"
const headingPrefix = "The number-triangle that has "
const headingSuffix = " lines is:"

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

let requestedLines = nextInt(inputData, scanPos)
appendOutput(entryPrompt)
if requestedLines <= 0:
  appendOutput(invalidMessage)
  outputBuffer.add '\n'
else:
  appendOutput(headingPrefix)
  appendOutput($requestedLines)
  appendOutput(headingSuffix)
  outputBuffer.add '\n'
  for rowNumber in 1 .. requestedLines:
    for repeatPosition in 1 .. rowNumber:
      if repeatPosition > 1:
        appendOutput(" ")
      appendOutput($rowNumber)
    outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
