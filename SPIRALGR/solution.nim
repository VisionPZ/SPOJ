const flushBlockBytes = 1 shl 17
const gridRadius = 70
const gridSide = 2 * gridRadius + 1
const cellCount = gridSide * gridSide
const largestNumber = cellCount
const deltaX = [1, 0, -1, 0]
const deltaY = [0, 1, 0, -1]

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

proc hasMoreTokens(data: string, pos: int): bool =
  var cursor = pos
  while cursor < data.len:
    if data[cursor] >= '0' and data[cursor] <= '9':
      return true
    cursor += 1
  return false

proc flatIndex(gridX: int, gridY: int): int =
  return (gridY + gridRadius) * gridSide + gridX + gridRadius

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var isPrime = newSeq[bool](largestNumber + 1)
for numberValue in 2 .. largestNumber:
  isPrime[numberValue] = true
var factorValue = 2
while factorValue * factorValue <= largestNumber:
  if isPrime[factorValue]:
    var multipleValue = factorValue * factorValue
    while multipleValue <= largestNumber:
      isPrime[multipleValue] = false
      multipleValue += factorValue
  factorValue += 1

var numberX = newSeq[int](largestNumber + 1)
var numberY = newSeq[int](largestNumber + 1)
var currentX = 0
var currentY = 0
var directionIndex = 0
var stepLength = 1
var stepsTaken = 0
var directionRepeat = 0
var numberValue = 1
while numberValue < largestNumber:
  currentX += deltaX[directionIndex]
  currentY += deltaY[directionIndex]
  numberValue += 1
  numberX[numberValue] = currentX
  numberY[numberValue] = currentY
  stepsTaken += 1
  if stepsTaken == stepLength:
    stepsTaken = 0
    directionIndex = (directionIndex + 1) mod 4
    if directionRepeat == 0:
      directionRepeat = 1
    else:
      directionRepeat = 0
      stepLength += 1

var passable = newSeq[bool](cellCount)
for spiralNumber in 1 .. largestNumber:
  let cell = flatIndex(numberX[spiralNumber], numberY[spiralNumber])
  passable[cell] = spiralNumber == 1 or not isPrime[spiralNumber]

var componentId = newSeq[int](cellCount)
for cell in 0 .. cellCount - 1:
  componentId[cell] = -1
var floodStack = newSeq[int](cellCount)
var componentCount = 0
for startCell in 0 .. cellCount - 1:
  if not passable[startCell] or componentId[startCell] != -1:
    continue
  var stackSize = 0
  floodStack[stackSize] = startCell
  stackSize += 1
  componentId[startCell] = componentCount
  while stackSize > 0:
    stackSize -= 1
    let currentCell = floodStack[stackSize]
    let currentY = currentCell div gridSide
    let currentX = currentCell mod gridSide
    for direction in 0 .. 3:
      let neighborX = currentX + deltaX[direction]
      let neighborY = currentY + deltaY[direction]
      if neighborX < 0 or neighborX >= gridSide or neighborY < 0 or neighborY >= gridSide:
        continue
      let neighborCell = neighborY * gridSide + neighborX
      if not passable[neighborCell] or componentId[neighborCell] != -1:
        continue
      componentId[neighborCell] = componentCount
      floodStack[stackSize] = neighborCell
      stackSize += 1
  componentCount += 1

var queryStarts = newSeq[int]()
var queryEnds = newSeq[int]()
while hasMoreTokens(inputData, scanPos):
  queryStarts.add nextInt(inputData, scanPos)
  queryEnds.add nextInt(inputData, scanPos)
let queryCount = queryStarts.len

var sourceHead = newSeq[int](cellCount)
var nextInSource = newSeq[int](queryCount)
var answerForQuery = newSeq[int](queryCount)
for cell in 0 .. cellCount - 1:
  sourceHead[cell] = -1
for queryIndex in 0 .. queryCount - 1:
  let startCell = flatIndex(numberX[queryStarts[queryIndex]], numberY[queryStarts[queryIndex]])
  nextInSource[queryIndex] = sourceHead[startCell]
  sourceHead[startCell] = queryIndex
  answerForQuery[queryIndex] = -1

var distance = newSeq[int](cellCount)
for cell in 0 .. cellCount - 1:
  distance[cell] = -1
var searchQueue = newSeq[int](cellCount)
var touchedCells = newSeq[int](cellCount)
var targetHead = newSeq[int](cellCount)
var targetNext = newSeq[int](queryCount)
for cell in 0 .. cellCount - 1:
  targetHead[cell] = -1

for startCell in 0 .. cellCount - 1:
  if sourceHead[startCell] == -1:
    continue
  var pendingTargets = 0
  var groupQuery = sourceHead[startCell]
  while groupQuery != -1:
    let endCell = flatIndex(numberX[queryEnds[groupQuery]], numberY[queryEnds[groupQuery]])
    if componentId[endCell] == componentId[startCell]:
      targetNext[groupQuery] = targetHead[endCell]
      targetHead[endCell] = groupQuery
      pendingTargets += 1
    else:
      targetNext[groupQuery] = -1
    groupQuery = nextInSource[groupQuery]
  if pendingTargets == 0:
    groupQuery = sourceHead[startCell]
    while groupQuery != -1:
      let endCell = flatIndex(numberX[queryEnds[groupQuery]], numberY[queryEnds[groupQuery]])
      targetHead[endCell] = -1
      groupQuery = nextInSource[groupQuery]
    continue

  var queueStart = 0
  var queueEnd = 0
  searchQueue[queueEnd] = startCell
  queueEnd += 1
  distance[startCell] = 0
  var touchedCount = 0
  touchedCells[touchedCount] = startCell
  touchedCount += 1

  while queueStart < queueEnd and pendingTargets > 0:
    let currentCell = searchQueue[queueStart]
    queueStart += 1
    let currentDistance = distance[currentCell]
    var matchingQuery = targetHead[currentCell]
    while matchingQuery != -1:
      let followingQuery = targetNext[matchingQuery]
      if answerForQuery[matchingQuery] == -1:
        answerForQuery[matchingQuery] = currentDistance
        pendingTargets -= 1
      matchingQuery = followingQuery
    let currentY = currentCell div gridSide
    let currentX = currentCell mod gridSide
    for direction in 0 .. 3:
      let neighborX = currentX + deltaX[direction]
      let neighborY = currentY + deltaY[direction]
      if neighborX < 0 or neighborX >= gridSide or neighborY < 0 or neighborY >= gridSide:
        continue
      let neighborCell = neighborY * gridSide + neighborX
      if not passable[neighborCell] or distance[neighborCell] != -1:
        continue
      distance[neighborCell] = currentDistance + 1
      searchQueue[queueEnd] = neighborCell
      queueEnd += 1
      touchedCells[touchedCount] = neighborCell
      touchedCount += 1

  for touchedIndex in 0 .. touchedCount - 1:
    distance[touchedCells[touchedIndex]] = -1
  groupQuery = sourceHead[startCell]
  while groupQuery != -1:
    let endCell = flatIndex(numberX[queryEnds[groupQuery]], numberY[queryEnds[groupQuery]])
    targetHead[endCell] = -1
    groupQuery = nextInSource[groupQuery]

for queryIndex in 0 .. queryCount - 1:
  appendOutput("Case " & $(queryIndex + 1) & ": ")
  if answerForQuery[queryIndex] == -1:
    appendOutput("impossible\n")
  else:
    appendOutput($answerForQuery[queryIndex])
    outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
