const
  positionsCount = 6
  moveCount = 4
  orientationsCount = 24
  rowsCount = 4
  statesPerColumn = 96
  reachablePerColumn = 48
  columnOffset = 4
  maxColumns = 8192
  flushBlockBytes = 1 shl 18
  infinite = high(int) div 4

  serializeGrid: array[positionsCount, array[positionsCount, int]] = [
    [-1, 0, 1, 2, 3, -1],
    [4, -1, 5, 6, -1, 7],
    [8, 9, -1, -1, 10, 11],
    [12, 13, -1, -1, 14, 15],
    [16, -1, 17, 18, -1, 19],
    [-1, 20, 21, 22, 23, -1]
  ]

  topFaceGrid: array[positionsCount, array[positionsCount, int]] = [
    [-1, 0, 0, 0, 0, -1],
    [1, -1, 2, 3, -1, 4],
    [1, 3, -1, -1, 2, 4],
    [1, 2, -1, -1, 3, 4],
    [1, -1, 3, 2, -1, 4],
    [-1, 5, 5, 5, 5, -1]
  ]

  rotationGrid: array[moveCount, array[positionsCount, int]] = [
    [1, 5, 2, 3, 0, 4],
    [4, 0, 2, 3, 5, 1],
    [2, 1, 5, 0, 4, 3],
    [3, 1, 0, 5, 4, 2]
  ]

type
  Column = object
    distances: array[statesPerColumn, int]
    remaining: int
    generation: int

  SearchNode = object
    distance: int
    columnIndex: int
    rowIndex: int
    orientation: int

var
  orientationNext: array[orientationsCount, array[moveCount, int]]
  orientationCostFace: array[orientationsCount, array[moveCount, int]]
  initialOrientation = 0
  faceCosts: array[positionsCount, int]
  searchHeap: seq[SearchNode] = @[]
  columnPool: array[maxColumns, Column]
  columnCount = 0
  caseGeneration = 0
  inputData = ""
  outputBuffer = ""
  i = 0

proc nextInt(input: string, i: var int): int =
  while i < input.len and (input[i] < '0' or input[i] > '9') and input[i] != '-':
    inc i
  var sign = 1
  if i < input.len and input[i] == '-':
    sign = -1
    inc i
  var value = 0
  while i < input.len and input[i] >= '0' and input[i] <= '9':
    value = value * 10 + (int(input[i]) - 48)
    inc i
  result = sign * value

proc heapPush(node: SearchNode) =
  searchHeap.add(node)
  var j = searchHeap.len - 1
  while j > 0:
    let k = (j - 1) div 2
    if searchHeap[j].distance < searchHeap[k].distance:
      swap searchHeap[j], searchHeap[k]
      j = k
    else:
      break

proc heapPop(): SearchNode =
  result = searchHeap[0]
  let lastNode = searchHeap[searchHeap.len - 1]
  searchHeap.setLen(searchHeap.len - 1)
  if searchHeap.len > 0:
    searchHeap[0] = lastNode
    var k = 0
    while true:
      let i = k * 2 + 1
      if i >= searchHeap.len:
        break
      let j = i + 1
      var l = i
      if j < searchHeap.len and searchHeap[j].distance < searchHeap[i].distance:
        l = j
      if searchHeap[l].distance < searchHeap[k].distance:
        swap searchHeap[l], searchHeap[k]
        k = l
      else:
        break

proc ensureColumn(i: int) =
  let j = i + columnOffset
  if j + 1 > columnCount:
    columnCount = j + 1
  if columnPool[j].generation != caseGeneration:
    for k in 0..<statesPerColumn:
      columnPool[j].distances[k] = infinite
    columnPool[j].remaining = reachablePerColumn
    columnPool[j].generation = caseGeneration

proc initializeOrientations() =
  for i in 0..<positionsCount:
    for j in 0..<positionsCount:
      let code = serializeGrid[i][j]
      if code < 0:
        continue
      for k in 0..<moveCount:
        let newTopPosition = rotationGrid[k][i]
        let newFrontPosition = rotationGrid[k][j]
        orientationNext[code][k] = serializeGrid[newTopPosition][newFrontPosition]
        orientationCostFace[code][k] = topFaceGrid[newTopPosition][newFrontPosition]
  initialOrientation = serializeGrid[0][1]

