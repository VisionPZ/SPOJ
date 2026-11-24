const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const infiniteFlow = 1 shl 29

var head = newSeq[int](0)
var inHead = newSeq[int](0)
var toNode = newSeq[int](0)
var arcCap = newSeq[int](0)
var nextArc = newSeq[int](0)
var nextIn = newSeq[int](0)
var nodeHeight = newSeq[int](0)
var nodeExcess = newSeq[int](0)
var gapCount = newSeq[int](0)
var nodeDistance = newSeq[int](0)
var iterArc = newSeq[int](0)
var inQueue = newSeq[bool](0)
var activeQueue = newSeq[int](0)
var relabelQueue = newSeq[int](0)
var clientList = newSeq[int](0)
var edgeFirst = newSeq[int](0)
var edgeSecond = newSeq[int](0)
var arcCount = 0
var nodeCount = 0
var queueFront = 0
var queueBack = 0
var pushCounter = 0

proc nextInt(data: string, scanPos: var int): int =
  while scanPos < data.len and (data[scanPos] < '0' or data[scanPos] > '9'):
    scanPos += 1
  result = 0
  while scanPos < data.len and data[scanPos] >= '0' and data[scanPos] <= '9':
    result = result * 10 + (int(data[scanPos]) - firstDigitValue)
    scanPos += 1

proc reverseArcIndex(arcIndex: int): int =
  if arcIndex mod 2 == 0: arcIndex + 1 else: arcIndex - 1

proc addArc(fromNode, targetNode, capacity: int) =
  toNode[arcCount] = targetNode
  arcCap[arcCount] = capacity
  nextArc[arcCount] = head[fromNode]
  head[fromNode] = arcCount
  nextIn[arcCount] = inHead[targetNode]
  inHead[targetNode] = arcCount
  arcCount += 1
  toNode[arcCount] = fromNode
  arcCap[arcCount] = 0
  nextArc[arcCount] = head[targetNode]
  head[targetNode] = arcCount
  nextIn[arcCount] = inHead[fromNode]
  inHead[fromNode] = arcCount
  arcCount += 1

proc addStreet(firstHouse, secondHouse, capacity: int) =
  addArc(firstHouse, secondHouse, capacity)
  addArc(secondHouse, firstHouse, capacity)

proc enqueueNode(nodeIndex: int) =
  if nodeIndex != 0 and nodeIndex != 1 and not inQueue[nodeIndex]:
    inQueue[nodeIndex] = true
    activeQueue[queueBack mod activeQueue.len] = nodeIndex
    queueBack += 1

proc globalRelabel(sinkNode: int) =
  for i in 0..nodeCount: nodeDistance[i] = -1
  var front = 0
  var back = 0
  nodeDistance[sinkNode] = 0
  relabelQueue[back] = sinkNode
  back += 1
  while front < back:
    let current = relabelQueue[front]
    front += 1
    var arcIndex = inHead[current]
    while arcIndex != -1:
      let previous = toNode[reverseArcIndex(arcIndex)]
      if arcCap[arcIndex] > 0 and nodeDistance[previous] == -1:
        nodeDistance[previous] = nodeDistance[current] + 1
        relabelQueue[back] = previous
        back += 1
      arcIndex = nextIn[arcIndex]
  for i in 0..nodeCount:
    let newHeight = if nodeDistance[i] == -1: nodeCount + 1 else: nodeDistance[i]
    if newHeight != nodeHeight[i]:
      gapCount[nodeHeight[i]] -= 1
      nodeHeight[i] = newHeight
      gapCount[nodeHeight[i]] += 1

proc relabelNode(nodeIndex: int) =
  let oldHeight = nodeHeight[nodeIndex]
  var minimum = infiniteFlow
  var arcIndex = head[nodeIndex]
  while arcIndex != -1:
    if arcCap[arcIndex] > 0:
      let neighbor = toNode[arcIndex]
      if nodeHeight[neighbor] < minimum: minimum = nodeHeight[neighbor]
    arcIndex = nextArc[arcIndex]
  gapCount[oldHeight] -= 1
  nodeHeight[nodeIndex] = minimum + 1
  gapCount[nodeHeight[nodeIndex]] += 1
  if gapCount[oldHeight] == 0 and oldHeight <= nodeCount:
    for i in 0..nodeCount:
      if nodeHeight[i] > oldHeight and nodeHeight[i] <= nodeCount:
        gapCount[nodeHeight[i]] -= 1
        nodeHeight[i] = nodeCount + 1
        gapCount[nodeHeight[i]] += 1

