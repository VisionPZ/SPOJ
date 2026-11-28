const flushBlockBytes = 1 shl 17
const maxCellCount = 400
const maxStateCount = maxCellCount * maxCellCount

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

proc skipToBoard(data: string, pos: var int) =
  while pos < data.len and data[pos] != '.' and data[pos] != '#' and data[pos] != 'a' and data[pos] != 'b':
    pos += 1

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var seenStates = newSeq[int](maxStateCount)
var stateDistances = newSeq[int](maxStateCount)
var queueStates = newSeq[int](maxStateCount)
var caseNumber = 0

while true:
  let rowCount = nextInt(inputData, scanPos)
  let columnCount = nextInt(inputData, scanPos)
  if rowCount == 0 and columnCount == 0:
    break
  caseNumber += 1
  var board = ""
  for rowIndex in 0 .. rowCount - 1:
    skipToBoard(inputData, scanPos)
    for columnIndex in 0 .. columnCount - 1:
      board.add inputData[scanPos]
      scanPos += 1
  let cellCount = rowCount * columnCount
  var startPieceA = -1
  var startPieceB = -1
  for cellIndex in 0 .. cellCount - 1:
    if board[cellIndex] == 'a':
      startPieceA = cellIndex
    elif board[cellIndex] == 'b':
      startPieceB = cellIndex
  var neighbors = newSeq[int](cellCount * 5)
  for cellIndex in 0 .. cellCount - 1:
    let rowIndex = cellIndex div columnCount
    let columnIndex = cellIndex mod columnCount
    for moveIndex in 0 .. 4:
      var neighborRow = rowIndex
      var neighborColumn = columnIndex
      case moveIndex
      of 0:
        discard
      of 1:
        neighborRow -= 1
      of 2:
        neighborRow += 1
      of 3:
        neighborColumn -= 1
      of 4:
        neighborColumn += 1
      else:
        discard
      var neighborIndex = -1
      if neighborRow >= 0 and neighborRow < rowCount and neighborColumn >= 0 and neighborColumn < columnCount:
        let candidateIndex = neighborRow * columnCount + neighborColumn
        if board[candidateIndex] != '#':
          neighborIndex = candidateIndex
      neighbors[cellIndex * 5 + moveIndex] = neighborIndex
  let goalState = startPieceB * cellCount + startPieceA
  let startState = startPieceA * cellCount + startPieceB
  var queueHead = 0
  var queueTail = 0
  seenStates[startState] = caseNumber
  stateDistances[startState] = 0
  queueStates[queueTail] = startState
  queueTail += 1
  var answerMoves = -1
  while queueHead < queueTail:
    let currentState = queueStates[queueHead]
    queueHead += 1
    if currentState == goalState:
      answerMoves = stateDistances[currentState]
      break
    let pieceA = currentState div cellCount
    let pieceB = currentState mod cellCount
    for moveA in 0 .. 4:
      let nextA = neighbors[pieceA * 5 + moveA]
      if nextA < 0:
        continue
      for moveB in 0 .. 4:
        let nextB = neighbors[pieceB * 5 + moveB]
        if nextB < 0:
          continue
        if nextA == nextB:
          continue
        if nextA == pieceB and nextB == pieceA:
          continue
        let nextState = nextA * cellCount + nextB
        if seenStates[nextState] != caseNumber:
          seenStates[nextState] = caseNumber
          stateDistances[nextState] = stateDistances[currentState] + 1
          queueStates[queueTail] = nextState
          queueTail += 1
  if answerMoves < 0:
    appendOutput("IMPOSSIBLE")
  else:
    appendOutput($answerMoves)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
