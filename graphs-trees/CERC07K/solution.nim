const flushBlockBytes = 1 shl 17
const keyCount = 16

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

proc nextCell(data: string, pos: var int): char =
  while pos < data.len and (data[pos] == ' ' or data[pos] == '\n' or data[pos] == '\r' or data[pos] == '\t'):
    pos += 1
  let cell = data[pos]
  pos += 1
  return cell

proc keyBit(cell: char): int =
  if cell == 'b' or cell == 'B':
    return 1
  if cell == 'y' or cell == 'Y':
    return 2
  if cell == 'r' or cell == 'R':
    return 4
  if cell == 'g' or cell == 'G':
    return 8
  return 0

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while true:
  let rowCount = nextInt(inputData, scanPos)
  let columnCount = nextInt(inputData, scanPos)
  if rowCount == 0 and columnCount == 0:
    break
  let cellCount = rowCount * columnCount
  var isWall = newSeq[bool](cellCount)
  var keyMasks = newSeq[int](cellCount)
  var doorMasks = newSeq[int](cellCount)
  var isExit = newSeq[bool](cellCount)
  var startCell = 0
  for cellIndex in 0 .. cellCount - 1:
    let cell = nextCell(inputData, scanPos)
    isWall[cellIndex] = cell == '#'
    if cell >= 'a' and cell <= 'z':
      keyMasks[cellIndex] = keyBit(cell)
    if (cell >= 'A' and cell <= 'Z') and cell != 'X':
      doorMasks[cellIndex] = keyBit(cell)
    isExit[cellIndex] = cell == 'X'
    if cell == '*':
      startCell = cellIndex
  let stateCount = cellCount * keyCount
  var distances = newSeq[int](stateCount)
  for stateIndex in 0 .. stateCount - 1:
    distances[stateIndex] = -1
  var queue = newSeq[int](stateCount)
  var queueHead = 0
  var queueTail = 0
  let startState = startCell * keyCount
  distances[startState] = 0
  queue[queueTail] = startState
  queueTail += 1
  var escapeSteps = -1
  while queueHead < queueTail and escapeSteps == -1:
    let currentState = queue[queueHead]
    queueHead += 1
    let currentCell = currentState div keyCount
    let currentKeys = currentState mod keyCount
    let currentRow = currentCell div columnCount
    let currentColumn = currentCell mod columnCount
    for direction in 0 .. 3:
      var nextRow = currentRow
      var nextColumn = currentColumn
      if direction == 0:
        nextRow -= 1
      elif direction == 1:
        nextRow += 1
      elif direction == 2:
        nextColumn -= 1
      else:
        nextColumn += 1
      if nextRow < 0 or nextRow >= rowCount or nextColumn < 0 or nextColumn >= columnCount:
        continue
      let nextCellIndex = nextRow * columnCount + nextColumn
      if isWall[nextCellIndex]:
        continue
      if (doorMasks[nextCellIndex] and currentKeys) == 0 and doorMasks[nextCellIndex] != 0:
        continue
      let nextKeys = currentKeys or keyMasks[nextCellIndex]
      let nextState = nextCellIndex * keyCount + nextKeys
      if distances[nextState] != -1:
        continue
      distances[nextState] = distances[currentState] + 1
      if isExit[nextCellIndex]:
        escapeSteps = distances[nextState]
        break
      queue[queueTail] = nextState
      queueTail += 1
  if escapeSteps == -1:
    appendOutput("The poor student is trapped!")
  else:
    appendOutput("Escape possible in " & $escapeSteps & " steps.")
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
