const flushBlockBytes = 1 shl 17
const boardCellCount = 9
const winningLines = [7, 56, 448, 73, 146, 292, 273, 84]

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

proc nextBoardMask(data: string, pos: var int): int =
  while pos < data.len and data[pos] != '0' and data[pos] != '1':
    pos += 1
  var maskValue = 0
  var bitsRead = 0
  while pos < data.len and bitsRead < boardCellCount and (data[pos] == '0' or data[pos] == '1'):
    maskValue = maskValue * 2 + int(data[pos]) - 48
    pos += 1
    bitsRead += 1
  return maskValue

proc hasWinningLine(boardMask: int): bool =
  for lineMask in winningLines:
    if (boardMask and lineMask) == lineMask:
      return true
  return false

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var grundyValues = newSeq[int](1 shl boardCellCount)
var boardMask = (1 shl boardCellCount) - 1
while boardMask >= 0:
  if hasWinningLine(boardMask):
    grundyValues[boardMask] = 0
  else:
    var seenValues = 0
    for cellIndex in 0 .. boardCellCount - 1:
      if (boardMask and (1 shl cellIndex)) == 0:
        let nextMask = boardMask or (1 shl cellIndex)
        var nextValue = 0
        if not hasWinningLine(nextMask):
          nextValue = grundyValues[nextMask]
        seenValues = seenValues or (1 shl nextValue)
    var mexValue = 0
    while (seenValues and (1 shl mexValue)) != 0:
      mexValue += 1
    grundyValues[boardMask] = mexValue
  boardMask -= 1

let gameCount = nextInt(inputData, scanPos)
for gameIndex in 0 .. gameCount - 1:
  let boardCount = nextInt(inputData, scanPos)
  var combinedValue = 0
  for boardIndex in 0 .. boardCount - 1:
    let startMask = nextBoardMask(inputData, scanPos)
    combinedValue = combinedValue xor grundyValues[startMask]
  if combinedValue != 0:
    appendOutput("Kang")
  else:
    appendOutput("Kung")
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
