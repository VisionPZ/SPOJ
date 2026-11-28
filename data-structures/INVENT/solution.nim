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

type TreeEdge = object
  endpointA: int
  endpointB: int
  edgeWeight: int

proc compareEdges(leftEdge: TreeEdge, rightEdge: TreeEdge): int =
  if leftEdge.edgeWeight < rightEdge.edgeWeight:
    return -1
  if leftEdge.edgeWeight > rightEdge.edgeWeight:
    return 1
  return 0

proc mergeSortEdges(edgeList: var seq[TreeEdge], helperList: var seq[TreeEdge], leftBound: int, rightBound: int) =
  if rightBound - leftBound <= 1:
    return
  let middleIndex = (leftBound + rightBound) div 2
  mergeSortEdges(edgeList, helperList, leftBound, middleIndex)
  mergeSortEdges(edgeList, helperList, middleIndex, rightBound)
  var leftCursor = leftBound
  var rightCursor = middleIndex
  var writeCursor = leftBound
  while leftCursor < middleIndex and rightCursor < rightBound:
    if compareEdges(edgeList[leftCursor], edgeList[rightCursor]) <= 0:
      helperList[writeCursor] = edgeList[leftCursor]
      leftCursor += 1
    else:
      helperList[writeCursor] = edgeList[rightCursor]
      rightCursor += 1
    writeCursor += 1
  while leftCursor < middleIndex:
    helperList[writeCursor] = edgeList[leftCursor]
    leftCursor += 1
    writeCursor += 1
  while rightCursor < rightBound:
    helperList[writeCursor] = edgeList[rightCursor]
    rightCursor += 1
    writeCursor += 1
  for edgeIndex in leftBound .. rightBound - 1:
    edgeList[edgeIndex] = helperList[edgeIndex]

proc findRoot(parentNodes: var seq[int], nodeIndex: int): int =
  var currentNode = nodeIndex
  while parentNodes[currentNode] != currentNode:
    parentNodes[currentNode] = parentNodes[parentNodes[currentNode]]
    currentNode = parentNodes[currentNode]
  return currentNode

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let nodeCount = nextInt(inputData, scanPos)
  var treeEdges = newSeq[TreeEdge](nodeCount - 1)
  var treeWeightTotal: int64 = 0
  for edgeIndex in 0 .. nodeCount - 2:
    treeEdges[edgeIndex].endpointA = nextInt(inputData, scanPos)
    treeEdges[edgeIndex].endpointB = nextInt(inputData, scanPos)
    treeEdges[edgeIndex].edgeWeight = nextInt(inputData, scanPos)
    treeWeightTotal = treeWeightTotal + int64(treeEdges[edgeIndex].edgeWeight)
  var helperEdges = newSeq[TreeEdge](nodeCount - 1)
  mergeSortEdges(treeEdges, helperEdges, 0, nodeCount - 1)
  var parentNodes = newSeq[int](nodeCount + 1)
  var componentSizes = newSeq[int](nodeCount + 1)
  for nodeIndex in 1 .. nodeCount:
    parentNodes[nodeIndex] = nodeIndex
    componentSizes[nodeIndex] = 1
  var extraWeightTotal: int64 = 0
  for edgeIndex in 0 .. nodeCount - 2:
    let firstEndpoint = treeEdges[edgeIndex].endpointA
    let secondEndpoint = treeEdges[edgeIndex].endpointB
    var firstRoot = findRoot(parentNodes, firstEndpoint)
    var secondRoot = findRoot(parentNodes, secondEndpoint)
    if firstRoot != secondRoot:
      let crossingPairs = int64(componentSizes[firstRoot]) * int64(componentSizes[secondRoot]) - 1
      extraWeightTotal = extraWeightTotal + crossingPairs * int64(treeEdges[edgeIndex].edgeWeight + 1)
      if componentSizes[firstRoot] < componentSizes[secondRoot]:
        swap firstRoot, secondRoot
      parentNodes[secondRoot] = firstRoot
      componentSizes[firstRoot] = componentSizes[firstRoot] + componentSizes[secondRoot]
  appendOutput($(treeWeightTotal + extraWeightTotal))
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
