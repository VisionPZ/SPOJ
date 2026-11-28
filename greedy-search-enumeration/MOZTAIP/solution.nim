const flushBlockBytes = 1 shl 17
const requiredLine = "Competitive\\tprogramming\\n"

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

appendOutput(requiredLine)
stdout.write outputBuffer
outputBuffer.setLen 0
