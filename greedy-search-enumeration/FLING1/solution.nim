import sets

const flushBlockBytes = 1 shl 17
const directionCount = 4

var rowCount = 0
var columnCount = 0
var visitedBoards: HashSet[string]
visitedBoards.init()

proc inBounds(rowIndex: int, columnIndex: int): bool =
  return rowIndex >= 0 and rowIndex < rowCount and
         columnIndex >= 0 and columnIndex < columnCount

proc solveBoard(board: var seq[char], remainingBalls: int): bool =
  if remainingBalls <= 1:
    return true
  var boardKey = ""
  for cell in board:
    boardKey.add cell
  if boardKey in visitedBoards:
    return false
  visitedBoards.incl boardKey
  for rowIndex in 0 .. rowCount - 1:
    for columnIndex in 0 .. columnCount - 1:
      let startIndex = rowIndex * columnCount + columnIndex
      if board[startIndex] != 'B':
        continue
      for directionIndex in 0 .. directionCount - 1:
        case directionIndex
        of 0:
          var neighborRow = rowIndex - 1
          var neighborColumn = columnIndex
          if not inBounds(neighborRow, neighborColumn):
            continue
          if board[neighborRow * columnCount + neighborColumn] != '.':
            continue
          var hitPositions = newSeq[int]()
          var scanRow = rowIndex - 2
          var scanColumn = columnIndex
          while inBounds(scanRow, scanColumn):
            if board[scanRow * columnCount + scanColumn] == 'B':
              hitPositions.add scanRow * columnCount + scanColumn
            scanRow -= 1
          if hitPositions.len == 0:
            continue
          var savedBoard = newSeq[char](board.len)
          for cellIndex in 0 .. board.len - 1:
            savedBoard[cellIndex] = board[cellIndex]
          board[startIndex] = '.'
          for hitIndex in hitPositions:
            board[hitIndex] = '.'
            board[hitIndex + columnCount] = 'B'
          if solveBoard(board, remainingBalls - 1):
            return true
          board = savedBoard
        of 1:
          var neighborRow = rowIndex
          var neighborColumn = columnIndex - 1
          if not inBounds(neighborRow, neighborColumn):
            continue
          if board[neighborRow * columnCount + neighborColumn] != '.':
            continue
          var hitPositions = newSeq[int]()
          var scanRow = rowIndex
          var scanColumn = columnIndex - 2
          while inBounds(scanRow, scanColumn):
            if board[scanRow * columnCount + scanColumn] == 'B':
              hitPositions.add scanRow * columnCount + scanColumn
            scanColumn -= 1
          if hitPositions.len == 0:
            continue
          var savedBoard = newSeq[char](board.len)
          for cellIndex in 0 .. board.len - 1:
            savedBoard[cellIndex] = board[cellIndex]
          board[startIndex] = '.'
          for hitIndex in hitPositions:
            board[hitIndex] = '.'
            board[hitIndex + 1] = 'B'
          if solveBoard(board, remainingBalls - 1):
            return true
          board = savedBoard
        of 2:
          var neighborRow = rowIndex
          var neighborColumn = columnIndex + 1
          if not inBounds(neighborRow, neighborColumn):
            continue
          if board[neighborRow * columnCount + neighborColumn] != '.':
            continue
          var hitPositions = newSeq[int]()
          var scanRow = rowIndex
          var scanColumn = columnIndex + 2
          while inBounds(scanRow, scanColumn):
            if board[scanRow * columnCount + scanColumn] == 'B':
              hitPositions.add scanRow * columnCount + scanColumn
            scanColumn += 1
          if hitPositions.len == 0:
            continue
          var savedBoard = newSeq[char](board.len)
          for cellIndex in 0 .. board.len - 1:
            savedBoard[cellIndex] = board[cellIndex]
          board[startIndex] = '.'
          for hitIndex in hitPositions:
            board[hitIndex] = '.'
            board[hitIndex - 1] = 'B'
          if solveBoard(board, remainingBalls - 1):
            return true
          board = savedBoard
        else:
          var neighborRow = rowIndex + 1
          var neighborColumn = columnIndex
          if not inBounds(neighborRow, neighborColumn):
            continue
          if board[neighborRow * columnCount + neighborColumn] != '.':
            continue
          var hitPositions = newSeq[int]()
          var scanRow = rowIndex + 2
          var scanColumn = columnIndex
          while inBounds(scanRow, scanColumn):
            if board[scanRow * columnCount + scanColumn] == 'B':
              hitPositions.add scanRow * columnCount + scanColumn
            scanRow += 1
          if hitPositions.len == 0:
            continue
          var savedBoard = newSeq[char](board.len)
          for cellIndex in 0 .. board.len - 1:
            savedBoard[cellIndex] = board[cellIndex]
          board[startIndex] = '.'
          for hitIndex in hitPositions:
            board[hitIndex] = '.'
            board[hitIndex - columnCount] = 'B'
          if solveBoard(board, remainingBalls - 1):
            return true
          board = savedBoard
  return false

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

proc nextBoardLine(data: string, pos: var int, width: int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  var lineText = ""
  while pos < data.len and data[pos] > ' ' and lineText.len < width:
    lineText.add data[pos]
    pos += 1
  return lineText

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  rowCount = nextInt(inputData, scanPos)
  columnCount = nextInt(inputData, scanPos)
  var board = newSeq[char](rowCount * columnCount)
  var ballCount = 0
  for rowIndex in 0 .. rowCount - 1:
    let boardLine = nextBoardLine(inputData, scanPos, columnCount)
    for columnIndex in 0 .. columnCount - 1:
      let cellIndex = rowIndex * columnCount + columnIndex
      board[cellIndex] = boardLine[columnIndex]
      if board[cellIndex] == 'B':
        ballCount += 1
  visitedBoards.init()
  if solveBoard(board, ballCount):
    appendOutput("Yes")
  else:
    appendOutput("No")
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
