const flushBlockBytes = 1 shl 17
const ancestorLevels = 19

proc buildAncestors(ancestorTable: var seq[seq[int]], nodeValue, level: int) =
  for levelIndex in 1 .. level - 1:
    let previousAncestor = ancestorTable[levelIndex - 1][nodeValue]
    ancestorTable[levelIndex][nodeValue] = ancestorTable[levelIndex - 1][previousAncestor]

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

let friendCount = nextInt(inputData, scanPos)
let queryCount = nextInt(inputData, scanPos)

var edgeHead = newSeq[int](friendCount + 1)
for nodeValue in 0 .. friendCount:
  edgeHead[nodeValue] = -1
var edgeTarget = newSeq[int](2 * friendCount)
var edgeNext = newSeq[int](2 * friendCount)
var edgeCursor = 0
proc addEdge(firstNode, secondNode: int) =
  edgeTarget[edgeCursor] = secondNode
  edgeNext[edgeCursor] = edgeHead[firstNode]
  edgeHead[firstNode] = edgeCursor
  edgeCursor += 1
for edgeIndex in 0 .. friendCount - 2:
  let firstNode = nextInt(inputData, scanPos)
  let secondNode = nextInt(inputData, scanPos)
  addEdge(firstNode, secondNode)
  addEdge(secondNode, firstNode)

var parentNode = newSeq[int](friendCount + 1)
var depthValue = newSeq[int](friendCount + 1)
var entryTime = newSeq[int](friendCount + 1)
var exitTime = newSeq[int](friendCount + 1)
var ancestorTable = newSeq[seq[int]](ancestorLevels)
for levelIndex in 0 .. ancestorLevels - 1:
  ancestorTable[levelIndex] = newSeq[int](friendCount + 1)

var stackNodes = newSeq[int](friendCount)
var stackEdges = newSeq[int](friendCount)
var stackTop = 0
stackNodes[0] = 1
stackEdges[0] = edgeHead[1]
parentNode[1] = 0
depthValue[1] = 0
entryTime[1] = 0
var timer = 1
while stackTop >= 0:
  let nodeValue = stackNodes[stackTop]
  if stackEdges[stackTop] == -1:
    exitTime[nodeValue] = timer - 1
    stackTop -= 1
  else:
    let edgeIndex = stackEdges[stackTop]
    stackEdges[stackTop] = edgeNext[edgeIndex]
    let neighbor = edgeTarget[edgeIndex]
    if neighbor == parentNode[nodeValue]:
      continue
    parentNode[neighbor] = nodeValue
    depthValue[neighbor] = depthValue[nodeValue] + 1
    ancestorTable[0][neighbor] = nodeValue
    buildAncestors(ancestorTable, neighbor, ancestorLevels)
    entryTime[neighbor] = timer
    timer += 1
    stackTop += 1
    stackNodes[stackTop] = neighbor
    stackEdges[stackTop] = edgeHead[neighbor]

proc climbToDepth(nodeValue, targetDepth: int): int =
  var currentNode = nodeValue
  for levelIndex in countdown(ancestorLevels - 1, 0):
    let candidate = ancestorTable[levelIndex][currentNode]
    if candidate != 0 and depthValue[candidate] >= targetDepth:
      currentNode = candidate
  return currentNode

proc lowestCommonAncestor(firstNode, secondNode: int): int =
  var leftNode = firstNode
  var rightNode = secondNode
  if depthValue[leftNode] < depthValue[rightNode]:
    swap leftNode, rightNode
  leftNode = climbToDepth(leftNode, depthValue[rightNode])
  if leftNode == rightNode:
    return leftNode
  for levelIndex in countdown(ancestorLevels - 1, 0):
    if ancestorTable[levelIndex][leftNode] != ancestorTable[levelIndex][rightNode]:
      leftNode = ancestorTable[levelIndex][leftNode]
      rightNode = ancestorTable[levelIndex][rightNode]
  return parentNode[leftNode]

proc neighborToward(nodeValue, targetNode: int): int =
  let joiningNode = lowestCommonAncestor(nodeValue, targetNode)
  if nodeValue == joiningNode:
    return climbToDepth(targetNode, depthValue[nodeValue] + 1)
  return parentNode[nodeValue]

var eventXPos = newSeq[int]()
var eventYLow = newSeq[int]()
var eventYHigh = newSeq[int]()
var eventDelta = newSeq[int]()

proc addRectangle(xLow, xHigh, yLow, yHigh: int) =
  if xLow > xHigh or yLow > yHigh:
    return
  eventXPos.add xLow
  eventYLow.add yLow
  eventYHigh.add yHigh
  eventDelta.add 1
  eventXPos.add xHigh + 1
  eventYLow.add yLow
  eventYHigh.add yHigh
  eventDelta.add -1

