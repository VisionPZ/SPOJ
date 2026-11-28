const flushBlockBytes = 1 shl 17
const infiniteDistance = int64(1) shl 60

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

var heapNode = newSeq[int](0)
var heapCost = newSeq[int64](0)

proc heapPush(nodeIndex: int, costValue: int64) =
  heapNode.add nodeIndex
  heapCost.add costValue
  var childIndex = heapNode.len - 1
  while childIndex > 0:
    let parentIndex = (childIndex - 1) div 2
    if heapCost[parentIndex] <= heapCost[childIndex]:
      break
    swap heapCost[parentIndex], heapCost[childIndex]
    swap heapNode[parentIndex], heapNode[childIndex]
    childIndex = parentIndex

proc heapPop(): (int, int64) =
  let topNode = heapNode[0]
  let topCost = heapCost[0]
  let lastIndex = heapNode.len - 1
  heapNode[0] = heapNode[lastIndex]
  heapCost[0] = heapCost[lastIndex]
  heapNode.setLen lastIndex
  heapCost.setLen lastIndex
  var parentIndex = 0
  while true:
    let leftChild = parentIndex * 2 + 1
    if leftChild >= heapNode.len:
      break
    let rightChild = leftChild + 1
    var smallerChild = leftChild
    if rightChild < heapNode.len and heapCost[rightChild] < heapCost[leftChild]:
      smallerChild = rightChild
    if heapCost[parentIndex] <= heapCost[smallerChild]:
      break
    swap heapCost[parentIndex], heapCost[smallerChild]
    swap heapNode[parentIndex], heapNode[smallerChild]
    parentIndex = smallerChild
  return (topNode, topCost)

proc solveCase(elementCount: int, sourceCount: int, targetCount: int,
               scanPosition: var int): string =
  var sources = newSeq[int](sourceCount)
  for sourceIndex in 0 .. sourceCount - 1:
    sources[sourceIndex] = nextInt(inputData, scanPosition)
  var targets = newSeq[int](targetCount)
  for targetIndex in 0 .. targetCount - 1:
    targets[targetIndex] = nextInt(inputData, scanPosition)
  let edgeCount = nextInt(inputData, scanPosition)

  var edgeHead = newSeq[int](elementCount)
  for headIndex in 0 .. elementCount - 1:
    edgeHead[headIndex] = -1
  var edgeTo = newSeq[int](edgeCount)
  var edgeEnergy = newSeq[int](edgeCount)
  var edgeNext = newSeq[int](edgeCount)
  for edgeIndex in 0 .. edgeCount - 1:
    let fromElement = nextInt(inputData, scanPosition)
    let toElement = nextInt(inputData, scanPosition)
    let energyValue = nextInt(inputData, scanPosition)
    edgeTo[edgeIndex] = toElement
    edgeEnergy[edgeIndex] = energyValue
    edgeNext[edgeIndex] = edgeHead[fromElement]
    edgeHead[fromElement] = edgeIndex

  var bottleneck = newSeq[int64](elementCount)
  for elementIndex in 0 .. elementCount - 1:
    bottleneck[elementIndex] = infiniteDistance
  heapNode.setLen 0
  heapCost.setLen 0
  for sourceIndex in 0 .. sourceCount - 1:
    let sourceElement = sources[sourceIndex]
    if bottleneck[sourceElement] != 0:
      bottleneck[sourceElement] = 0
      heapPush(sourceElement, 0)

  while heapNode.len > 0:
    let popped = heapPop()
    let currentElement = popped[0]
    let currentCost = popped[1]
    if currentCost != bottleneck[currentElement]:
      continue
    var edgeIndex = edgeHead[currentElement]
    while edgeIndex >= 0:
      let nextElement = edgeTo[edgeIndex]
      var candidate = currentCost
      if int64(edgeEnergy[edgeIndex]) > candidate:
        candidate = int64(edgeEnergy[edgeIndex])
      if candidate < bottleneck[nextElement]:
        bottleneck[nextElement] = candidate
        heapPush(nextElement, candidate)
      edgeIndex = edgeNext[edgeIndex]

  var upperBound: int64 = 0
  for targetIndex in 0 .. targetCount - 1:
    let targetElement = targets[targetIndex]
    if bottleneck[targetElement] == infiniteDistance:
      return "Excessive Energy."
    if bottleneck[targetElement] > upperBound:
      upperBound = bottleneck[targetElement]

  var pathLength = newSeq[int](elementCount)
  for elementIndex in 0 .. elementCount - 1:
    pathLength[elementIndex] = -1
  var queue = newSeq[int](elementCount)
  var queueHead = 0
  var queueTail = 0
  for sourceIndex in 0 .. sourceCount - 1:
    let sourceElement = sources[sourceIndex]
    if pathLength[sourceElement] < 0:
      pathLength[sourceElement] = 0
      queue[queueTail] = sourceElement
      queueTail += 1
  while queueHead < queueTail:
    let currentElement = queue[queueHead]
    queueHead += 1
    var edgeIndex = edgeHead[currentElement]
    while edgeIndex >= 0:
      if int64(edgeEnergy[edgeIndex]) <= upperBound:
        let nextElement = edgeTo[edgeIndex]
        if pathLength[nextElement] < 0:
          pathLength[nextElement] = pathLength[currentElement] + 1
          queue[queueTail] = nextElement
          queueTail += 1
      edgeIndex = edgeNext[edgeIndex]

  var conversionCount: int64 = 0
  for targetIndex in 0 .. targetCount - 1:
    conversionCount = conversionCount + int64(pathLength[targets[targetIndex]])
  return $upperBound & " " & $conversionCount

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let sourceCount = nextInt(inputData, scanPos)
  let targetCount = nextInt(inputData, scanPos)
  let elementCount = nextInt(inputData, scanPos)
  appendOutput(solveCase(elementCount, sourceCount, targetCount, scanPos))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
