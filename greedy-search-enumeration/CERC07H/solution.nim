const flushBlockBytes = 1 shl 17
const areaCount = 4
const subsetCount = 16
const infiniteCost = 1000000000

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

proc nextCell(data: string, pos: var int): char =
  while pos < data.len and (data[pos] == ' ' or data[pos] == '\n' or data[pos] == '\r' or data[pos] == '\t'):
    pos += 1
  let cell = data[pos]
  pos += 1
  return cell

proc areaBit(cell: char): int =
  if cell == 'A':
    return 1
  if cell == 'B':
    return 2
  if cell == 'C':
    return 4
  if cell == 'D':
    return 8
  return 0

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while true:
  let landSize = nextInt(inputData, scanPos)
  if landSize == 0:
    break
  let rowCount = 2 * landSize - 1
  var rowLengths = newSeq[int](rowCount)
  var rowOffsets = newSeq[int](rowCount)
  var rowStarts = newSeq[int](rowCount)
  var cellCount = 0
  for rowIndex in 0 .. rowCount - 1:
    rowLengths[rowIndex] = landSize + min(rowIndex, rowCount - 1 - rowIndex)
    if rowIndex < landSize:
      rowOffsets[rowIndex] = landSize - 1 - rowIndex
    else:
      rowOffsets[rowIndex] = rowIndex - landSize + 1
    rowStarts[rowIndex] = cellCount
    cellCount += rowLengths[rowIndex]
  var cellColumns = newSeq[int](cellCount)
  var cellCosts = newSeq[int](cellCount)
  var cellAreas = newSeq[int](cellCount)
  for rowIndex in 0 .. rowCount - 1:
    for positionInRow in 0 .. rowLengths[rowIndex] - 1:
      let cellIndex = rowStarts[rowIndex] + positionInRow
      cellColumns[cellIndex] = rowOffsets[rowIndex] + 2 * positionInRow
      let cell = nextCell(inputData, scanPos)
      cellAreas[cellIndex] = areaBit(cell)
      if cell == '.':
        cellCosts[cellIndex] = 1
      else:
        cellCosts[cellIndex] = 0
  proc findCell(rowIndex: int, columnValue: int): int =
    if rowIndex < 0 or rowIndex >= rowCount:
      return -1
    let difference = columnValue - rowOffsets[rowIndex]
    if difference < 0 or difference mod 2 != 0:
      return -1
    let positionInRow = difference div 2
    if positionInRow >= rowLengths[rowIndex]:
      return -1
    return rowStarts[rowIndex] + positionInRow
  var neighborLists = newSeq[seq[int]](cellCount)
  for rowIndex in 0 .. rowCount - 1:
    for positionInRow in 0 .. rowLengths[rowIndex] - 1:
      let cellIndex = rowStarts[rowIndex] + positionInRow
      let columnValue = cellColumns[cellIndex]
      var neighborList: seq[int] = @[]
      let sameLeft = findCell(rowIndex, columnValue - 2)
      if sameLeft >= 0:
        neighborList.add sameLeft
      let sameRight = findCell(rowIndex, columnValue + 2)
      if sameRight >= 0:
        neighborList.add sameRight
      let aboveLeft = findCell(rowIndex - 1, columnValue - 1)
      if aboveLeft >= 0:
        neighborList.add aboveLeft
      let aboveRight = findCell(rowIndex - 1, columnValue + 1)
      if aboveRight >= 0:
        neighborList.add aboveRight
      let belowLeft = findCell(rowIndex + 1, columnValue - 1)
      if belowLeft >= 0:
        neighborList.add belowLeft
      let belowRight = findCell(rowIndex + 1, columnValue + 1)
      if belowRight >= 0:
        neighborList.add belowRight
      neighborLists[cellIndex] = neighborList
  var distances = newSeq[int](subsetCount * cellCount)
  for stateIndex in 0 .. subsetCount * cellCount - 1:
    distances[stateIndex] = infiniteCost
  for areaIndex in 0 .. areaCount - 1:
    let areaMask = 1 shl areaIndex
    for cellIndex in 0 .. cellCount - 1:
      if (cellAreas[cellIndex] and areaMask) != 0:
        distances[areaMask * cellCount + cellIndex] = 0
  for subsetMask in 1 .. subsetCount - 1:
    var firstPart = (subsetMask - 1) and subsetMask
    while firstPart > 0:
      let secondPart = subsetMask xor firstPart
      for cellIndex in 0 .. cellCount - 1:
        let firstCost = distances[firstPart * cellCount + cellIndex]
        let secondCost = distances[secondPart * cellCount + cellIndex]
        if firstCost >= infiniteCost or secondCost >= infiniteCost:
          continue
        let combinedCost = firstCost + secondCost - cellCosts[cellIndex]
        let targetIndex = subsetMask * cellCount + cellIndex
        if combinedCost < distances[targetIndex]:
          distances[targetIndex] = combinedCost
      firstPart = (firstPart - 1) and subsetMask
    var visited = newSeq[bool](cellCount)
    while true:
      var bestCell = -1
      var bestCost = infiniteCost
      for cellIndex in 0 .. cellCount - 1:
        let candidate = distances[subsetMask * cellCount + cellIndex]
        if not visited[cellIndex] and candidate < bestCost:
          bestCost = candidate
          bestCell = cellIndex
      if bestCell == -1:
        break
      visited[bestCell] = true
      for neighborIndex in neighborLists[bestCell]:
        if visited[neighborIndex]:
          continue
        let nextCost = bestCost + cellCosts[neighborIndex]
        let targetIndex = subsetMask * cellCount + neighborIndex
        if nextCost < distances[targetIndex]:
          distances[targetIndex] = nextCost
  var minimumParcels = infiniteCost
  for cellIndex in 0 .. cellCount - 1:
    let candidate = distances[(subsetCount - 1) * cellCount + cellIndex]
    if candidate < minimumParcels:
      minimumParcels = candidate
  appendOutput("You have to buy " & $minimumParcels & " parcels.")
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
