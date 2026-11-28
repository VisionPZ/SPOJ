const flushBlockBytes = 1 shl 17
const infiniteTime = 1000000000

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
var cells = newSeq[char](rowCount * columnCount)
for cellIndex in 0 .. rowCount * columnCount - 1:
  while scanPos < inputData.len and (inputData[scanPos] == '\n' or inputData[scanPos] == '\r' or inputData[scanPos] == ' '):
    scanPos += 1
  cells[cellIndex] = inputData[scanPos]
  scanPos += 1

var waterTimes = newSeq[int](rowCount * columnCount)
var hedgehogTimes = newSeq[int](rowCount * columnCount)
for cellIndex in 0 .. rowCount * columnCount - 1:
  waterTimes[cellIndex] = infiniteTime
  hedgehogTimes[cellIndex] = -1
var waterQueue = newSeq[int](rowCount * columnCount)
var hedgehogQueue = newSeq[int](rowCount * columnCount)
var waterHead = 0
var waterTail = 0
var hedgehogHead = 0
var hedgehogTail = 0
var startCell = -1
var denCell = -1
for cellIndex in 0 .. rowCount * columnCount - 1:
  if cells[cellIndex] == '*':
    waterTimes[cellIndex] = 0
    waterQueue[waterTail] = cellIndex
    waterTail += 1
  elif cells[cellIndex] == 'S':
    startCell = cellIndex
  elif cells[cellIndex] == 'D':
    denCell = cellIndex

hedgehogQueue[hedgehogTail] = startCell
hedgehogTail += 1
hedgehogTimes[startCell] = 0

proc rowOf(cellIndex: int): int =
  return cellIndex div columnCount

proc columnOf(cellIndex: int): int =
  return cellIndex mod columnCount

proc neighbourIndex(cellIndex: int, direction: int): int =
  let currentRow = rowOf(cellIndex)
  let currentColumn = columnOf(cellIndex)
  if direction == 0:
    if currentRow == 0:
      return -1
    return cellIndex - columnCount
  if direction == 1:
    if currentRow == rowCount - 1:
      return -1
    return cellIndex + columnCount
  if direction == 2:
    if currentColumn == 0:
      return -1
    return cellIndex - 1
  if currentColumn == columnCount - 1:
    return -1
  return cellIndex + 1

while waterHead < waterTail:
  let currentCell = waterQueue[waterHead]
  waterHead += 1
  let arrivalTime = waterTimes[currentCell]
  for direction in 0 .. 3:
    let neighbourCell = neighbourIndex(currentCell, direction)
    if neighbourCell == -1:
      continue
    if cells[neighbourCell] == 'X' or cells[neighbourCell] == 'D':
      continue
    if waterTimes[neighbourCell] != infiniteTime:
      continue
    waterTimes[neighbourCell] = arrivalTime + 1
    waterQueue[waterTail] = neighbourCell
    waterTail += 1

var escapeTime = -1
while hedgehogHead < hedgehogTail and escapeTime == -1:
  let currentCell = hedgehogQueue[hedgehogHead]
  hedgehogHead += 1
  let arrivalTime = hedgehogTimes[currentCell]
  for direction in 0 .. 3:
    let neighbourCell = neighbourIndex(currentCell, direction)
    if neighbourCell == -1:
      continue
    if cells[neighbourCell] == 'X':
      continue
    if hedgehogTimes[neighbourCell] != -1:
      continue
    if arrivalTime + 1 >= waterTimes[neighbourCell]:
      continue
    hedgehogTimes[neighbourCell] = arrivalTime + 1
    hedgehogQueue[hedgehogTail] = neighbourCell
    hedgehogTail += 1
    if neighbourCell == denCell:
      escapeTime = arrivalTime + 1
      break

if escapeTime == -1:
  appendOutput("KAKTUS")
else:
  appendOutput($escapeTime)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
