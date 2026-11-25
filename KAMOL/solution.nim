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

if inputData.len > 0:
  discard

appendOutput("GoodBye Kam0L Bhai")
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
