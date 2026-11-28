const flushBlockBytes = 1 shl 17
const unreachableValue = int64(1 shl 60)
const deltaX = [1, -1, 0, 0]
const deltaY = [0, 0, 1, -1]

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

var farmCount = 0
var farmX = newSeq[int](0)
var farmY = newSeq[int](0)
var farmCodes = newSeq[int64](0)

proc pointIsFarm(pointX, pointY: int): bool =
  let targetCode = (int64(pointX) shl 32) or int64(pointY)
  var lowIndex = 0
  var highIndex = farmCodes.len - 1
  while lowIndex <= highIndex:
    let middleIndex = (lowIndex + highIndex) div 2
    if farmCodes[middleIndex] == targetCode:
      return true
    elif farmCodes[middleIndex] < targetCode:
      lowIndex = middleIndex + 1
    else:
      highIndex = middleIndex - 1
  return false

proc inSegment(pointX, pointY, fromX, fromY, toX, toY: int): bool =
  if fromX == toX:
    return pointX == fromX and pointY > min(fromY, toY) and pointY < max(fromY, toY)
  elif fromY == toY:
    return pointY == fromY and pointX > min(fromX, toX) and pointX < max(fromX, toX)
  return false

var nodeX = newSeq[int](0)
var nodeY = newSeq[int](0)
var centerNodes = newSeq[int](0)

proc rightAnglePossible(firstNode, secondNode: int): bool =
  let startX = nodeX[firstNode]
  let startY = nodeY[firstNode]
  let endX = nodeX[secondNode]
  let endY = nodeY[secondNode]
  var verticalGood = true
  if startX != endX and startY != endY and pointIsFarm(startX, endY):
    verticalGood = false
  if verticalGood:
    for farmIndex in 0 .. farmCount - 1:
      if inSegment(farmX[farmIndex], farmY[farmIndex], startX, startY, startX, endY) or
         inSegment(farmX[farmIndex], farmY[farmIndex], startX, endY, endX, endY):
        verticalGood = false
        break
  if verticalGood:
    return true
  var horizontalGood = true
  if startX != endX and startY != endY and pointIsFarm(endX, startY):
    horizontalGood = false
  if horizontalGood:
    for farmIndex in 0 .. farmCount - 1:
      if inSegment(farmX[farmIndex], farmY[farmIndex], startX, startY, endX, startY) or
         inSegment(farmX[farmIndex], farmY[farmIndex], endX, startY, endX, endY):
        horizontalGood = false
        break
  return horizontalGood

var adjacency = newSeq[seq[int]](0)
var distanceValues = newSeq[int64](0)
var visitedNodes = newSeq[bool](0)

proc shortestLeg(startNode, targetNode: int): int64 =
  let nodeCount = nodeX.len
  for nodeIndex in 0 .. nodeCount - 1:
    distanceValues[nodeIndex] = unreachableValue
    visitedNodes[nodeIndex] = false
  for farmIndex in 0 .. farmCount - 1:
    if centerNodes[farmIndex] != startNode and centerNodes[farmIndex] != targetNode:
      visitedNodes[centerNodes[farmIndex]] = true
  distanceValues[startNode] = 0
  for stepIndex in 0 .. nodeCount - 1:
    var chosenNode = -1
    for nodeIndex in 0 .. nodeCount - 1:
      if not visitedNodes[nodeIndex]:
        if chosenNode == -1 or distanceValues[nodeIndex] < distanceValues[chosenNode]:
          chosenNode = nodeIndex
    if chosenNode == -1 or distanceValues[chosenNode] >= unreachableValue:
      return -1
    if chosenNode == targetNode:
      return distanceValues[chosenNode]
    visitedNodes[chosenNode] = true
    for edgeIndex in adjacency[chosenNode]:
      if not visitedNodes[edgeIndex]:
        let stepCost = int64(abs(nodeX[chosenNode] - nodeX[edgeIndex]) +
                             abs(nodeY[chosenNode] - nodeY[edgeIndex]))
        let candidate = distanceValues[chosenNode] + stepCost
        if candidate < distanceValues[edgeIndex]:
          distanceValues[edgeIndex] = candidate
  return -1

farmCount = nextInt(inputData, scanPos)
farmX = newSeq[int](farmCount)
farmY = newSeq[int](farmCount)
for farmIndex in 0 .. farmCount - 1:
  farmX[farmIndex] = nextInt(inputData, scanPos)
  farmY[farmIndex] = nextInt(inputData, scanPos)
  farmCodes.add((int64(farmX[farmIndex]) shl 32) or int64(farmY[farmIndex]))
for sortIndex in 1 .. farmCodes.len - 1:
  let keyCode = farmCodes[sortIndex]
  var holeIndex = sortIndex
  while holeIndex > 0 and farmCodes[holeIndex - 1] > keyCode:
    farmCodes[holeIndex] = farmCodes[holeIndex - 1]
    holeIndex -= 1
  farmCodes[holeIndex] = keyCode
centerNodes = newSeq[int](farmCount)
for farmIndex in 0 .. farmCount - 1:
  centerNodes[farmIndex] = nodeX.len
  nodeX.add farmX[farmIndex]
  nodeY.add farmY[farmIndex]
  for direction in 0 .. 3:
    let neighborX = farmX[farmIndex] + deltaX[direction]
    let neighborY = farmY[farmIndex] + deltaY[direction]
    if not pointIsFarm(neighborX, neighborY):
      nodeX.add neighborX
      nodeY.add neighborY
let nodeCount = nodeX.len
adjacency = newSeq[seq[int]](nodeCount)
distanceValues = newSeq[int64](nodeCount)
visitedNodes = newSeq[bool](nodeCount)
for firstNode in 0 .. nodeCount - 1:
  for secondNode in firstNode + 1 .. nodeCount - 1:
    if rightAnglePossible(firstNode, secondNode):
      adjacency[firstNode].add secondNode
      adjacency[secondNode].add firstNode
var totalDistance = int64(0)
var routePossible = true
for legIndex in 0 .. farmCount - 1:
  let nextFarm = (legIndex + 1) mod farmCount
  let legDistance = shortestLeg(centerNodes[legIndex], centerNodes[nextFarm])
  if legDistance < 0:
    routePossible = false
    break
  totalDistance += legDistance
if routePossible:
  appendOutput($totalDistance)
else:
  appendOutput("-1")
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
