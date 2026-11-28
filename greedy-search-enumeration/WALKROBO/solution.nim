const flushBlockBytes = 1 shl 17

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
    value = value * 10 + int(data[pos]) - 48
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

var caseNumber = 0
while true:
  let rowCount = nextInt(inputData, scanPos)
  let columnCount = nextInt(inputData, scanPos)
  let moveCount = nextInt(inputData, scanPos)
  let knownCount = nextInt(inputData, scanPos)
  if rowCount == 0 and columnCount == 0 and moveCount == 0 and knownCount == 0:
    break
  caseNumber += 1
  var moveX = newSeq[int](moveCount)
  var moveY = newSeq[int](moveCount)
  for moveIndex in 0 .. moveCount - 1:
    moveX[moveIndex] = nextInt(inputData, scanPos)
    moveY[moveIndex] = nextInt(inputData, scanPos)
  var initialMask = 0
  for knownIndex in 0 .. knownCount - 1:
    let moveNumber = nextInt(inputData, scanPos)
    initialMask = initialMask or (1 shl (moveNumber - 1))
  var grid = newSeq[seq[int]](rowCount)
  for rowIndex in 0 .. rowCount - 1:
    grid[rowIndex] = newSeq[int](columnCount)
    for columnIndex in 0 .. columnCount - 1:
      grid[rowIndex][columnIndex] = nextInt(inputData, scanPos)
  let cellCount = rowCount * columnCount
  let maskCount = 1 shl moveCount
  var distances = newSeq[int](maskCount * cellCount)
  for stateIndex in 0 .. distances.len - 1:
    distances[stateIndex] = -1
  var queue = newSeq[int](maskCount * cellCount)
  var queueHead = 0
  var queueTail = 0
  let startState = initialMask * cellCount
  distances[startState] = 0
  queue[queueTail] = startState
  queueTail += 1
  var answer = -1
  while queueHead < queueTail:
    let state = queue[queueHead]
    queueHead += 1
    let knowledgeMask = state div cellCount
    let cellIndex = state mod cellCount
    let row = cellIndex div columnCount
    let column = cellIndex mod columnCount
    let stepsTaken = distances[state]
    if row == rowCount - 1 and column == columnCount - 1:
      answer = stepsTaken
      break
    for moveIndex in 0 .. moveCount - 1:
      if (knowledgeMask and (1 shl moveIndex)) == 0:
        continue
      let nextColumn = column + moveX[moveIndex]
      let nextRow = row + moveY[moveIndex]
      if nextColumn >= 0 and nextColumn < columnCount and nextRow >= 0 and nextRow < rowCount:
        let nextState = knowledgeMask * cellCount + nextRow * columnCount + nextColumn
        if distances[nextState] < 0:
          distances[nextState] = stepsTaken + 1
          queue[queueTail] = nextState
          queueTail += 1
    let downloadSpot = grid[rowCount - 1 - row][column]
    if downloadSpot > 0:
      let moveBit = 1 shl (downloadSpot - 1)
      if (knowledgeMask and moveBit) == 0:
        let nextState = (knowledgeMask or moveBit) * cellCount + cellIndex
        if distances[nextState] < 0:
          distances[nextState] = stepsTaken + 1
          queue[queueTail] = nextState
          queueTail += 1
  appendOutput("Case #" & $caseNumber & ": " & $answer & "\n")
stdout.write outputBuffer
outputBuffer.setLen 0
