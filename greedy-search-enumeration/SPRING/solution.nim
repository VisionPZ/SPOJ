const flushBlockBytes = 1 shl 17
const infiniteWeight = 1e100

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

proc atEnd(data: string, pos: int): bool =
  var cursor = pos
  while cursor < data.len and (data[cursor] < '0' or data[cursor] > '9'):
    cursor += 1
  return cursor >= data.len

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc pushHeap(weightHeap: var seq[float], nodeHeap: var seq[int], weight: float, node: int) =
  weightHeap.add weight
  nodeHeap.add node
  var childIndex = weightHeap.len - 1
  while childIndex > 0:
    let parentIndex = (childIndex - 1) div 2
    if weightHeap[parentIndex] <= weightHeap[childIndex]:
      break
    swap weightHeap[parentIndex], weightHeap[childIndex]
    swap nodeHeap[parentIndex], nodeHeap[childIndex]
    childIndex = parentIndex

proc popHeap(weightHeap: var seq[float], nodeHeap: var seq[int]): tuple[weight: float, node: int] =
  let topWeight = weightHeap[0]
  let topNode = nodeHeap[0]
  let lastWeight = weightHeap[weightHeap.len - 1]
  let lastNode = nodeHeap[nodeHeap.len - 1]
  weightHeap.setLen(weightHeap.len - 1)
  nodeHeap.setLen(nodeHeap.len - 1)
  if weightHeap.len > 0:
    weightHeap[0] = lastWeight
    nodeHeap[0] = lastNode
    var parentIndex = 0
    while true:
      let leftChild = parentIndex * 2 + 1
      if leftChild >= weightHeap.len:
        break
      let rightChild = leftChild + 1
      var smallerChild = leftChild
      if rightChild < weightHeap.len and weightHeap[rightChild] < weightHeap[leftChild]:
        smallerChild = rightChild
      if weightHeap[parentIndex] <= weightHeap[smallerChild]:
        break
      swap weightHeap[parentIndex], weightHeap[smallerChild]
      swap nodeHeap[parentIndex], nodeHeap[smallerChild]
      parentIndex = smallerChild
  return (topWeight, topNode)

while not atEnd(inputData, scanPos):
  let barCount = nextInt(inputData, scanPos)
  let springCount = nextInt(inputData, scanPos)
  let targetDistance = nextInt(inputData, scanPos)
  var springLeft = newSeq[int](springCount)
  var springRight = newSeq[int](springCount)
  var springConstant = newSeq[int](springCount)
  var nodeLimit = barCount - 1
  for springIndex in 0 .. springCount - 1:
    springLeft[springIndex] = nextInt(inputData, scanPos)
    springRight[springIndex] = nextInt(inputData, scanPos)
    springConstant[springIndex] = nextInt(inputData, scanPos)
    if springLeft[springIndex] > nodeLimit:
      nodeLimit = springLeft[springIndex]
    if springRight[springIndex] > nodeLimit:
      nodeLimit = springRight[springIndex]
  var adjacencyHead = newSeq[int](nodeLimit + 1)
  for nodeIndex in 0 .. nodeLimit:
    adjacencyHead[nodeIndex] = -1
  var edgeTarget = newSeq[int](springCount * 2)
  var edgeWeight = newSeq[float](springCount * 2)
  var edgeNext = newSeq[int](springCount * 2)
  var edgeCount = 0
  for springIndex in 0 .. springCount - 1:
    let firstBar = springLeft[springIndex]
    let secondBar = springRight[springIndex]
    let reciprocalWeight = 1.0 / float(springConstant[springIndex])
    edgeTarget[edgeCount] = secondBar
    edgeWeight[edgeCount] = reciprocalWeight
    edgeNext[edgeCount] = adjacencyHead[firstBar]
    adjacencyHead[firstBar] = edgeCount
    edgeCount += 1
    edgeTarget[edgeCount] = firstBar
    edgeWeight[edgeCount] = reciprocalWeight
    edgeNext[edgeCount] = adjacencyHead[secondBar]
    adjacencyHead[secondBar] = edgeCount
    edgeCount += 1
  var bestWeights = newSeq[float](nodeLimit + 1)
  for nodeIndex in 0 .. nodeLimit:
    bestWeights[nodeIndex] = infiniteWeight
  bestWeights[0] = 0.0
  var weightHeap = newSeq[float](0)
  var nodeHeap = newSeq[int](0)
  pushHeap(weightHeap, nodeHeap, 0.0, 0)
  while weightHeap.len > 0:
    let poppedItem = popHeap(weightHeap, nodeHeap)
    if poppedItem.weight != bestWeights[poppedItem.node]:
      continue
    var edgeIndex = adjacencyHead[poppedItem.node]
    while edgeIndex != -1:
      let candidateWeight = poppedItem.weight + edgeWeight[edgeIndex]
      if candidateWeight < bestWeights[edgeTarget[edgeIndex]]:
        bestWeights[edgeTarget[edgeIndex]] = candidateWeight
        pushHeap(weightHeap, nodeHeap, candidateWeight, edgeTarget[edgeIndex])
      edgeIndex = edgeNext[edgeIndex]
  let maxForce = float(targetDistance) / bestWeights[barCount - 1]
  let roundedForce = int64(maxForce * 100.0 + 0.5)
  appendOutput($(roundedForce div 100))
  outputBuffer.add '.'
  let fractionDigits = roundedForce mod 100
  if fractionDigits < 10:
    outputBuffer.add '0'
  appendOutput($(fractionDigits))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