proc solveCase() =
  for k in 0..<positionsCount:
    faceCosts[k] = nextInt(inputData, i)
  let startX = nextInt(inputData, i)
  var startRow = nextInt(inputData, i)
  let targetX = nextInt(inputData, i)
  var targetRow = nextInt(inputData, i)

  var horizontalDistance: int
  if targetX < startX:
    swap faceCosts[2], faceCosts[3]
    horizontalDistance = startX - targetX
  else:
    horizontalDistance = targetX - startX
  dec startRow
  dec targetRow

  searchHeap.setLen(0)
  columnCount = 0
  inc caseGeneration
  ensureColumn(0)
  searchHeap.add(SearchNode(distance: 0, columnIndex: 0, rowIndex: startRow, orientation: initialOrientation))

  var leftEdge = 0
  var rightEdge = 0
  var periodLength = -1
  var periodDelta = 0
  var pendingColumns = 0
  var answer = -1

  while searchHeap.len > 0:
    let node = heapPop()
    if node.columnIndex == horizontalDistance and node.rowIndex == targetRow:
      answer = node.distance
      break

    ensureColumn(node.columnIndex)
    let i = node.columnIndex + columnOffset
    let j = orientationsCount * node.rowIndex + node.orientation
    if columnPool[i].distances[j] != infinite:
      continue
    columnPool[i].distances[j] = node.distance
    dec columnPool[i].remaining

    if columnPool[i].remaining == 0:
      if periodLength < 0:
        for j in 0..<columnCount:
          if j == i or columnPool[j].remaining != 0:
            continue
          var delta = infinite
          var matches = true
          for l in 0..<statesPerColumn:
            let currentDistance = columnPool[i].distances[l]
            if currentDistance == infinite:
              continue
            let earlierDistance = columnPool[j].distances[l]
            if earlierDistance == infinite:
              matches = false
              break
            if delta == infinite:
              delta = currentDistance - earlierDistance
            elif currentDistance - earlierDistance != delta:
              matches = false
              break
          if matches and delta > 0:
            periodLength = abs(node.columnIndex - (j - columnOffset))
            leftEdge = min(node.columnIndex, j - columnOffset)
            rightEdge = max(node.columnIndex, j - columnOffset)
            periodDelta = delta
            for k in leftEdge..rightEdge:
              ensureColumn(k)
              if columnPool[k + columnOffset].remaining > 0:
                inc pendingColumns
            break
      elif node.columnIndex >= leftEdge and node.columnIndex <= rightEdge:
        dec pendingColumns

      if periodLength > 0 and pendingColumns == 0 and horizontalDistance >= leftEdge:
        let blocks = (horizontalDistance - leftEdge) div periodLength
        let offset = (horizontalDistance - leftEdge) mod periodLength
        let baseColumn = columnPool[leftEdge + offset + columnOffset]
        var baseCost = infinite
        for l in 0..<orientationsCount:
          baseCost = min(baseCost, baseColumn.distances[orientationsCount * targetRow + l])
        answer = baseCost + blocks * periodDelta
        break

    for k in 0..<moveCount:
      var newColumn = node.columnIndex
      var newRow = node.rowIndex
      case k
      of 0:
        if node.rowIndex == 0:
          continue
        dec newRow
      of 1:
        if node.rowIndex == rowsCount - 1:
          continue
        inc newRow
      of 2:
        if node.columnIndex <= -columnOffset:
          continue
        dec newColumn
      else:
        inc newColumn
      let newOrientation = orientationNext[node.orientation][k]
      let moveCost = faceCosts[orientationCostFace[node.orientation][k]]
      heapPush(SearchNode(distance: node.distance + moveCost, columnIndex: newColumn, rowIndex: newRow, orientation: newOrientation))

  outputBuffer.add($answer)
  outputBuffer.add('\n')
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen(0)

while not stdin.endOfFile():
  var line = ""
  if readLine(stdin, line):
    inputData.add(line)
    inputData.add('\n')

initializeOrientations()
let testCount = nextInt(inputData, i)
for j in 0..<testCount:
  solveCase()
stdout.write outputBuffer
