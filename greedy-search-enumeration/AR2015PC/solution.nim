const flushBlockBytes = 1 shl 17
const infinityDistance = 1 shl 60
const liftLevels = 17

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

var nodeCount = 0
var graphHead = newSeq[int](0)
var graphTo = newSeq[int](0)
var graphNext = newSeq[int](0)
var graphWeight = newSeq[int](0)
var treeHead = newSeq[int](0)
var treeTo = newSeq[int](0)
var treeNext = newSeq[int](0)
var treeWeight = newSeq[int](0)
var nodeDepths = newSeq[int](0)
var rootDistances = newSeq[int](0)
var liftTable = newSeq[seq[int]](0)
var unionParent = newSeq[int](0)

proc findRoot(nodeIndex: int): int =
  var currentNode = nodeIndex
  while unionParent[currentNode] != currentNode:
    unionParent[currentNode] = unionParent[unionParent[currentNode]]
    currentNode = unionParent[currentNode]
  return currentNode

proc lowestCommonAncestor(firstNode: int, secondNode: int): int =
  var firstWalker = firstNode
  var secondWalker = secondNode
  if nodeDepths[firstWalker] < nodeDepths[secondWalker]:
    swap firstWalker, secondWalker
  var depthGap = nodeDepths[firstWalker] - nodeDepths[secondWalker]
  var levelIndex = 0
  while depthGap > 0:
    if (depthGap and 1) != 0:
      firstWalker = liftTable[levelIndex][firstWalker]
    depthGap = depthGap div 2
    levelIndex += 1
  if firstWalker == secondWalker:
    return firstWalker
  for levelIndex in countdown(liftLevels, 0):
    if liftTable[levelIndex][firstWalker] != liftTable[levelIndex][secondWalker]:
      firstWalker = liftTable[levelIndex][firstWalker]
      secondWalker = liftTable[levelIndex][secondWalker]
  return liftTable[0][firstWalker]

proc treeDistance(firstNode: int, secondNode: int): int =
  let meetingNode = lowestCommonAncestor(firstNode, secondNode)
  return rootDistances[firstNode] + rootDistances[secondNode] - 2 * rootDistances[meetingNode]

