const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var pictureLines: seq[string] = @[]
var lineStart = 0
for index in 0 .. inputData.len - 1:
  if inputData[index] == '\n':
    var lineText = ""
    if index > lineStart:
      lineText = inputData[lineStart .. index - 1]
    if lineText.len > 0 and lineText[lineText.len - 1] == '\r':
      lineText.setLen lineText.len - 1
    pictureLines.add lineText
    lineStart = index + 1

proc findRoot(parent: var seq[int], node: int): int =
  var current = node
  while parent[current] != current:
    parent[current] = parent[parent[current]]
    current = parent[current]
  return current

proc joinNodes(parent: var seq[int], leftNode: int, rightNode: int) =
  let leftRoot = findRoot(parent, leftNode)
  let rightRoot = findRoot(parent, rightNode)
  if leftRoot != rightRoot:
    parent[rightRoot] = leftRoot

proc acceptsRight(cell: char): bool =
  result = cell == '-' or cell == '+' or cell == '=' or cell == 'o' or cell == '#' or
           cell == '0' or cell == '1'

proc acceptsLeft(cell: char): bool =
  result = cell == '-' or cell == '+' or cell == '=' or cell == 'o' or cell == '#' or
           (cell >= 'A' and cell <= 'Z')

proc acceptsDown(cell: char): bool =
  result = cell == '|' or cell == '+' or cell == 'x'

proc acceptsUp(cell: char): bool =
  result = cell == '|' or cell == '+' or cell == 'x'

proc isSeparator(line: string): bool =
  if line.len == 0:
    return false
  var stars = 0
  for index in 0 .. line.len - 1:
    if line[index] == '*':
      stars += 1
    elif line[index] != ' ':
      return false
  return stars > 0

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

type GateInfo = object
  gateType: char
  inputNodes: seq[int]
  outputNodes: seq[int]
  negateOutputs: seq[bool]

