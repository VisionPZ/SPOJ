const flushBlockBytes = 1 shl 17
const farDistance = 1 shl 28

type HeapEntry = tuple[key: int, id: int]
type MinHeap = seq[HeapEntry]

proc heapPush(heap: var MinHeap; entry: HeapEntry) =
  heap.add entry
  var childIndex = heap.len - 1
  while childIndex > 0:
    let parentIndex = (childIndex - 1) div 2
    if heap[parentIndex].key <= heap[childIndex].key:
      break
    let parentEntry = heap[parentIndex]
    heap[parentIndex] = heap[childIndex]
    heap[childIndex] = parentEntry
    childIndex = parentIndex

proc heapPop(heap: var MinHeap): HeapEntry =
  result = heap[0]
  let lastEntry = heap.pop()
  if heap.len > 0:
    heap[0] = lastEntry
    var parentIndex = 0
    while true:
      let leftIndex = parentIndex * 2 + 1
      let rightIndex = leftIndex + 1
      var smallestIndex = leftIndex
      if rightIndex < heap.len and heap[rightIndex].key < heap[leftIndex].key:
        smallestIndex = rightIndex
      if smallestIndex >= heap.len or heap[parentIndex].key <= heap[smallestIndex].key:
        break
      let smallerEntry = heap[smallestIndex]
      heap[smallestIndex] = heap[parentIndex]
      heap[parentIndex] = smallerEntry
      parentIndex = smallestIndex

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

var nodeCount = nextInt(inputData, scanPos)
var headEdge = newSeq[int](nodeCount + 1)
for index in 0 .. nodeCount:
  headEdge[index] = -1
var edgeTarget = newSeq[int](2 * nodeCount)
var edgeNext = newSeq[int](2 * nodeCount)
var edgeCursor = 0

proc addEdge(fromNode, toNode: int) =
  edgeTarget[edgeCursor] = toNode
  edgeNext[edgeCursor] = headEdge[fromNode]
  headEdge[fromNode] = edgeCursor
  edgeCursor += 1

for edgeIndex in 0 .. nodeCount - 2:
  let firstNode = nextInt(inputData, scanPos)
  let secondNode = nextInt(inputData, scanPos)
  addEdge(firstNode, secondNode)
  addEdge(secondNode, firstNode)

var aliveNodes = newSeq[bool](nodeCount + 1)
for nodeIndex in 1 .. nodeCount:
  aliveNodes[nodeIndex] = true
var subtreeSizes = newSeq[int](nodeCount + 1)
var walkParent = newSeq[int](nodeCount + 1)
var ancestorCentroid = newSeq[seq[int]](nodeCount + 1)
var ancestorDistance = newSeq[seq[int]](nodeCount + 1)
var ancestorPart = newSeq[seq[int]](nodeCount + 1)
var partHeaps = newSeq[MinHeap](0)
var selfPart = newSeq[int](nodeCount + 1)
var centroidHeaps = newSeq[MinHeap](nodeCount + 1)
var whiteNodes = newSeq[bool](nodeCount + 1)

proc measureSubtrees(startNode, parentNode: int): seq[int] =
  var stackNodes = newSeq[int](0)
  var visitOrder = newSeq[int](0)
  stackNodes.add startNode
  walkParent[startNode] = parentNode
  while stackNodes.len > 0:
    let currentNode = stackNodes.pop()
    visitOrder.add currentNode
    var edgeIndex = headEdge[currentNode]
    while edgeIndex != -1:
      let neighbor = edgeTarget[edgeIndex]
      if neighbor != walkParent[currentNode] and aliveNodes[neighbor]:
        walkParent[neighbor] = currentNode
        stackNodes.add neighbor
      edgeIndex = edgeNext[edgeIndex]
  for orderIndex in countdown(visitOrder.len - 1, 0):
    let currentNode = visitOrder[orderIndex]
    var sizeValue = 1
    var edgeIndex = headEdge[currentNode]
    while edgeIndex != -1:
      let neighbor = edgeTarget[edgeIndex]
      if walkParent[neighbor] == currentNode and aliveNodes[neighbor]:
        sizeValue += subtreeSizes[neighbor]
      edgeIndex = edgeNext[edgeIndex]
    subtreeSizes[currentNode] = sizeValue
  return visitOrder

proc createPart(ownerCentroid: int): int =
  let partIndex = partHeaps.len
  partHeaps.add newSeq[HeapEntry]()
  selfPart[ownerCentroid] = partIndex
  return partIndex

proc recordAncestors(centroidNode, startNode, startDistance, partIndex: int) =
  var stackNodes = newSeq[int](0)
  var stackDistances = newSeq[int](0)
  stackNodes.add startNode
  stackDistances.add startDistance
  walkParent[startNode] = centroidNode
  while stackNodes.len > 0:
    let currentNode = stackNodes.pop()
    let currentDistance = stackDistances.pop()
    ancestorCentroid[currentNode].add centroidNode
    ancestorDistance[currentNode].add currentDistance
    ancestorPart[currentNode].add partIndex
    var edgeIndex = headEdge[currentNode]
    while edgeIndex != -1:
      let neighbor = edgeTarget[edgeIndex]
      if neighbor != walkParent[currentNode] and aliveNodes[neighbor]:
        walkParent[neighbor] = currentNode
        stackNodes.add neighbor
        stackDistances.add currentDistance + 1
      edgeIndex = edgeNext[edgeIndex]

