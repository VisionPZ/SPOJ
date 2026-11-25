import algorithm

const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextToken(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  result = ""
  while pos < data.len and data[pos] > ' ':
    result.add data[pos]
    pos += 1

proc hasNextToken(data: string, pos: int): bool =
  var checkPos = pos
  while checkPos < data.len:
    if data[checkPos] > ' ':
      return true
    checkPos += 1
  return false

proc decimalValue(token: string): int =
  result = 0
  for character in token:
    result = result * 10 + int(character) - 48

proc base64Value(token: string): int64 =
  result = 0
  for character in token:
    var digit = 0
    if character >= '0' and character <= '9':
      digit = int(character) - 48
    elif character >= 'A' and character <= 'Z':
      digit = int(character) - 65 + 10
    elif character >= 'a' and character <= 'z':
      digit = int(character) - 97 + 36
    elif character == '+':
      digit = 62
    else:
      digit = 63
    result = result * 64 + int64(digit)

var sourceCount = 0
var parentLabels = newSeq[int](0)
var edgeLengths = newSeq[int64](0)

proc parentNodeOf(nodeIndex: int): int =
  let label = parentLabels[nodeIndex]
  if label == -1:
    return -1
  return sourceCount + label

var eventTimes = newSeq[int64](0)
var eventNodes = newSeq[int](0)

proc eventLess(leftIndex: int, rightIndex: int): bool =
  if eventTimes[leftIndex] < eventTimes[rightIndex]:
    return true
  if eventTimes[leftIndex] > eventTimes[rightIndex]:
    return false
  return eventNodes[leftIndex] < eventNodes[rightIndex]

proc swapEvent(leftIndex: int, rightIndex: int) =
  let savedTime = eventTimes[leftIndex]
  let savedNode = eventNodes[leftIndex]
  eventTimes[leftIndex] = eventTimes[rightIndex]
  eventNodes[leftIndex] = eventNodes[rightIndex]
  eventTimes[rightIndex] = savedTime
  eventNodes[rightIndex] = savedNode

proc siftUpEvent(startIndex: int) =
  var childIndex = startIndex
  while childIndex > 0:
    let parentIndex = (childIndex - 1) div 2
    if eventLess(childIndex, parentIndex):
      swapEvent(childIndex, parentIndex)
      childIndex = parentIndex
    else:
      break

proc siftDownEvent(startIndex: int) =
  var parentIndex = startIndex
  while true:
    let leftIndex = parentIndex * 2 + 1
    if leftIndex >= eventTimes.len:
      break
    let rightIndex = leftIndex + 1
    var smallestIndex = leftIndex
    if rightIndex < eventTimes.len and eventLess(rightIndex, leftIndex):
      smallestIndex = rightIndex
    if eventLess(smallestIndex, parentIndex):
      swapEvent(parentIndex, smallestIndex)
      parentIndex = smallestIndex
    else:
      break

proc pushEvent(flipTime: int64, nodeIndex: int) =
  eventTimes.add flipTime
  eventNodes.add nodeIndex
  siftUpEvent(eventTimes.len - 1)

proc popEvent(flipTime: var int64, nodeIndex: var int) =
  flipTime = eventTimes[0]
  nodeIndex = eventNodes[0]
  let lastIndex = eventTimes.len - 1
  eventTimes[0] = eventTimes[lastIndex]
  eventNodes[0] = eventNodes[lastIndex]
  eventTimes.setLen(lastIndex)
  eventNodes.setLen(lastIndex)
  if eventTimes.len > 0:
    siftDownEvent(0)

var nodeStates = newSeq[int](0)
var activeChildren = newSeq[int](0)
var flowLengths = newSeq[int64](0)
var childLists = newSeq[seq[int]](0)
var sweepLength: int64 = 0
var longCount: int64 = 0

proc notifyParent(childNode: int)

proc notifyParent(childNode: int) =
  let parentNode = parentNodeOf(childNode)
  if parentNode == -1:
    return
  activeChildren[parentNode] -= 1
  if activeChildren[parentNode] == 0 and nodeStates[parentNode] == 0:
    var bestArrival: int64 = high(int64)
    for downstreamNode in childLists[parentNode]:
      let arriving = flowLengths[downstreamNode] + edgeLengths[downstreamNode]
      if arriving < bestArrival:
        bestArrival = arriving
    flowLengths[parentNode] = bestArrival
    let arrivingAtParent = bestArrival + edgeLengths[parentNode]
    if arrivingAtParent > sweepLength:
      nodeStates[parentNode] = 1
      longCount += 1
      pushEvent(arrivingAtParent, parentNode)
    else:
      nodeStates[parentNode] = 2
      notifyParent(parentNode)

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc solveRiverSystem() =
  let confluenceCount = parentLabels.len - sourceCount
  let nodeCount = sourceCount + confluenceCount
  childLists = newSeq[seq[int]](nodeCount)
  for nodeIndex in 0 .. nodeCount - 1:
    childLists[nodeIndex] = newSeq[int](0)
  for nodeIndex in 0 .. nodeCount - 1:
    let downstream = parentNodeOf(nodeIndex)
    if downstream != -1:
      childLists[downstream].add nodeIndex
  var distanceToSea = newSeq[int64](nodeCount)
  var pendingNodes = newSeq[int](0)
  for nodeIndex in 0 .. nodeCount - 1:
    if parentNodeOf(nodeIndex) == -1:
      distanceToSea[nodeIndex] = edgeLengths[nodeIndex]
      pendingNodes.add nodeIndex
  while pendingNodes.len > 0:
    let lastIndex = pendingNodes.len - 1
    let currentNode = pendingNodes[lastIndex]
    pendingNodes.setLen(lastIndex)
    for downstreamNode in childLists[currentNode]:
      distanceToSea[downstreamNode] = distanceToSea[currentNode] + edgeLengths[downstreamNode]
      pendingNodes.add downstreamNode
  nodeStates = newSeq[int](nodeCount)
  activeChildren = newSeq[int](nodeCount)
  flowLengths = newSeq[int64](nodeCount)
  for nodeIndex in 0 .. nodeCount - 1:
    if nodeIndex < sourceCount:
      nodeStates[nodeIndex] = 1
    else:
      nodeStates[nodeIndex] = 0
    activeChildren[nodeIndex] = childLists[nodeIndex].len
    flowLengths[nodeIndex] = 0
  eventTimes.setLen(0)
  eventNodes.setLen(0)
  for nodeIndex in 0 .. sourceCount - 1:
    pushEvent(edgeLengths[nodeIndex], nodeIndex)
  longCount = int64(sourceCount)
  var sourceOrder = newSeq[int](sourceCount)
  for nodeIndex in 0 .. sourceCount - 1:
    sourceOrder[nodeIndex] = nodeIndex
  sourceOrder.sort(proc(leftIndex: int, rightIndex: int): int =
    if distanceToSea[leftIndex] < distanceToSea[rightIndex]:
      return -1
    if distanceToSea[leftIndex] > distanceToSea[rightIndex]:
      return 1
    return 0)
  var ranks = newSeq[int64](sourceCount)
  var answerIndex = 0
  while answerIndex < sourceCount:
    let targetLength = distanceToSea[sourceOrder[answerIndex]]
    sweepLength = targetLength
    while eventTimes.len > 0 and eventTimes[0] <= targetLength:
      var flipTime: int64 = 0
      var flippedNode = 0
      popEvent(flipTime, flippedNode)
      if nodeStates[flippedNode] == 1:
        nodeStates[flippedNode] = 2
        longCount -= 1
        notifyParent(flippedNode)
    while answerIndex < sourceCount and distanceToSea[sourceOrder[answerIndex]] == targetLength:
      ranks[sourceOrder[answerIndex]] = longCount + 1
      answerIndex += 1
  for sourceIndex in 0 .. sourceCount - 1:
    appendOutput($(ranks[sourceIndex]))
    outputBuffer.add '\n'

proc readRiverSystem(): bool =
  if not hasNextToken(inputData, scanPos):
    return false
  let firstToken = nextToken(inputData, scanPos)
  let nextCountToken = nextToken(inputData, scanPos)
  sourceCount = decimalValue(firstToken)
  let confluenceCount = decimalValue(nextCountToken)
  let nodeCount = sourceCount + confluenceCount
  parentLabels = newSeq[int](nodeCount)
  edgeLengths = newSeq[int64](nodeCount)
  for nodeIndex in 0 .. nodeCount - 1:
    let downstreamToken = nextToken(inputData, scanPos)
    let distanceToken = nextToken(inputData, scanPos)
    let downstream = int(base64Value(downstreamToken))
    parentLabels[nodeIndex] = downstream - 1
    edgeLengths[nodeIndex] = base64Value(distanceToken)
  return true

while readRiverSystem():
  solveRiverSystem()
stdout.write outputBuffer
outputBuffer.setLen 0