proc addSideRectangles(sideALow, sideAHigh, sideBLow, sideBHigh: seq[int]) =
  for firstIndex in 0 .. sideALow.len - 1:
    for secondIndex in 0 .. sideBLow.len - 1:
      addRectangle(sideALow[firstIndex], sideAHigh[firstIndex], sideBLow[secondIndex], sideBHigh[secondIndex])

for firstLabel in 1 .. friendCount - 1:
  let secondLabel = firstLabel + 1
  let firstNeighbor = neighborToward(firstLabel, secondLabel)
  let secondNeighbor = neighborToward(secondLabel, firstLabel)
  var firstLow = newSeq[int]()
  var firstHigh = newSeq[int]()
  if parentNode[firstLabel] == firstNeighbor:
    firstLow.add entryTime[firstLabel]
    firstHigh.add exitTime[firstLabel]
  else:
    if entryTime[firstNeighbor] > 0:
      firstLow.add 0
      firstHigh.add entryTime[firstNeighbor] - 1
    if exitTime[firstNeighbor] < friendCount - 1:
      firstLow.add exitTime[firstNeighbor] + 1
      firstHigh.add friendCount - 1
  var secondLow = newSeq[int]()
  var secondHigh = newSeq[int]()
  if parentNode[secondLabel] == secondNeighbor:
    secondLow.add entryTime[secondLabel]
    secondHigh.add exitTime[secondLabel]
  else:
    if entryTime[secondNeighbor] > 0:
      secondLow.add 0
      secondHigh.add entryTime[secondNeighbor] - 1
    if exitTime[secondNeighbor] < friendCount - 1:
      secondLow.add exitTime[secondNeighbor] + 1
      secondHigh.add friendCount - 1
  addSideRectangles(firstLow, firstHigh, secondLow, secondHigh)
  addSideRectangles(secondLow, secondHigh, firstLow, firstHigh)

var queryFirst = newSeq[int](queryCount)
var querySecond = newSeq[int](queryCount)
var queryPathLength = newSeq[int](queryCount)
var queryHead = newSeq[int](friendCount)
for nodeValue in 0 .. friendCount - 1:
  queryHead[nodeValue] = -1
var queryNext = newSeq[int](queryCount)
for queryIndex in 0 .. queryCount - 1:
  let firstNode = nextInt(inputData, scanPos)
  let secondNode = nextInt(inputData, scanPos)
  queryFirst[queryIndex] = firstNode
  querySecond[queryIndex] = secondNode
  let joiningNode = lowestCommonAncestor(firstNode, secondNode)
  queryPathLength[queryIndex] = depthValue[firstNode] + depthValue[secondNode] - 2 * depthValue[joiningNode] + 1
  let xPosition = entryTime[firstNode]
  queryNext[queryIndex] = queryHead[xPosition]
  queryHead[xPosition] = queryIndex

var countByX = newSeq[int](friendCount + 1)
for eventIndex in 0 .. eventXPos.len - 1:
  countByX[eventXPos[eventIndex]] += 1
var offsetByX = newSeq[int](friendCount + 1)
var positionTotal = 0
for xPosition in 0 .. friendCount:
  offsetByX[xPosition] = positionTotal
  positionTotal += countByX[xPosition]
var sortedEvents = newSeq[int](eventXPos.len)
for eventIndex in 0 .. eventXPos.len - 1:
  let xPosition = eventXPos[eventIndex]
  sortedEvents[offsetByX[xPosition]] = eventIndex
  offsetByX[xPosition] += 1

var bitTree = newSeq[int](friendCount + 2)
proc bitAdd(position, delta: int) =
  var currentPosition = position + 1
  while currentPosition <= friendCount + 1:
    bitTree[currentPosition] += delta
    currentPosition += currentPosition and -currentPosition
proc bitSum(position: int): int =
  var total = 0
  var currentPosition = position + 1
  while currentPosition > 0:
    total += bitTree[currentPosition]
    currentPosition -= currentPosition and -currentPosition
  return total

var queryAnswers = newSeq[int](queryCount)
var eventCursor = 0
for xPosition in 0 .. friendCount - 1:
  while eventCursor < sortedEvents.len:
    let eventIndex = sortedEvents[eventCursor]
    if eventXPos[eventIndex] != xPosition:
      break
    bitAdd(eventYLow[eventIndex], eventDelta[eventIndex])
    bitAdd(eventYHigh[eventIndex] + 1, -eventDelta[eventIndex])
    eventCursor += 1
  var queryIndex = queryHead[xPosition]
  while queryIndex != -1:
    queryAnswers[queryIndex] = queryPathLength[queryIndex] - bitSum(entryTime[querySecond[queryIndex]])
    queryIndex = queryNext[queryIndex]

for queryIndex in 0 .. queryCount - 1:
  appendOutput($queryAnswers[queryIndex])
  appendOutput("\n")
stdout.write outputBuffer
outputBuffer.setLen 0
