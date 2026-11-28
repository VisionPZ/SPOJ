const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let pondoStep = int64(nextInt(inputData, scanPos))
let punduStep = int64(nextInt(inputData, scanPos))
let trackLength = int64(nextInt(inputData, scanPos))
let pondoStepsToFinish = (trackLength + pondoStep - 1) div pondoStep
let lastPondoReach = (pondoStepsToFinish - 1) * pondoStep
let punduFinishReach = ((trackLength + punduStep - 1) div punduStep) * punduStep
if lastPondoReach > punduFinishReach - punduStep:
  appendOutput("LOSS")
else:
  appendOutput("WIN")
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
