const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const infiniteCapacity = 1000000000

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int(data[position]) - firstDigitValue
    position += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var headEdge: seq[int]
var edgeTo: seq[int]
var edgeCap: seq[int]
var edgeNext: seq[int]
var edgeCount = 0
var levelNode: seq[int]
var iterEdge: seq[int]
var queueNode: seq[int]
var nodeTotal = 0

proc addCorridor(fromNode, toNode, capacity: int) =
  edgeTo[edgeCount] = toNode
  edgeCap[edgeCount] = capacity
  edgeNext[edgeCount] = headEdge[fromNode]
  headEdge[fromNode] = edgeCount
  edgeCount += 1
  edgeTo[edgeCount] = fromNode
  edgeCap[edgeCount] = 0
  edgeNext[edgeCount] = headEdge[toNode]
  headEdge[toNode] = edgeCount
  edgeCount += 1

proc buildLevels(sourceNode, sinkNode: int): bool =
  for i in 0..nodeTotal:
    levelNode[i] = -1
  var queueHead = 0
  var queueTail = 0
  levelNode[sourceNode] = 0
  queueNode[queueTail] = sourceNode
  queueTail += 1
  while queueHead < queueTail:
    let currentNode = queueNode[queueHead]
    queueHead += 1
    var edgeIndex = headEdge[currentNode]
    while edgeIndex != -1:
      let nextNode = edgeTo[edgeIndex]
      if edgeCap[edgeIndex] > 0 and levelNode[nextNode] == -1:
        levelNode[nextNode] = levelNode[currentNode] + 1
        queueNode[queueTail] = nextNode
        queueTail += 1
      edgeIndex = edgeNext[edgeIndex]
  return levelNode[sinkNode] != -1

proc pushFlow(currentNode, sinkNode, limit: int): int =
  if currentNode == sinkNode:
    return limit
  var edgeIndex = iterEdge[currentNode]
  while edgeIndex != -1:
    let nextNode = edgeTo[edgeIndex]
    if edgeCap[edgeIndex] > 0 and levelNode[nextNode] == levelNode[currentNode] + 1:
      let pushed = pushFlow(nextNode, sinkNode, min(limit, edgeCap[edgeIndex]))
      if pushed > 0:
        edgeCap[edgeIndex] -= pushed
        edgeCap[edgeIndex xor 1] += pushed
        return pushed
    edgeIndex = edgeNext[edgeIndex]
    iterEdge[currentNode] = edgeIndex
  return 0

proc maxFlow(sourceNode, sinkNode: int): int =
  result = 0
  while buildLevels(sourceNode, sinkNode):
    for i in 0..nodeTotal:
      iterEdge[i] = headEdge[i]
    while true:
      let pushed = pushFlow(sourceNode, sinkNode, infiniteCapacity)
      if pushed == 0:
        break
      result += pushed

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let chamberCount = nextInt(inputData, scanPos)
  nodeTotal = chamberCount
  headEdge.setLen(chamberCount + 1)
  levelNode.setLen(chamberCount + 1)
  iterEdge.setLen(chamberCount + 1)
  queueNode.setLen(chamberCount + 1)
  for i in 0..chamberCount:
    headEdge[i] = -1
  edgeTo.setLen(2 * (chamberCount * chamberCount + 2))
  edgeCap.setLen(2 * (chamberCount * chamberCount + 2))
  edgeNext.setLen(2 * (chamberCount * chamberCount + 2))
  edgeCount = 0
  for fromChamber in 1..<chamberCount:
    let corridorCount = nextInt(inputData, scanPos)
    for j in 0..<corridorCount:
      let toChamber = nextInt(inputData, scanPos)
      var capacity = infiniteCapacity
      if fromChamber == 1 or toChamber == chamberCount:
        capacity = 1
      addCorridor(fromChamber, toChamber, capacity)
  appendOutput($(maxFlow(1, chamberCount)))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
