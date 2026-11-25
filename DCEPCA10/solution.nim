import algorithm

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

proc compareValues(leftValue, rightValue: int): int =
  if leftValue < rightValue:
    return -1
  if leftValue > rightValue:
    return 1
  return 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let elementCount = nextInt(inputData, scanPos)
  var values = newSeq[int](elementCount)
  for elementIndex in 0 .. elementCount - 1:
    values[elementIndex] = nextInt(inputData, scanPos)
  values.sort(compareValues)
  var longestRun = 1
  var currentRun = 1
  for elementIndex in 1 .. elementCount - 1:
    if values[elementIndex] == values[elementIndex - 1]:
      currentRun += 1
      if currentRun > longestRun:
        longestRun = currentRun
    else:
      currentRun = 1
  let requiredRun = elementCount div 2 + 1
  var changesNeeded = requiredRun - longestRun
  if changesNeeded < 0:
    changesNeeded = 0
  appendOutput($changesNeeded)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
