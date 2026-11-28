const firstDigitValue = 48
const flushBlockBytes = 1 shl 16
const unreachableCost = 1 shl 28

proc nextInt(inputData: string, scanPos: var int): int =
  while scanPos < inputData.len and inputData[scanPos] <= ' ':
    scanPos += 1
  var parsedValue = 0
  while scanPos < inputData.len and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    parsedValue = parsedValue * 10 + int(inputData[scanPos]) - firstDigitValue
    scanPos += 1
  return parsedValue

var labelKeys: seq[int]
var labelIds: seq[int]
var nodeCount = 0
var hashMask = 0

proc prepareLabelTable(expectedLabels: int) =
  var tableSize = 1024
  while tableSize < expectedLabels * 2:
    tableSize = tableSize * 2
  hashMask = tableSize - 1
  labelKeys = newSeq[int](tableSize)
  labelIds = newSeq[int](tableSize)
  for slot in 0..<tableSize:
    labelKeys[slot] = -1
    labelIds[slot] = -1
  nodeCount = 0

proc idForLabel(label: int): int =
  var slot = (label * 1000003) and hashMask
  while true:
    if labelKeys[slot] == -1:
      nodeCount += 1
      labelKeys[slot] = label
      labelIds[slot] = nodeCount - 1
      return nodeCount - 1
    if labelKeys[slot] == label:
      return labelIds[slot]
    slot = (slot + 1) and hashMask

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add "\n"

var scanPos = 0
var caseCount = nextInt(inputData, scanPos)
var outputBuffer = ""

var cardLabels: seq[int]
var cardNodes: seq[int]
var cardRows: seq[int]
var edgeLeft: seq[int]
var edgeRight: seq[int]
var edgeFrom: seq[int]
var edgeTo: seq[int]
var targetNodes: seq[int]
var targetSlot: seq[int]
var adjacencyStart: seq[int]
var adjacencyTo: seq[int]
var seenStamp: seq[int]
var seenDist: seq[int]
var searchQueue: seq[int]
var nodeRowIndex: seq[int]
var distinctNodes: seq[int]
var rowData: seq[int]
var costData: seq[int]
var hungarianU: seq[int]
var hungarianV: seq[int]
var hungarianMatch: seq[int]
var hungarianWay: seq[int]
var hungarianMin: seq[int]
var hungarianUsed: seq[bool]
var currentStamp = 0
var rowOffset = 0
var remainingTargets = 0

