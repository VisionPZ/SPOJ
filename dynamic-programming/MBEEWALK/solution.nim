const flushBlockBytes = 1 shl 17
const stepDirectionCount = 6
const maxWalkSteps = 14
const coordinateOffset = 14
const gridSide = 2 * coordinateOffset + 1
const centerCell = coordinateOffset * gridSide + coordinateOffset

const stepDirections: array[stepDirectionCount, array[2, int]] = [
  [1, 0], [0, 1], [-1, 1], [-1, 0], [0, -1], [1, -1]
]

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

var walkAnswers = newSeq[int](maxWalkSteps + 1)
var currentCounts = newSeq[int](gridSide * gridSide)
var nextCounts = newSeq[int](gridSide * gridSide)
currentCounts[centerCell] = 1

for stepNumber in 1 .. maxWalkSteps:
  for cellIndex in 0 .. nextCounts.len - 1:
    nextCounts[cellIndex] = 0
  for cellIndex in 0 .. currentCounts.len - 1:
    let pathCount = currentCounts[cellIndex]
    if pathCount == 0:
      continue
    let gridX = cellIndex div gridSide - coordinateOffset
    let gridY = cellIndex mod gridSide - coordinateOffset
    for directionIndex in 0 .. stepDirectionCount - 1:
      let nextX = gridX + stepDirections[directionIndex][0]
      let nextY = gridY + stepDirections[directionIndex][1]
      let nextCell = (nextX + coordinateOffset) * gridSide + nextY + coordinateOffset
      nextCounts[nextCell] = nextCounts[nextCell] + pathCount
  for cellIndex in 0 .. currentCounts.len - 1:
    currentCounts[cellIndex] = nextCounts[cellIndex]
  walkAnswers[stepNumber] = currentCounts[centerCell]

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let walkSteps = nextInt(inputData, scanPos)
  appendOutput($walkAnswers[walkSteps])
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
