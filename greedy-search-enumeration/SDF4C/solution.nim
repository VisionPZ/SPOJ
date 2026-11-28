const flushBlockBytes = 1 shl 17
const directionCount = 4

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

proc findPatternNumber(cellNumber: int): int =
  var lowValue = 0
  var highValue = 1000000
  while lowValue < highValue:
    let middleValue = (lowValue + highValue + 1) div 2
    if middleValue * middleValue + middleValue <= cellNumber:
      lowValue = middleValue
    else:
      highValue = middleValue - 1
  return lowValue

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let startCell = nextInt(inputData, scanPos)
  let targetCell = nextInt(inputData, scanPos)
  let patternNumber = findPatternNumber(startCell)
  let patternStart = patternNumber * patternNumber + patternNumber
  let startOffset = startCell - patternStart
  let segmentLength = patternNumber + 1
  let travelSteps = targetCell - startCell
  var stepOffset = 0
  var currentLength = segmentLength
  var directionIndex = 0
  if patternNumber mod 2 == 0:
    if startOffset >= segmentLength:
      stepOffset = startOffset - segmentLength
      directionIndex = 1
    else:
      stepOffset = startOffset
  elif startOffset >= segmentLength:
    stepOffset = startOffset - segmentLength
    directionIndex = 3
  else:
    stepOffset = startOffset
    directionIndex = 2
  var remainingSteps = travelSteps
  var firstInstruction = true
  while remainingSteps > 0:
    var stepCount = 0
    var nextRemaining = 0
    if currentLength <= remainingSteps:
      nextRemaining = remainingSteps - currentLength + stepOffset
      stepCount = currentLength - stepOffset
    else:
      stepCount = remainingSteps
    if not firstInstruction:
      appendOutput(" -> ")
    firstInstruction = false
    appendOutput($stepCount)
    case directionIndex:
      of 0: appendOutput("U")
      of 1: appendOutput("T")
      of 2: appendOutput("S")
      else: appendOutput("B")
    stepOffset = 0
    remainingSteps = nextRemaining
    if remainingSteps == 0:
      break
    if directionIndex == 1 or directionIndex == 3:
      currentLength += 1
    directionIndex = (directionIndex + 1) mod directionCount
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
