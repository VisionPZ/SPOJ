import sets

const flushBlockBytes = 1 shl 17

type
  BoardState = tuple[cells: string, width: int]

var rowCount = 0
var columnCount = 0

proc stateKey(cells: string, width: int): string =
  return cells & "/" & $width

proc applyGravity(grid: var seq[char], width: int) =
  for columnIndex in 0 .. width - 1:
    var writeRow = rowCount - 1
    for rowIndex in countdown(rowCount - 1, 0):
      let cellIndex = rowIndex * width + columnIndex
      if grid[cellIndex] != '.':
        if writeRow != rowIndex:
          grid[writeRow * width + columnIndex] = grid[cellIndex]
          grid[cellIndex] = '.'
        writeRow -= 1

proc compactColumns(grid: var seq[char], width: var int) =
  var keptColumns = newSeq[int]()
  for columnIndex in 0 .. width - 1:
    var holdsBlock = false
    for rowIndex in 0 .. rowCount - 1:
      if grid[rowIndex * width + columnIndex] != '.':
        holdsBlock = true
    if holdsBlock:
      keptColumns.add columnIndex
  if keptColumns.len == width:
    return
  var compacted = ""
  for rowIndex in 0 .. rowCount - 1:
    for columnIndex in keptColumns:
      compacted.add grid[rowIndex * width + columnIndex]
  grid.setLen rowCount * keptColumns.len
  for cellIndex in 0 .. compacted.len - 1:
    grid[cellIndex] = compacted[cellIndex]
  width = keptColumns.len

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

proc nextBoardLine(data: string, pos: var int, width: int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  var lineText = ""
  while pos < data.len and data[pos] > ' ' and lineText.len < width:
    lineText.add data[pos]
    pos += 1
  return lineText

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc solveCase(initialCells: string): int =
  var visited: HashSet[string]
  visited.init()
  var queue = newSeq[BoardState]()
  var depths = newSeq[int]()
  queue.add((initialCells, columnCount))
  depths.add 0
  visited.incl stateKey(initialCells, columnCount)
  var headIndex = 0
  while headIndex < queue.len:
    let currentState = queue[headIndex]
    let currentDepth = depths[headIndex]
    headIndex += 1
    let width = currentState.width
    var grid = newSeq[char](currentState.cells.len)
    for cellIndex in 0 .. currentState.cells.len - 1:
      grid[cellIndex] = currentState.cells[cellIndex]
    var componentSeen = newSeq[bool](grid.len)
    for startIndex in 0 .. grid.len - 1:
      if grid[startIndex] == '.' or componentSeen[startIndex]:
        continue
      let componentColor = grid[startIndex]
      var stack = newSeq[int]()
      var members = newSeq[int]()
      stack.add startIndex
      componentSeen[startIndex] = true
      while stack.len > 0:
        let cellIndex = stack[stack.len - 1]
        stack.setLen stack.len - 1
        members.add cellIndex
        let rowIndex = cellIndex div width
        let columnIndex = cellIndex mod width
        if rowIndex > 0:
          let neighbor = cellIndex - width
          if grid[neighbor] == componentColor and not componentSeen[neighbor]:
            componentSeen[neighbor] = true
            stack.add neighbor
        if rowIndex < rowCount - 1:
          let neighbor = cellIndex + width
          if grid[neighbor] == componentColor and not componentSeen[neighbor]:
            componentSeen[neighbor] = true
            stack.add neighbor
        if columnIndex > 0:
          let neighbor = cellIndex - 1
          if grid[neighbor] == componentColor and not componentSeen[neighbor]:
            componentSeen[neighbor] = true
            stack.add neighbor
        if columnIndex < width - 1:
          let neighbor = cellIndex + 1
          if grid[neighbor] == componentColor and not componentSeen[neighbor]:
            componentSeen[neighbor] = true
            stack.add neighbor
      if members.len < 2:
        continue
      var nextGrid = newSeq[char](grid.len)
      for cellIndex in 0 .. grid.len - 1:
        nextGrid[cellIndex] = grid[cellIndex]
      for cellIndex in members:
        nextGrid[cellIndex] = '.'
      var nextWidth = width
      applyGravity(nextGrid, nextWidth)
      compactColumns(nextGrid, nextWidth)
      var nextCells = ""
      for cell in nextGrid:
        nextCells.add cell
      var cleared = true
      for cell in nextGrid:
        if cell != '.':
          cleared = false
      if cleared:
        return currentDepth + 1
      let nextKey = stateKey(nextCells, nextWidth)
      if not (nextKey in visited):
        visited.incl nextKey
        queue.add((nextCells, nextWidth))
        depths.add currentDepth + 1
  return -1

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  rowCount = nextInt(inputData, scanPos)
  columnCount = nextInt(inputData, scanPos)
  var initialCells = ""
  for rowIndex in 0 .. rowCount - 1:
    initialCells.add nextBoardLine(inputData, scanPos, columnCount)
  let answer = solveCase(initialCells)
  appendOutput($answer)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