proc solvePicture(rows: seq[string]) =
  let rowCount = rows.len
  var columnCount = 0
  for rowIndex in 0 .. rowCount - 1:
    columnCount = max(columnCount, rows[rowIndex].len)
  var grid = newSeq[string](rowCount)
  for rowIndex in 0 .. rowCount - 1:
    grid[rowIndex] = rows[rowIndex]
    while grid[rowIndex].len < columnCount:
      grid[rowIndex].add ' '
  let cellCount = rowCount * columnCount
  var mainNodes = newSeq[int](cellCount)
  var crossNodes = newSeq[int](cellCount)
  var nextNode = 0
  for cellIndex in 0 .. cellCount - 1:
    mainNodes[cellIndex] = nextNode
    crossNodes[cellIndex] = nextNode
    nextNode += 1
    let rowIndex = cellIndex div columnCount
    let columnIndex = cellIndex mod columnCount
    if grid[rowIndex][columnIndex] == 'x':
      crossNodes[cellIndex] = nextNode
      nextNode += 1
  var parent = newSeq[int](nextNode)
  for nodeIndex in 0 .. nextNode - 1:
    parent[nodeIndex] = nodeIndex
  for rowIndex in 0 .. rowCount - 1:
    for columnIndex in 0 .. columnCount - 2:
      let leftIndex = rowIndex * columnCount + columnIndex
      let rightIndex = leftIndex + 1
      let leftCell = grid[rowIndex][columnIndex]
      let rightCell = grid[rowIndex][columnIndex + 1]
      if leftCell == '#' or rightCell == '#':
        continue
      if acceptsRight(leftCell) and acceptsLeft(rightCell):
        let leftNode = if leftCell == 'x': crossNodes[leftIndex] else: mainNodes[leftIndex]
        let rightNode = if rightCell == 'x': crossNodes[rightIndex] else: mainNodes[rightIndex]
        joinNodes(parent, leftNode, rightNode)
  for rowIndex in 0 .. rowCount - 2:
    for columnIndex in 0 .. columnCount - 1:
      let upperIndex = rowIndex * columnCount + columnIndex
      let lowerIndex = upperIndex + columnCount
      let upperCell = grid[rowIndex][columnIndex]
      let lowerCell = grid[rowIndex + 1][columnIndex]
      if upperCell == '#' or lowerCell == '#':
        continue
      if acceptsDown(upperCell) and acceptsUp(lowerCell):
        let upperNode = mainNodes[upperIndex]
        let lowerNode = mainNodes[lowerIndex]
        joinNodes(parent, upperNode, lowerNode)
  var gates: seq[GateInfo] = @[]
  var gateVisited = newSeq[bool](cellCount)
  for cellIndex in 0 .. cellCount - 1:
    let rowIndex = cellIndex div columnCount
    let columnIndex = cellIndex mod columnCount
    if grid[rowIndex][columnIndex] != '#' or gateVisited[cellIndex]:
      continue
    var gateCells: seq[int] = @[]
    var frontier: seq[int] = @[cellIndex]
    gateVisited[cellIndex] = true
    while frontier.len > 0:
      let currentIndex = frontier[frontier.len - 1]
      frontier.setLen frontier.len - 1
      gateCells.add currentIndex
      let currentRow = currentIndex div columnCount
      let currentColumn = currentIndex mod columnCount
      for direction in 0 .. 3:
        var nextRow = currentRow
        var nextColumn = currentColumn
        if direction == 0:
          nextRow -= 1
        elif direction == 1:
          nextRow += 1
        elif direction == 2:
          nextColumn -= 1
        else:
          nextColumn += 1
        if nextRow < 0 or nextRow >= rowCount or nextColumn < 0 or nextColumn >= columnCount:
          continue
        let nextIndex = nextRow * columnCount + nextColumn
        if gateVisited[nextIndex] or grid[nextRow][nextColumn] != '#':
          continue
        gateVisited[nextIndex] = true
        frontier.add nextIndex
    var minRow = rowCount
    var maxRow = -1
    var minCol = columnCount
    var maxCol = -1
    for gateCell in gateCells:
      let gateRow = gateCell div columnCount
      let gateColumn = gateCell mod columnCount
      minRow = min(minRow, gateRow)
      maxRow = max(maxRow, gateRow)
      minCol = min(minCol, gateColumn)
      maxCol = max(maxCol, gateColumn)
    var gateChar = '?'
    for innerRow in minRow + 1 .. maxRow - 1:
      for innerColumn in minCol + 1 .. maxCol - 1:
        let symbol = grid[innerRow][innerColumn]
        if symbol != ' ':
          gateChar = symbol
    var gateInfo: GateInfo
    gateInfo.gateType = gateChar
    gateInfo.inputNodes = @[]
    gateInfo.outputNodes = @[]
    gateInfo.negateOutputs = @[]
    for gateRow in minRow .. maxRow:
      if minCol > 0 and grid[gateRow][minCol - 1] == '=':
        let inputIndex = gateRow * columnCount + minCol - 1
        gateInfo.inputNodes.add mainNodes[inputIndex]
      if maxCol + 1 < columnCount:
        let outputChar = grid[gateRow][maxCol + 1]
        if outputChar == '=':
          let outputIndex = gateRow * columnCount + maxCol + 1
          gateInfo.outputNodes.add mainNodes[outputIndex]
          gateInfo.negateOutputs.add false
        elif outputChar == 'o' and maxCol + 2 < columnCount:
          let outputIndex = gateRow * columnCount + maxCol + 2
          gateInfo.outputNodes.add mainNodes[outputIndex]
          gateInfo.negateOutputs.add true
    gates.add gateInfo
  var known = newSeq[bool](nextNode)
  var values = newSeq[int](nextNode)
  for cellIndex in 0 .. cellCount - 1:
    let rowIndex = cellIndex div columnCount
    let columnIndex = cellIndex mod columnCount
    let symbol = grid[rowIndex][columnIndex]
    if symbol == '0' or symbol == '1':
      let root = findRoot(parent, mainNodes[cellIndex])
      known[root] = true
      values[root] = int(symbol) - 48
  var changed = true
  while changed:
    changed = false
    for gateInfo in gates:
      var allKnown = gateInfo.inputNodes.len > 0
      for inputNode in gateInfo.inputNodes:
        if not known[findRoot(parent, inputNode)]:
          allKnown = false
      if not allKnown:
        continue
      var ones = 0
      for inputNode in gateInfo.inputNodes:
        ones += values[findRoot(parent, inputNode)]
      var gateOutput = 0
      if gateInfo.gateType == '1':
        gateOutput = ones
        if gateOutput > 1:
          gateOutput = 1
      elif gateInfo.gateType == '&':
        gateOutput = 1
        if ones < gateInfo.inputNodes.len:
          gateOutput = 0
      elif gateInfo.gateType == '=':
        gateOutput = ones mod 2
      for outputPosition in 0 .. gateInfo.outputNodes.len - 1:
        let root = findRoot(parent, gateInfo.outputNodes[outputPosition])
        let desired = gateOutput xor (if gateInfo.negateOutputs[outputPosition]: 1 else: 0)
        if not known[root] or values[root] != desired:
          known[root] = true
          values[root] = desired
          changed = true
  var namedOutputs: seq[tuple[letter: char, node: int]] = @[]
  for cellIndex in 0 .. cellCount - 1:
    let rowIndex = cellIndex div columnCount
    let columnIndex = cellIndex mod columnCount
    let symbol = grid[rowIndex][columnIndex]
    if symbol >= 'A' and symbol <= 'Z':
      namedOutputs.add (symbol, mainNodes[cellIndex])
  for outputIndex in 0 .. namedOutputs.len - 1:
    for nextIndex in outputIndex + 1 .. namedOutputs.len - 1:
      if namedOutputs[nextIndex].letter < namedOutputs[outputIndex].letter:
        let held = namedOutputs[outputIndex]
        namedOutputs[outputIndex] = namedOutputs[nextIndex]
        namedOutputs[nextIndex] = held
  for namedOutput in namedOutputs:
    let root = findRoot(parent, namedOutput.node)
    appendOutput($namedOutput.letter & "=" & $values[root])
    outputBuffer.add '\n'
  outputBuffer.add '\n'

var activeRows: seq[string] = @[]
for lineText in pictureLines:
  if isSeparator(lineText):
    if activeRows.len > 0:
      solvePicture(activeRows)
      activeRows = @[]
    else:
      break
  else:
    activeRows.add lineText

stdout.write outputBuffer
outputBuffer.setLen 0
