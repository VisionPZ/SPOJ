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

proc isLetterCharacter(value: char): bool =
  return (value >= 'A' and value <= 'Z') or (value >= 'a' and value <= 'z')

var nodeCount = 0
var sourceNode = 0
var sinkNode = 0
var friendBase = 1
var groupBase = 1
var edgeTarget = newSeq[int]()
var edgeNext = newSeq[int]()
var edgeCapacity = newSeq[int]()
var baseCapacity = newSeq[int]()
var nodeHead = newSeq[int]()
var groupEdgeIndex = newSeq[int]()
var levelValues = newSeq[int]()
var cursorEdges = newSeq[int]()
var queueNodes = newSeq[int]()

proc addEdge(fromNode: int, toNode: int, capacityValue: int) =
  let forwardIndex = edgeTarget.len
  edgeTarget.add toNode
  edgeCapacity.add capacityValue
  edgeNext.add nodeHead[fromNode]
  nodeHead[fromNode] = forwardIndex
  edgeTarget.add fromNode
  edgeCapacity.add 0
  edgeNext.add nodeHead[toNode]
  nodeHead[toNode] = forwardIndex + 1

proc buildLevels(): bool =
  for nodeIndex in 0 .. nodeCount - 1:
    levelValues[nodeIndex] = -1
  var queueHead = 0
  var queueTail = 0
  levelValues[sourceNode] = 0
  queueNodes[queueTail] = sourceNode
  queueTail += 1
  while queueHead < queueTail:
    let currentNode = queueNodes[queueHead]
    queueHead += 1
    var edgeIndex = nodeHead[currentNode]
    while edgeIndex != -1:
      if edgeCapacity[edgeIndex] > 0 and levelValues[edgeTarget[edgeIndex]] < 0:
        levelValues[edgeTarget[edgeIndex]] = levelValues[currentNode] + 1
        queueNodes[queueTail] = edgeTarget[edgeIndex]
        queueTail += 1
      edgeIndex = edgeNext[edgeIndex]
  return levelValues[sinkNode] >= 0

proc pushFlow(atNode: int, availableFlow: int): int =
  if atNode == sinkNode:
    return availableFlow
  var pushedTotal = 0
  while cursorEdges[atNode] != -1:
    let edgeIndex = cursorEdges[atNode]
    cursorEdges[atNode] = edgeNext[edgeIndex]
    if edgeCapacity[edgeIndex] > 0 and levelValues[edgeTarget[edgeIndex]] == levelValues[atNode] + 1:
      let nextFlow = pushFlow(edgeTarget[edgeIndex], min(availableFlow - pushedTotal, edgeCapacity[edgeIndex]))
      if nextFlow > 0:
        edgeCapacity[edgeIndex] -= nextFlow
        edgeCapacity[edgeIndex xor 1] += nextFlow
        pushedTotal += nextFlow
        if pushedTotal == availableFlow:
          break
  return pushedTotal

proc canAssign(capacityLimit: int, friendCount: int, groupCount: int): bool =
  for edgeIndex in 0 .. edgeCapacity.len - 1:
    edgeCapacity[edgeIndex] = baseCapacity[edgeIndex]
  for groupIndex in 0 .. groupCount - 1:
    edgeCapacity[groupEdgeIndex[groupIndex]] = capacityLimit
  var totalFlow = 0
  while buildLevels():
    for nodeIndex in 0 .. nodeCount - 1:
      cursorEdges[nodeIndex] = nodeHead[nodeIndex]
    while true:
      let flowBlock = pushFlow(sourceNode, friendCount - totalFlow)
      if flowBlock == 0:
        break
      totalFlow += flowBlock
      if totalFlow == friendCount:
        return true
  return false

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while scanPos < inputData.len:
  let friendCount = nextInt(inputData, scanPos)
  let groupCount = nextInt(inputData, scanPos)
  if friendCount == 0 and groupCount == 0:
    break
  nodeCount = friendCount + groupCount + 2
  sourceNode = 0
  friendBase = 1
  groupBase = 1 + friendCount
  sinkNode = friendCount + groupCount + 1
  edgeTarget.setLen 0
  edgeNext.setLen 0
  edgeCapacity.setLen 0
  nodeHead = newSeq[int](nodeCount)
  for nodeIndex in 0 .. nodeCount - 1:
    nodeHead[nodeIndex] = -1
  groupEdgeIndex = newSeq[int](groupCount)
  for friendIndex in 0 .. friendCount - 1:
    addEdge(sourceNode, friendBase + friendIndex, 1)
  for groupIndex in 0 .. groupCount - 1:
    let forwardIndex = edgeTarget.len
    addEdge(groupBase + groupIndex, sinkNode, 1)
    groupEdgeIndex[groupIndex] = forwardIndex
  for friendIndex in 0 .. friendCount - 1:
    while scanPos < inputData.len and inputData[scanPos] != '\n':
      scanPos += 1
    if scanPos < inputData.len:
      scanPos += 1
    while scanPos < inputData.len and isLetterCharacter(inputData[scanPos]):
      scanPos += 1
    while scanPos < inputData.len:
      while scanPos < inputData.len and inputData[scanPos] == ' ':
        scanPos += 1
      if scanPos >= inputData.len or inputData[scanPos] == '\n':
        break
      let groupLabel = nextInt(inputData, scanPos)
      addEdge(friendBase + friendIndex, groupBase + groupLabel, 1)
  baseCapacity = newSeq[int](edgeCapacity.len)
  for edgeIndex in 0 .. edgeCapacity.len - 1:
    baseCapacity[edgeIndex] = edgeCapacity[edgeIndex]
  levelValues = newSeq[int](nodeCount)
  cursorEdges = newSeq[int](nodeCount)
  queueNodes = newSeq[int](nodeCount)
  var lowBound = (friendCount + groupCount - 1) div groupCount
  var highBound = friendCount
  while lowBound < highBound:
    let middleValue = (lowBound + highBound) div 2
    if canAssign(middleValue, friendCount, groupCount):
      highBound = middleValue
    else:
      lowBound = middleValue + 1
  appendOutput($lowBound)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
