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

var normalizedText = ""
var pendingSpace = false
for inputChar in inputData:
  if inputChar == ' ' or inputChar == '\t' or inputChar == '\n' or inputChar == '\r':
    if normalizedText.len > 0:
      pendingSpace = true
  else:
    if pendingSpace:
      normalizedText.add ' '
      pendingSpace = false
    normalizedText.add inputChar

appendOutput(normalizedText)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
