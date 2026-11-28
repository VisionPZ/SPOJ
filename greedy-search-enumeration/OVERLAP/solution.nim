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

proc byValue(left: int, right: int): int =
  return left - right

proc upperBound(values: seq[int], limit: int): int =
  var low = 0
  var high = values.len
  while low < high:
    let middle = low + (high - low) div 2
    if values[middle] <= limit:
      low = middle + 1
    else:
      high = middle
  return low

proc lowerBound(values: seq[int], limit: int): int =
  var low = 0
  var high = values.len
  while low < high:
    let middle = low + (high - low) div 2
    if values[middle] < limit:
      low = middle + 1
    else:
      high = middle
  return low

proc bitAdd(tree: var seq[int], index: int, delta: int, treeSize: int) =
  var position = index
  while position <= treeSize:
    tree[position] += delta
    position += position and -position

proc bitSum(tree: seq[int], index: int): int =
  var position = index
  var total = 0
  while position > 0:
    total += tree[position]
    position -= position and -position
  return total

var firstRow = newSeq[int](0)
var firstColumn = newSeq[int](0)
var lastRow = newSeq[int](0)
var lastColumn = newSeq[int](0)
var overlapCounts = newSeq[int](0)

proc byRowAndColumn(left: int, right: int): int =
  if firstRow[left] != firstRow[right]:
    return firstRow[left] - firstRow[right]
  if firstColumn[left] != firstColumn[right]:
    return firstColumn[left] - firstColumn[right]
  return lastColumn[left] - lastColumn[right]

proc byColumnAndRow(left: int, right: int): int =
  if firstColumn[left] != firstColumn[right]:
    return firstColumn[left] - firstColumn[right]
  if firstRow[left] != firstRow[right]:
    return firstRow[left] - firstRow[right]
  return lastRow[left] - lastRow[right]

proc byRow(left: int, right: int): int =
  return firstRow[left] - firstRow[right]

proc byColumn(left: int, right: int): int =
  return firstColumn[left] - firstColumn[right]

var eventCoordinate = newSeq[int](0)
var eventValue = newSeq[int](0)
var eventDelta = newSeq[int](0)
var eventOrder = newSeq[int](0)

proc byEventCoordinate(left: int, right: int): int =
  return eventCoordinate[left] - eventCoordinate[right]

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let childCount = nextInt(inputData, scanPos)
let gridSize = nextInt(inputData, scanPos)
firstRow.setLen(childCount)
firstColumn.setLen(childCount)
lastRow.setLen(childCount)
lastColumn.setLen(childCount)
overlapCounts.setLen(childCount)
var horizontalWords = newSeq[int](0)
var verticalWords = newSeq[int](0)
for childIndex in 0 .. childCount - 1:
  let startRow = nextInt(inputData, scanPos)
  let startColumn = nextInt(inputData, scanPos)
  let endRow = nextInt(inputData, scanPos)
  let endColumn = nextInt(inputData, scanPos)
  firstRow[childIndex] = startRow
  lastRow[childIndex] = endRow
  if startRow == endRow:
    firstColumn[childIndex] = startColumn
    lastColumn[childIndex] = endColumn
    horizontalWords.add childIndex
  else:
    firstColumn[childIndex] = startColumn
    lastColumn[childIndex] = endColumn
    verticalWords.add childIndex

sort(horizontalWords, byRowAndColumn)
var groupStart = 0
while groupStart < horizontalWords.len:
  let groupRow = firstRow[horizontalWords[groupStart]]
  var groupEnd = groupStart
  while groupEnd < horizontalWords.len and firstRow[horizontalWords[groupEnd]] == groupRow:
    groupEnd += 1
  let groupLength = groupEnd - groupStart
  var starts = newSeq[int](groupLength)
  var ends = newSeq[int](groupLength)
  for offset in 0 .. groupLength - 1:
    let wordIndex = horizontalWords[groupStart + offset]
    starts[offset] = firstColumn[wordIndex]
    ends[offset] = lastColumn[wordIndex]
  sort(starts, byValue)
  sort(ends, byValue)
  for offset in 0 .. groupLength - 1:
    let wordIndex = horizontalWords[groupStart + offset]
    let wordStart = firstColumn[wordIndex]
    let wordEnd = lastColumn[wordIndex]
    overlapCounts[wordIndex] += upperBound(starts, wordEnd) - lowerBound(ends, wordStart) - 1
  groupStart = groupEnd

