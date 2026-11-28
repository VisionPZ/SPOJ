const flushBlockBytes = 1 shl 17

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

proc hasNextToken(data: string, pos: int): bool =
  var checkPos = pos
  while checkPos < data.len:
    if data[checkPos] >= '0' and data[checkPos] <= '9':
      return true
    checkPos += 1
  return false

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let rowCount = nextInt(inputData, scanPos)
let columnCount = nextInt(inputData, scanPos)
var groupSizes = newSeq[int]()
while hasNextToken(inputData, scanPos):
  groupSizes.add nextInt(inputData, scanPos)
var emptyRow = ""
for columnIndex in 0 .. columnCount - 1:
  emptyRow.add '0'
var seatGrid = newSeq[string](rowCount)
for rowIndex in 0 .. rowCount - 1:
  seatGrid[rowIndex] = emptyRow
var currentRow = 0
var nextColumn = 0
var firstFailedIndex = -1
for groupIndex in 0 .. groupSizes.len - 1:
  let groupSize = groupSizes[groupIndex]
  var placed = false
  while currentRow < rowCount:
    if nextColumn + groupSize <= columnCount:
      for columnOffset in 0 .. groupSize - 1:
        seatGrid[currentRow][nextColumn + columnOffset] = '1'
      nextColumn += groupSize + 1
      placed = true
      break
    currentRow += 2
    nextColumn = 0
  if not placed:
    firstFailedIndex = groupIndex
    break
appendOutput("Seats:")
var printRow = rowCount - 1
while printRow >= 0:
  appendOutput(seatGrid[printRow])
  printRow -= 1
if firstFailedIndex >= 0:
  appendOutput("Failed to seat:")
  for groupIndex in firstFailedIndex .. groupSizes.len - 1:
    appendOutput($groupSizes[groupIndex])
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
