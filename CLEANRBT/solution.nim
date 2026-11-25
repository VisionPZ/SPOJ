const flushBlockBytes = 1 shl 17
const directionRows = [1, -1, 0, 0]
const directionColumns = [0, 0, 1, -1]

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

proc nextCellChar(data: string, pos: var int): char =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  result = data[pos]
  pos += 1

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while true:
  let widthCount = nextInt(inputData, scanPos)
  let heightCount = nextInt(inputData, scanPos)
  if widthCount == 0 and heightCount == 0:
    break
  let cellCount = widthCount * heightCount
  var blockedCells = newSeq[bool](cellCount)
  var dirtyIndex = newSeq[int](cellCount)
  for cellIndex in 0 .. cellCount - 1:
    dirtyIndex[cellIndex] = -1
  var dirtyCount = 0
  var startIndex = -1
  for cellIndex in 0 .. cellCount - 1:
    let cellChar = nextCellChar(inputData, scanPos)
    if cellChar == 'x':
      blockedCells[cellIndex] = true
    elif cellChar == '*':
      dirtyIndex[cellIndex] = dirtyCount
      dirtyCount += 1
    elif cellChar == 'o':
      startIndex = cellIndex
  let fullMask = (1 shl dirtyCount) - 1
  var bestMoves = -1
  if fullMask == 0:
    bestMoves = 0
  let stateCount = cellCount * (fullMask + 1)
  var distanceTable = newSeq[int](stateCount)
  for stateIndex in 0 .. stateCount - 1:
    distanceTable[stateIndex] = -1
  var stateQueue = newSeq[int](stateCount)
  var queueHead = 0
  var queueTail = 0
  let initialState = startIndex * (fullMask + 1)
  distanceTable[initialState] = 0
  stateQueue[queueTail] = initialState
  queueTail += 1
  while queueHead < queueTail and bestMoves == -1:
    let currentState = stateQueue[queueHead]
    queueHead += 1
    let currentCell = currentState div (fullMask + 1)
    let currentMask = currentState mod (fullMask + 1)
    let currentRow = currentCell div widthCount
    let currentColumn = currentCell mod widthCount
    for directionIndex in 0 .. 3:
      let nextRow = currentRow + directionRows[directionIndex]
      let nextColumn = currentColumn + directionColumns[directionIndex]
      if nextRow < 0 or nextRow >= heightCount:
        continue
      if nextColumn < 0 or nextColumn >= widthCount:
        continue
      let neighborCell = nextRow * widthCount + nextColumn
      if blockedCells[neighborCell]:
        continue
      var nextMask = currentMask
      if dirtyIndex[neighborCell] != -1:
        nextMask = currentMask or (1 shl dirtyIndex[neighborCell])
      let neighborState = neighborCell * (fullMask + 1) + nextMask
      if distanceTable[neighborState] != -1:
        continue
      distanceTable[neighborState] = distanceTable[currentState] + 1
      if nextMask == fullMask:
        bestMoves = distanceTable[neighborState]
        break
      stateQueue[queueTail] = neighborState
      queueTail += 1
  appendOutput($bestMoves)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
