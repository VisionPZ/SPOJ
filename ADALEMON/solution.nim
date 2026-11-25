import algorithm
import tables

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

proc compareIds(leftValue, rightValue: int): int =
  if leftValue < rightValue: return -1
  if leftValue > rightValue: return 1
  return 0

proc encodeNumbers(values: seq[int]): string =
  var key = newString(values.len * 4)
  for index in 0 .. values.len - 1:
    let value = values[index]
    let offset = index * 4
    key[offset] = chr(value and 255)
    key[offset + 1] = chr((value shr 8) and 255)
    key[offset + 2] = chr((value shr 16) and 255)
    key[offset + 3] = chr((value shr 24) and 255)
  return key

proc encodePair(firstValue, secondValue: int): string =
  var key = newString(8)
  key[0] = chr(firstValue and 255)
  key[1] = chr((firstValue shr 8) and 255)
  key[2] = chr((firstValue shr 16) and 255)
  key[3] = chr((firstValue shr 24) and 255)
  key[4] = chr(secondValue and 255)
  key[5] = chr((secondValue shr 8) and 255)
  key[6] = chr((secondValue shr 16) and 255)
  key[7] = chr((secondValue shr 24) and 255)
  return key

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var edgeTarget: seq[int]
var edgeLink: seq[int]
var nodeHead: seq[int]
var edgeCursor = 0

proc resetEdges(nodeTotal: int) =
  edgeTarget = newSeq[int](2 * nodeTotal + 4)
  edgeLink = newSeq[int](2 * nodeTotal + 4)
  nodeHead = newSeq[int](nodeTotal + 1)
  for node in 0 .. nodeTotal:
    nodeHead[node] = -1
  edgeCursor = 0

proc addEdge(sourceNode, targetNode: int) =
  edgeTarget[edgeCursor] = targetNode
  edgeLink[edgeCursor] = nodeHead[sourceNode]
  nodeHead[sourceNode] = edgeCursor
  edgeCursor += 1

proc findCenters(nodeTotal: int): seq[int] =
  var walkParent = newSeq[int](nodeTotal)
  for node in 0 .. nodeTotal - 1:
    walkParent[node] = -1
  var walkOrder = newSeq[int]()
  walkParent[0] = -2
  walkOrder.add 0
  var walkCursor = 0
  while walkCursor < walkOrder.len:
    let node = walkOrder[walkCursor]
    var edgeIndex = nodeHead[node]
    while edgeIndex != -1:
      let neighbor = edgeTarget[edgeIndex]
      if walkParent[neighbor] == -1:
        walkParent[neighbor] = node
        walkOrder.add neighbor
      edgeIndex = edgeLink[edgeIndex]
    walkCursor += 1
  var subtreeSizes = newSeq[int](nodeTotal)
  for node in 0 .. nodeTotal - 1:
    subtreeSizes[node] = 1
  for orderPos in countdown(walkOrder.len - 1, 0):
    let node = walkOrder[orderPos]
    var edgeIndex = nodeHead[node]
    while edgeIndex != -1:
      let neighbor = edgeTarget[edgeIndex]
      if walkParent[neighbor] == node:
        subtreeSizes[node] += subtreeSizes[neighbor]
      edgeIndex = edgeLink[edgeIndex]
  var centers = newSeq[int]()
  for node in 0 .. nodeTotal - 1:
    var largestPart = nodeTotal - subtreeSizes[node]
    var edgeIndex = nodeHead[node]
    while edgeIndex != -1:
      let neighbor = edgeTarget[edgeIndex]
      if walkParent[neighbor] == node and subtreeSizes[neighbor] > largestPart:
        largestPart = subtreeSizes[neighbor]
      edgeIndex = edgeLink[edgeIndex]
    if largestPart <= nodeTotal div 2:
      centers.add node
  return centers

proc countLeafShapes(nodeTotal: int): int =
  if nodeTotal == 1:
    return 0
  let centers = findCenters(nodeTotal)
  let virtualRoot = nodeTotal
  addEdge(virtualRoot, centers[0])
  if centers.len == 2:
    addEdge(virtualRoot, centers[1])
  var rootedParent = newSeq[int](nodeTotal + 1)
  for node in 0 .. nodeTotal:
    rootedParent[node] = -1
  var rootedOrder = newSeq[int]()
  rootedParent[virtualRoot] = -2
  rootedOrder.add virtualRoot
  var orderCursor = 0
  while orderCursor < rootedOrder.len:
    let node = rootedOrder[orderCursor]
    var edgeIndex = nodeHead[node]
    while edgeIndex != -1:
      let neighbor = edgeTarget[edgeIndex]
      if rootedParent[neighbor] == -1:
        rootedParent[neighbor] = node
        rootedOrder.add neighbor
      edgeIndex = edgeLink[edgeIndex]
    orderCursor += 1
  var subtreeIds = newSeq[int](nodeTotal + 1)
  var shapeTable = initTable[string, int]()
  var childIds = newSeq[int]()
  for orderPos in countdown(rootedOrder.len - 1, 0):
    let node = rootedOrder[orderPos]
    childIds.setLen 0
    var edgeIndex = nodeHead[node]
    while edgeIndex != -1:
      let neighbor = edgeTarget[edgeIndex]
      if rootedParent[neighbor] == node:
        childIds.add subtreeIds[neighbor]
      edgeIndex = edgeLink[edgeIndex]
    childIds.sort(compareIds)
    let shapeKey = encodeNumbers(childIds)
    if shapeTable.hasKey(shapeKey):
      subtreeIds[node] = shapeTable[shapeKey]
    else:
      let assignedId = shapeTable.len + 1
      shapeTable[shapeKey] = assignedId
      subtreeIds[node] = assignedId
  var orbitIds = newSeq[int](nodeTotal + 1)
  var pairTable = initTable[string, int]()
  orbitIds[virtualRoot] = 0
  var nextOrbit = 1
  for orderPos in 1 .. rootedOrder.len - 1:
    let node = rootedOrder[orderPos]
    let parentOrbit = orbitIds[rootedParent[node]]
    let shapeId = subtreeIds[node]
    let pairKey = encodePair(parentOrbit, shapeId)
    if pairTable.hasKey(pairKey):
      orbitIds[node] = pairTable[pairKey]
    else:
      orbitIds[node] = nextOrbit
      pairTable[pairKey] = nextOrbit
      nextOrbit += 1
  var leafOrbits = initTable[int, bool]()
  for node in 0 .. nodeTotal - 1:
    var hasChild = false
    var edgeIndex = nodeHead[node]
    while edgeIndex != -1:
      let neighbor = edgeTarget[edgeIndex]
      if rootedParent[neighbor] == node:
        hasChild = true
      edgeIndex = edgeLink[edgeIndex]
    if not hasChild:
      leafOrbits[orbitIds[node]] = true
  return leafOrbits.len

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let nodeCount = nextInt(inputData, scanPos)
  resetEdges(nodeCount)
  for edgeIndex in 0 .. nodeCount - 2:
    let firstNode = nextInt(inputData, scanPos)
    let secondNode = nextInt(inputData, scanPos)
    addEdge(firstNode, secondNode)
    addEdge(secondNode, firstNode)
  let shapeCount = countLeafShapes(nodeCount)
  appendOutput($shapeCount)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