for caseIndex in 0..<caseCount:
  let cardCount = nextInt(inputData, scanPos)
  cardLabels.setLen(cardCount)
  for k in 0..<cardCount:
    cardLabels[k] = nextInt(inputData, scanPos)
  let edgeCount = nextInt(inputData, scanPos)
  edgeLeft.setLen(edgeCount)
  edgeRight.setLen(edgeCount)
  for k in 0..<edgeCount:
    edgeLeft[k] = nextInt(inputData, scanPos)
    edgeRight[k] = nextInt(inputData, scanPos)

  prepareLabelTable(cardCount * 2 + edgeCount * 2 + 16)
  targetNodes.setLen(cardCount)
  for k in 0..<cardCount:
    targetNodes[k] = idForLabel(k + 1)
  cardNodes.setLen(cardCount)
  for k in 0..<cardCount:
    cardNodes[k] = idForLabel(cardLabels[k])
  edgeFrom.setLen(edgeCount)
  edgeTo.setLen(edgeCount)
  for k in 0..<edgeCount:
    edgeFrom[k] = idForLabel(edgeLeft[k])
    edgeTo[k] = idForLabel(edgeRight[k])

  adjacencyStart = newSeq[int](nodeCount + 1)
  for node in 0..<nodeCount:
    adjacencyStart[node] = 0
  for k in 0..<edgeCount:
    adjacencyStart[edgeFrom[k] + 1] += 1
    adjacencyStart[edgeTo[k] + 1] += 1
  for node in 0..<nodeCount:
    adjacencyStart[node + 1] += adjacencyStart[node]
  var adjacencyFill = newSeq[int](nodeCount)
  for node in 0..<nodeCount:
    adjacencyFill[node] = adjacencyStart[node]
  adjacencyTo = newSeq[int](edgeCount * 2)
  for k in 0..<edgeCount:
    let leftNode = edgeFrom[k]
    let rightNode = edgeTo[k]
    adjacencyTo[adjacencyFill[leftNode]] = rightNode
    adjacencyFill[leftNode] += 1
    adjacencyTo[adjacencyFill[rightNode]] = leftNode
    adjacencyFill[rightNode] += 1

  targetSlot = newSeq[int](nodeCount)
  for node in 0..<nodeCount:
    targetSlot[node] = -1
  for k in 0..<cardCount:
    targetSlot[targetNodes[k]] = k

  nodeRowIndex = newSeq[int](nodeCount)
  for node in 0..<nodeCount:
    nodeRowIndex[node] = -1
  distinctNodes.setLen(0)
  cardRows.setLen(cardCount)
  for k in 0..<cardCount:
    let node = cardNodes[k]
    if nodeRowIndex[node] == -1:
      nodeRowIndex[node] = distinctNodes.len
      distinctNodes.add node
    cardRows[k] = nodeRowIndex[node]

  rowData = newSeq[int](distinctNodes.len * cardCount)
  for k in 0..<rowData.len:
    rowData[k] = unreachableCost
  seenStamp = newSeq[int](nodeCount)
  seenDist = newSeq[int](nodeCount)
  searchQueue.setLen(nodeCount)

  for rowIndex in 0..<distinctNodes.len:
    currentStamp += 1
    rowOffset = rowIndex * cardCount
    remainingTargets = cardCount
    var queueHead = 0
    var queueTail = 0
    let startNode = distinctNodes[rowIndex]
    searchQueue[0] = startNode
    queueTail = 1
    seenStamp[startNode] = currentStamp
    seenDist[startNode] = 0
    while queueHead < queueTail:
      let node = searchQueue[queueHead]
      queueHead += 1
      let nodeDistance = seenDist[node]
      let slot = targetSlot[node]
      if slot >= 0 and rowData[rowOffset + slot] == unreachableCost:
        rowData[rowOffset + slot] = nodeDistance
        remainingTargets -= 1
        if remainingTargets == 0: break
      for arcIndex in adjacencyStart[node]..<adjacencyStart[node + 1]:
        let neighbor = adjacencyTo[arcIndex]
        if seenStamp[neighbor] != currentStamp:
          seenStamp[neighbor] = currentStamp
          seenDist[neighbor] = nodeDistance + 1
          searchQueue[queueTail] = neighbor
          queueTail += 1

  costData = newSeq[int](cardCount * cardCount)
  for rowIndex in 0..<cardCount:
    let sourceOffset = cardRows[rowIndex] * cardCount
    let destinationOffset = rowIndex * cardCount
    for k in 0..<cardCount:
      costData[destinationOffset + k] = rowData[sourceOffset + k]

  hungarianU = newSeq[int](cardCount + 1)
  hungarianV = newSeq[int](cardCount + 1)
  hungarianMatch = newSeq[int](cardCount + 1)
  hungarianWay = newSeq[int](cardCount + 1)
  hungarianMin = newSeq[int](cardCount + 1)
  hungarianUsed = newSeq[bool](cardCount + 1)
  for rowIndex in 1..cardCount:
    hungarianMatch[0] = rowIndex
    var columnZero = 0
    for k in 0..cardCount:
      hungarianMin[k] = unreachableCost
      hungarianUsed[k] = false
    while true:
      hungarianUsed[columnZero] = true
      let rowZero = hungarianMatch[columnZero]
      var delta = unreachableCost
      var columnOne = 0
      for column in 1..cardCount:
        if not hungarianUsed[column]:
          let directCost = costData[(rowZero - 1) * cardCount + (column - 1)]
          let reducedCost = directCost - hungarianU[rowZero] - hungarianV[column]
          if reducedCost < hungarianMin[column]:
            hungarianMin[column] = reducedCost
            hungarianWay[column] = columnZero
          if hungarianMin[column] < delta:
            delta = hungarianMin[column]
            columnOne = column
      for column in 0..cardCount:
        if hungarianUsed[column]:
          hungarianU[hungarianMatch[column]] += delta
          hungarianV[column] -= delta
        else:
          hungarianMin[column] -= delta
      columnZero = columnOne
      if hungarianMatch[columnZero] == 0: break
    while true:
      let previousColumn = hungarianWay[columnZero]
      hungarianMatch[columnZero] = hungarianMatch[previousColumn]
      columnZero = previousColumn
      if columnZero == 0: break

  let bestCost = -hungarianV[0]
  outputBuffer.add $bestCost
  outputBuffer.add "\n"
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

stdout.write outputBuffer
outputBuffer.setLen 0
