import algorithm

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

proc ascending(left: int, right: int): int =
  if left < right:
    return -1
  if left > right:
    return 1
  return 0

proc lowerBound(values: seq[int], target: int): int =
  var low = 0
  var high = values.len
  while low < high:
    let middle = (low + high) div 2
    if values[middle] < target:
      low = middle + 1
    else:
      high = middle
  return low

proc uniqueSorted(values: seq[int]): seq[int] =
  var sortedValues = values
  sortedValues.sort(ascending)
  var uniqueValues = newSeq[int]()
  for value in sortedValues:
    if uniqueValues.len == 0 or uniqueValues[uniqueValues.len - 1] != value:
      uniqueValues.add value
  return uniqueValues

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let parkWidth = nextInt(inputData, scanPos)
  let parkHeight = nextInt(inputData, scanPos)
  let carpetCount = nextInt(inputData, scanPos)
  let pipeCount = nextInt(inputData, scanPos)
  var rawX = newSeq[int]()
  var rawY = newSeq[int]()
  rawX.add 0
  rawX.add parkWidth
  rawY.add 0
  rawY.add parkHeight
  var carpetX1 = newSeq[int](carpetCount)
  var carpetY1 = newSeq[int](carpetCount)
  var carpetX2 = newSeq[int](carpetCount)
  var carpetY2 = newSeq[int](carpetCount)
  for carpetIndex in 0 .. carpetCount - 1:
    carpetX1[carpetIndex] = nextInt(inputData, scanPos)
    carpetY1[carpetIndex] = nextInt(inputData, scanPos)
    carpetX2[carpetIndex] = nextInt(inputData, scanPos)
    carpetY2[carpetIndex] = nextInt(inputData, scanPos)
    rawX.add carpetX1[carpetIndex]
    rawX.add carpetX2[carpetIndex]
    rawY.add carpetY1[carpetIndex]
    rawY.add carpetY2[carpetIndex]
  let xCoordinates = uniqueSorted(rawX)
  let yCoordinates = uniqueSorted(rawY)
  let columns = xCoordinates.len - 1
  let rows = yCoordinates.len - 1
  var cellCovered = newSeq[bool](columns * rows)
  for carpetIndex in 0 .. carpetCount - 1:
    let firstColumn = lowerBound(xCoordinates, carpetX1[carpetIndex])
    let lastColumn = lowerBound(xCoordinates, carpetX2[carpetIndex]) - 1
    let firstRow = lowerBound(yCoordinates, carpetY1[carpetIndex])
    let lastRow = lowerBound(yCoordinates, carpetY2[carpetIndex]) - 1
    for column in firstColumn .. lastColumn:
      for row in firstRow .. lastRow:
        cellCovered[column * rows + row] = true
  var cellVisited = newSeq[bool](columns * rows)
  var componentAreas = newSeq[int]()
  for column in 0 .. columns - 1:
    for row in 0 .. rows - 1:
      let startCell = column * rows + row
      if cellVisited[startCell] or cellCovered[startCell]:
        continue
      cellVisited[startCell] = true
      var pending = newSeq[int]()
      pending.add startCell
      var componentArea: int64 = 0
      while pending.len > 0:
        let currentCell = pending[pending.len - 1]
        pending.setLen pending.len - 1
        let currentColumn = currentCell div rows
        let currentRow = currentCell mod rows
        let cellWidth = xCoordinates[currentColumn + 1] - xCoordinates[currentColumn]
        let cellHeight = yCoordinates[currentRow + 1] - yCoordinates[currentRow]
        componentArea = componentArea + int64(cellWidth) * int64(cellHeight)
        var neighborColumn = currentColumn - 1
        if neighborColumn >= 0:
          let neighborCell = neighborColumn * rows + currentRow
          if not cellVisited[neighborCell] and not cellCovered[neighborCell]:
            cellVisited[neighborCell] = true
            pending.add neighborCell
        neighborColumn = currentColumn + 1
        if neighborColumn < columns:
          let neighborCell = neighborColumn * rows + currentRow
          if not cellVisited[neighborCell] and not cellCovered[neighborCell]:
            cellVisited[neighborCell] = true
            pending.add neighborCell
        var neighborRow = currentRow - 1
        if neighborRow >= 0:
          let neighborCell = currentColumn * rows + neighborRow
          if not cellVisited[neighborCell] and not cellCovered[neighborCell]:
            cellVisited[neighborCell] = true
            pending.add neighborCell
        neighborRow = currentRow + 1
        if neighborRow < rows:
          let neighborCell = currentColumn * rows + neighborRow
          if not cellVisited[neighborCell] and not cellCovered[neighborCell]:
            cellVisited[neighborCell] = true
            pending.add neighborCell
      componentAreas.add int(componentArea)
  var bestTotal: int64 = 0
  var pipesLeft = pipeCount
  while pipesLeft > 0:
    var largestIndex = -1
    for areaIndex in 0 .. componentAreas.len - 1:
      if largestIndex < 0 or componentAreas[areaIndex] > componentAreas[largestIndex]:
        largestIndex = areaIndex
    if largestIndex < 0 or componentAreas[largestIndex] <= 0:
      break
    bestTotal = bestTotal + int64(componentAreas[largestIndex])
    componentAreas[largestIndex] = -1
    pipesLeft -= 1
  appendOutput($bestTotal)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
