import algorithm

const flushBlockBytes = 1 shl 17
const negativeInfinite = -9000000000000000000

type
  TreeEdge = object
    target: int
    weight: int
    next: int

  HeapNode = object
    value: int64
    firstField: int
    secondField: int

  PathEntry = object
    centroid: int
    distance: int64
    branchId: int
    entryId: int

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  var negativeValue = false
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    if data[pos] == '-':
      negativeValue = true
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  if negativeValue:
    return -value
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc heapPush(heap: var seq[HeapNode], item: HeapNode) =
  heap.add item
  var position = heap.len - 1
  while position > 0:
    let parentPosition = (position - 1) div 2
    if heap[parentPosition].value >= heap[position].value:
      break
    swap heap[parentPosition], heap[position]
    position = parentPosition

proc heapPop(heap: var seq[HeapNode]): HeapNode =
  let rootItem = heap[0]
  let lastItem = heap[heap.len - 1]
  heap.setLen(heap.len - 1)
  if heap.len > 0:
    heap[0] = lastItem
    var position = 0
    while true:
      let leftChild = position * 2 + 1
      let rightChild = leftChild + 1
      var largestChild = leftChild
      if rightChild < heap.len and heap[rightChild].value > heap[leftChild].value:
        largestChild = rightChild
      if leftChild >= heap.len or heap[position].value >= heap[largestChild].value:
        break
      swap heap[position], heap[largestChild]
      position = largestChild
  return rootItem

let nodeCount = nextInt(inputData, scanPos)
var adjacencyHead = newSeq[int](nodeCount + 1)
for nodeIndex in 0 .. nodeCount:
  adjacencyHead[nodeIndex] = -1
var edgeTarget = newSeq[int](2 * nodeCount)
var edgeWeight = newSeq[int](2 * nodeCount)
var edgeNext = newSeq[int](2 * nodeCount)
var edgeCount = 0
for edgeIndex in 0 .. nodeCount - 2:
  let firstNode = nextInt(inputData, scanPos)
  let secondNode = nextInt(inputData, scanPos)
  let weightValue = nextInt(inputData, scanPos)
  edgeTarget[edgeCount] = secondNode
  edgeWeight[edgeCount] = weightValue
  edgeNext[edgeCount] = adjacencyHead[firstNode]
  adjacencyHead[firstNode] = edgeCount
  edgeCount += 1
  edgeTarget[edgeCount] = firstNode
  edgeWeight[edgeCount] = weightValue
  edgeNext[edgeCount] = adjacencyHead[secondNode]
  adjacencyHead[secondNode] = edgeCount
  edgeCount += 1

var removed = newSeq[bool](nodeCount + 1)
var subtreeSize = newSeq[int](nodeCount + 1)
var componentParent = newSeq[int](nodeCount + 1)
var nodeEntries = newSeq[seq[PathEntry]](nodeCount + 1)
var entryVersion = newSeq[int]()
var branchVersion = newSeq[int]()
var branchBest = newSeq[int64]()
var branchCentroid = newSeq[int]()
var branchHeaps = newSeq[seq[HeapNode]]()
var centroidHeaps = newSeq[seq[HeapNode]](nodeCount + 1)
var centroidVersion = newSeq[int](nodeCount + 1)
var centroidValue = newSeq[int64](nodeCount + 1)
var answerHeap = newSeq[HeapNode]()

proc addPathEntry(nodeIndex: int, centroidIndex: int, distanceValue: int64, branchId: int) =
  var pathEntry: PathEntry
  pathEntry.centroid = centroidIndex
  pathEntry.distance = distanceValue
  pathEntry.branchId = branchId
  pathEntry.entryId = entryVersion.len
  entryVersion.add 0
  nodeEntries[nodeIndex].add pathEntry

proc collectComponent(startNode: int): seq[int] =
  var componentNodes = newSeq[int]()
  var traversalStack = newSeq[int]()
  traversalStack.add startNode
  componentParent[startNode] = 0
  while traversalStack.len > 0:
    let currentNode = traversalStack[traversalStack.len - 1]
    traversalStack.setLen(traversalStack.len - 1)
    componentNodes.add currentNode
    var edgePointer = adjacencyHead[currentNode]
    while edgePointer != -1:
      let neighborNode = edgeTarget[edgePointer]
      if not removed[neighborNode] and neighborNode != componentParent[currentNode]:
        componentParent[neighborNode] = currentNode
        traversalStack.add neighborNode
      edgePointer = edgeNext[edgePointer]
  return componentNodes

