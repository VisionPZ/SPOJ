const flushBlockBytes = 1 shl 17
const boardSize = 1000
const boardCells = boardSize * boardSize
const rowOffsets = [1, 1, -1, -1, 2, 2, -2, -2]
const columnOffsets = [2, -2, 2, -2, 1, -1, 1, -1]

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

var distances = newSeq[int16](boardCells)
for cellIndex in 0 .. boardCells - 1:
  distances[cellIndex] = -1
var queue = newSeq[int](boardCells)
var queueHead = 0
var queueTail = 0
distances[0] = 0
queue[0] = 0
queueTail = 1
while queueHead < queueTail:
  let cellIndex = queue[queueHead]
  queueHead += 1
  let rowIndex = cellIndex div boardSize
  let columnIndex = cellIndex mod boardSize
  for moveIndex in 0 .. 7:
    let nextRow = rowIndex + rowOffsets[moveIndex]
    let nextColumn = columnIndex + columnOffsets[moveIndex]
    if nextRow >= 0 and nextRow < boardSize and nextColumn >= 0 and nextColumn < boardSize:
      let nextIndex = nextRow * boardSize + nextColumn
      if distances[nextIndex] < 0:
        distances[nextIndex] = distances[cellIndex] + int16(1)
        queue[queueTail] = nextIndex
        queueTail += 1

let queryCount = nextInt(inputData, scanPos)
for queryIndex in 0 .. queryCount - 1:
  let rowPosition = nextInt(inputData, scanPos)
  let columnPosition = nextInt(inputData, scanPos)
  let cellIndex = (rowPosition - 1) * boardSize + (columnPosition - 1)
  appendOutput($int(distances[cellIndex]))
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
