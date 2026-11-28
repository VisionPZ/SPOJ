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

let stringLength = nextInt(inputData, scanPos)
while scanPos < inputData.len and inputData[scanPos] != '\n':
  scanPos += 1
scanPos += 1

var firstPassword = ""
var secondPassword = ""
for charIndex in 0 .. stringLength - 1:
  firstPassword.add inputData[scanPos + charIndex]
scanPos += stringLength + 1
for charIndex in 0 .. stringLength - 1:
  secondPassword.add inputData[scanPos + charIndex]
scanPos += stringLength + 1

let operationCount = nextInt(inputData, scanPos)
var swapParity = newSeq[int](stringLength + 1)
for operationIndex in 0 .. operationCount - 1:
  let leftPosition = nextInt(inputData, scanPos)
  let rightPosition = nextInt(inputData, scanPos)
  swapParity[leftPosition] = swapParity[leftPosition] xor 1
  swapParity[rightPosition + 1] = swapParity[rightPosition + 1] xor 1

var parityState = 0
var firstResult = ""
var secondResult = ""
for charIndex in 0 .. stringLength - 1:
  parityState = parityState xor swapParity[charIndex]
  if parityState == 1:
    firstResult.add secondPassword[charIndex]
    secondResult.add firstPassword[charIndex]
  else:
    firstResult.add firstPassword[charIndex]
    secondResult.add secondPassword[charIndex]

appendOutput(firstResult)
outputBuffer.add '\n'
appendOutput(secondResult)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
