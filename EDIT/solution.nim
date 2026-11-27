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
while scanPos < inputData.len:
  while scanPos < inputData.len and (inputData[scanPos] == '\n' or inputData[scanPos] == '\r' or inputData[scanPos] == ' '):
    scanPos += 1
  if scanPos >= inputData.len:
    break
  var lineStart = scanPos
  while scanPos < inputData.len and inputData[scanPos] != '\n' and inputData[scanPos] != '\r' and inputData[scanPos] != ' ':
    scanPos += 1
  let lineLength = scanPos - lineStart
  var mismatchUpperStart = 0
  for offset in 0 .. lineLength - 1:
    let ch = inputData[lineStart + offset]
    let isUpper = ch >= 'A' and ch <= 'Z'
    let expectUpper = (offset and 1) == 0
    if isUpper != expectUpper:
      mismatchUpperStart += 1
  let mismatchLowerStart = lineLength - mismatchUpperStart
  let minChanges = if mismatchUpperStart < mismatchLowerStart: mismatchUpperStart else: mismatchLowerStart
  appendOutput($minChanges)
  appendOutput("\n")

if outputBuffer.len > 0:
  stdout.write outputBuffer
  outputBuffer.setLen 0
