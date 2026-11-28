const firstDigitValue = 48
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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let firstSetSize = nextInt(inputData, scanPos)
let secondSetSize = nextInt(inputData, scanPos)
var firstSet = newSeq[int](firstSetSize)
for elementIndex in 0 .. firstSetSize - 1:
  firstSet[elementIndex] = nextInt(inputData, scanPos)
var secondSet = newSeq[int](secondSetSize)
for elementIndex in 0 .. secondSetSize - 1:
  secondSet[elementIndex] = nextInt(inputData, scanPos)

var intersectionText = ""
var firstCursor = 0
var secondCursor = 0
while firstCursor < firstSetSize and secondCursor < secondSetSize:
  if firstSet[firstCursor] == secondSet[secondCursor]:
    intersectionText.add $(firstSet[firstCursor])
    intersectionText.add ' '
    firstCursor += 1
    secondCursor += 1
  elif firstSet[firstCursor] < secondSet[secondCursor]:
    firstCursor += 1
  else:
    secondCursor += 1

var unionText = ""
firstCursor = 0
secondCursor = 0
while firstCursor < firstSetSize or secondCursor < secondSetSize:
  if secondCursor >= secondSetSize or (firstCursor < firstSetSize and firstSet[firstCursor] < secondSet[secondCursor]):
    unionText.add $(firstSet[firstCursor])
    unionText.add ' '
    firstCursor += 1
  elif firstCursor >= firstSetSize or secondSet[secondCursor] < firstSet[firstCursor]:
    unionText.add $(secondSet[secondCursor])
    unionText.add ' '
    secondCursor += 1
  else:
    unionText.add $(firstSet[firstCursor])
    unionText.add ' '
    firstCursor += 1
    secondCursor += 1

if intersectionText.len == 0:
  appendOutput(" ")
appendOutput(intersectionText)
outputBuffer.add '\n'
if unionText.len == 0:
  appendOutput(" ")
appendOutput(unionText)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
