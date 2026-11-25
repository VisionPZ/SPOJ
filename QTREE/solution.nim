const firstDigitValue = 48
const flushBlockBytes = 1 shl 17
const maxNodeCount = 10000
const maxEdgeCount = 10000
const maxAdjacencyEntries = 2 * maxEdgeCount
const segmentBase = 16384
const segmentCellCount = 2 * segmentBase

var parentNode: array[maxNodeCount + 1, int]
var nodeDepth: array[maxNodeCount + 1, int]
var subtreeSize: array[maxNodeCount + 1, int]
var heavyChild: array[maxNodeCount + 1, int]
var chainHead: array[maxNodeCount + 1, int]
var chainPosition: array[maxNodeCount + 1, int]
var nodeAtPosition: array[maxNodeCount + 1, int]
var edgeCostAtNode: array[maxNodeCount + 1, int]
var deeperNodeOfEdge: array[maxEdgeCount + 1, int]
var edgeWeight: array[maxEdgeCount + 1, int]
var adjacencyHead: array[maxNodeCount + 1, int]
var adjacencyTo: array[maxAdjacencyEntries + 2, int]
var adjacencyNext: array[maxAdjacencyEntries + 2, int]
var adjacencyEdgeId: array[maxAdjacencyEntries + 2, int]
var segmentTree: array[segmentCellCount + 1, int]
var adjacencyCount = 0
var nextPosition = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

