import algorithm

const flushBlockBytes = 1 shl 17
const columnSplit = 256

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-':
    pos += 1
  var negative = false
  if pos < data.len and data[pos] == '-':
    negative = true
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  if negative:
    return -value
  return value

proc compareIntegers(left: int, right: int): int =
  if left < right:
    return -1
  elif left > right:
    return 1
  return 0

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let pointCount = nextInt(inputData, scanPos)
var xCoordinates = newSeq[int](pointCount)
var yCoordinates = newSeq[int](pointCount)
for pointIndex in 0 .. pointCount - 1:
  xCoordinates[pointIndex] = nextInt(inputData, scanPos)
  yCoordinates[pointIndex] = nextInt(inputData, scanPos)

var sortedY = newSeq[int](pointCount)
for pointIndex in 0 .. pointCount - 1:
  sortedY[pointIndex] = yCoordinates[pointIndex]
sort(sortedY, compareIntegers)
var distinctY = 0
for pointIndex in 0 .. pointCount - 1:
  if pointIndex == 0 or sortedY[pointIndex] != sortedY[pointIndex - 1]:
    sortedY[distinctY] = sortedY[pointIndex]
    distinctY += 1
sortedY.setLen(distinctY)

var yIds = newSeq[int](pointCount)
for pointIndex in 0 .. pointCount - 1:
  var lowIndex = 0
  var highIndex = distinctY - 1
  while lowIndex <= highIndex:
    let middleIndex = (lowIndex + highIndex) div 2
    if sortedY[middleIndex] < yCoordinates[pointIndex]:
      lowIndex = middleIndex + 1
    else:
      highIndex = middleIndex - 1
  yIds[pointIndex] = lowIndex

var pointOrder = newSeq[int](pointCount)
for pointIndex in 0 .. pointCount - 1:
  pointOrder[pointIndex] = pointIndex

proc comparePoints(left: int, right: int): int =
  if xCoordinates[left] != xCoordinates[right]:
    return compareIntegers(xCoordinates[left], xCoordinates[right])
  return compareIntegers(yIds[left], yIds[right])

sort(pointOrder, comparePoints)

var columnYids = newSeq[int](pointCount)
var columnStarts = newSeq[int]()
var columnEnds = newSeq[int]()
var filled = 0
var readIndex = 0
while readIndex < pointCount:
  let currentX = xCoordinates[pointOrder[readIndex]]
  columnStarts.add(filled)
  while readIndex < pointCount and xCoordinates[pointOrder[readIndex]] == currentX:
    columnYids[filled] = yIds[pointOrder[readIndex]]
    filled += 1
    readIndex += 1
  columnEnds.add(filled)
let columnCount = columnStarts.len

var isLargeColumn = newSeq[bool](columnCount)
var largeColumns = newSeq[int]()
var pairTotal: int64 = 0
for columnIndex in 0 .. columnCount - 1:
  let columnSize = columnEnds[columnIndex] - columnStarts[columnIndex]
  if columnSize > columnSplit:
    isLargeColumn[columnIndex] = true
    largeColumns.add(columnIndex)
  else:
    pairTotal = pairTotal + int64(columnSize * (columnSize - 1) div 2)

var hashCapacity = 16
while int64(hashCapacity) < pairTotal * 2:
  hashCapacity = hashCapacity shl 1
var hashShift = 0
var capacityProbe = 1
while capacityProbe < hashCapacity:
  capacityProbe = capacityProbe shl 1
  hashShift += 1
const hashMultiplier = 11400714819323198485'u64
var hashKeys = newSeq[int64](hashCapacity)
var hashCounts = newSeq[int32](hashCapacity)
for slotIndex in 0 .. hashCapacity - 1:
  hashKeys[slotIndex] = -1

proc recordPair(pairKey: int64) =
  var slotIndex = int((cast[uint64](pairKey) * hashMultiplier) shr (64 - hashShift))
  while hashKeys[slotIndex] != -1 and hashKeys[slotIndex] != pairKey:
    slotIndex = (slotIndex + 1) and (hashCapacity - 1)
  if hashKeys[slotIndex] == -1:
    hashKeys[slotIndex] = pairKey
    hashCounts[slotIndex] = 1
  else:
    hashCounts[slotIndex] = hashCounts[slotIndex] + 1

for columnIndex in 0 .. columnCount - 1:
  if isLargeColumn[columnIndex]:
    continue
  for firstPos in columnStarts[columnIndex] .. columnEnds[columnIndex] - 1:
    for secondPos in firstPos + 1 .. columnEnds[columnIndex] - 1:
      let pairKey = int64(columnYids[firstPos]) * int64(distinctY) + int64(columnYids[secondPos])
      recordPair(pairKey)

var rectangleCount: int64 = 0
for slotIndex in 0 .. hashCapacity - 1:
  if hashKeys[slotIndex] != -1:
    let count = int64(hashCounts[slotIndex])
    rectangleCount = rectangleCount + count * (count - 1) div 2

var marks = newSeq[int](distinctY)
for yIndex in 0 .. distinctY - 1:
  marks[yIndex] = -1
for largePosition in 0 .. largeColumns.len - 1:
  let largeColumn = largeColumns[largePosition]
  let stamp = largeColumn + 1
  for yPos in columnStarts[largeColumn] .. columnEnds[largeColumn] - 1:
    marks[columnYids[yPos]] = stamp
  for otherColumn in 0 .. columnCount - 1:
    if otherColumn == largeColumn:
      continue
    if isLargeColumn[otherColumn] and otherColumn < largeColumn:
      continue
    var commonCount: int64 = 0
    for yPos in columnStarts[otherColumn] .. columnEnds[otherColumn] - 1:
      if marks[columnYids[yPos]] == stamp:
        commonCount += 1
    rectangleCount = rectangleCount + commonCount * (commonCount - 1) div 2

appendOutput($rectangleCount)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
