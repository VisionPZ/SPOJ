const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

proc nextInteger(inputData: string, scanPos: var int): int64 =
  while scanPos < inputData.len and inputData[scanPos] != '-' and
        (inputData[scanPos] < '0' or inputData[scanPos] > '9'):
    scanPos += 1
  var signValue = 1'i64
  if scanPos < inputData.len and inputData[scanPos] == '-':
    signValue = -1'i64
    scanPos += 1
  var parsedValue = 0'i64
  while scanPos < inputData.len and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    parsedValue = parsedValue * 10 + int64(int(inputData[scanPos]) - firstDigitValue)
    scanPos += 1
  return signValue * parsedValue

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let layerCount = int(nextInteger(inputData, scanPos))
for layerIndex in 0 ..< layerCount - 1:
  if (layerIndex + 1) mod 2 == 1:
    appendOutput("I hate that ")
  else:
    appendOutput("I love that ")
if layerCount mod 2 == 1:
  appendOutput("I hate it")
else:
  appendOutput("I love it")
outputBuffer.add '\n'
stdout.write outputBuffer
