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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let rowCount = nextInt(inputData, scanPos)
let columnCount = nextInt(inputData, scanPos)
let fieldSize = rowCount * columnCount
var field = newSeq[char](fieldSize)
for cellIndex in 0 .. fieldSize - 1:
  while scanPos < inputData.len and inputData[scanPos] <= ' ':
    scanPos += 1
  field[cellIndex] = inputData[scanPos]
  scanPos += 1

var visitedCell = newSeq[bool](fieldSize)
var floodQueue = newSeq[int](fieldSize)
var survivingSheep = 0
var survivingWolves = 0

for startCell in 0 .. fieldSize - 1:
  if visitedCell[startCell] or field[startCell] == '#':
    continue
  var queueHead = 0
  var queueTail = 0
  floodQueue[queueTail] = startCell
  queueTail += 1
  visitedCell[startCell] = true
  var sectorSheep = 0
  var sectorWolves = 0
  var reachesBorder = false
  while queueHead < queueTail:
    let currentCell = floodQueue[queueHead]
    queueHead += 1
    let currentRow = currentCell div columnCount
    let currentColumn = currentCell mod columnCount
    if currentRow == 0 or currentRow == rowCount - 1 or
       currentColumn == 0 or currentColumn == columnCount - 1:
      reachesBorder = true
    if field[currentCell] == 'k':
      sectorSheep += 1
    elif field[currentCell] == 'v':
      sectorWolves += 1
    if currentRow > 0:
      let neighborCell = currentCell - columnCount
      if not visitedCell[neighborCell] and field[neighborCell] != '#':
        visitedCell[neighborCell] = true
        floodQueue[queueTail] = neighborCell
        queueTail += 1
    if currentRow < rowCount - 1:
      let neighborCell = currentCell + columnCount
      if not visitedCell[neighborCell] and field[neighborCell] != '#':
        visitedCell[neighborCell] = true
        floodQueue[queueTail] = neighborCell
        queueTail += 1
    if currentColumn > 0:
      let neighborCell = currentCell - 1
      if not visitedCell[neighborCell] and field[neighborCell] != '#':
        visitedCell[neighborCell] = true
        floodQueue[queueTail] = neighborCell
        queueTail += 1
    if currentColumn < columnCount - 1:
      let neighborCell = currentCell + 1
      if not visitedCell[neighborCell] and field[neighborCell] != '#':
        visitedCell[neighborCell] = true
        floodQueue[queueTail] = neighborCell
        queueTail += 1
  if reachesBorder:
    survivingSheep += sectorSheep
    survivingWolves += sectorWolves
  elif sectorSheep > sectorWolves:
    survivingSheep += sectorSheep
  else:
    survivingWolves += sectorWolves

appendOutput($survivingSheep & " " & $survivingWolves & "\n")
stdout.write outputBuffer
outputBuffer.setLen 0