proc findCentroid(componentNodes: seq[int]): int =
  for nodeIndex in componentNodes:
    subtreeSize[nodeIndex] = 1
  for nodePosition in componentNodes.len - 1 .. 0:
    let currentNode = componentNodes[nodePosition]
    let parentNode = componentParent[currentNode]
    if parentNode != 0:
      subtreeSize[parentNode] = subtreeSize[parentNode] + subtreeSize[currentNode]
  let totalNodes = componentNodes.len
  var bestCentroid = componentNodes[0]
  var bestMaximum = totalNodes + 1
  for nodeIndex in componentNodes:
    var maximumPart = totalNodes - subtreeSize[nodeIndex]
    var edgePointer = adjacencyHead[nodeIndex]
    while edgePointer != -1:
      let neighborNode = edgeTarget[edgePointer]
      if not removed[neighborNode] and componentParent[neighborNode] == nodeIndex:
        if subtreeSize[neighborNode] > maximumPart:
          maximumPart = subtreeSize[neighborNode]
      edgePointer = edgeNext[edgePointer]
    if maximumPart < bestMaximum:
      bestMaximum = maximumPart
      bestCentroid = nodeIndex
  return bestCentroid

proc collectBranch(startNode: int, centroidIndex: int, branchId: int, initialDistance: int64) =
  var traversalStack = newSeq[int]()
  var distanceStack = newSeq[int64]()
  traversalStack.add startNode
  distanceStack.add initialDistance
  componentParent[startNode] = centroidIndex
  addPathEntry(startNode, centroidIndex, initialDistance, branchId)
  while traversalStack.len > 0:
    let currentNode = traversalStack[traversalStack.len - 1]
    let currentDistance = distanceStack[distanceStack.len - 1]
    traversalStack.setLen(traversalStack.len - 1)
    distanceStack.setLen(distanceStack.len - 1)
    var edgePointer = adjacencyHead[currentNode]
    while edgePointer != -1:
      let neighborNode = edgeTarget[edgePointer]
      if not removed[neighborNode] and neighborNode != componentParent[currentNode]:
        componentParent[neighborNode] = currentNode
        let branchDistance = currentDistance + int64(edgeWeight[edgePointer])
        addPathEntry(neighborNode, centroidIndex, branchDistance, branchId)
        traversalStack.add neighborNode
        distanceStack.add branchDistance
      edgePointer = edgeNext[edgePointer]

proc refreshCentroid(centroidIndex: int) =
  while centroidHeaps[centroidIndex].len > 0 and
        centroidHeaps[centroidIndex][0].secondField != branchVersion[centroidHeaps[centroidIndex][0].firstField]:
    discard heapPop(centroidHeaps[centroidIndex])
  var bestValue = negativeInfinite
  var bestBranch = -1
  var secondValue = negativeInfinite
  if centroidHeaps[centroidIndex].len > 0:
    let firstItem = heapPop(centroidHeaps[centroidIndex])
    bestValue = firstItem.value
    bestBranch = firstItem.firstField
    while centroidHeaps[centroidIndex].len > 0:
      let topItem = centroidHeaps[centroidIndex][0]
      if topItem.secondField != branchVersion[topItem.firstField]:
        discard heapPop(centroidHeaps[centroidIndex])
        continue
      if topItem.firstField != bestBranch:
        secondValue = topItem.value
        break
      discard heapPop(centroidHeaps[centroidIndex])
    heapPush(centroidHeaps[centroidIndex], firstItem)
  var contribution: int64 = 0
  if bestValue > negativeInfinite div 2:
    if secondValue > negativeInfinite div 2:
      contribution = bestValue + secondValue
    if contribution < 0:
      contribution = 0
  if contribution != centroidValue[centroidIndex]:
    centroidValue[centroidIndex] = contribution
    centroidVersion[centroidIndex] += 1
    heapPush(answerHeap, HeapNode(value: contribution, firstField: centroidIndex,
                                  secondField: centroidVersion[centroidIndex]))

