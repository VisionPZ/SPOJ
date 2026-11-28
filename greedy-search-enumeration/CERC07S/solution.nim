const flushBlockBytes = 1 shl 17
const firstDigitValue = 48
const emptyNode = 0

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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var nodeLeft: seq[int]
var nodeRight: seq[int]
var nodeParent: seq[int]
var nodeSize: seq[int]
var nodeReversed: seq[bool]
var splayRoot = emptyNode

proc refreshNodeSize(nodeIndex: int) =
  nodeSize[nodeIndex] = 1 + nodeSize[nodeLeft[nodeIndex]] + nodeSize[nodeRight[nodeIndex]]

proc pushDown(nodeIndex: int) =
  if nodeIndex != emptyNode and nodeReversed[nodeIndex]:
    let formerLeft = nodeLeft[nodeIndex]
    let formerRight = nodeRight[nodeIndex]
    nodeLeft[nodeIndex] = formerRight
    nodeRight[nodeIndex] = formerLeft
    if formerLeft != emptyNode:
      nodeReversed[formerLeft] = not nodeReversed[formerLeft]
    if formerRight != emptyNode:
      nodeReversed[formerRight] = not nodeReversed[formerRight]
    nodeReversed[nodeIndex] = false

proc rotateNode(nodeIndex: int) =
  let parentIndex = nodeParent[nodeIndex]
  let grandIndex = nodeParent[parentIndex]
  pushDown(parentIndex)
  pushDown(nodeIndex)
  if nodeLeft[parentIndex] == nodeIndex:
    nodeLeft[parentIndex] = nodeRight[nodeIndex]
    if nodeRight[nodeIndex] != emptyNode:
      nodeParent[nodeRight[nodeIndex]] = parentIndex
    nodeRight[nodeIndex] = parentIndex
  else:
    nodeRight[parentIndex] = nodeLeft[nodeIndex]
    if nodeLeft[nodeIndex] != emptyNode:
      nodeParent[nodeLeft[nodeIndex]] = parentIndex
    nodeLeft[nodeIndex] = parentIndex
  nodeParent[nodeIndex] = grandIndex
  nodeParent[parentIndex] = nodeIndex
  if grandIndex != emptyNode:
    if nodeLeft[grandIndex] == parentIndex:
      nodeLeft[grandIndex] = nodeIndex
    else:
      nodeRight[grandIndex] = nodeIndex
  refreshNodeSize(parentIndex)
  refreshNodeSize(nodeIndex)

proc splayNode(nodeIndex: int) =
  var pathNodes: seq[int] = @[]
  var cursor = nodeIndex
  while cursor != emptyNode:
    pathNodes.add cursor
    cursor = nodeParent[cursor]
  for pathIndex in countdown(pathNodes.len - 1, 0):
    pushDown(pathNodes[pathIndex])
  while nodeParent[nodeIndex] != emptyNode:
    let parentIndex = nodeParent[nodeIndex]
    let grandIndex = nodeParent[parentIndex]
    if grandIndex != emptyNode:
      if (nodeLeft[parentIndex] == nodeIndex) == (nodeLeft[grandIndex] == parentIndex):
        rotateNode(parentIndex)
      else:
        rotateNode(nodeIndex)
    rotateNode(nodeIndex)
  splayRoot = nodeIndex

proc splayUnderParent(nodeIndex: int, stopParent: int) =
  var pathNodes: seq[int] = @[]
  var cursor = nodeIndex
  while cursor != emptyNode and cursor != stopParent:
    pathNodes.add cursor
    cursor = nodeParent[cursor]
  for pathIndex in countdown(pathNodes.len - 1, 0):
    pushDown(pathNodes[pathIndex])
  while nodeParent[nodeIndex] != emptyNode and nodeParent[nodeIndex] != stopParent:
    let parentIndex = nodeParent[nodeIndex]
    let grandIndex = nodeParent[parentIndex]
    if grandIndex != emptyNode and grandIndex != stopParent:
      if (nodeLeft[parentIndex] == nodeIndex) == (nodeLeft[grandIndex] == parentIndex):
        rotateNode(parentIndex)
      else:
        rotateNode(nodeIndex)
    rotateNode(nodeIndex)

