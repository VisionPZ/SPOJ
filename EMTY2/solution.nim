const flushBlockBytes = 1 shl 17
const awaitingFirstZero = 0'i8
const awaitingSecondZero = 1'i8
const unmatchedZero = 2'i8

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

proc nextToken(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  let startPos = pos
  while pos < data.len and data[pos] > ' ':
    pos += 1
  return data[startPos .. pos - 1]

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let testCount = nextInt(inputData, scanPos)
for caseNumber in 1 .. testCount:
  let binaryText = nextToken(inputData, scanPos)
  var stackStates = newSeq[int8](binaryText.len)
  var stackSize = 0
  for characterIndex in 0 .. binaryText.len - 1:
    if binaryText[characterIndex] == '1':
      stackStates[stackSize] = awaitingFirstZero
      stackSize += 1
    elif stackSize > 0 and stackStates[stackSize - 1] == awaitingFirstZero:
      stackStates[stackSize - 1] = awaitingSecondZero
    elif stackSize > 0 and stackStates[stackSize - 1] == awaitingSecondZero:
      stackSize -= 1
    else:
      stackStates[stackSize] = unmatchedZero
      stackSize += 1
  appendOutput("Case " & $caseNumber & ": ")
  if stackSize == 0:
    appendOutput("yes\n")
  else:
    appendOutput("no\n")
stdout.write outputBuffer
outputBuffer.setLen 0
