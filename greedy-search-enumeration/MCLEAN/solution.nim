const flushBlockBytes = 1 shl 17
const impassableCell = 'x'
const robotCell = 'o'
const dirtyCell = '*'
const unreachableCost = 1000000000

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
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  result = data[pos]
  pos += 1

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc fillDistances(grid: seq[char], gridWidth: int, gridHeight: int, startCell: int): seq[int] =
  let cellCount = grid.len
  result = newSeq[int](cellCount)
  for cellIndex in 0 .. cellCount - 1:
    result[cellIndex] = -1
  var queue = newSeq[int](cellCount)
  var queueHead = 0
  var queueTail = 0
  result[startCell] = 0
  queue[queueTail] = startCell
  queueTail = queueTail + 1
  while queueHead < queueTail:
    let currentCell = queue[queueHead]
    queueHead = queueHead + 1
    let currentX = currentCell mod gridWidth
    let currentY = currentCell div gridWidth
    let currentDistance = result[currentCell] + 1
    if currentX > 0:
      let neighbour = currentCell - 1
      if grid[neighbour] != impassableCell and result[neighbour] == -1:
        result[neighbour] = currentDistance
        queue[queueTail] = neighbour
        queueTail = queueTail + 1
    if currentX + 1 < gridWidth:
      let neighbour = currentCell + 1
      if grid[neighbour] != impassableCell and result[neighbour] == -1:
        result[neighbour] = currentDistance
        queue[queueTail] = neighbour
        queueTail = queueTail + 1
    if currentY > 0:
      let neighbour = currentCell - gridWidth
      if grid[neighbour] != impassableCell and result[neighbour] == -1:
        result[neighbour] = currentDistance
        queue[queueTail] = neighbour
        queueTail = queueTail + 1
    if currentY + 1 < gridHeight:
      let neighbour = currentCell + gridWidth
      if grid[neighbour] != impassableCell and result[neighbour] == -1:
        result[neighbour] = currentDistance
        queue[queueTail] = neighbour
        queueTail = queueTail + 1

while true:
  let gridWidth = nextInt(inputData, scanPos)
  let gridHeight = nextInt(inputData, scanPos)
  if gridWidth == 0 and gridHeight == 0:
    break
  let cellCount = gridWidth * gridHeight
  var grid = newSeq[char](cellCount)
  var robotPosition = 0
  var dirtyCells = newSeq[int](0)
  for rowIndex in 0 .. gridHeight - 1:
    for columnIndex in 0 .. gridWidth - 1:
      let cellIndex = rowIndex * gridWidth + columnIndex
      let cellSymbol = nextCell(inputData, scanPos)
      grid[cellIndex] = cellSymbol
      if cellSymbol == robotCell:
        robotPosition = cellIndex
      elif cellSymbol == dirtyCell:
        dirtyCells.add cellIndex
  let dirtyCount = dirtyCells.len
  let pointCount = dirtyCount + 1
  var distances = newSeq[seq[int]](pointCount)
  distances[0] = fillDistances(grid, gridWidth, gridHeight, robotPosition)
  for dirtyIndex in 0 .. dirtyCount - 1:
    distances[dirtyIndex + 1] = fillDistances(grid, gridWidth, gridHeight, dirtyCells[dirtyIndex])
  var unreachable = false
  for dirtyIndex in 0 .. dirtyCount - 1:
    if distances[0][dirtyCells[dirtyIndex]] < 0:
      unreachable = true
  if unreachable:
    appendOutput("-1")
    outputBuffer.add '\n'
    continue
  let stateLimit = dirtyCount + 1
  let stateCount = (1 shl dirtyCount) * stateLimit
  var bestCosts = newSeq[int](stateCount)
  for stateIndex in 0 .. stateCount - 1:
    bestCosts[stateIndex] = unreachableCost
  bestCosts[dirtyCount] = 0
  let fullMask = (1 shl dirtyCount) - 1
  for mask in 0 .. fullMask:
    for lastPoint in 0 .. dirtyCount:
      let currentCost = bestCosts[mask * stateLimit + lastPoint]
      if currentCost >= unreachableCost:
        continue
      var sourcePoint = lastPoint + 1
      if lastPoint == dirtyCount:
        sourcePoint = 0
      for nextDirty in 0 .. dirtyCount - 1:
        if (mask and (1 shl nextDirty)) != 0:
          continue
        let stepDistance = distances[sourcePoint][dirtyCells[nextDirty]]
        if stepDistance < 0:
          continue
        let nextMask = mask or (1 shl nextDirty)
        let nextCost = currentCost + stepDistance
        let nextState = nextMask * stateLimit + nextDirty
        if nextCost < bestCosts[nextState]:
          bestCosts[nextState] = nextCost
  var minimumMoves = unreachableCost
  if dirtyCount == 0:
    minimumMoves = 0
  for lastPoint in 0 .. dirtyCount - 1:
    let candidate = bestCosts[fullMask * stateLimit + lastPoint]
    if candidate < minimumMoves:
      minimumMoves = candidate
  if minimumMoves >= unreachableCost:
    appendOutput("-1")
  else:
    appendOutput($minimumMoves)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
