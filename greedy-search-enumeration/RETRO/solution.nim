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

let strandLength = nextInt(inputData, scanPos)
while scanPos < inputData.len and inputData[scanPos] != '\n':
  scanPos += 1
scanPos += 1
let firstStrandStart = scanPos
scanPos += strandLength + 1
let secondStrandStart = scanPos
scanPos += strandLength + 1
let queryCount = nextInt(inputData, scanPos)

let rowWidth = strandLength + 1
var similarityTable = newSeq[int](rowWidth * rowWidth)
var firstIndex = strandLength - 1
while firstIndex >= 0:
  var secondIndex = strandLength - 1
  while secondIndex >= 0:
    var matchValue = 0
    if inputData[firstStrandStart + firstIndex] == inputData[secondStrandStart + secondIndex]:
      matchValue = 1
    similarityTable[firstIndex * rowWidth + secondIndex] =
      matchValue + similarityTable[(firstIndex + 1) * rowWidth + secondIndex + 1]
    secondIndex -= 1
  firstIndex -= 1

for queryIndex in 0 .. queryCount - 1:
  let firstStart = nextInt(inputData, scanPos) - 1
  let secondStart = nextInt(inputData, scanPos) - 1
  let regionLength = nextInt(inputData, scanPos)
  let fullScore = similarityTable[firstStart * rowWidth + secondStart]
  let tailScore = similarityTable[(firstStart + regionLength) * rowWidth + secondStart + regionLength]
  appendOutput($(fullScore - tailScore))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
