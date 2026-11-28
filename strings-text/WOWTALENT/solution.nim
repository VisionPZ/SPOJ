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

let welcomePrefix = "Welcome "
let welcomeSuffix = " to SIU\n"
var scanPos = 0

while scanPos < inputData.len:
  let nameStart = scanPos
  while scanPos < inputData.len and inputData[scanPos] != '\n':
    scanPos += 1
  var nameEnd = scanPos
  if nameEnd > nameStart and inputData[nameEnd - 1] == '\r':
    nameEnd -= 1
  if nameEnd > nameStart:
    let studentName = inputData[nameStart ..< nameEnd]
    appendOutput(welcomePrefix)
    appendOutput(studentName)
    appendOutput(welcomeSuffix)
  scanPos += 1

stdout.write outputBuffer
outputBuffer.setLen 0
