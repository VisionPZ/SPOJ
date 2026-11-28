const flushBlockBytes = 1 shl 17
const directionCount = 8

var rowSteps = [1, 1, 0, -1, -1, -1, 0, 1]
var columnSteps = [0, 1, 1, 1, 0, -1, -1, -1]
var knightRowSteps = [1, 2, 2, 1, -1, -2, -2, -1]
var knightColumnSteps = [2, 1, -1, -2, 2, 1, -1, -2]

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

var boardNumber = 0
while true:
  let rowCount = nextInt(inputData, scanPos)
  let columnCount = nextInt(inputData, scanPos)
  if rowCount == 0 and columnCount == 0:
    break
  boardNumber += 1
  var queenRows = newSeq[int]()
  var queenColumns = newSeq[int]()
  var knightRows = newSeq[int]()
  var knightColumns = newSeq[int]()
  var cellCount = rowCount * columnCount
  var occupied = newSeq[uint8](cellCount)
  var attacked = newSeq[uint8](cellCount)
  let queenCount = nextInt(inputData, scanPos)
  for pieceIndex in 0 .. queenCount - 1:
    let pieceRow = nextInt(inputData, scanPos) - 1
    let pieceColumn = nextInt(inputData, scanPos) - 1
    queenRows.add pieceRow
    queenColumns.add pieceColumn
    occupied[pieceRow * columnCount + pieceColumn] = 1
  let knightCount = nextInt(inputData, scanPos)
  for pieceIndex in 0 .. knightCount - 1:
    let pieceRow = nextInt(inputData, scanPos) - 1
    let pieceColumn = nextInt(inputData, scanPos) - 1
    knightRows.add pieceRow
    knightColumns.add pieceColumn
    occupied[pieceRow * columnCount + pieceColumn] = 1
  let pawnCount = nextInt(inputData, scanPos)
  for pieceIndex in 0 .. pawnCount - 1:
    let pieceRow = nextInt(inputData, scanPos) - 1
    let pieceColumn = nextInt(inputData, scanPos) - 1
    occupied[pieceRow * columnCount + pieceColumn] = 1
  for queenIndex in 0 .. queenRows.len - 1:
    let startRow = queenRows[queenIndex]
    let startColumn = queenColumns[queenIndex]
    for directionIndex in 0 .. directionCount - 1:
      var stepRow = startRow + rowSteps[directionIndex]
      var stepColumn = startColumn + columnSteps[directionIndex]
      while stepRow >= 0 and stepRow < rowCount and stepColumn >= 0 and stepColumn < columnCount:
        let cellIndex = stepRow * columnCount + stepColumn
        if occupied[cellIndex] != 0:
          break
        attacked[cellIndex] = 1
        stepRow = stepRow + rowSteps[directionIndex]
        stepColumn = stepColumn + columnSteps[directionIndex]
  for knightIndex in 0 .. knightRows.len - 1:
    let startRow = knightRows[knightIndex]
    let startColumn = knightColumns[knightIndex]
    for directionIndex in 0 .. directionCount - 1:
      let stepRow = startRow + knightRowSteps[directionIndex]
      let stepColumn = startColumn + knightColumnSteps[directionIndex]
      if stepRow >= 0 and stepRow < rowCount and stepColumn >= 0 and stepColumn < columnCount:
        attacked[stepRow * columnCount + stepColumn] = 1
  var safeCount: int64 = 0
  for cellIndex in 0 .. cellCount - 1:
    if occupied[cellIndex] == 0 and attacked[cellIndex] == 0:
      safeCount += 1
  appendOutput("Board ")
  appendOutput($boardNumber)
  appendOutput(" has ")
  appendOutput($safeCount)
  appendOutput(" safe squares.\n")

stdout.write outputBuffer
outputBuffer.setLen 0