proc shortestDistances(sourceNode: int): seq[int] =
  var distances = newSeq[int](nodeCount + 1)
  for nodeIndex in 0 .. nodeCount:
    distances[nodeIndex] = infinityDistance
  var heapNodes = newSeq[int](1)
  var heapPriorities = newSeq[int](1)
  heapNodes[0] = sourceNode
  heapPriorities[0] = 0
  distances[sourceNode] = 0
  while heapNodes.len > 0:
    let currentNode = heapNodes[0]
    let currentDistance = heapPriorities[0]
    let lastNode = heapNodes[heapNodes.len - 1]
    let lastPriority = heapPriorities[heapPriorities.len - 1]
    heapNodes.setLen(heapNodes.len - 1)
    heapPriorities.setLen(heapPriorities.len - 1)
    if heapNodes.len > 0:
      var position = 0
      while true:
        let leftChild = 2 * position + 1
        if leftChild >= heapNodes.len:
          break
        let rightChild = leftChild + 1
        var smallerChild = leftChild
        if rightChild < heapNodes.len and heapPriorities[rightChild] < heapPriorities[leftChild]:
          smallerChild = rightChild
        if heapPriorities[smallerChild] >= lastPriority:
          break
        heapNodes[position] = heapNodes[smallerChild]
        heapPriorities[position] = heapPriorities[smallerChild]
        position = smallerChild
      heapNodes[position] = lastNode
      heapPriorities[position] = lastPriority
    if currentDistance != distances[currentNode]:
      continue
    var edgeIndex = graphHead[currentNode]
    while edgeIndex != -1:
      let neighborNode = graphTo[edgeIndex]
      let candidateDistance = currentDistance + graphWeight[edgeIndex]
      if candidateDistance < distances[neighborNode]:
        distances[neighborNode] = candidateDistance
        var position = heapNodes.len
        heapNodes.add neighborNode
        heapPriorities.add candidateDistance
        while position > 0:
          let parentPosition = (position - 1) div 2
          if heapPriorities[parentPosition] <= candidateDistance:
            break
          heapNodes[position] = heapNodes[parentPosition]
          heapPriorities[position] = heapPriorities[parentPosition]
          position = parentPosition
        heapNodes[position] = neighborNode
        heapPriorities[position] = candidateDistance
      edgeIndex = graphNext[edgeIndex]
  return distances

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 1 .. caseCount:
  nodeCount = nextInt(inputData, scanPos)
  let roadCount = nextInt(inputData, scanPos)
  let planCount = nextInt(inputData, scanPos)

  graphHead = newSeq[int](nodeCount + 1)
  treeHead = newSeq[int](nodeCount + 1)
  for nodeIndex in 1 .. nodeCount:
    graphHead[nodeIndex] = -1
    treeHead[nodeIndex] = -1
  graphTo = newSeq[int](2 * roadCount)
  graphNext = newSeq[int](2 * roadCount)
  graphWeight = newSeq[int](2 * roadCount)
  treeTo = newSeq[int](2 * max(0, nodeCount - 1))
  treeNext = newSeq[int](2 * max(0, nodeCount - 1))
  treeWeight = newSeq[int](2 * max(0, nodeCount - 1))
  unionParent = newSeq[int](nodeCount + 1)
  for nodeIndex in 1 .. nodeCount:
    unionParent[nodeIndex] = nodeIndex

  var graphEdgeCount = 0
  var treeEdgeCount = 0
  var extraFrom = newSeq[int](0)
  var extraTo = newSeq[int](0)
  var extraWeight = newSeq[int](0)
  for roadIndex in 0 .. roadCount - 1:
    let roadFrom = nextInt(inputData, scanPos)
    let roadTo = nextInt(inputData, scanPos)
    let roadLength = nextInt(inputData, scanPos)
    graphTo[graphEdgeCount] = roadTo
    graphWeight[graphEdgeCount] = roadLength
    graphNext[graphEdgeCount] = graphHead[roadFrom]
    graphHead[roadFrom] = graphEdgeCount
    graphEdgeCount += 1
    graphTo[graphEdgeCount] = roadFrom
    graphWeight[graphEdgeCount] = roadLength
    graphNext[graphEdgeCount] = graphHead[roadTo]
    graphHead[roadTo] = graphEdgeCount
    graphEdgeCount += 1
    let fromRoot = findRoot(roadFrom)
    let toRoot = findRoot(roadTo)
    if fromRoot != toRoot:
      unionParent[fromRoot] = toRoot
      treeTo[treeEdgeCount] = roadTo
      treeWeight[treeEdgeCount] = roadLength
      treeNext[treeEdgeCount] = treeHead[roadFrom]
      treeHead[roadFrom] = treeEdgeCount
      treeEdgeCount += 1
      treeTo[treeEdgeCount] = roadFrom
      treeWeight[treeEdgeCount] = roadLength
      treeNext[treeEdgeCount] = treeHead[roadTo]
      treeHead[roadTo] = treeEdgeCount
      treeEdgeCount += 1
    else:
      extraFrom.add roadFrom
      extraTo.add roadTo
      extraWeight.add roadLength

  nodeDepths = newSeq[int](nodeCount + 1)
  rootDistances = newSeq[int](nodeCount + 1)
  liftTable = newSeq[seq[int]](liftLevels + 1)
  for levelIndex in 0 .. liftLevels:
    liftTable[levelIndex] = newSeq[int](nodeCount + 1)
  var traversalStack = newSeq[int](1)
  traversalStack[0] = 1
  liftTable[0][1] = 1
  while traversalStack.len > 0:
    let currentNode = traversalStack[traversalStack.len - 1]
    traversalStack.setLen(traversalStack.len - 1)
    var edgeIndex = treeHead[currentNode]
    while edgeIndex != -1:
      let neighborNode = treeTo[edgeIndex]
      if neighborNode != liftTable[0][currentNode]:
        liftTable[0][neighborNode] = currentNode
        nodeDepths[neighborNode] = nodeDepths[currentNode] + 1
        rootDistances[neighborNode] = rootDistances[currentNode] + treeWeight[edgeIndex]
        traversalStack.add neighborNode
      edgeIndex = treeNext[edgeIndex]
  for levelIndex in 1 .. liftLevels:
    for nodeIndex in 1 .. nodeCount:
      let middleNode = liftTable[levelIndex - 1][nodeIndex]
      liftTable[levelIndex][nodeIndex] = liftTable[levelIndex - 1][middleNode]

  var specialNodes = newSeq[int](0)
  for extraIndex in 0 .. extraFrom.len - 1:
    if extraWeight[extraIndex] < treeDistance(extraFrom[extraIndex], extraTo[extraIndex]):
      var fromSeen = false
      var toSeen = false
      for specialIndex in 0 .. specialNodes.len - 1:
        if specialNodes[specialIndex] == extraFrom[extraIndex]:
          fromSeen = true
        if specialNodes[specialIndex] == extraTo[extraIndex]:
          toSeen = true
      if not fromSeen:
        specialNodes.add extraFrom[extraIndex]
      if not toSeen:
        specialNodes.add extraTo[extraIndex]

  var distanceTables = newSeq[seq[int]](specialNodes.len)
  for specialIndex in 0 .. specialNodes.len - 1:
    distanceTables[specialIndex] = shortestDistances(specialNodes[specialIndex])

  appendOutput("Case " & $caseIndex & ":")
  outputBuffer.add '\n'
  for planIndex in 0 .. planCount - 1:
    let meetNode = nextInt(inputData, scanPos)
    let targetNode = nextInt(inputData, scanPos)
    var bestDistance = treeDistance(meetNode, targetNode)
    for specialIndex in 0 .. specialNodes.len - 1:
      let viaSpecial = distanceTables[specialIndex][meetNode] + distanceTables[specialIndex][targetNode]
      if viaSpecial < bestDistance:
        bestDistance = viaSpecial
    appendOutput($bestDistance)
    outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
