const flushBlockBytes = 1 shl 17
const decimalPlaces = 1000000
const absentCell = -1

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
let squareSize = nextInt(inputData, scanPos)
let cellCount = rowCount * columnCount
while scanPos < inputData.len and inputData[scanPos] <= ' ':
  scanPos += 1

var grid = newSeq[char](cellCount)
for rowIndex in 0 .. rowCount - 1:
  for columnIndex in 0 .. columnCount - 1:
    grid[rowIndex * columnCount + columnIndex] = inputData[scanPos]
    scanPos += 1
  while scanPos < inputData.len and inputData[scanPos] <= ' ':
    scanPos += 1

var componentOf = newSeq[int](cellCount)
var firstInComponent = newSeq[int](cellCount)
var nextInComponent = newSeq[int](cellCount)
var stackCells = newSeq[int](cellCount)
for index in 0 .. cellCount - 1:
  componentOf[index] = absentCell
  firstInComponent[index] = absentCell

proc pushNeighbor(neighborRow: int, neighborColumn: int, componentIndex: int, stackCells: var seq[int], stackSize: var int) =
  if neighborRow < 0 or neighborRow >= rowCount:
    return
  if neighborColumn < 0 or neighborColumn >= columnCount:
    return
  let neighbor = neighborRow * columnCount + neighborColumn
  if grid[neighbor] == 'X' and componentOf[neighbor] == absentCell:
    componentOf[neighbor] = componentIndex
    stackCells[stackSize] = neighbor
    stackSize += 1

var componentCount = 0
for cellIndex in 0 .. cellCount - 1:
  if grid[cellIndex] != 'X' or componentOf[cellIndex] != absentCell:
    continue
  let componentIndex = componentCount
  componentCount += 1
  componentOf[cellIndex] = componentIndex
  var stackSize = 1
  stackCells[0] = cellIndex
  while stackSize > 0:
    stackSize -= 1
    let cell = stackCells[stackSize]
    nextInComponent[cell] = firstInComponent[componentIndex]
    firstInComponent[componentIndex] = cell
    let rowIndex = cell div columnCount
    let columnIndex = cell mod columnCount
    pushNeighbor(rowIndex - 1, columnIndex, componentIndex, stackCells, stackSize)
    pushNeighbor(rowIndex + 1, columnIndex, componentIndex, stackCells, stackSize)
    pushNeighbor(rowIndex, columnIndex - 1, componentIndex, stackCells, stackSize)
    pushNeighbor(rowIndex, columnIndex + 1, componentIndex, stackCells, stackSize)

let topRows = rowCount - squareSize + 1
let topColumns = columnCount - squareSize + 1
var shipTotal: int64 = 0

if squareSize == 1:
  for cellIndex in 0 .. cellCount - 1:
    if grid[cellIndex] == 'X':
      shipTotal += 1
