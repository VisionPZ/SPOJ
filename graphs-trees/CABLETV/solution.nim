const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const maxVertexCount = 50
const maxNodeCount = 100
const maxEdgeCount = 6000
const largeCapacity = 1000

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

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

var scanPos = 0
var adjacent: array[maxVertexCount * maxVertexCount, bool]
var nodeHead: array[maxNodeCount, int]
var edgeTo: array[maxEdgeCount, int]
var edgeNext: array[maxEdgeCount, int]
var baseCap: array[maxEdgeCount, int]
var workCap: array[maxEdgeCount, int]
var splitEdge: array[maxVertexCount, int]
var level: array[maxNodeCount, int]
var iterEdge: array[maxNodeCount, int]
var queueNodes: array[maxNodeCount, int]
var edgeCount = 0
var nodeCount = 0

proc addArc(fromNode, toNode, capacity: int) =
  edgeTo[edgeCount] = toNode
  edgeNext[edgeCount] = nodeHead[fromNode]
  baseCap[edgeCount] = capacity
  nodeHead[fromNode] = edgeCount
  edgeCount += 1
  edgeTo[edgeCount] = fromNode
  edgeNext[edgeCount] = nodeHead[toNode]
  baseCap[edgeCount] = 0
  nodeHead[toNode] = edgeCount
  edgeCount += 1

proc graphConnected(vertexCount: int): bool =
  if vertexCount <= 1: return true
  var seen: array[maxVertexCount, bool]
  var queue: array[maxVertexCount, int]
  var headPos = 0
  var tailPos = 0
  queue[tailPos] = 0
  tailPos += 1
  seen[0] = true
  while headPos < tailPos:
    let current = queue[headPos]
    headPos += 1
    for neighbor in 0..<vertexCount:
      if adjacent[current * maxVertexCount + neighbor] and not seen[neighbor]:
        seen[neighbor] = true
        queue[tailPos] = neighbor
        tailPos += 1
  for vertex in 0..<vertexCount:
    if not seen[vertex]: return false
  return true

proc flowDfs(current, sink, available: int): int =
  if current == sink: return available
  var edgeIdx = iterEdge[current]
  while edgeIdx != -1:
    let target = edgeTo[edgeIdx]
    if workCap[edgeIdx] > 0 and level[target] == level[current] + 1:
      let pushed = flowDfs(target, sink, min(available, workCap[edgeIdx]))
      if pushed > 0:
        workCap[edgeIdx] -= pushed
        workCap[edgeIdx xor 1] += pushed
        return pushed
    edgeIdx = edgeNext[edgeIdx]
  iterEdge[current] = -1
  return 0

proc minCutValue(source, sink, limit: int): int =
  var total = 0
  while total < limit:
    for node in 0..<nodeCount: level[node] = -1
    level[source] = 0
    var headPos = 0
    var tailPos = 0
    queueNodes[tailPos] = source
    tailPos += 1
    while headPos < tailPos:
      let current = queueNodes[headPos]
      headPos += 1
      var edgeIdx = nodeHead[current]
      while edgeIdx != -1:
        let target = edgeTo[edgeIdx]
        if workCap[edgeIdx] > 0 and level[target] == -1:
          level[target] = level[current] + 1
          queueNodes[tailPos] = target
          tailPos += 1
        edgeIdx = edgeNext[edgeIdx]
    if level[sink] == -1: break
    for node in 0..<nodeCount: iterEdge[node] = nodeHead[node]
    while total < limit:
      let pushed = flowDfs(source, sink, limit - total)
      if pushed == 0: break
      total += pushed
  return total

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let vertexCount = nextInt(inputData, scanPos)
  let cableCount = nextInt(inputData, scanPos)
  for index in 0..<vertexCount * maxVertexCount: adjacent[index] = false
  nodeCount = vertexCount * 2
  for node in 0..<nodeCount: nodeHead[node] = -1
  edgeCount = 0
  for vertex in 0..<vertexCount:
    splitEdge[vertex] = edgeCount
    addArc(vertex * 2, vertex * 2 + 1, 1)
  for cable in 0..<cableCount:
    let firstVertex = nextInt(inputData, scanPos)
    let secondVertex = nextInt(inputData, scanPos)
    adjacent[firstVertex * maxVertexCount + secondVertex] = true
    adjacent[secondVertex * maxVertexCount + firstVertex] = true
    addArc(firstVertex * 2 + 1, secondVertex * 2, largeCapacity)
    addArc(secondVertex * 2 + 1, firstVertex * 2, largeCapacity)
  var safetyFactor = vertexCount
  if not graphConnected(vertexCount):
    safetyFactor = 0
  else:
    var bestCut = vertexCount
    var sourceVertex = 0
    while sourceVertex < vertexCount and bestCut > 1:
      var sinkVertex = sourceVertex + 1
      while sinkVertex < vertexCount and bestCut > 1:
        if not adjacent[sourceVertex * maxVertexCount + sinkVertex]:
          for edgeIdx in 0..<edgeCount: workCap[edgeIdx] = baseCap[edgeIdx]
          workCap[splitEdge[sourceVertex]] = largeCapacity
          workCap[splitEdge[sinkVertex]] = largeCapacity
          let cutValue = minCutValue(sourceVertex * 2 + 1, sinkVertex * 2, bestCut)
          if cutValue < bestCut: bestCut = cutValue
        sinkVertex += 1
      sourceVertex += 1
    safetyFactor = bestCut
  appendOutput($safetyFactor)
  outputBuffer.add '\n'
stdout.write outputBuffer
