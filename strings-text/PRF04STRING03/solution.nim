const flushBlockBytes = 1 shl 17

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
var textLine = ""
while scanPos < inputData.len and inputData[scanPos] != '\n':
  textLine.add inputData[scanPos]
  scanPos += 1
var trimEnd = textLine.len
while trimEnd > 0 and (textLine[trimEnd - 1] == ' ' or textLine[trimEnd - 1] == '\t' or textLine[trimEnd - 1] == '\r'):
  trimEnd -= 1
var trimmedLine = ""
var writePos = 0
while writePos < trimEnd:
  trimmedLine.add textLine[writePos]
  writePos += 1
appendOutput(trimmedLine)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
