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
while scanPos < inputData.len and (inputData[scanPos] == ' ' or inputData[scanPos] == '\t' or inputData[scanPos] == '\r'):
  scanPos += 1
var trimmedLine = ""
while scanPos < inputData.len and inputData[scanPos] != '\n':
  trimmedLine.add inputData[scanPos]
  scanPos += 1
appendOutput(trimmedLine)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
