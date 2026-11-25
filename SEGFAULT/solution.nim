const flushBlockBytes = 1 shl 17
const infDistance = 1 shl 28

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

proc tryVisit(neighborIndex: int, cellKinds: seq[uint8], nikolajTimes: seq[int],
              petarDistances: var seq[int], visitQueue: var seq[int],
              queueTail: var int, nextDistance: int, considerBlocks: bool) =
  if cellKinds[neighborIndex] == 1:
    return
  if petarDistances[neighborIndex] != infDistance:
    return
  if considerBlocks and nikolajTimes[neighborIndex] != infDistance and
     nextDistance >= nikolajTimes[neighborIndex]:
    return
  petarDistances[neighborIndex] = nextDistance
  visitQueue[queueTail] = neighborIndex
  queueTail += 1

proc bfsDistances(cellKinds: seq[uint8], nikolajTimes: seq[int],
                  petarDistances: var seq[int], visitQueue: var seq[int],
                  startIndex: int, rowCount: int, columnCount: int,
                  considerBlocks: bool): int =
  for cellIndex in 0 .. rowCount * columnCount - 1:
    petarDistances[cellIndex] = infDistance
  var queueHead = 0
  var queueTail = 0
  petarDistances[startIndex] = 0
  visitQueue[queueTail] = startIndex
  queueTail += 1
  while queueHead < queueTail:
    let currentIndex = visitQueue[queueHead]
    queueHead += 1
    let nextDistance = petarDistances[currentIndex] + 1
    let currentRow = currentIndex div columnCount
    let currentColumn = currentIndex mod columnCount
    if currentRow > 0:
      tryVisit(currentIndex - columnCount, cellKinds, nikolajTimes, petarDistances,
               visitQueue, queueTail, nextDistance, considerBlocks)
    if currentRow < rowCount - 1:
      tryVisit(currentIndex + columnCount, cellKinds, nikolajTimes, petarDistances,
               visitQueue, queueTail, nextDistance, considerBlocks)
    if currentColumn > 0:
      tryVisit(currentIndex - 1, cellKinds, nikolajTimes, petarDistances,
               visitQueue, queueTail, nextDistance, considerBlocks)
    if currentColumn < columnCount - 1:
      tryVisit(currentIndex + 1, cellKinds, nikolajTimes, petarDistances,
               visitQueue, queueTail, nextDistance, considerBlocks)
  return queueTail

let rowCount = nextInt(inputData, scanPos)
let columnCount = nextInt(inputData, scanPos)
while scanPos < inputData.len and inputData[scanPos] != '\n':
  scanPos += 1
scanPos += 1

var cellKinds = newSeq[uint8](rowCount * columnCount)
var startIndex = 0
for rowIndex in 0 .. rowCount - 1:
  for columnIndex in 0 .. columnCount - 1:
    let cellIndex = rowIndex * columnCount + columnIndex
    let cellChar = inputData[scanPos + columnIndex]
    if cellChar == '#':
      cellKinds[cellIndex] = 1
    elif cellChar == 'S':
      cellKinds[cellIndex] = 2
      startIndex = cellIndex
    else:
      cellKinds[cellIndex] = 0
  scanPos += columnCount + 1

var programFlags = newSeq[uint8](rowCount * columnCount)
let programCount = nextInt(inputData, scanPos)
for programIndex in 0 .. programCount - 1:
  let startRow = nextInt(inputData, scanPos) - 1
  let startColumn = nextInt(inputData, scanPos) - 1
  while scanPos < inputData.len and (inputData[scanPos] == ' ' or
        inputData[scanPos] == '\n' or inputData[scanPos] == '\r'):
    scanPos += 1
  let directionChar = inputData[scanPos]
  scanPos += 1
  let programIndexFlat = startRow * columnCount + startColumn
  if cellKinds[programIndexFlat] != 0:
    continue
  case directionChar
  of 'R':
    programFlags[programIndexFlat] = programFlags[programIndexFlat] or 1'u8
  of 'L':
    programFlags[programIndexFlat] = programFlags[programIndexFlat] or 2'u8
  of 'D':
    programFlags[programIndexFlat] = programFlags[programIndexFlat] or 4'u8
  of 'U':
    programFlags[programIndexFlat] = programFlags[programIndexFlat] or 8'u8
  else:
    discard

var nikolajTimes = newSeq[int](rowCount * columnCount)
for cellIndex in 0 .. rowCount * columnCount - 1:
  nikolajTimes[cellIndex] = infDistance

for rowIndex in 0 .. rowCount - 1:
  var bestStart = -1
  var columnIndex = 0
  while columnIndex < columnCount:
    let cellIndex = rowIndex * columnCount + columnIndex
    if cellKinds[cellIndex] != 0:
      bestStart = -1
    else:
      if (programFlags[cellIndex] and 1'u8) != 0:
        bestStart = columnIndex
      if bestStart >= 0:
        let arrival = columnIndex - bestStart + 1
        if arrival < nikolajTimes[cellIndex]:
          nikolajTimes[cellIndex] = arrival
    columnIndex += 1
  bestStart = columnCount
  columnIndex = columnCount - 1
  while columnIndex >= 0:
    let cellIndex = rowIndex * columnCount + columnIndex
    if cellKinds[cellIndex] != 0:
      bestStart = columnCount
    else:
      if (programFlags[cellIndex] and 2'u8) != 0:
        bestStart = columnIndex
      if bestStart < columnCount:
        let arrival = bestStart - columnIndex + 1
        if arrival < nikolajTimes[cellIndex]:
          nikolajTimes[cellIndex] = arrival
    columnIndex -= 1

for columnIndex in 0 .. columnCount - 1:
  var bestStart = -1
  var rowIndex = 0
  while rowIndex < rowCount:
    let cellIndex = rowIndex * columnCount + columnIndex
    if cellKinds[cellIndex] != 0:
      bestStart = -1
    else:
      if (programFlags[cellIndex] and 4'u8) != 0:
        bestStart = rowIndex
      if bestStart >= 0:
        let arrival = rowIndex - bestStart + 1
        if arrival < nikolajTimes[cellIndex]:
          nikolajTimes[cellIndex] = arrival
    rowIndex += 1
  bestStart = rowCount
  rowIndex = rowCount - 1
  while rowIndex >= 0:
    let cellIndex = rowIndex * columnCount + columnIndex
    if cellKinds[cellIndex] != 0:
      bestStart = rowCount
    else:
      if (programFlags[cellIndex] and 8'u8) != 0:
        bestStart = rowIndex
      if bestStart < rowCount:
        let arrival = bestStart - rowIndex + 1
        if arrival < nikolajTimes[cellIndex]:
          nikolajTimes[cellIndex] = arrival
    rowIndex -= 1

var petarDistances = newSeq[int](rowCount * columnCount)
var visitQueue = newSeq[int](rowCount * columnCount)
discard bfsDistances(cellKinds, nikolajTimes, petarDistances, visitQueue,
                     startIndex, rowCount, columnCount, false)
let capturedCount = bfsDistances(cellKinds, nikolajTimes, petarDistances, visitQueue,
                                 startIndex, rowCount, columnCount, true)
appendOutput($capturedCount)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
