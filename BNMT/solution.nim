const flushBlockBytes = 1 shl 17
const infiniteDistance = 1000000000

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

proc nextBit(data: string, pos: var int): int =
  while pos < data.len and data[pos] != '0' and data[pos] != '1':
    pos += 1
  let value = int(data[pos]) - 48
  pos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

type
  FlowEdge = object
    targetNode: int
    capacity: int
    cost: int
    reverseIndex: int

proc greatestCommonDivisor(leftValue, rightValue: int): int =
  var firstValue = leftValue
  var secondValue = rightValue
  while secondValue != 0:
    let remainder = firstValue mod secondValue
    firstValue = secondValue
    secondValue = remainder
  return firstValue

proc minimumZeroCells(rowCount, colCount: int, cells: seq[int],
                      targetOnes, rowTarget, columnTarget: int): int =
  let sourceNode = rowCount + colCount
  let sinkNode = sourceNode + 1
  let nodeCount = sinkNode + 1
  var graph = newSeq[seq[FlowEdge]](nodeCount)
  proc addEdge(fromNode, toNode, capacity, cost: int) =
    let forwardIndex = graph[fromNode].len
    graph[fromNode].add FlowEdge(targetNode: toNode, capacity: capacity,
                                  cost: cost, reverseIndex: graph[toNode].len)
    graph[toNode].add FlowEdge(targetNode: fromNode, capacity: 0,
                                cost: -cost, reverseIndex: forwardIndex)
  for rowIndex in 0 .. rowCount - 1:
    addEdge(sourceNode, rowIndex, rowTarget, 0)
  for columnIndex in 0 .. colCount - 1:
    addEdge(rowCount + columnIndex, sinkNode, columnTarget, 0)
  for rowIndex in 0 .. rowCount - 1:
    for columnIndex in 0 .. colCount - 1:
      let cellValue = cells[rowIndex * colCount + columnIndex]
      addEdge(rowIndex, rowCount + columnIndex, 1, if cellValue == 1: 0 else: 1)
  var sentFlow = 0
  var totalCost = 0
  while sentFlow < targetOnes:
    var distance = newSeq[int](nodeCount)
    var inQueue = newSeq[bool](nodeCount)
    var parentNode = newSeq[int](nodeCount)
    var parentEdge = newSeq[int](nodeCount)
    for nodeIndex in 0 .. nodeCount - 1:
      distance[nodeIndex] = infiniteDistance
    var queue = newSeq[int](0)
    queue.add sourceNode
    distance[sourceNode] = 0
    inQueue[sourceNode] = true
    var queueHead = 0
    while queueHead < queue.len:
      let currentNode = queue[queueHead]
      queueHead += 1
      inQueue[currentNode] = false
      for edgeIndex in 0 .. graph[currentNode].len - 1:
        let edge = graph[currentNode][edgeIndex]
        if edge.capacity > 0 and distance[currentNode] + edge.cost < distance[edge.targetNode]:
          distance[edge.targetNode] = distance[currentNode] + edge.cost
          parentNode[edge.targetNode] = currentNode
          parentEdge[edge.targetNode] = edgeIndex
          if not inQueue[edge.targetNode]:
            inQueue[edge.targetNode] = true
            queue.add edge.targetNode
    if distance[sinkNode] == infiniteDistance:
      return -1
    var augment = targetOnes - sentFlow
    var cursor = sinkNode
    while cursor != sourceNode:
      let previousNode = parentNode[cursor]
      let edgeCapacity = graph[previousNode][parentEdge[cursor]].capacity
      if edgeCapacity < augment:
        augment = edgeCapacity
      cursor = previousNode
    cursor = sinkNode
    while cursor != sourceNode:
      let previousNode = parentNode[cursor]
      let edgeIndex = parentEdge[cursor]
      let reverseIndex = graph[previousNode][edgeIndex].reverseIndex
      graph[previousNode][edgeIndex].capacity -= augment
      graph[cursor][reverseIndex].capacity += augment
      cursor = previousNode
    sentFlow += augment
    totalCost += augment * distance[sinkNode]
  return totalCost

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let rowCount = nextInt(inputData, scanPos)
  let colCount = nextInt(inputData, scanPos)
  var cells = newSeq[int](rowCount * colCount)
  var oneCount = 0
  for cellIndex in 0 .. rowCount * colCount - 1:
    cells[cellIndex] = nextBit(inputData, scanPos)
    oneCount += cells[cellIndex]
  let divisor = greatestCommonDivisor(rowCount, colCount)
  let stepSize = colCount div divisor
  var candidates = newSeq[int](0)
  var rowTarget = 0
  while rowTarget <= colCount:
    candidates.add rowTarget
    rowTarget += stepSize
  for candidateIndex in 1 .. candidates.len - 1:
    let candidate = candidates[candidateIndex]
    let candidateGap = abs(oneCount - candidate * rowCount)
    var previousIndex = candidateIndex - 1
    while previousIndex >= 0 and abs(oneCount - candidates[previousIndex] * rowCount) > candidateGap:
      candidates[previousIndex + 1] = candidates[previousIndex]
      previousIndex -= 1
    candidates[previousIndex + 1] = candidate
  var answer = oneCount
  for candidateIndex in 0 .. candidates.len - 1:
    let candidate = candidates[candidateIndex]
    let targetOnes = candidate * rowCount
    let columnTarget = targetOnes div colCount
    let lowerBound = oneCount - targetOnes
    if abs(lowerBound) >= answer:
      continue
    let zeroCells = minimumZeroCells(rowCount, colCount, cells,
                                     targetOnes, candidate, columnTarget)
    if zeroCells >= 0:
      let flips = lowerBound + 2 * zeroCells
      if flips < answer:
        answer = flips
  appendOutput("Case " & $(caseIndex + 1) & ": " & $answer)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