proc nextWord(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  let wordStart = pos
  while pos < data.len and data[pos] > ' ':
    pos += 1
  return data[wordStart .. pos - 1]

proc appendAdjacency(fromNode, toNode, weightId: int) =
  adjacencyCount += 1
  adjacencyTo[adjacencyCount] = toNode
  adjacencyEdgeId[adjacencyCount] = weightId
  adjacencyNext[adjacencyCount] = adjacencyHead[fromNode]
  adjacencyHead[fromNode] = adjacencyCount

proc measureSubtree(nodeIndex, parentIndex: int) =
  parentNode[nodeIndex] = parentIndex
  subtreeSize[nodeIndex] = 1
  heavyChild[nodeIndex] = 0
  var edgeCursor = adjacencyHead[nodeIndex]
  while edgeCursor != 0:
    let neighborNode = adjacencyTo[edgeCursor]
    if neighborNode != parentIndex:
      let weightId = adjacencyEdgeId[edgeCursor]
      nodeDepth[neighborNode] = nodeDepth[nodeIndex] + 1
      edgeCostAtNode[neighborNode] = edgeWeight[weightId]
      deeperNodeOfEdge[weightId] = neighborNode
      measureSubtree(neighborNode, nodeIndex)
      subtreeSize[nodeIndex] += subtreeSize[neighborNode]
      if heavyChild[nodeIndex] == 0 or subtreeSize[neighborNode] > subtreeSize[heavyChild[nodeIndex]]:
        heavyChild[nodeIndex] = neighborNode
    edgeCursor = adjacencyNext[edgeCursor]

proc decomposeChain(nodeIndex, headNode: int) =
  chainHead[nodeIndex] = headNode
  chainPosition[nodeIndex] = nextPosition
  nodeAtPosition[nextPosition] = nodeIndex
  nextPosition += 1
  if heavyChild[nodeIndex] != 0:
    decomposeChain(heavyChild[nodeIndex], headNode)
  var edgeCursor = adjacencyHead[nodeIndex]
  while edgeCursor != 0:
    let neighborNode = adjacencyTo[edgeCursor]
    if neighborNode != parentNode[nodeIndex] and neighborNode != heavyChild[nodeIndex]:
      decomposeChain(neighborNode, neighborNode)
    edgeCursor = adjacencyNext[edgeCursor]

proc buildSegmentTree(nodeCount: int) =
  for cellIndex in segmentBase .. segmentCellCount:
    segmentTree[cellIndex] = 0
  for nodeIndex in 1 .. nodeCount:
    segmentTree[segmentBase + chainPosition[nodeIndex]] = edgeCostAtNode[nodeIndex]
  var cellIndex = segmentBase - 1
  while cellIndex >= 1:
    segmentTree[cellIndex] = max(segmentTree[2 * cellIndex], segmentTree[2 * cellIndex + 1])
    cellIndex -= 1

proc updateSegment(positionValue, weightValue: int) =
  var cellIndex = segmentBase + positionValue
  segmentTree[cellIndex] = weightValue
  cellIndex = cellIndex div 2
  while cellIndex >= 1:
    let mergedValue = max(segmentTree[2 * cellIndex], segmentTree[2 * cellIndex + 1])
    if segmentTree[cellIndex] == mergedValue: break
    segmentTree[cellIndex] = mergedValue
    cellIndex = cellIndex div 2

proc querySegment(leftPosition, rightPosition: int): int =
  var leftCell = segmentBase + leftPosition
  var rightCell = segmentBase + rightPosition
  result = 0
  while leftCell <= rightCell:
    if (leftCell and 1) == 1:
      if segmentTree[leftCell] > result: result = segmentTree[leftCell]
      leftCell += 1
    if (rightCell and 1) == 0:
      if segmentTree[rightCell] > result: result = segmentTree[rightCell]
      rightCell -= 1
    leftCell = leftCell div 2
    rightCell = rightCell div 2

proc queryPath(firstNode, secondNode: int): int =
  var nodeA = firstNode
  var nodeB = secondNode
  result = 0
  while chainHead[nodeA] != chainHead[nodeB]:
    if nodeDepth[chainHead[nodeA]] < nodeDepth[chainHead[nodeB]]:
      let swapNode = nodeA
      nodeA = nodeB
      nodeB = swapNode
    let headPosition = chainPosition[chainHead[nodeA]]
    let endPosition = chainPosition[nodeA]
    let chainBest = querySegment(headPosition, endPosition)
    if chainBest > result: result = chainBest
    nodeA = parentNode[chainHead[nodeA]]
  if nodeDepth[nodeA] > nodeDepth[nodeB]:
    let swapNode = nodeA
    nodeA = nodeB
    nodeB = swapNode
  let chainBest = querySegment(chainPosition[nodeA] + 1, chainPosition[nodeB])
  if chainBest > result: result = chainBest

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
var outputBuffer = ""
let caseCount = nextInt(inputData, scanPos)

for caseIndex in 0 .. caseCount - 1:
  let nodeCount = nextInt(inputData, scanPos)
  adjacencyCount = 0
  for nodeIndex in 1 .. nodeCount:
    adjacencyHead[nodeIndex] = 0
    heavyChild[nodeIndex] = 0
  for weightId in 1 .. nodeCount - 1:
    edgeWeight[weightId] = 0
    deeperNodeOfEdge[weightId] = 0
  nodeDepth[1] = 0
  for weightId in 1 .. nodeCount - 1:
    let fromNode = nextInt(inputData, scanPos)
    let toNode = nextInt(inputData, scanPos)
    let costValue = nextInt(inputData, scanPos)
    edgeWeight[weightId] = costValue
    appendAdjacency(fromNode, toNode, weightId)
    appendAdjacency(toNode, fromNode, weightId)
  measureSubtree(1, 0)
  nextPosition = 0
  decomposeChain(1, 1)
  buildSegmentTree(nodeCount)
  while scanPos < inputData.len:
    let commandWord = nextWord(inputData, scanPos)
    if commandWord == "DONE": break
    if commandWord == "QUERY":
      let firstNode = nextInt(inputData, scanPos)
      let secondNode = nextInt(inputData, scanPos)
      let answerValue = queryPath(firstNode, secondNode)
      outputBuffer.add $answerValue
      outputBuffer.add '\n'
      if outputBuffer.len >= flushBlockBytes:
        stdout.write outputBuffer
        outputBuffer.setLen 0
    elif commandWord == "CHANGE":
      let weightId = nextInt(inputData, scanPos)
      let newWeight = nextInt(inputData, scanPos)
      edgeWeight[weightId] = newWeight
      updateSegment(chainPosition[deeperNodeOfEdge[weightId]], newWeight)

stdout.write outputBuffer
outputBuffer.setLen 0
