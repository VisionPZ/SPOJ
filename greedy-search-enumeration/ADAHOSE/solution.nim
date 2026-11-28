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

proc pushNode(distanceValue: int64, nodeIndex: int, heapDistance: var seq[int64], heapNode: var seq[int], heapSize: var int) =
  heapDistance.setLen(heapSize + 1)
  heapNode.setLen(heapSize + 1)
  var childIndex = heapSize
  heapSize += 1
  while childIndex > 0:
    let parentIndex = (childIndex - 1) div 2
    if heapDistance[parentIndex] <= distanceValue:
      break
    heapDistance[childIndex] = heapDistance[parentIndex]
    heapNode[childIndex] = heapNode[parentIndex]
    childIndex = parentIndex
  heapDistance[childIndex] = distanceValue
  heapNode[childIndex] = nodeIndex

proc popNode(heapDistance: var seq[int64], heapNode: var seq[int], heapSize: var int): tuple[distanceValue: int64, nodeIndex: int] =
  let bestDistance = heapDistance[0]
  let bestNode = heapNode[0]
  heapSize -= 1
  if heapSize > 0:
    let movedDistance = heapDistance[heapSize]
    let movedNode = heapNode[heapSize]
    var parentIndex = 0
    while true:
      let leftIndex = parentIndex * 2 + 1
      if leftIndex >= heapSize:
        break
      let rightIndex = leftIndex + 1
      var childIndex = leftIndex
      if rightIndex < heapSize and heapDistance[rightIndex] < heapDistance[leftIndex]:
        childIndex = rightIndex
      if heapDistance[childIndex] >= movedDistance:
        break
      heapDistance[parentIndex] = heapDistance[childIndex]
      heapNode[parentIndex] = heapNode[childIndex]
      parentIndex = childIndex
    heapDistance[parentIndex] = movedDistance
    heapNode[parentIndex] = movedNode
  return (bestDistance, bestNode)

proc relaxNeighbor(neighborIndex: int, travelledFlow: int64, hoseFlows: seq[int64], shortestFlow: var seq[int64], heapDistance: var seq[int64], heapNode: var seq[int], heapSize: var int) =
  let candidateFlow = travelledFlow + hoseFlows[neighborIndex]
  if candidateFlow < shortestFlow[neighborIndex]:
    shortestFlow[neighborIndex] = candidateFlow
    pushNode(candidateFlow, neighborIndex, heapDistance, heapNode, heapSize)

let fieldSize = nextInt(inputData, scanPos)
let cellCount = fieldSize * fieldSize
var hoseFlows = newSeq[int64](cellCount)
for rowIndex in 0 .. fieldSize - 1:
  for columnIndex in 0 .. fieldSize - 1:
    hoseFlows[rowIndex * fieldSize + columnIndex] = int64(nextInt(inputData, scanPos))

let infiniteFlow = int64(1) shl 60
var shortestFlow = newSeq[int64](cellCount)
for cellIndex in 0 .. cellCount - 1:
  shortestFlow[cellIndex] = infiniteFlow
var heapDistance = newSeq[int64](cellCount)
var heapNode = newSeq[int](cellCount)
var heapSize = 0
for rowIndex in 0 .. fieldSize - 1:
  let entryCell = rowIndex * fieldSize
  shortestFlow[entryCell] = hoseFlows[entryCell]
  pushNode(shortestFlow[entryCell], entryCell, heapDistance, heapNode, heapSize)

while heapSize > 0:
  let poppedNode = popNode(heapDistance, heapNode, heapSize)
  if poppedNode.distanceValue != shortestFlow[poppedNode.nodeIndex]:
    continue
  let rowIndex = poppedNode.nodeIndex div fieldSize
  let columnIndex = poppedNode.nodeIndex mod fieldSize
  if rowIndex > 0:
    relaxNeighbor(poppedNode.nodeIndex - fieldSize, poppedNode.distanceValue, hoseFlows, shortestFlow, heapDistance, heapNode, heapSize)
  if rowIndex + 1 < fieldSize:
    relaxNeighbor(poppedNode.nodeIndex + fieldSize, poppedNode.distanceValue, hoseFlows, shortestFlow, heapDistance, heapNode, heapSize)
  if columnIndex > 0:
    relaxNeighbor(poppedNode.nodeIndex - 1, poppedNode.distanceValue, hoseFlows, shortestFlow, heapDistance, heapNode, heapSize)
  if columnIndex + 1 < fieldSize:
    relaxNeighbor(poppedNode.nodeIndex + 1, poppedNode.distanceValue, hoseFlows, shortestFlow, heapDistance, heapNode, heapSize)

var bestFlow = infiniteFlow
for rowIndex in 0 .. fieldSize - 1:
  let exitCell = rowIndex * fieldSize + fieldSize - 1
  if shortestFlow[exitCell] < bestFlow:
    bestFlow = shortestFlow[exitCell]

appendOutput($(bestFlow * 2))
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
