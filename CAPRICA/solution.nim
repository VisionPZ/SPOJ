const flushBlockBytes = 1 shl 17
const infinityDistance = int64(1 shl 60)

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

proc pushHeap(distHeap: var seq[int64], nodeHeap: var seq[int], distance: int64, node: int) =
  distHeap.add distance
  nodeHeap.add node
  var childIndex = distHeap.len - 1
  while childIndex > 0:
    let parentIndex = (childIndex - 1) div 2
    if distHeap[parentIndex] <= distHeap[childIndex]:
      break
    swap distHeap[parentIndex], distHeap[childIndex]
    swap nodeHeap[parentIndex], nodeHeap[childIndex]
    childIndex = parentIndex

proc popHeap(distHeap: var seq[int64], nodeHeap: var seq[int]): tuple[distance: int64, node: int] =
  let topDistance = distHeap[0]
  let topNode = nodeHeap[0]
  let lastDistance = distHeap[distHeap.len - 1]
  let lastNode = nodeHeap[nodeHeap.len - 1]
  distHeap.setLen(distHeap.len - 1)
  nodeHeap.setLen(nodeHeap.len - 1)
  if distHeap.len > 0:
    distHeap[0] = lastDistance
    nodeHeap[0] = lastNode
    var parentIndex = 0
    while true:
      let leftChild = parentIndex * 2 + 1
      if leftChild >= distHeap.len:
        break
      let rightChild = leftChild + 1
      var smallerChild = leftChild
      if rightChild < distHeap.len and distHeap[rightChild] < distHeap[leftChild]:
        smallerChild = rightChild
      if distHeap[parentIndex] <= distHeap[smallerChild]:
        break
      swap distHeap[parentIndex], distHeap[smallerChild]
      swap nodeHeap[parentIndex], nodeHeap[smallerChild]
      parentIndex = smallerChild
  return (topDistance, topNode)

while true:
  let cityCount = nextInt(inputData, scanPos)
  let roadCount = nextInt(inputData, scanPos)
  let groupXCount = nextInt(inputData, scanPos)
  let groupYCount = nextInt(inputData, scanPos)
  if cityCount == 0 and roadCount == 0:
    break
  var groupX = newSeq[int](groupXCount)
  for cityIndex in 0 .. groupXCount - 1:
    groupX[cityIndex] = nextInt(inputData, scanPos)
  var groupY = newSeq[int](groupYCount)
  for cityIndex in 0 .. groupYCount - 1:
    groupY[cityIndex] = nextInt(inputData, scanPos)
  var adjacencyHead = newSeq[int](cityCount)
  for cityIndex in 0 .. cityCount - 1:
    adjacencyHead[cityIndex] = -1
  var edgeTarget = newSeq[int](roadCount * 2)
  var edgeWeight = newSeq[int](roadCount * 2)
  var edgeNext = newSeq[int](roadCount * 2)
  var edgeCount = 0
  for roadIndex in 0 .. roadCount - 1:
    let fromCity = nextInt(inputData, scanPos)
    let toCity = nextInt(inputData, scanPos)
    let roadLength = nextInt(inputData, scanPos)
    edgeTarget[edgeCount] = toCity
    edgeWeight[edgeCount] = roadLength
    edgeNext[edgeCount] = adjacencyHead[fromCity]
    adjacencyHead[fromCity] = edgeCount
    edgeCount += 1
    edgeTarget[edgeCount] = fromCity
    edgeWeight[edgeCount] = roadLength
    edgeNext[edgeCount] = adjacencyHead[toCity]
    adjacencyHead[toCity] = edgeCount
    edgeCount += 1
  var distances = newSeq[int64](cityCount)
  for cityIndex in 0 .. cityCount - 1:
    distances[cityIndex] = infinityDistance
  var distHeap = newSeq[int64](0)
  var nodeHeap = newSeq[int](0)
  for sourceCity in groupX:
    distances[sourceCity] = 0
    pushHeap(distHeap, nodeHeap, 0, sourceCity)
  while distHeap.len > 0:
    let poppedItem = popHeap(distHeap, nodeHeap)
    if poppedItem.distance != distances[poppedItem.node]:
      continue
    var edgeIndex = adjacencyHead[poppedItem.node]
    while edgeIndex != -1:
      let candidateDistance = poppedItem.distance + int64(edgeWeight[edgeIndex])
      if candidateDistance < distances[edgeTarget[edgeIndex]]:
        distances[edgeTarget[edgeIndex]] = candidateDistance
        pushHeap(distHeap, nodeHeap, candidateDistance, edgeTarget[edgeIndex])
      edgeIndex = edgeNext[edgeIndex]
  var bestLength = infinityDistance
  for targetCity in groupY:
    if distances[targetCity] < bestLength:
      bestLength = distances[targetCity]
  appendOutput($bestLength)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
