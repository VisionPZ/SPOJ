const flushBlockBytes = 1 shl 17
const gestureCount = 3

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

let caseCount = nextInt(inputData, scanPos)
var caseIndex = 0
while caseIndex < caseCount:
  let gonNumber = nextInt(inputData, scanPos)
  let killuaNumber = nextInt(inputData, scanPos)
  let gonSign = gonNumber mod gestureCount
  let killuaSign = killuaNumber mod gestureCount
  if gonSign == killuaSign:
    appendOutput("DRAW")
  elif (gonSign - killuaSign + gestureCount) mod gestureCount == 1:
    appendOutput("GON")
  else:
    appendOutput("KILLUA")
  outputBuffer.add '\n'
  caseIndex += 1
stdout.write outputBuffer
outputBuffer.setLen 0
