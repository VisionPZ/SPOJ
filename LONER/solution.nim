const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const dfaOnZero = [1, 1, 4, 4, 7, 3, 3, 7, 11, 12, 10, 10, 10, 8, 11, 10, 12, 14]
const dfaOnOne = [2, 3, 5, 6, 8, 9, 9, 10, 4, 13, 10, 14, 15, 16, 7, 11, 17, 16]
const dfaAccepting = [0, 0, 1, 1, 1, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int(data[position]) - firstDigitValue
    position += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for i in 0..<caseCount:
  let boardLength = nextInt(inputData, scanPos)
  while scanPos < inputData.len and (inputData[scanPos] < '0' or inputData[scanPos] > '1'):
    scanPos += 1
  var automatonState = 0
  for j in 0..<boardLength:
    if inputData[scanPos] == '1':
      automatonState = dfaOnOne[automatonState]
    else:
      automatonState = dfaOnZero[automatonState]
    scanPos += 1
  if dfaAccepting[automatonState] == 1:
    appendOutput("yes\n")
  else:
    appendOutput("no\n")

stdout.write outputBuffer
outputBuffer.setLen 0
