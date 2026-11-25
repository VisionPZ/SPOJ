const flushBlockBytes = 1 shl 17
const firstDigitValue = 48
const infiniteCapacity = 1 shl 29

type
  FlowEdge = object
    destination: int
    reverseIndex: int
    capacity: int
  ElementPair = tuple[firstIndex: int, secondIndex: int]

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

var flowGraph = newSeq[seq[FlowEdge]]()
var levelGraph = newSeq[int]()
var edgeCursor = newSeq[int]()

proc addFlowEdge(sourceIndex, targetIndex, capacityValue: int) =
  let forwardIndex = flowGraph[sourceIndex].len
  flowGraph[sourceIndex].add FlowEdge(destination: targetIndex, reverseIndex: flowGraph[targetIndex].len, capacity: capacityValue)
  flowGraph[targetIndex].add FlowEdge(destination: sourceIndex, reverseIndex: forwardIndex, capacity: 0)

proc sendFlow(nodeIndex, availableFlow, sinkIndex: int): int =
  if nodeIndex == sinkIndex:
    return availableFlow
  while edgeCursor[nodeIndex] < flowGraph[nodeIndex].len:
    let edgeIndex = edgeCursor[nodeIndex]
    let edgeDestination = flowGraph[nodeIndex][edgeIndex].destination
    if flowGraph[nodeIndex][edgeIndex].capacity > 0 and levelGraph[edgeDestination] == levelGraph[nodeIndex] + 1:
      let pushedFlow = sendFlow(edgeDestination, min(availableFlow, flowGraph[nodeIndex][edgeIndex].capacity), sinkIndex)
      if pushedFlow > 0:
        flowGraph[nodeIndex][edgeIndex].capacity -= pushedFlow
        flowGraph[edgeDestination][flowGraph[nodeIndex][edgeIndex].reverseIndex].capacity += pushedFlow
        return pushedFlow
    edgeCursor[nodeIndex] += 1
  return 0

proc maximumFlow(sourceIndex, sinkIndex: int): int =
  var totalFlow = 0
  while true:
    let nodeCount = flowGraph.len
    levelGraph = newSeq[int](nodeCount)
    for nodeIndex in 0 .. nodeCount - 1:
      levelGraph[nodeIndex] = -1
    levelGraph[sourceIndex] = 0
    var queue = newSeq[int]()
    queue.add sourceIndex
    var queueHead = 0
    while queueHead < queue.len:
      let currentNode = queue[queueHead]
      queueHead += 1
      for edgeIndex in 0 .. flowGraph[currentNode].len - 1:
        let edge = flowGraph[currentNode][edgeIndex]
        if edge.capacity > 0 and levelGraph[edge.destination] == -1:
          levelGraph[edge.destination] = levelGraph[currentNode] + 1
          queue.add edge.destination
    if levelGraph[sinkIndex] == -1:
      break
    edgeCursor = newSeq[int](nodeCount)
    while true:
      let pushedFlow = sendFlow(sourceIndex, infiniteCapacity, sinkIndex)
      if pushedFlow == 0:
        break
      totalFlow += pushedFlow
  return totalFlow

proc greatestCommonDivisor(firstValue, secondValue: int): int =
  var leftValue = firstValue
  var rightValue = secondValue
  while rightValue != 0:
    let remainderValue = leftValue mod rightValue
    leftValue = rightValue
    rightValue = remainderValue
  return leftValue

let elementCount = nextInt(inputData, scanPos)
var firstArray = newSeq[int](elementCount)
var secondArray = newSeq[int](elementCount)
for elementIndex in 0 .. elementCount - 1:
  firstArray[elementIndex] = nextInt(inputData, scanPos)
for elementIndex in 0 .. elementCount - 1:
  secondArray[elementIndex] = nextInt(inputData, scanPos)

var qualifyingPairs = newSeq[ElementPair]()
var smallerSecondCount = 0
for firstIndex in 0 .. elementCount - 1:
  for secondIndex in 0 .. elementCount - 1:
    if firstArray[firstIndex] != secondArray[secondIndex] and
       greatestCommonDivisor(firstArray[firstIndex], secondArray[secondIndex]) > 1:
      qualifyingPairs.add (firstIndex, secondIndex)
      if secondArray[secondIndex] < firstArray[firstIndex]:
        smallerSecondCount += 1

var firstPenalties = newSeq[int](elementCount)
var secondPenalties = newSeq[int](elementCount)
for pairEntry in qualifyingPairs:
  if secondArray[pairEntry.secondIndex] < firstArray[pairEntry.firstIndex]:
    firstPenalties[pairEntry.firstIndex] += 1
    secondPenalties[pairEntry.secondIndex] += 1

let sourceNode = 0
let sinkNode = 2 * elementCount + qualifyingPairs.len + 1
flowGraph = newSeq[seq[FlowEdge]](sinkNode + 1)
for nodeIndex in 0 .. sinkNode:
  flowGraph[nodeIndex] = newSeq[FlowEdge]()
for firstIndex in 0 .. elementCount - 1:
  if firstPenalties[firstIndex] > 0:
    addFlowEdge(1 + firstIndex, sinkNode, firstPenalties[firstIndex])
for secondIndex in 0 .. elementCount - 1:
  if secondPenalties[secondIndex] > 0:
    addFlowEdge(1 + elementCount + secondIndex, sinkNode, secondPenalties[secondIndex])

var pairNode = 2 * elementCount + 1
for pairEntry in qualifyingPairs:
  addFlowEdge(sourceNode, pairNode, 1)
  addFlowEdge(pairNode, 1 + pairEntry.firstIndex, infiniteCapacity)
  addFlowEdge(pairNode, 1 + elementCount + pairEntry.secondIndex, infiniteCapacity)
  pairNode += 1

let minimumCut = maximumFlow(sourceNode, sinkNode)
let bestScore = qualifyingPairs.len - minimumCut + smallerSecondCount
appendOutput($bestScore)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