proc nodeAtRank(wantedRank: int): int =
  var remainingRank = wantedRank
  var cursor = splayRoot
  while cursor != emptyNode:
    pushDown(cursor)
    let leftSize = nodeSize[nodeLeft[cursor]]
    if remainingRank <= leftSize:
      cursor = nodeLeft[cursor]
    elif remainingRank == leftSize + 1:
      return cursor
    else:
      remainingRank = remainingRank - leftSize - 1
      cursor = nodeRight[cursor]
  return emptyNode

proc reverseInterval(leftRank: int, rightRank: int) =
  let totalNodes = nodeSize[splayRoot]
  if rightRank < totalNodes:
    if leftRank > 1:
      splayNode(nodeAtRank(leftRank - 1))
      let boundaryNode = nodeAtRank(rightRank + 1)
      splayUnderParent(boundaryNode, splayRoot)
      let middleNode = nodeLeft[boundaryNode]
      if middleNode != emptyNode:
        nodeReversed[middleNode] = not nodeReversed[middleNode]
    else:
      splayNode(nodeAtRank(rightRank + 1))
      let middleNode = nodeLeft[splayRoot]
      if middleNode != emptyNode:
        nodeReversed[middleNode] = not nodeReversed[middleNode]
  else:
    if leftRank > 1:
      splayNode(nodeAtRank(leftRank - 1))
      let middleNode = nodeRight[splayRoot]
      if middleNode != emptyNode:
        nodeReversed[middleNode] = not nodeReversed[middleNode]
    else:
      nodeReversed[splayRoot] = not nodeReversed[splayRoot]

proc buildTree(lowerIndex: int, upperIndex: int): int =
  if lowerIndex > upperIndex:
    return emptyNode
  let middleIndex = (lowerIndex + upperIndex) div 2
  nodeLeft[middleIndex] = buildTree(lowerIndex, middleIndex - 1)
  nodeRight[middleIndex] = buildTree(middleIndex + 1, upperIndex)
  if nodeLeft[middleIndex] != emptyNode:
    nodeParent[nodeLeft[middleIndex]] = middleIndex
  if nodeRight[middleIndex] != emptyNode:
    nodeParent[nodeRight[middleIndex]] = middleIndex
  refreshNodeSize(middleIndex)
  return middleIndex

proc quickSortKeys(keys: var seq[int64], lowerIndex: int, upperIndex: int) =
  var lowCursor = lowerIndex
  var highCursor = upperIndex
  let pivotValue = keys[(lowerIndex + upperIndex) div 2]
  while lowCursor <= highCursor:
    while keys[lowCursor] < pivotValue:
      lowCursor += 1
    while keys[highCursor] > pivotValue:
      highCursor -= 1
    if lowCursor <= highCursor:
      let swapValue = keys[lowCursor]
      keys[lowCursor] = keys[highCursor]
      keys[highCursor] = swapValue
      lowCursor += 1
      highCursor -= 1
  if lowerIndex < highCursor:
    quickSortKeys(keys, lowerIndex, highCursor)
  if lowCursor < upperIndex:
    quickSortKeys(keys, lowCursor, upperIndex)

while true:
  let sampleCount = nextInt(inputData, scanPos)
  if sampleCount == 0:
    break
  var heightValues = newSeq[int](sampleCount + 1)
  for sampleIndex in 1 .. sampleCount:
    heightValues[sampleIndex] = nextInt(inputData, scanPos)

  nodeLeft = newSeq[int](sampleCount + 1)
  nodeRight = newSeq[int](sampleCount + 1)
  nodeParent = newSeq[int](sampleCount + 1)
  nodeSize = newSeq[int](sampleCount + 1)
  nodeReversed = newSeq[bool](sampleCount + 1)
  splayRoot = buildTree(1, sampleCount)

  var sortedKeys = newSeq[int64](sampleCount)
  let keyStride = int64(sampleCount + 1)
  for sampleIndex in 1 .. sampleCount:
    sortedKeys[sampleIndex - 1] = int64(heightValues[sampleIndex]) * keyStride + int64(sampleIndex)
  quickSortKeys(sortedKeys, 0, sampleCount - 1)

  for stepIndex in 0 .. sampleCount - 1:
    let targetNode = int(sortedKeys[stepIndex] mod keyStride)
    splayNode(targetNode)
    let positionValue = nodeSize[nodeLeft[splayRoot]] + 1
    appendOutput($positionValue)
    if stepIndex == sampleCount - 1:
      outputBuffer.add '\n'
    else:
      outputBuffer.add ' '
    reverseInterval(stepIndex + 1, positionValue)

stdout.write outputBuffer
outputBuffer.setLen 0
