const flushBlockBytes = 1 shl 17
const unreachableDistance = 1000000000

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return value

var gridWidth = 0
var gridHeight = 0
var cellKinds: seq[int] = @[]
var firstTwo = 0
var secondTwo = 0
var firstThree = 0
var secondThree = 0
var blockedCells: uint64 = 0'u64
var lengthLimit = 0
var bestTotal = unreachableDistance

proc cellDistance(first: int, second: int): int =
  return abs(first div gridWidth - second div gridWidth) + abs(first mod gridWidth - second mod gridWidth)

proc shortestSecondPath(startCell: int, targetCell: int): int =
  var distances = newSeq[int](gridWidth * gridHeight)
  for index in 0 .. distances.high:
    distances[index] = -1
  var queue = newSeq[int](gridWidth * gridHeight)
  var queueHead = 0
  var queueTail = 0
  queue[queueTail] = startCell
  queueTail += 1
  distances[startCell] = 0
  while queueHead < queueTail:
    let current = queue[queueHead]
    queueHead += 1
    let row = current div gridWidth
    let column = current mod gridWidth
    for step in 0 .. 3:
      var nextRow = row
      var nextColumn = column
      if step == 0:
        nextRow -= 1
      elif step == 1:
        nextRow += 1
      elif step == 2:
        nextColumn -= 1
      else:
        nextColumn += 1
      if nextRow < 0 or nextRow >= gridHeight or nextColumn < 0 or nextColumn >= gridWidth:
        continue
      let nextCell = nextRow * gridWidth + nextColumn
      if cellKinds[nextCell] == 1:
        continue
      if cellKinds[nextCell] == 2:
        continue
      if (blockedCells and (1'u64 shl uint(nextCell))) != 0'u64:
        continue
      if distances[nextCell] >= 0:
        continue
      distances[nextCell] = distances[current] + 1
      if nextCell == targetCell:
        return distances[nextCell]
      queue[queueTail] = nextCell
      queueTail += 1
  return unreachableDistance

proc searchFirstPath(currentCell: int, walkedLength: int) =
  if bestTotal < unreachableDistance:
    return
  let remainingBound = cellDistance(currentCell, secondTwo) +
                       cellDistance(firstThree, secondThree)
  if walkedLength + remainingBound > lengthLimit:
    return
  if currentCell == secondTwo:
    let secondLength = shortestSecondPath(firstThree, secondThree)
    if secondLength < unreachableDistance and walkedLength + secondLength <= lengthLimit:
      bestTotal = walkedLength + secondLength
    return
  let row = currentCell div gridWidth
  let column = currentCell mod gridWidth
  for step in 0 .. 3:
    var nextRow = row
    var nextColumn = column
    if step == 0:
      nextRow -= 1
    elif step == 1:
      nextRow += 1
    elif step == 2:
      nextColumn -= 1
    else:
      nextColumn += 1
    if nextRow < 0 or nextRow >= gridHeight or nextColumn < 0 or nextColumn >= gridWidth:
      continue
    let nextCell = nextRow * gridWidth + nextColumn
    if cellKinds[nextCell] == 1 or cellKinds[nextCell] == 3:
      continue
    if (blockedCells and (1'u64 shl uint(nextCell))) != 0'u64:
      continue
    blockedCells = blockedCells or (1'u64 shl uint(nextCell))
    searchFirstPath(nextCell, walkedLength + 1)
    blockedCells = blockedCells and not (1'u64 shl uint(nextCell))

proc solveDataset(): int =
  let lowerBound = cellDistance(firstTwo, secondTwo) + cellDistance(firstThree, secondThree)
  let upperBound = 4 * gridWidth * gridHeight
  bestTotal = unreachableDistance
  for candidateLimit in lowerBound .. upperBound:
    lengthLimit = candidateLimit
    blockedCells = 1'u64 shl uint(firstTwo)
    searchFirstPath(firstTwo, 0)
    if bestTotal < unreachableDistance:
      return bestTotal
  return 0

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while true:
  gridHeight = nextInt(inputData, scanPos)
  gridWidth = nextInt(inputData, scanPos)
  if gridHeight == 0 and gridWidth == 0:
    break
  if scanPos > inputData.len:
    break
  cellKinds = newSeq[int](gridWidth * gridHeight)
  var twoCount = 0
  var threeCount = 0
  for rowIndex in 0 .. gridHeight - 1:
    for columnIndex in 0 .. gridWidth - 1:
      let cellValue = nextInt(inputData, scanPos)
      let cellIndex = rowIndex * gridWidth + columnIndex
      cellKinds[cellIndex] = cellValue
      if cellValue == 2:
        if twoCount == 0:
          firstTwo = cellIndex
        else:
          secondTwo = cellIndex
        twoCount += 1
      elif cellValue == 3:
        if threeCount == 0:
          firstThree = cellIndex
        else:
          secondThree = cellIndex
        threeCount += 1
  if twoCount != 2 or threeCount != 2:
    appendOutput("0")
    outputBuffer.add '\n'
  else:
    appendOutput($(solveDataset()))
    outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
