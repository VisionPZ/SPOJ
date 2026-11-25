const flushBlockBytes = 1 shl 17
const firstDigitValue = 48
const initialStepX = 1
const initialStepY = -1
const maxSimulationSteps = 12000000

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and data[pos] != '-' and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var negative = false
  if pos < data.len and data[pos] == '-':
    negative = true
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  if negative:
    return -value
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc formatHalf(doubledValue: int): string =
  var negative = false
  var magnitude = doubledValue
  if magnitude < 0:
    negative = true
    magnitude = -magnitude
  let wholePart = magnitude div 2
  let halfPart = magnitude mod 2
  result = (if negative: "-" else: "") & $wholePart & (if halfPart == 1: ".5" else: ".0")

let boxCount = nextInt(inputData, scanPos)
let laserX = nextInt(inputData, scanPos)
let laserY = nextInt(inputData, scanPos)
var boxCorners = newSeq[int](boxCount * 4)
var minCellX = 0
var maxCellX = 0
var minCellY = 0
var maxCellY = 0
for boxIndex in 0 .. boxCount - 1:
  let firstX = nextInt(inputData, scanPos)
  let firstY = nextInt(inputData, scanPos)
  let secondX = nextInt(inputData, scanPos)
  let secondY = nextInt(inputData, scanPos)
  boxCorners[boxIndex * 4] = firstX
  boxCorners[boxIndex * 4 + 1] = firstY
  boxCorners[boxIndex * 4 + 2] = secondX
  boxCorners[boxIndex * 4 + 3] = secondY
  let lowerX = min(firstX, secondX)
  let upperX = max(firstX, secondX)
  let lowerY = min(firstY, secondY)
  let upperY = max(firstY, secondY)
  if boxIndex == 0:
    minCellX = lowerX
    maxCellX = upperX
    minCellY = lowerY
    maxCellY = upperY
  else:
    if lowerX < minCellX: minCellX = lowerX
    if upperX > maxCellX: maxCellX = upperX
    if lowerY < minCellY: minCellY = lowerY
    if upperY > maxCellY: maxCellY = upperY

let gridWidth = maxCellX - minCellX + 1
let gridHeight = maxCellY - minCellY + 1
let gridSize = gridWidth * gridHeight
var occupiedCells = newSeq[int8](gridSize)
var visitedPoints = newSeq[int8](gridSize)
var visitedOrientations = newSeq[int8](gridSize)

proc cellIndex(cellX, cellY: int): int =
  return (cellY - minCellY) * gridWidth + (cellX - minCellX)

proc isOccupied(cellX, cellY: int): bool =
  if cellX < minCellX or cellX >= maxCellX or cellY < minCellY or cellY >= maxCellY:
    return false
  return occupiedCells[cellIndex(cellX, cellY)] == 1

for boxIndex in 0 .. boxCount - 1:
  let lowerX = min(boxCorners[boxIndex * 4], boxCorners[boxIndex * 4 + 2])
  let upperX = max(boxCorners[boxIndex * 4], boxCorners[boxIndex * 4 + 2])
  let lowerY = min(boxCorners[boxIndex * 4 + 1], boxCorners[boxIndex * 4 + 3])
  let upperY = max(boxCorners[boxIndex * 4 + 1], boxCorners[boxIndex * 4 + 3])
  var cellX = lowerX
  while cellX < upperX:
    var cellY = lowerY
    while cellY < upperY:
      occupiedCells[cellIndex(cellX, cellY)] = 1
      cellY += 1
    cellX += 1

visitedPoints[cellIndex(laserX, laserY)] = 1
var currentX = laserX
var currentY = laserY
var stepX = initialStepX
var stepY = initialStepY
var timeValue = 0
var simulationStep = 0
var finished = false

while simulationStep < maxSimulationSteps and not finished:
  let forwardX = currentX + min(0, stepX)
  let forwardY = currentY + min(0, stepY)
  let sideBelowX = currentX + min(0, -stepX)
  let sideBelowY = currentY + min(0, stepY)
  let sideAsideX = currentX + min(0, stepX)
  let sideAsideY = currentY + min(0, -stepY)
  let forwardInside = isOccupied(forwardX, forwardY)
  let sideBelowInside = isOccupied(sideBelowX, sideBelowY)
  let sideAsideInside = isOccupied(sideAsideX, sideAsideY)
  var headOn = false
  if not (forwardInside and sideBelowInside and sideAsideInside):
    if sideBelowInside and not sideAsideInside:
      stepX = -stepX
    elif sideAsideInside and not sideBelowInside:
      stepY = -stepY
    else:
      stepX = -stepX
      stepY = -stepY
      headOn = true
    if headOn:
      appendOutput(formatHalf(timeValue * 2))
      appendOutput("\n")
      appendOutput(formatHalf(currentX * 2))
      appendOutput(" ")
      appendOutput(formatHalf(currentY * 2))
      appendOutput("\n")
      finished = true
      break
  let travelledX = currentX + min(0, stepX)
  let travelledY = currentY + min(0, stepY)
  let orientation = if stepX == stepY: 0 else: 1
  let travelledIndex = cellIndex(travelledX, travelledY)
  let previousMask = visitedOrientations[travelledIndex]
  let oppositeMask: int8 = int8(1 shl (1 - orientation))
  if (previousMask and oppositeMask) != 0:
    appendOutput(formatHalf(timeValue * 2 + 1))
    appendOutput("\n")
    appendOutput(formatHalf(travelledX * 2 + 1))
    appendOutput(" ")
    appendOutput(formatHalf(travelledY * 2 + 1))
    appendOutput("\n")
    finished = true
    break
  visitedOrientations[travelledIndex] = previousMask or int8(1 shl orientation)
  let nextX = currentX + stepX
  let nextY = currentY + stepY
  let nextTime = timeValue + 1
  if nextX == laserX and nextY == laserY:
    appendOutput(formatHalf(nextTime * 2))
    appendOutput("\n")
    appendOutput("Broken equipment")
    appendOutput("\n")
    finished = true
    break
  let nextIndex = cellIndex(nextX, nextY)
  if visitedPoints[nextIndex] == 1:
    appendOutput(formatHalf(nextTime * 2))
    appendOutput("\n")
    appendOutput(formatHalf(nextX * 2))
    appendOutput(" ")
    appendOutput(formatHalf(nextY * 2))
    appendOutput("\n")
    finished = true
    break
  visitedPoints[nextIndex] = 1
  currentX = nextX
  currentY = nextY
  timeValue = nextTime
  simulationStep += 1

if not finished:
  appendOutput("Time limit exceeded")
  appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0
