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

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  var leftColors: array[4, int]
  var rightColors: array[4, int]
  for colorIndex in 0 .. 3:
    leftColors[colorIndex] = nextInt(inputData, scanPos)
  for colorIndex in 0 .. 3:
    rightColors[colorIndex] = nextInt(inputData, scanPos)
  var answerPositions: array[4, int]
  for leftIndex in 0 .. 3:
    for rightIndex in 0 .. 3:
      if rightColors[rightIndex] == leftColors[leftIndex]:
        answerPositions[leftIndex] = rightIndex + 1
  for leftIndex in 0 .. 3:
    if leftIndex > 0:
      appendOutput(" ")
    appendOutput($(answerPositions[leftIndex]))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
