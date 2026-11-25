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

let roomCount = nextInt(inputData, scanPos)
var westEdges = newSeq[int](roomCount)
var southEdges = newSeq[int](roomCount)
var eastEdges = newSeq[int](roomCount)
var northEdges = newSeq[int](roomCount)
var allYValues = newSeq[int](2 * roomCount)
for roomIndex in 0 .. roomCount - 1:
  westEdges[roomIndex] = nextInt(inputData, scanPos)
  southEdges[roomIndex] = nextInt(inputData, scanPos)
  eastEdges[roomIndex] = nextInt(inputData, scanPos)
  northEdges[roomIndex] = nextInt(inputData, scanPos)
  allYValues[2 * roomIndex] = southEdges[roomIndex]
  allYValues[2 * roomIndex + 1] = northEdges[roomIndex]

proc compareNumbers(first: int, second: int): int =
  if first < second: return -1
  if first > second: return 1
  return 0

allYValues.sort(compareNumbers)
var distinctYValues = newSeq[int](0)
for value in allYValues:
  if distinctYValues.len == 0 or distinctYValues[distinctYValues.len - 1] != value:
    distinctYValues.add value

proc findValueIndex(values: seq[int], target: int): int =
  var lowIndex = 0
  var highIndex = values.len - 1
  while lowIndex <= highIndex:
    let middleIndex = (lowIndex + highIndex) div 2
    if values[middleIndex] < target:
      lowIndex = middleIndex + 1
    elif values[middleIndex] > target:
      highIndex = middleIndex - 1
    else:
      return middleIndex
  return -1

var yIndices = newSeq[int](roomCount)
for roomIndex in 0 .. roomCount - 1:
  yIndices[roomIndex] = findValueIndex(distinctYValues, southEdges[roomIndex])
  discard findValueIndex(distinctYValues, northEdges[roomIndex])

var leafCount = distinctYValues.len - 1
var treeSize = 1
while treeSize < leafCount:
  treeSize = treeSize * 2
var nodeStacks = newSeq[seq[int]](2 * treeSize)

proc pushRange(roomIndex: int) =
  var leftLeaf = treeSize + yIndices[roomIndex]
  var rightLeaf = treeSize + findValueIndex(distinctYValues, northEdges[roomIndex]) - 1
  while leftLeaf <= rightLeaf:
    if (leftLeaf and 1) == 1:
      nodeStacks[leftLeaf].add roomIndex
      leftLeaf += 1
    if (rightLeaf and 1) == 0:
      nodeStacks[rightLeaf].add roomIndex
      rightLeaf -= 1
    leftLeaf = leftLeaf div 2
    rightLeaf = rightLeaf div 2

proc popRange(roomIndex: int) =
  var leftLeaf = treeSize + yIndices[roomIndex]
  var rightLeaf = treeSize + findValueIndex(distinctYValues, northEdges[roomIndex]) - 1
  while leftLeaf <= rightLeaf:
    if (leftLeaf and 1) == 1:
      nodeStacks[leftLeaf].setLen(nodeStacks[leftLeaf].len - 1)
      leftLeaf += 1
    if (rightLeaf and 1) == 0:
      nodeStacks[rightLeaf].setLen(nodeStacks[rightLeaf].len - 1)
      rightLeaf -= 1
    leftLeaf = leftLeaf div 2
    rightLeaf = rightLeaf div 2

proc findContainer(roomIndex: int): int =
  var nodePos = treeSize + yIndices[roomIndex]
  var bestRoom = -1
  var bestWest = -1
  while nodePos >= 1:
    let stackAtNode = nodeStacks[nodePos]
    if stackAtNode.len > 0:
      let topRoom = stackAtNode[stackAtNode.len - 1]
      if westEdges[topRoom] > bestWest:
        bestWest = westEdges[topRoom]
        bestRoom = topRoom
    nodePos = nodePos div 2
  return bestRoom

var roomOrder = newSeq[int](roomCount)
for roomIndex in 0 .. roomCount - 1:
  roomOrder[roomIndex] = roomIndex

proc compareRooms(firstRoom: int, secondRoom: int): int =
  if westEdges[firstRoom] < westEdges[secondRoom]: return -1
  if westEdges[firstRoom] > westEdges[secondRoom]: return 1
  if firstRoom < secondRoom: return -1
  if firstRoom > secondRoom: return 1
  return 0

roomOrder.sort(compareRooms)
var removalOrder = newSeq[int](roomCount)
for roomIndex in 0 .. roomCount - 1:
  removalOrder[roomIndex] = roomIndex

proc compareRemovals(firstRoom: int, secondRoom: int): int =
  if eastEdges[firstRoom] < eastEdges[secondRoom]: return -1
  if eastEdges[firstRoom] > eastEdges[secondRoom]: return 1
  if firstRoom < secondRoom: return -1
  if firstRoom > secondRoom: return 1
  return 0

removalOrder.sort(compareRemovals)
var parents = newSeq[int](roomCount)
for roomIndex in 0 .. roomCount - 1:
  parents[roomIndex] = -1

var removalPos = 0
var groupStart = 0
while groupStart < roomCount:
  let sweepX = westEdges[roomOrder[groupStart]]
  while removalPos < roomCount and eastEdges[removalOrder[removalPos]] <= sweepX:
    popRange(removalOrder[removalPos])
    removalPos += 1
  var groupEnd = groupStart + 1
  while groupEnd < roomCount and westEdges[roomOrder[groupEnd]] == sweepX:
    groupEnd += 1
  for groupIndex in groupStart .. groupEnd - 1:
    let roomIndex = roomOrder[groupIndex]
    parents[roomIndex] = findContainer(roomIndex)
  for groupIndex in groupStart .. groupEnd - 1:
    pushRange(roomOrder[groupIndex])
  groupStart = groupEnd

for roomIndex in 0 .. roomCount - 1:
  appendOutput($parents[roomIndex])
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