proc decompose(startNode, parentNode: int) =
  let visitOrder = measureSubtrees(startNode, parentNode)
  let totalNodes = visitOrder.len
  var centroidNode = startNode
  var moved = true
  while moved:
    moved = false
    var edgeIndex = headEdge[centroidNode]
    while edgeIndex != -1:
      let neighbor = edgeTarget[edgeIndex]
      if aliveNodes[neighbor]:
        var branchSize = subtreeSizes[neighbor]
        if neighbor == walkParent[centroidNode]:
          branchSize = totalNodes - subtreeSizes[centroidNode]
        if branchSize > totalNodes div 2:
          centroidNode = neighbor
          moved = true
          break
      edgeIndex = edgeNext[edgeIndex]
  aliveNodes[centroidNode] = false
  let ownPart = createPart(centroidNode)
  ancestorCentroid[centroidNode].add centroidNode
  ancestorDistance[centroidNode].add 0
  ancestorPart[centroidNode].add ownPart
  var edgeIndex = headEdge[centroidNode]
  while edgeIndex != -1:
    let neighbor = edgeTarget[edgeIndex]
    if aliveNodes[neighbor]:
      let branchPart = partHeaps.len
      partHeaps.add newSeq[HeapEntry]()
      recordAncestors(centroidNode, neighbor, 1, branchPart)
    edgeIndex = edgeNext[edgeIndex]
  edgeIndex = headEdge[centroidNode]
  while edgeIndex != -1:
    let neighbor = edgeTarget[edgeIndex]
    if aliveNodes[neighbor]:
      decompose(neighbor, centroidNode)
    edgeIndex = edgeNext[edgeIndex]

decompose(1, 0)

proc partMinimum(partIndex: int): int =
  while partHeaps[partIndex].len > 0 and not whiteNodes[partHeaps[partIndex][0].id]:
    discard heapPop(partHeaps[partIndex])
  if partHeaps[partIndex].len == 0:
    return farDistance
  return partHeaps[partIndex][0].key

proc cleanCentroidHeap(centroidNode: int) =
  while centroidHeaps[centroidNode].len > 0:
    let topEntry = centroidHeaps[centroidNode][0]
    var expected = partMinimum(topEntry.id)
    if topEntry.id == selfPart[centroidNode]:
      if whiteNodes[centroidNode]:
        expected = 0
      else:
        expected = farDistance
    if topEntry.key == expected:
      break
    discard heapPop(centroidHeaps[centroidNode])

proc toggleNode(nodeIndex: int) =
  whiteNodes[nodeIndex] = not whiteNodes[nodeIndex]
  for recordIndex in 0 ..< ancestorCentroid[nodeIndex].len:
    let centroidNode = ancestorCentroid[nodeIndex][recordIndex]
    let distanceValue = ancestorDistance[nodeIndex][recordIndex]
    let partIndex = ancestorPart[nodeIndex][recordIndex]
    if whiteNodes[nodeIndex]:
      heapPush(partHeaps[partIndex], (key: distanceValue, id: nodeIndex))
    let currentMin = partMinimum(partIndex)
    if currentMin < farDistance:
      heapPush(centroidHeaps[centroidNode], (key: currentMin, id: partIndex))

proc nearestWhiteDistance(nodeIndex: int): int =
  var bestDistance = farDistance
  for recordIndex in 0 ..< ancestorCentroid[nodeIndex].len:
    let centroidNode = ancestorCentroid[nodeIndex][recordIndex]
    let distanceValue = ancestorDistance[nodeIndex][recordIndex]
    let partIndex = ancestorPart[nodeIndex][recordIndex]
    cleanCentroidHeap(centroidNode)
    if centroidHeaps[centroidNode].len == 0:
      continue
    let firstEntry = centroidHeaps[centroidNode][0]
    discard heapPop(centroidHeaps[centroidNode])
    cleanCentroidHeap(centroidNode)
    while centroidHeaps[centroidNode].len > 0 and centroidHeaps[centroidNode][0].id == firstEntry.id:
      discard heapPop(centroidHeaps[centroidNode])
      cleanCentroidHeap(centroidNode)
    var secondKey = farDistance
    if centroidHeaps[centroidNode].len > 0:
      secondKey = centroidHeaps[centroidNode][0].key
    heapPush(centroidHeaps[centroidNode], firstEntry)
    var chosenKey = firstEntry.key
    if centroidNode != nodeIndex and firstEntry.id == partIndex:
      chosenKey = secondKey
    if chosenKey < farDistance and distanceValue + chosenKey < bestDistance:
      bestDistance = distanceValue + chosenKey
  if bestDistance >= farDistance:
    return -1
  return bestDistance

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let instructionCount = nextInt(inputData, scanPos)
for instructionIndex in 0 .. instructionCount - 1:
  let instructionType = nextInt(inputData, scanPos)
  if instructionType == 0:
    let targetNode = nextInt(inputData, scanPos)
    toggleNode(targetNode)
  else:
    let queryNode = nextInt(inputData, scanPos)
    appendOutput($nearestWhiteDistance(queryNode))
    outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
