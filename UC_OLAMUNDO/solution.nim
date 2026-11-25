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

var nameStart = 0
while nameStart < inputData.len and (inputData[nameStart] == '\n' or inputData[nameStart] == '\r' or inputData[nameStart] == ' '):
  nameStart += 1
var nameEnd = nameStart
while nameEnd < inputData.len and inputData[nameEnd] != '\n' and inputData[nameEnd] != '\r':
  nameEnd += 1
let visitorName = inputData[nameStart ..< nameEnd]
appendOutput("Olá " & visitorName & ", este é seu primeiro programa!")
outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