sort(verticalWords, byColumnAndRow)
groupStart = 0
while groupStart < verticalWords.len:
  let groupColumn = firstColumn[verticalWords[groupStart]]
  var groupEnd = groupStart
  while groupEnd < verticalWords.len and firstColumn[verticalWords[groupEnd]] == groupColumn:
    groupEnd += 1
  let groupLength = groupEnd - groupStart
  var starts = newSeq[int](groupLength)
  var ends = newSeq[int](groupLength)
  for offset in 0 .. groupLength - 1:
    let wordIndex = verticalWords[groupStart + offset]
    starts[offset] = firstRow[wordIndex]
    ends[offset] = lastRow[wordIndex]
  sort(starts, byValue)
  sort(ends, byValue)
  for offset in 0 .. groupLength - 1:
    let wordIndex = verticalWords[groupStart + offset]
    let wordStart = firstRow[wordIndex]
    let wordEnd = lastRow[wordIndex]
    overlapCounts[wordIndex] += upperBound(starts, wordEnd) - lowerBound(ends, wordStart) - 1
  groupStart = groupEnd

var horizontalByRow = newSeq[int](horizontalWords.len)
for index in 0 .. horizontalWords.len - 1:
  horizontalByRow[index] = horizontalWords[index]
sort(horizontalByRow, byRow)
eventCoordinate.setLen(0)
eventValue.setLen(0)
eventDelta.setLen(0)
for wordIndex in verticalWords:
  let column = firstColumn[wordIndex]
  eventCoordinate.add firstRow[wordIndex]
  eventValue.add column
  eventDelta.add 1
  if lastRow[wordIndex] + 1 <= gridSize:
    eventCoordinate.add lastRow[wordIndex] + 1
    eventValue.add column
    eventDelta.add -1
eventOrder.setLen(eventCoordinate.len)
for index in 0 .. eventOrder.len - 1:
  eventOrder[index] = index
sort(eventOrder, byEventCoordinate)
var columnTree = newSeq[int](gridSize + 1)
var eventPosition = 0
for wordIndex in horizontalByRow:
  let queryRow = firstRow[wordIndex]
  while eventPosition < eventOrder.len and eventCoordinate[eventOrder[eventPosition]] <= queryRow:
    let activeEvent = eventOrder[eventPosition]
    bitAdd(columnTree, eventValue[activeEvent], eventDelta[activeEvent], gridSize)
    eventPosition += 1
  let wordStart = firstColumn[wordIndex]
  let wordEnd = lastColumn[wordIndex]
  overlapCounts[wordIndex] += bitSum(columnTree, wordEnd) - bitSum(columnTree, wordStart - 1)

var verticalByColumn = newSeq[int](verticalWords.len)
for index in 0 .. verticalWords.len - 1:
  verticalByColumn[index] = verticalWords[index]
sort(verticalByColumn, byColumn)
eventCoordinate.setLen(0)
eventValue.setLen(0)
eventDelta.setLen(0)
for wordIndex in horizontalWords:
  let row = firstRow[wordIndex]
  eventCoordinate.add firstColumn[wordIndex]
  eventValue.add row
  eventDelta.add 1
  if lastColumn[wordIndex] + 1 <= gridSize:
    eventCoordinate.add lastColumn[wordIndex] + 1
    eventValue.add row
    eventDelta.add -1
eventOrder.setLen(eventCoordinate.len)
for index in 0 .. eventOrder.len - 1:
  eventOrder[index] = index
sort(eventOrder, byEventCoordinate)
var rowTree = newSeq[int](gridSize + 1)
eventPosition = 0
for wordIndex in verticalByColumn:
  let queryColumn = firstColumn[wordIndex]
  while eventPosition < eventOrder.len and eventCoordinate[eventOrder[eventPosition]] <= queryColumn:
    let activeEvent = eventOrder[eventPosition]
    bitAdd(rowTree, eventValue[activeEvent], eventDelta[activeEvent], gridSize)
    eventPosition += 1
  let wordStart = firstRow[wordIndex]
  let wordEnd = lastRow[wordIndex]
  overlapCounts[wordIndex] += bitSum(rowTree, wordEnd) - bitSum(rowTree, wordStart - 1)

for childIndex in 0 .. childCount - 1:
  appendOutput($overlapCounts[childIndex])
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