proc pushRelabel(sourceNode, sinkNode: int): int =
  queueFront = 0
  queueBack = 0
  pushCounter = 0
  for i in 0..nodeCount:
    nodeExcess[i] = 0
    nodeHeight[i] = 0
    inQueue[i] = false
    iterArc[i] = head[i]
    gapCount[i] = 0
  gapCount[nodeCount + 1] = 0
  gapCount[0] = nodeCount + 1
  nodeHeight[sourceNode] = nodeCount + 1
  gapCount[0] -= 1
  gapCount[nodeCount + 1] += 1
  var arcIndex = head[sourceNode]
  while arcIndex != -1:
    let available = arcCap[arcIndex]
    if available > 0:
      arcCap[arcIndex] = 0
      arcCap[reverseArcIndex(arcIndex)] += available
      let neighbor = toNode[arcIndex]
      nodeExcess[neighbor] += available
      enqueueNode(neighbor)
    arcIndex = nextArc[arcIndex]
  while queueFront < queueBack:
    let current = activeQueue[queueFront mod activeQueue.len]
    queueFront += 1
    inQueue[current] = false
    while nodeExcess[current] > 0:
      var edgeIndex = iterArc[current]
      while edgeIndex != -1:
        let neighbor = toNode[edgeIndex]
        if arcCap[edgeIndex] > 0 and nodeHeight[neighbor] + 1 == nodeHeight[current]:
          let amount = min(nodeExcess[current], arcCap[edgeIndex])
          arcCap[edgeIndex] -= amount
          arcCap[reverseArcIndex(edgeIndex)] += amount
          nodeExcess[current] -= amount
          nodeExcess[neighbor] += amount
          enqueueNode(neighbor)
          pushCounter += 1
          if nodeExcess[current] == 0: break
        edgeIndex = nextArc[edgeIndex]
      iterArc[current] = edgeIndex
      if nodeExcess[current] > 0:
        if iterArc[current] == -1:
          if pushCounter mod (nodeCount * 4 + 1) == 0: globalRelabel(sinkNode)
          relabelNode(current)
          iterArc[current] = head[current]
        else:
          iterArc[current] = nextArc[iterArc[current]]
  return nodeExcess[sinkNode]

proc enoughColors(capacity: int): bool =
  for i in 0..nodeCount:
    head[i] = -1
    inHead[i] = -1
  arcCount = 0
  for i in 0..<clientList.len:
    addArc(0, clientList[i], 1)
  for i in 0..<edgeFirst.len:
    addStreet(edgeFirst[i], edgeSecond[i], capacity)
  return pushRelabel(0, 1) == clientList.len

let inputData = stdin.readAll()
var scanPos = 0
let caseCount = nextInt(inputData, scanPos)
var outputBuffer = ""

for caseIndex in 0..<caseCount:
  let houseCount = nextInt(inputData, scanPos)
  let streetCount = nextInt(inputData, scanPos)
  let clientCount = nextInt(inputData, scanPos)
  nodeCount = houseCount
  if head.len <= houseCount:
    head.setLen(houseCount + 1)
    inHead.setLen(houseCount + 1)
    nodeHeight.setLen(houseCount + 1)
    nodeExcess.setLen(houseCount + 1)
    nodeDistance.setLen(houseCount + 1)
    iterArc.setLen(houseCount + 1)
    inQueue.setLen(houseCount + 1)
    activeQueue.setLen(houseCount + 2)
    relabelQueue.setLen(houseCount + 2)
  if gapCount.len < 2 * houseCount + 4: gapCount.setLen(2 * houseCount + 4)
  let neededArcs = 4 * streetCount + 2 * clientCount + 4
  if toNode.len < neededArcs:
    toNode.setLen(neededArcs)
    arcCap.setLen(neededArcs)
    nextArc.setLen(neededArcs)
    nextIn.setLen(neededArcs)
  clientList.setLen(clientCount)
  for i in 0..<clientCount: clientList[i] = nextInt(inputData, scanPos)
  edgeFirst.setLen(streetCount)
  edgeSecond.setLen(streetCount)
  for i in 0..<streetCount:
    edgeFirst[i] = nextInt(inputData, scanPos)
    edgeSecond[i] = nextInt(inputData, scanPos)
  var lowerBound = 0
  var upperBound = clientCount + 1
  while upperBound - lowerBound > 1:
    let middle = (lowerBound + upperBound) div 2
    if enoughColors(middle): upperBound = middle
    else: lowerBound = middle
  outputBuffer.add($upperBound)
  outputBuffer.add('\n')
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

stdout.write outputBuffer
outputBuffer.setLen 0
