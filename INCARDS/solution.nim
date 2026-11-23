const firstDigitValue = 48
const nullEdgeIndex = -1
const flushBlockBytes = 1 shl 18
const unreachableDistance = high(int64) div 4

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

proc heapPush(heapNode: var seq[int], heapKey: var seq[int64], heapSize: var int,
              nodeIndex: int, nodeKey: int64) =
  var childPos = heapSize
  heapSize += 1
  while childPos > 0:
    let parentPos = (childPos - 1) div 2
    if heapKey[parentPos] <= nodeKey:
      break
    heapNode[childPos] = heapNode[parentPos]
    heapKey[childPos] = heapKey[parentPos]
    childPos = parentPos
  heapNode[childPos] = nodeIndex
  heapKey[childPos] = nodeKey

proc heapPop(heapNode: var seq[int], heapKey: var seq[int64], heapSize: var int): tuple[nodeIndex: int, nodeKey: int64] =
  let rootNode = heapNode[0]
  let rootKey = heapKey[0]
  heapSize -= 1
  if heapSize > 0:
    let lastNode = heapNode[heapSize]
    let lastKey = heapKey[heapSize]
    var parentPos = 0
    while true:
      let leftPos = parentPos * 2 + 1
      if leftPos >= heapSize:
        break
      let rightPos = leftPos + 1
      var childPos = leftPos
      if rightPos < heapSize and heapKey[rightPos] < heapKey[leftPos]:
        childPos = rightPos
      if heapKey[childPos] >= lastKey:
        break
      heapNode[parentPos] = heapNode[childPos]
      heapKey[parentPos] = heapKey[childPos]
      parentPos = childPos
    heapNode[parentPos] = lastNode
    heapKey[parentPos] = lastKey
  return (rootNode, rootKey)

proc totalShortestDistance(nodeCount: int, edgeHead: seq[int], edgeTo: seq[int],
                           edgeWeight: seq[int], edgeNext: seq[int],
                           sourceNode: int, heapNode: var seq[int],
                           heapKey: var seq[int64]): int64 =
  var distance = newSeq[int64](nodeCount + 1)
  for nodeIndex in 1..nodeCount:
    distance[nodeIndex] = unreachableDistance
  var heapSize = 0
  distance[sourceNode] = 0
  heapPush(heapNode, heapKey, heapSize, sourceNode, 0)
  while heapSize > 0:
    let entry = heapPop(heapNode, heapKey, heapSize)
    let currentNode = entry.nodeIndex
    let currentDistance = entry.nodeKey
    if currentDistance != distance[currentNode]:
      continue
    var edgeIndex = edgeHead[currentNode]
    while edgeIndex != nullEdgeIndex:
      let neighborNode = edgeTo[edgeIndex]
      let candidateDistance = currentDistance + int64(edgeWeight[edgeIndex])
      if candidateDistance < distance[neighborNode]:
        distance[neighborNode] = candidateDistance
        heapPush(heapNode, heapKey, heapSize, neighborNode, candidateDistance)
      edgeIndex = edgeNext[edgeIndex]
  var total: int64 = 0
  for nodeIndex in 1..nodeCount:
    total += distance[nodeIndex]
  return total

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 1..caseCount:
  let nodeCount = nextInt(inputData, scanPos)
  let edgeCount = nextInt(inputData, scanPos)
  var forwardHead = newSeq[int](nodeCount + 1)
  var reverseHead = newSeq[int](nodeCount + 1)
  for nodeIndex in 0..nodeCount:
    forwardHead[nodeIndex] = nullEdgeIndex
    reverseHead[nodeIndex] = nullEdgeIndex
  var edgeTo = newSeq[int](edgeCount * 2 + 5)
  var edgeWeight = newSeq[int](edgeCount * 2 + 5)
  var edgeNext = newSeq[int](edgeCount * 2 + 5)
  for edgeIndex in 0..<edgeCount:
    let originNode = nextInt(inputData, scanPos)
    let targetNode = nextInt(inputData, scanPos)
    let ticketPrice = nextInt(inputData, scanPos)
    let forwardIndex = edgeIndex * 2
    edgeTo[forwardIndex] = targetNode
    edgeWeight[forwardIndex] = ticketPrice
    edgeNext[forwardIndex] = forwardHead[originNode]
    forwardHead[originNode] = forwardIndex
    let reverseIndex = forwardIndex + 1
    edgeTo[reverseIndex] = originNode
    edgeWeight[reverseIndex] = ticketPrice
    edgeNext[reverseIndex] = reverseHead[targetNode]
    reverseHead[targetNode] = reverseIndex
  var heapNode = newSeq[int](edgeCount + 5)
  var heapKey = newSeq[int64](edgeCount + 5)
  let outbound = totalShortestDistance(nodeCount, forwardHead, edgeTo, edgeWeight,
                                       edgeNext, 1, heapNode, heapKey)
  let inbound = totalShortestDistance(nodeCount, reverseHead, edgeTo, edgeWeight,
                                      edgeNext, 1, heapNode, heapKey)
  appendOutput($(outbound + inbound))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
