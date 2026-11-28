const flushBlockBytes = 1 shl 17
const maxNodes = 50
const unreachableCost = 1000000000

type
  HeapItem = object
    cost: int
    node: int
    pathId: int

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

var edgeWeights: array[maxNodes + 1, array[maxNodes + 1, int]]
var distanceToGoal: array[maxNodes + 1, int]
var goalNode = 0
var nodeCount = 0
var pathNodes = newSeq[int](0)
var pathParents = newSeq[int](0)
var pathMasks = newSeq[uint64](0)

proc lexLessPath(firstId: int, secondId: int): bool =
  var firstOrder: array[maxNodes + 1, int]
  var secondOrder: array[maxNodes + 1, int]
  var firstLength = 0
  var currentId = firstId
  while currentId >= 0:
    firstOrder[firstLength] = pathNodes[currentId]
    firstLength = firstLength + 1
    currentId = pathParents[currentId]
  var secondLength = 0
  currentId = secondId
  while currentId >= 0:
    secondOrder[secondLength] = pathNodes[currentId]
    secondLength = secondLength + 1
    currentId = pathParents[currentId]
  var firstPos = firstLength - 1
  var secondPos = secondLength - 1
  while firstPos >= 0 and secondPos >= 0:
    if firstOrder[firstPos] != secondOrder[secondPos]:
      return firstOrder[firstPos] < secondOrder[secondPos]
    firstPos = firstPos - 1
    secondPos = secondPos - 1
  return firstLength <= secondLength

proc heapLess(firstItem: HeapItem, secondItem: HeapItem): bool =
  if firstItem.cost != secondItem.cost:
    return firstItem.cost < secondItem.cost
  return lexLessPath(firstItem.pathId, secondItem.pathId)

proc pushItem(heap: var seq[HeapItem], item: HeapItem) =
  heap.add item
  var index = heap.len - 1
  while index > 0:
    let parentIndex = (index - 1) div 2
    if heapLess(heap[index], heap[parentIndex]):
      swap heap[index], heap[parentIndex]
      index = parentIndex
    else:
      break

proc popItem(heap: var seq[HeapItem]): HeapItem =
  result = heap[0]
  let lastIndex = heap.len - 1
  heap[0] = heap[lastIndex]
  heap.setLen(lastIndex)
  var index = 0
  while true:
    let leftChild = 2 * index + 1
    let rightChild = leftChild + 1
    var smallestIndex = index
    if leftChild < heap.len and heapLess(heap[leftChild], heap[smallestIndex]):
      smallestIndex = leftChild
    if rightChild < heap.len and heapLess(heap[rightChild], heap[smallestIndex]):
      smallestIndex = rightChild
    if smallestIndex == index:
      break
    swap heap[index], heap[smallestIndex]
    index = smallestIndex

proc findGoalDistances() =
  var visited: array[maxNodes + 1, bool]
  for node in 1 .. nodeCount:
    distanceToGoal[node] = unreachableCost
    visited[node] = false
  distanceToGoal[goalNode] = 0
  for step in 1 .. nodeCount:
    var chosenNode = 0
    var bestDistance = unreachableCost
    for node in 1 .. nodeCount:
      if not visited[node] and distanceToGoal[node] < bestDistance:
        bestDistance = distanceToGoal[node]
        chosenNode = node
    if chosenNode == 0:
      break
    visited[chosenNode] = true
    for predecessor in 1 .. nodeCount:
      let edgeLength = edgeWeights[predecessor][chosenNode]
      if edgeLength > 0 and not visited[predecessor]:
        let candidate = bestDistance + edgeLength
        if candidate < distanceToGoal[predecessor]:
          distanceToGoal[predecessor] = candidate

proc appendPathFromId(pathId: int) =
  var pathOrder: array[maxNodes + 1, int]
  var pathLength = 0
  var currentId = pathId
  while currentId >= 0:
    pathOrder[pathLength] = pathNodes[currentId]
    pathLength = pathLength + 1
    currentId = pathParents[currentId]
  var pathText = ""
  var position = pathLength - 1
  while position >= 0:
    if position < pathLength - 1:
      pathText.add '-'
    pathText.add $pathOrder[position]
    position = position - 1
  appendOutput(pathText)
  outputBuffer.add '\n'

while true:
  let datasetNodes = nextInt(inputData, scanPos)
  let datasetEdges = nextInt(inputData, scanPos)
  let wantedRank = nextInt(inputData, scanPos)
  let startNode = nextInt(inputData, scanPos)
  goalNode = nextInt(inputData, scanPos)
  if datasetNodes == 0 and datasetEdges == 0 and wantedRank == 0 and
     startNode == 0 and goalNode == 0:
    break
  nodeCount = datasetNodes
  for fromNode in 1 .. nodeCount:
    for toNode in 1 .. nodeCount:
      edgeWeights[fromNode][toNode] = 0
  for edgeIndex in 0 .. datasetEdges - 1:
    let fromNode = nextInt(inputData, scanPos)
    let toNode = nextInt(inputData, scanPos)
    let edgeLength = nextInt(inputData, scanPos)
    edgeWeights[fromNode][toNode] = edgeLength
  findGoalDistances()
  pathNodes.setLen(0)
  pathParents.setLen(0)
  pathMasks.setLen(0)
  pathNodes.add startNode
  pathParents.add -1
  pathMasks.add uint64(1) shl uint64(startNode)
  var heap = newSeq[HeapItem](0)
  pushItem(heap, HeapItem(cost: 0, node: startNode, pathId: 0))
  var foundPaths = newSeq[int](0)
  while heap.len > 0 and foundPaths.len < wantedRank:
    let currentItem = popItem(heap)
    if currentItem.node == goalNode:
      foundPaths.add currentItem.pathId
      continue
    for neighbour in 1 .. nodeCount:
      let edgeLength = edgeWeights[currentItem.node][neighbour]
      if edgeLength == 0 or distanceToGoal[neighbour] >= unreachableCost:
        continue
      let neighbourBit = uint64(1) shl uint64(neighbour)
      if (pathMasks[currentItem.pathId] and neighbourBit) != 0:
        continue
      let newPathId = pathNodes.len
      pathNodes.add neighbour
      pathParents.add currentItem.pathId
      pathMasks.add pathMasks[currentItem.pathId] or neighbourBit
      pushItem(heap, HeapItem(cost: currentItem.cost + edgeLength,
                              node: neighbour, pathId: newPathId))
  if foundPaths.len >= wantedRank:
    appendPathFromId(foundPaths[wantedRank - 1])
  else:
    appendOutput("None")
    outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
