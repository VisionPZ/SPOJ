const firstDigitValue = 48
const flushBlockBytes = 1 shl 17
const noPreviousNode = -1

proc nextInt(inputData: string, scanPos: var int): int =
  while scanPos < inputData.len and inputData[scanPos] <= ' ':
    scanPos += 1
  var parsedValue = 0
  while scanPos < inputData.len and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    parsedValue = parsedValue * 10 + int(inputData[scanPos]) - firstDigitValue
    scanPos += 1
  return parsedValue

proc farthestFrom(startNode: int, headIndex: seq[int], edgeTarget: seq[int], streetLength: seq[int], nextEdge: seq[int], previousNode: var seq[int], travelDistance: var seq[int64], nodeStack: var seq[int]): (int, int64) =
  var stackTop = 0
  nodeStack[stackTop] = startNode
  stackTop += 1
  previousNode[startNode] = noPreviousNode
  travelDistance[startNode] = 0
  var farthestNode = startNode
  var farthestDistance: int64 = 0
  while stackTop > 0:
    stackTop -= 1
    let currentNode = nodeStack[stackTop]
    if travelDistance[currentNode] > farthestDistance:
      farthestDistance = travelDistance[currentNode]
      farthestNode = currentNode
    var edgeCursor = headIndex[currentNode]
    while edgeCursor != noPreviousNode:
      let neighbor = edgeTarget[edgeCursor]
      if neighbor != previousNode[currentNode]:
        previousNode[neighbor] = currentNode
        travelDistance[neighbor] = travelDistance[currentNode] + int64(streetLength[edgeCursor])
        nodeStack[stackTop] = neighbor
        stackTop += 1
      edgeCursor = nextEdge[edgeCursor]
  return (farthestNode, farthestDistance)

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
let caseCount = nextInt(inputData, scanPos)
var headIndex: seq[int]
var edgeTarget: seq[int]
var streetLength: seq[int]
var nextEdge: seq[int]
var previousNode: seq[int]
var travelDistance: seq[int64]
var nodeStack: seq[int]
var outputBuffer = ""

for caseIndex in 0..<caseCount:
  let nodeCount = nextInt(inputData, scanPos)
  headIndex.setLen(nodeCount + 1)
  for place in 1..nodeCount:
    headIndex[place] = noPreviousNode
  let edgeSlotCount = 2 * (nodeCount - 1)
  edgeTarget.setLen(edgeSlotCount)
  streetLength.setLen(edgeSlotCount)
  nextEdge.setLen(edgeSlotCount)
  var edgeSlot = 0
  for streetOrdinal in 1..<nodeCount:
    let firstPlace = nextInt(inputData, scanPos)
    let secondPlace = nextInt(inputData, scanPos)
    let streetLengthValue = nextInt(inputData, scanPos)
    edgeTarget[edgeSlot] = secondPlace
    streetLength[edgeSlot] = streetLengthValue
    nextEdge[edgeSlot] = headIndex[firstPlace]
    headIndex[firstPlace] = edgeSlot
    edgeSlot += 1
    edgeTarget[edgeSlot] = firstPlace
    streetLength[edgeSlot] = streetLengthValue
    nextEdge[edgeSlot] = headIndex[secondPlace]
    headIndex[secondPlace] = edgeSlot
    edgeSlot += 1
  previousNode.setLen(nodeCount + 1)
  travelDistance.setLen(nodeCount + 1)
  nodeStack.setLen(nodeCount)
  let firstSweep = farthestFrom(1, headIndex, edgeTarget, streetLength, nextEdge, previousNode, travelDistance, nodeStack)
  let secondSweep = farthestFrom(firstSweep[0], headIndex, edgeTarget, streetLength, nextEdge, previousNode, travelDistance, nodeStack)
  outputBuffer.add $secondSweep[1]
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

stdout.write outputBuffer
outputBuffer.setLen 0