proc refreshBranch(branchId: int, centroidIndex: int) =
  while branchHeaps[branchId].len > 0:
    let topItem = branchHeaps[branchId][0]
    if topItem.firstField == entryVersion[topItem.secondField]:
      break
    discard heapPop(branchHeaps[branchId])
  let newBest = if branchHeaps[branchId].len > 0: branchHeaps[branchId][0].value else: negativeInfinite
  if newBest != branchBest[branchId]:
    branchBest[branchId] = newBest
    branchVersion[branchId] += 1
    if newBest > negativeInfinite div 2:
      heapPush(centroidHeaps[centroidIndex], HeapNode(value: newBest, firstField: branchId,
                                                      secondField: branchVersion[branchId]))
    refreshCentroid(centroidIndex)

var decompositionStack = newSeq[int]()
decompositionStack.add 1
while decompositionStack.len > 0:
  let startNode = decompositionStack[decompositionStack.len - 1]
  decompositionStack.setLen(decompositionStack.len - 1)
  let componentNodes = collectComponent(startNode)
  let centroidIndex = findCentroid(componentNodes)
  let selfBranch = branchVersion.len
  branchVersion.add 0
  branchBest.add negativeInfinite
  branchCentroid.add centroidIndex
  branchHeaps.add newSeq[HeapNode]()
  addPathEntry(centroidIndex, centroidIndex, 0, selfBranch)
  var edgePointer = adjacencyHead[centroidIndex]
  while edgePointer != -1:
    let neighborNode = edgeTarget[edgePointer]
    if not removed[neighborNode]:
      let newBranch = branchVersion.len
      branchVersion.add 0
      branchBest.add negativeInfinite
      branchCentroid.add centroidIndex
      branchHeaps.add newSeq[HeapNode]()
      collectBranch(neighborNode, centroidIndex, newBranch, int64(edgeWeight[edgePointer]))
      decompositionStack.add neighborNode
    edgePointer = edgeNext[edgePointer]
  removed[centroidIndex] = true

for nodeIndex in 1 .. nodeCount:
  for pathEntry in nodeEntries[nodeIndex]:
    heapPush(branchHeaps[pathEntry.branchId], HeapNode(value: pathEntry.distance,
             firstField: 0, secondField: pathEntry.entryId))
for branchId in 0 .. branchVersion.len - 1:
  refreshBranch(branchId, branchCentroid[branchId])
for centroidIndex in 1 .. nodeCount:
  refreshCentroid(centroidIndex)

var isWhite = newSeq[bool](nodeCount + 1)
for nodeIndex in 1 .. nodeCount:
  isWhite[nodeIndex] = true
var whiteCount = nodeCount

proc toggleNode(nodeIndex: int) =
  let turningWhite = not isWhite[nodeIndex]
  isWhite[nodeIndex] = turningWhite
  if turningWhite:
    whiteCount += 1
  else:
    whiteCount -= 1
  for pathEntry in nodeEntries[nodeIndex]:
    let currentEntryId = pathEntry.entryId
    entryVersion[currentEntryId] += 1
    if turningWhite:
      heapPush(branchHeaps[pathEntry.branchId], HeapNode(value: pathEntry.distance,
               firstField: entryVersion[currentEntryId], secondField: currentEntryId))
    refreshBranch(pathEntry.branchId, pathEntry.centroid)

let queryCount = nextInt(inputData, scanPos)
for queryIndex in 0 .. queryCount - 1:
  while scanPos < inputData.len and inputData[scanPos] <= ' ':
    scanPos += 1
  if inputData[scanPos] == 'C':
    scanPos += 1
    let nodeIndex = nextInt(inputData, scanPos)
    toggleNode(nodeIndex)
  else:
    scanPos += 1
    while answerHeap.len > 0 and answerHeap[0].secondField != centroidVersion[answerHeap[0].firstField]:
      discard heapPop(answerHeap)
    if whiteCount == 0:
      appendOutput("They have disappeared.")
    else:
      var bestAnswer: int64 = 0
      if answerHeap.len > 0:
        bestAnswer = answerHeap[0].value
      appendOutput($bestAnswer)
    outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
