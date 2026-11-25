const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var lineBreak = 0
while lineBreak < inputData.len and inputData[lineBreak] != '\n':
  lineBreak += 1

var scanPos = lineBreak + 1
while scanPos < inputData.len and inputData[scanPos] <= ' ':
  scanPos += 1

var occurrenceCount = 0
if scanPos < inputData.len:
  let targetChar = inputData[scanPos]
  for index in 0..<lineBreak:
    if inputData[index] == targetChar:
      occurrenceCount += 1

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

appendOutput($(occurrenceCount))
outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
