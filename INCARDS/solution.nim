const firstDigitValue = 48
const nullEdgeIndex = -1
const flushBlockBytes = 1 shl 18
const unreachableDistance = high(int64) div 4

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var i = 0

proc nextInt(data: string, i: var int): int =
  while i < data.len and (data[i] < '0' or data[i] > '9'):
    i += 1
  var value = 0
  while i < data.len and data[i] >= '0' and data[i] <= '9':
    value = value * 10 + int(data[i]) - firstDigitValue
    i += 1
  return value

proc heapPush(heapNode: var seq[int], heapKey: var seq[int64], heapSize: var int,
              i: int, nodeKey: int64) =
  var j = heapSize
  heapSize += 1
  while j > 0:
    let k = (j - 1) div 2
    if heapKey[k] <= nodeKey:
      break
    heapNode[j] = heapNode[k]
    heapKey[j] = heapKey[k]
    j = k
  heapNode[j] = i
  heapKey[j] = nodeKey

proc heapPop(heapNode: var seq[int], heapKey: var seq[int64], heapSize: var int): tuple[nodeIndex: int, nodeKey: int64] =
  let rootNode = heapNode[0]
  let rootKey = heapKey[0]
  heapSize -= 1
  if heapSize > 0:
    let lastNode = heapNode[heapSize]
    let lastKey = heapKey[heapSize]
    var i = 0
    while true:
      let j = i * 2 + 1
      if j >= heapSize:
        break
      let k = j + 1
      var l = j
      if k < heapSize and heapKey[k] < heapKey[j]:
        l = k
      if heapKey[l] >= lastKey:
        break
      heapNode[i] = heapNode[l]
      heapKey[i] = heapKey[l]
      i = l
    heapNode[i] = lastNode
    heapKey[i] = lastKey
  return (rootNode, rootKey)

proc totalShortestDistance(nodeCount: int, edgeHead: seq[int], edgeTo: seq[int],
                           edgeWeight: seq[int], edgeNext: seq[int],
                           sourceNode: int, heapNode: var seq[int],
                           heapKey: var seq[int64]): int64 =
  var distance = newSeq[int64](nodeCount + 1)
  for i in 1..nodeCount:
    distance[i] = unreachableDistance
  var heapSize = 0
  distance[sourceNode] = 0
  heapPush(heapNode, heapKey, heapSize, sourceNode, 0)
  while heapSize > 0:
    let entry = heapPop(heapNode, heapKey, heapSize)
    let currentNode = entry.nodeIndex
    let currentDistance = entry.nodeKey
    if currentDistance != distance[currentNode]:
      continue
    var j = edgeHead[currentNode]
    while j != nullEdgeIndex:
      let neighborNode = edgeTo[j]
      let candidateDistance = currentDistance + int64(edgeWeight[j])
      if candidateDistance < distance[neighborNode]:
        distance[neighborNode] = candidateDistance
        heapPush(heapNode, heapKey, heapSize, neighborNode, candidateDistance)
      j = edgeNext[j]
  var total: int64 = 0
  for i in 1..nodeCount:
    total += distance[i]
  return total

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, i)
for j in 1..caseCount:
  let nodeCount = nextInt(inputData, i)
  let edgeCount = nextInt(inputData, i)
  var forwardHead = newSeq[int](nodeCount + 1)
  var reverseHead = newSeq[int](nodeCount + 1)
  for k in 0..nodeCount:
    forwardHead[k] = nullEdgeIndex
    reverseHead[k] = nullEdgeIndex
  var edgeTo = newSeq[int](edgeCount * 2 + 5)
  var edgeWeight = newSeq[int](edgeCount * 2 + 5)
  var edgeNext = newSeq[int](edgeCount * 2 + 5)
  for k in 0..<edgeCount:
    let originNode = nextInt(inputData, i)
    let targetNode = nextInt(inputData, i)
    let ticketPrice = nextInt(inputData, i)
    let l = k * 2
    edgeTo[l] = targetNode
    edgeWeight[l] = ticketPrice
    edgeNext[l] = forwardHead[originNode]
    forwardHead[originNode] = l
    let i = l + 1
    edgeTo[i] = originNode
    edgeWeight[i] = ticketPrice
    edgeNext[i] = reverseHead[targetNode]
    reverseHead[targetNode] = i
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
