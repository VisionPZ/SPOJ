const flushBlockBytes = 1 shl 17
const largeDistance = 1 shl 28

type
  FlowEdge = object
    destination: int
    reverseIndex: int
    capacity: int
    cost: int

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

var flowGraph = newSeq[seq[FlowEdge]]()

proc addFlowEdge(sourceIndex, targetIndex, capacityValue, costValue: int) =
  let forwardIndex = flowGraph[sourceIndex].len
  flowGraph[sourceIndex].add FlowEdge(destination: targetIndex, reverseIndex: flowGraph[targetIndex].len, capacity: capacityValue, cost: costValue)
  flowGraph[targetIndex].add FlowEdge(destination: sourceIndex, reverseIndex: forwardIndex, capacity: 0, cost: -costValue)

proc cheapestFlow(sourceIndex, sinkIndex: int): (int, int) =
  var totalFlow = 0
  var totalCost = 0
  while true:
    let nodeCount = flowGraph.len
    var distance = newSeq[int](nodeCount)
    var previousNode = newSeq[int](nodeCount)
    var previousEdge = newSeq[int](nodeCount)
    var queued = newSeq[bool](nodeCount)
    for nodeIndex in 0 .. nodeCount - 1:
      distance[nodeIndex] = largeDistance
      previousNode[nodeIndex] = -1
      previousEdge[nodeIndex] = -1
      queued[nodeIndex] = false
    distance[sourceIndex] = 0
    var queue = newSeq[int]()
    queue.add sourceIndex
    queued[sourceIndex] = true
    var queueHead = 0
    while queueHead < queue.len:
      let currentNode = queue[queueHead]
      queueHead += 1
      queued[currentNode] = false
      for edgeIndex in 0 .. flowGraph[currentNode].len - 1:
        let edge = flowGraph[currentNode][edgeIndex]
        if edge.capacity > 0 and distance[currentNode] + edge.cost < distance[edge.destination]:
          distance[edge.destination] = distance[currentNode] + edge.cost
          previousNode[edge.destination] = currentNode
          previousEdge[edge.destination] = edgeIndex
          if not queued[edge.destination]:
            queued[edge.destination] = true
            queue.add edge.destination
    if previousNode[sinkIndex] == -1:
      break
    var augmentBy = largeDistance
    var walkNode = sinkIndex
    while walkNode != sourceIndex:
      let parentNode = previousNode[walkNode]
      let edgeIndex = previousEdge[walkNode]
      if flowGraph[parentNode][edgeIndex].capacity < augmentBy:
        augmentBy = flowGraph[parentNode][edgeIndex].capacity
      walkNode = parentNode
    walkNode = sinkIndex
    while walkNode != sourceIndex:
      let parentNode = previousNode[walkNode]
      let edgeIndex = previousEdge[walkNode]
      flowGraph[parentNode][edgeIndex].capacity -= augmentBy
      flowGraph[walkNode][flowGraph[parentNode][edgeIndex].reverseIndex].capacity += augmentBy
      totalCost = totalCost + augmentBy * flowGraph[parentNode][edgeIndex].cost
      walkNode = parentNode
    totalFlow += augmentBy
  return (totalFlow, totalCost)

while true:
  let rowCount = nextInt(inputData, scanPos)
  let columnCount = nextInt(inputData, scanPos)
  let ticketCost = nextInt(inputData, scanPos)
  if rowCount == 0 and columnCount == 0 and ticketCost == 0:
    break
  let cellCount = rowCount * columnCount
  var heights = newSeq[int](cellCount)
  for cellIndex in 0 .. cellCount - 1:
    heights[cellIndex] = nextInt(inputData, scanPos)
  flowGraph = newSeq[seq[FlowEdge]](2 * cellCount + 2)
  for graphIndex in 0 .. flowGraph.len - 1:
    flowGraph[graphIndex] = newSeq[FlowEdge]()
  let sourceNode = 0
  let sinkNode = 2 * cellCount + 1
  for cellIndex in 0 .. cellCount - 1:
    addFlowEdge(sourceNode, 1 + cellIndex, 1, 0)
    addFlowEdge(1 + cellCount + cellIndex, sinkNode, 1, 0)
  for rowIndex in 0 .. rowCount - 1:
    for columnIndex in 0 .. columnCount - 1:
      let cellIndex = rowIndex * columnCount + columnIndex
      let currentHeight = heights[cellIndex]
      for directionIndex in 0 .. 3:
        var neighborRow = rowIndex
        var neighborColumn = columnIndex
        if directionIndex == 0:
          neighborRow += 1
        elif directionIndex == 1:
          neighborRow -= 1
        elif directionIndex == 2:
          neighborColumn += 1
        else:
          neighborColumn -= 1
        if neighborRow < 0 or neighborRow >= rowCount:
          continue
        if neighborColumn < 0 or neighborColumn >= columnCount:
          continue
        let neighborIndex = neighborRow * columnCount + neighborColumn
        let neighborHeight = heights[neighborIndex]
        if neighborHeight < currentHeight:
          addFlowEdge(1 + cellIndex, 1 + cellCount + neighborIndex, 1, currentHeight - neighborHeight)
  let resultPair = cheapestFlow(sourceNode, sinkNode)
  let pathCount = cellCount - resultPair[0]
  let rideCount = pathCount - 1
  let visitCost = rideCount * ticketCost
  appendOutput($visitCost)
  outputBuffer.add ' '
  appendOutput($resultPair[1])
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
