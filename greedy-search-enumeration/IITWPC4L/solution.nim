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

var adjacencyHead = newSeq[int](0)
var edgeTarget = newSeq[int](0)
var edgeNext = newSeq[int](0)
var edgeCapacity = newSeq[int](0)
var edgeCostValue = newSeq[int](0)
var nodeDistance = newSeq[int64](0)
var inQueue = newSeq[bool](0)
var parentNode = newSeq[int](0)
var parentEdge = newSeq[int](0)
var pathQueue = newSeq[int](0)
var queueCapacity = 0

proc addEdge(fromNode, toNode, capacity, costValue: int) =
  let forwardIndex = edgeTarget.len
  edgeTarget.add toNode
  edgeCapacity.add capacity
  edgeCostValue.add costValue
  edgeNext.add adjacencyHead[fromNode]
  adjacencyHead[fromNode] = forwardIndex
  edgeTarget.add fromNode
  edgeCapacity.add 0
  edgeCostValue.add -costValue
  edgeNext.add adjacencyHead[toNode]
  adjacencyHead[toNode] = forwardIndex + 1

proc findCheapestPath(sourceNode, sinkNode: int): bool =
  for nodeIndex in 0 .. adjacencyHead.len - 1:
    nodeDistance[nodeIndex] = high(int64) div 4
    inQueue[nodeIndex] = false
  nodeDistance[sourceNode] = 0
  var queueHead = 0
  var queueTail = 0
  pathQueue[queueTail] = sourceNode
  queueTail = (queueTail + 1) mod queueCapacity
  inQueue[sourceNode] = true
  while queueHead != queueTail:
    let currentNode = pathQueue[queueHead]
    queueHead = (queueHead + 1) mod queueCapacity
    inQueue[currentNode] = false
    var edgeIndex = adjacencyHead[currentNode]
    while edgeIndex != -1:
      if edgeCapacity[edgeIndex] > 0:
        let nextNode = edgeTarget[edgeIndex]
        let candidateDistance = nodeDistance[currentNode] + int64(edgeCostValue[edgeIndex])
        if candidateDistance < nodeDistance[nextNode]:
          nodeDistance[nextNode] = candidateDistance
          parentNode[nextNode] = currentNode
          parentEdge[nextNode] = edgeIndex
          if not inQueue[nextNode]:
            pathQueue[queueTail] = nextNode
            queueTail = (queueTail + 1) mod queueCapacity
            inQueue[nextNode] = true
      edgeIndex = edgeNext[edgeIndex]
  return nodeDistance[sinkNode] < high(int64) div 4

let testCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. testCount - 1:
  let doorCount = nextInt(inputData, scanPos)
  let requiredDoors = nextInt(inputData, scanPos)
  var lockKeys = newSeq[int](doorCount)
  var movePowers = newSeq[int](doorCount)
  var lowestKey = 1000000
  var highestKey = -1000000
  for doorIndex in 0 .. doorCount - 1:
    lockKeys[doorIndex] = nextInt(inputData, scanPos)
    if lockKeys[doorIndex] < lowestKey:
      lowestKey = lockKeys[doorIndex]
    if lockKeys[doorIndex] > highestKey:
      highestKey = lockKeys[doorIndex]
  for doorIndex in 0 .. doorCount - 1:
    movePowers[doorIndex] = nextInt(inputData, scanPos)
  let keyStart = lowestKey - 5 * requiredDoors
  let keyCount = highestKey + 5 * requiredDoors - keyStart + 1
  let sourceNode = 0
  let firstDoorNode = 1
  let firstKeyNode = 1 + doorCount
  let sinkNode = firstKeyNode + keyCount
  let nodeCount = sinkNode + 1
  adjacencyHead.setLen(nodeCount)
  for nodeIndex in 0 .. nodeCount - 1:
    adjacencyHead[nodeIndex] = -1
  edgeTarget.setLen(0)
  edgeNext.setLen(0)
  edgeCapacity.setLen(0)
  edgeCostValue.setLen(0)
  for doorIndex in 0 .. doorCount - 1:
    addEdge(sourceNode, firstDoorNode + doorIndex, 1, 0)
  for keyIndex in 0 .. keyCount - 1:
    addEdge(firstKeyNode + keyIndex, sinkNode, 1, 0)
  for doorIndex in 0 .. doorCount - 1:
    let baseKey = lockKeys[doorIndex]
    let doorPower = movePowers[doorIndex]
    for keyIndex in 0 .. keyCount - 1:
      let keyValue = keyStart + keyIndex
      let keyDistance = if keyValue > baseKey: keyValue - baseKey else: baseKey - keyValue
      let operationCost = (keyDistance + doorPower - 1) div doorPower
      addEdge(firstDoorNode + doorIndex, firstKeyNode + keyIndex, 1, operationCost)
  nodeDistance.setLen(nodeCount)
  inQueue.setLen(nodeCount)
  parentNode.setLen(nodeCount)
  parentEdge.setLen(nodeCount)
  queueCapacity = nodeCount + 1
  pathQueue.setLen(queueCapacity)
  var totalOperations: int64 = 0
  var openedDoors = 0
  while openedDoors < requiredDoors and findCheapestPath(sourceNode, sinkNode):
    var currentNode = sinkNode
    while currentNode != sourceNode:
      let viaEdge = parentEdge[currentNode]
      edgeCapacity[viaEdge] = edgeCapacity[viaEdge] - 1
      edgeCapacity[viaEdge xor 1] = edgeCapacity[viaEdge xor 1] + 1
      currentNode = parentNode[currentNode]
    totalOperations = totalOperations + nodeDistance[sinkNode]
    openedDoors += 1
  appendOutput($totalOperations)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