else:
  let treeSize = 4 * topColumns + 4
  var treeMinimum = newSeq[int](treeSize)
  var treeMinimumCount = newSeq[int](treeSize)
  var treeLazy = newSeq[int](treeSize)
  var segmentLength = newSeq[int](treeSize)

  proc buildSegments(node: int, left: int, right: int) =
    segmentLength[node] = right - left + 1
    treeMinimumCount[node] = segmentLength[node]
    if left < right:
      let middle = (left + right) div 2
      buildSegments(node * 2, left, middle)
      buildSegments(node * 2 + 1, middle + 1, right)

  buildSegments(1, 0, topColumns - 1)

  var visitStamp = newSeq[int](treeSize)
  var touchedNodes = newSeq[int](treeSize)
  var touchedCount = 0
  var eventStamp = newSeq[int](topRows + 1)
  var eventHead = newSeq[int](topRows + 1)
  var eventNext = newSeq[int](cellCount * 2 + 2)
  var eventLeft = newSeq[int](cellCount * 2 + 2)
  var eventRight = newSeq[int](cellCount * 2 + 2)
  var eventDelta = newSeq[int](cellCount * 2 + 2)
  var eventCount = 0

  proc markNode(node: int, stamp: int) =
    if visitStamp[node] != stamp:
      visitStamp[node] = stamp
      touchedNodes[touchedCount] = node
      touchedCount += 1
      treeMinimum[node] = 0
      treeMinimumCount[node] = segmentLength[node]
      treeLazy[node] = 0

  proc pushDown(node: int, stamp: int) =
    if treeLazy[node] != 0:
      let leftNode = node * 2
      let rightNode = node * 2 + 1
      markNode(leftNode, stamp)
      markNode(rightNode, stamp)
      treeMinimum[leftNode] += treeLazy[node]
      treeMinimum[rightNode] += treeLazy[node]
      treeLazy[leftNode] += treeLazy[node]
      treeLazy[rightNode] += treeLazy[node]
      treeLazy[node] = 0

  proc rangeAdd(node: int, left: int, right: int, queryLeft: int, queryRight: int, delta: int, stamp: int) =
    markNode(node, stamp)
    if queryLeft <= left and right <= queryRight:
      treeMinimum[node] += delta
      treeLazy[node] += delta
      return
    pushDown(node, stamp)
    let middle = (left + right) div 2
    let leftNode = node * 2
    let rightNode = node * 2 + 1
    if queryLeft <= middle:
      rangeAdd(leftNode, left, middle, queryLeft, queryRight, delta, stamp)
    if queryRight > middle:
      rangeAdd(rightNode, middle + 1, right, queryLeft, queryRight, delta, stamp)
    markNode(leftNode, stamp)
    markNode(rightNode, stamp)
    if treeMinimum[leftNode] < treeMinimum[rightNode]:
      treeMinimum[node] = treeMinimum[leftNode]
      treeMinimumCount[node] = treeMinimumCount[leftNode]
    elif treeMinimum[leftNode] > treeMinimum[rightNode]:
      treeMinimum[node] = treeMinimum[rightNode]
      treeMinimumCount[node] = treeMinimumCount[rightNode]
    else:
      treeMinimum[node] = treeMinimum[leftNode]
      treeMinimumCount[node] = treeMinimumCount[leftNode] + treeMinimumCount[rightNode]

  proc addEvent(eventRow: int, leftBound: int, rightBound: int, eventChange: int, stamp: int) =
    if eventStamp[eventRow] != stamp:
      eventStamp[eventRow] = stamp
      eventHead[eventRow] = absentCell
    eventNext[eventCount] = eventHead[eventRow]
    eventLeft[eventCount] = leftBound
    eventRight[eventCount] = rightBound
    eventDelta[eventCount] = eventChange
    eventHead[eventRow] = eventCount
    eventCount += 1

  for componentIndex in 0 .. componentCount - 1:
    let stamp = componentIndex + 1
    eventCount = 0
    touchedCount = 0
    markNode(1, stamp)
    var cell = firstInComponent[componentIndex]
    while cell != absentCell:
      let rowIndex = cell div columnCount
      let columnIndex = cell mod columnCount
      let firstRow = max(0, rowIndex - squareSize + 1)
      let lastRow = min(rowIndex, topRows - 1)
      let firstColumn = max(0, columnIndex - squareSize + 1)
      let lastColumn = min(columnIndex, topColumns - 1)
      addEvent(firstRow, firstColumn, lastColumn, 1, stamp)
      addEvent(lastRow + 1, firstColumn, lastColumn, -1, stamp)
      cell = nextInComponent[cell]
    for topRow in 0 .. topRows - 1:
      var eventIndex = eventHead[topRow]
      if eventStamp[topRow] == stamp:
        while eventIndex != absentCell:
          rangeAdd(1, 0, topColumns - 1, eventLeft[eventIndex], eventRight[eventIndex], eventDelta[eventIndex], stamp)
          eventIndex = eventNext[eventIndex]
      let coveredColumns = if treeMinimum[1] > 0: segmentLength[1] else: segmentLength[1] - treeMinimumCount[1]
      shipTotal = shipTotal + int64(coveredColumns)

let squareCount = int64(rowCount - squareSize + 1) * int64(columnCount - squareSize + 1)
var wholePart = shipTotal div squareCount
let remainder = shipTotal mod squareCount
var fractionalPart = (2 * remainder * int64(decimalPlaces) + squareCount) div (2 * squareCount)
if fractionalPart >= int64(decimalPlaces):
  fractionalPart = 0
  wholePart += 1

appendOutput($wholePart)
appendOutput(".")
var digitDivisor = decimalPlaces div 10
while digitDivisor > 0:
  appendOutput($(fractionalPart div int64(digitDivisor) mod 10))
  digitDivisor = digitDivisor div 10
appendOutput("\n")
stdout.write outputBuffer
outputBuffer.setLen 0
