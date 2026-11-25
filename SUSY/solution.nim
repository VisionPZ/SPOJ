const flushBlockBytes = 1 shl 17
const directionNames = ["Down", "Left", "Right", "Up"]
const directionSteps = [(1, 0), (0, -1), (0, 1), (-1, 0)]

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

let rowCount = nextInt(inputData, scanPos)
let columnCount = nextInt(inputData, scanPos)
while scanPos < inputData.len and inputData[scanPos] != '\n':
  scanPos += 1
if scanPos < inputData.len:
  scanPos += 1

var mazeRows = newSeq[string]()
var rowText = ""
for characterPos in scanPos .. inputData.len - 1:
  let currentChar = inputData[characterPos]
  if currentChar == '\n':
    while rowText.len < columnCount:
      rowText.add '.'
    mazeRows.add rowText
    rowText = ""
    if mazeRows.len == rowCount:
      break
  elif currentChar == '\r' or currentChar == ' ' or currentChar == '\t':
    discard
  elif rowText.len < columnCount:
    rowText.add currentChar
if mazeRows.len < rowCount:
  while rowText.len < columnCount:
    rowText.add '.'
  mazeRows.add rowText

var stoneIndex = newSeq[int](rowCount * columnCount)
for cellIndex in 0 .. rowCount * columnCount - 1:
  stoneIndex[cellIndex] = -1
var stoneCount = 0
var startCell = 0
for rowIndex in 0 .. rowCount - 1:
  for columnIndex in 0 .. columnCount - 1:
    let cellIndex = rowIndex * columnCount + columnIndex
    let cellChar = mazeRows[rowIndex][columnIndex]
    if cellChar == '*':
      stoneIndex[cellIndex] = stoneCount
      stoneCount += 1
    elif cellChar == 'S':
      startCell = cellIndex

let maskCount = 1 shl stoneCount
let fullMask = maskCount - 1
var slideDestination = newSeq[int](rowCount * columnCount * 4)
var slideStones = newSeq[int](rowCount * columnCount * 4)
for cellIndex in 0 .. rowCount * columnCount - 1:
  let startRow = cellIndex div columnCount
  let startColumn = cellIndex mod columnCount
  for directionIndex in 0 .. 3:
    let stepRow = directionSteps[directionIndex][0]
    let stepColumn = directionSteps[directionIndex][1]
    var currentRow = startRow
    var currentColumn = startColumn
    var collectedMask = 0
    while true:
      let nextRow = currentRow + stepRow
      let nextColumn = currentColumn + stepColumn
      if nextRow < 0 or nextRow >= rowCount or nextColumn < 0 or nextColumn >= columnCount:
        break
      let nextCell = nextRow * columnCount + nextColumn
      if mazeRows[nextRow][nextColumn] == '#':
        break
      currentRow = nextRow
      currentColumn = nextColumn
      if stoneIndex[nextCell] >= 0:
        collectedMask = collectedMask or (1 shl stoneIndex[nextCell])
    let stateIndex = cellIndex * 4 + directionIndex
    slideDestination[stateIndex] = currentRow * columnCount + currentColumn
    slideStones[stateIndex] = collectedMask

var startMask = 0
if stoneIndex[startCell] >= 0:
  startMask = 1 shl stoneIndex[startCell]
let startState = startCell * maskCount + startMask
let stateTotal = rowCount * columnCount * maskCount
var stateSeen = newSeq[bool](stateTotal)
var stateParent = newSeq[int](stateTotal)
var stateDirection = newSeq[int](stateTotal)
for stateIndex in 0 .. stateTotal - 1:
  stateParent[stateIndex] = -1
  stateDirection[stateIndex] = -1
var searchQueue = newSeq[int](stateTotal)
var queueHead = 0
var queueTail = 0
searchQueue[queueTail] = startState
queueTail += 1
stateSeen[startState] = true
var goalState = -1
while queueHead < queueTail and goalState == -1:
  let currentState = searchQueue[queueHead]
  queueHead += 1
  let currentCell = currentState div maskCount
  let currentMask = currentState mod maskCount
  if currentMask == fullMask:
    goalState = currentState
    break
  for directionIndex in 0 .. 3:
    let moveIndex = currentCell * 4 + directionIndex
    let nextCell = slideDestination[moveIndex]
    let nextMask = currentMask or slideStones[moveIndex]
    let nextState = nextCell * maskCount + nextMask
    if not stateSeen[nextState]:
      stateSeen[nextState] = true
      stateParent[nextState] = currentState
      stateDirection[nextState] = directionIndex
      searchQueue[queueTail] = nextState
      queueTail += 1

var moveCount = 0
var traceState = goalState
while traceState != startState and traceState != -1:
  moveCount += 1
  traceState = stateParent[traceState]
var moveDirections = newSeq[int](moveCount)
traceState = goalState
for moveIndex in countdown(moveCount - 1, 0):
  if traceState == startState:
    break
  moveDirections[moveIndex] = stateDirection[traceState]
  traceState = stateParent[traceState]

appendOutput($moveCount)
outputBuffer.add '\n'
for moveIndex in 0 .. moveCount - 1:
  if moveIndex > 0:
    outputBuffer.add '-'
  outputBuffer.add directionNames[moveDirections[moveIndex]]
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
