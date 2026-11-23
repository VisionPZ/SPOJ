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
  scanPos = 0

proc nextInt(input: string, pos: var int): int =
  while pos < input.len and (input[pos] < '0' or input[pos] > '9') and input[pos] != '-':
    inc pos
  var sign = 1
  if pos < input.len and input[pos] == '-':
    sign = -1
    inc pos
  var value = 0
  while pos < input.len and input[pos] >= '0' and input[pos] <= '9':
    value = value * 10 + (int(input[pos]) - 48)
    inc pos
  result = sign * value

proc heapPush(node: SearchNode) =
  searchHeap.add(node)
  var childIndex = searchHeap.len - 1
  while childIndex > 0:
    let parentIndex = (childIndex - 1) div 2
    if searchHeap[childIndex].distance < searchHeap[parentIndex].distance:
      swap searchHeap[childIndex], searchHeap[parentIndex]
      childIndex = parentIndex
    else:
      break

proc heapPop(): SearchNode =
  result = searchHeap[0]
  let lastNode = searchHeap[searchHeap.len - 1]
  searchHeap.setLen(searchHeap.len - 1)
  if searchHeap.len > 0:
    searchHeap[0] = lastNode
    var parentIndex = 0
    while true:
      let leftIndex = parentIndex * 2 + 1
      if leftIndex >= searchHeap.len:
        break
      let rightIndex = leftIndex + 1
      var smallerIndex = leftIndex
      if rightIndex < searchHeap.len and searchHeap[rightIndex].distance < searchHeap[leftIndex].distance:
        smallerIndex = rightIndex
      if searchHeap[smallerIndex].distance < searchHeap[parentIndex].distance:
        swap searchHeap[smallerIndex], searchHeap[parentIndex]
        parentIndex = smallerIndex
      else:
        break

proc ensureColumn(columnIndex: int) =
  let pooledIndex = columnIndex + columnOffset
  if pooledIndex + 1 > columnCount:
    columnCount = pooledIndex + 1
  if columnPool[pooledIndex].generation != caseGeneration:
    for stateIndex in 0..<statesPerColumn:
      columnPool[pooledIndex].distances[stateIndex] = infinite
    columnPool[pooledIndex].remaining = reachablePerColumn
    columnPool[pooledIndex].generation = caseGeneration

proc initializeOrientations() =
  for topPosition in 0..<positionsCount:
    for frontPosition in 0..<positionsCount:
      let code = serializeGrid[topPosition][frontPosition]
      if code < 0:
        continue
      for move in 0..<moveCount:
        let newTopPosition = rotationGrid[move][topPosition]
        let newFrontPosition = rotationGrid[move][frontPosition]
        orientationNext[code][move] = serializeGrid[newTopPosition][newFrontPosition]
        orientationCostFace[code][move] = topFaceGrid[newTopPosition][newFrontPosition]
  initialOrientation = serializeGrid[0][1]

proc solveCase() =
  for face in 0..<positionsCount:
    faceCosts[face] = nextInt(inputData, scanPos)
  let startX = nextInt(inputData, scanPos)
  var startRow = nextInt(inputData, scanPos)
  let targetX = nextInt(inputData, scanPos)
  var targetRow = nextInt(inputData, scanPos)

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
    let columnIndex = node.columnIndex + columnOffset
    let stateIndex = orientationsCount * node.rowIndex + node.orientation
    if columnPool[columnIndex].distances[stateIndex] != infinite:
      continue
    columnPool[columnIndex].distances[stateIndex] = node.distance
    dec columnPool[columnIndex].remaining

    if columnPool[columnIndex].remaining == 0:
      if periodLength < 0:
        for earlierIndex in 0..<columnCount:
          if earlierIndex == columnIndex or columnPool[earlierIndex].remaining != 0:
            continue
          var delta = infinite
          var matches = true
          for state in 0..<statesPerColumn:
            let currentDistance = columnPool[columnIndex].distances[state]
            if currentDistance == infinite:
              continue
            let earlierDistance = columnPool[earlierIndex].distances[state]
            if earlierDistance == infinite:
              matches = false
              break
            if delta == infinite:
              delta = currentDistance - earlierDistance
            elif currentDistance - earlierDistance != delta:
              matches = false
              break
          if matches and delta > 0:
            periodLength = abs(node.columnIndex - (earlierIndex - columnOffset))
            leftEdge = min(node.columnIndex, earlierIndex - columnOffset)
            rightEdge = max(node.columnIndex, earlierIndex - columnOffset)
            periodDelta = delta
            for pendingIndex in leftEdge..rightEdge:
              ensureColumn(pendingIndex)
              if columnPool[pendingIndex + columnOffset].remaining > 0:
                inc pendingColumns
            break
      elif node.columnIndex >= leftEdge and node.columnIndex <= rightEdge:
        dec pendingColumns

      if periodLength > 0 and pendingColumns == 0 and horizontalDistance >= leftEdge:
        let blocks = (horizontalDistance - leftEdge) div periodLength
        let offset = (horizontalDistance - leftEdge) mod periodLength
        let baseColumn = columnPool[leftEdge + offset + columnOffset]
        var baseCost = infinite
        for orientation in 0..<orientationsCount:
          baseCost = min(baseCost, baseColumn.distances[orientationsCount * targetRow + orientation])
        answer = baseCost + blocks * periodDelta
        break

    for move in 0..<moveCount:
      var newColumn = node.columnIndex
      var newRow = node.rowIndex
      case move
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
      let newOrientation = orientationNext[node.orientation][move]
      let moveCost = faceCosts[orientationCostFace[node.orientation][move]]
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
let testCount = nextInt(inputData, scanPos)
for caseIndex in 0..<testCount:
  solveCase()
stdout.write outputBuffer
