const flushBlockBytes = 1 shl 17
const maximumNodes = 15
const maximumEdges = 20

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

var edgeStart: array[0 .. maximumEdges - 1, int]
var edgeEnd: array[0 .. maximumEdges - 1, int]
var edgePrice: array[0 .. maximumEdges - 1, int]
var nodeTotal = 0
var edgeTotal = 0
var examinedMask = 0
var discoveryTime: array[0 .. maximumNodes - 1, int]
var lowValue: array[0 .. maximumNodes - 1, int]
var clockValue = 0
var bridgeFound = false
var reachedNodes = 0

proc visitNode(currentNode: int, incomingEdge: int) =
  discoveryTime[currentNode] = clockValue
  lowValue[currentNode] = clockValue
  clockValue += 1
  reachedNodes += 1
  for edgeIndex in 0 .. edgeTotal - 1:
    if (examinedMask and (1 shl edgeIndex)) == 0:
      continue
    var neighborNode = -1
    if edgeStart[edgeIndex] == currentNode:
      neighborNode = edgeEnd[edgeIndex]
    elif edgeEnd[edgeIndex] == currentNode:
      neighborNode = edgeStart[edgeIndex]
    else:
      continue
    if edgeIndex == incomingEdge:
      continue
    if discoveryTime[neighborNode] == 0:
      visitNode(neighborNode, edgeIndex)
      if lowValue[neighborNode] > discoveryTime[currentNode]:
        bridgeFound = true
      if lowValue[neighborNode] < lowValue[currentNode]:
        lowValue[currentNode] = lowValue[neighborNode]
    elif discoveryTime[neighborNode] < lowValue[currentNode]:
      lowValue[currentNode] = discoveryTime[neighborNode]

proc isReliable(candidateMask: int): bool =
  if nodeTotal == 1:
    return true
  var degrees: array[0 .. maximumNodes - 1, int]
  for edgeIndex in 0 .. edgeTotal - 1:
    if (candidateMask and (1 shl edgeIndex)) != 0:
      degrees[edgeStart[edgeIndex]] += 1
      degrees[edgeEnd[edgeIndex]] += 1
  for nodeIndex in 0 .. nodeTotal - 1:
    if degrees[nodeIndex] < 2:
      return false
  for nodeIndex in 0 .. nodeTotal - 1:
    discoveryTime[nodeIndex] = 0
    lowValue[nodeIndex] = 0
  examinedMask = candidateMask
  clockValue = 1
  bridgeFound = false
  reachedNodes = 0
  visitNode(0, -1)
  return (not bridgeFound) and reachedNodes == nodeTotal

var testNumber = 0
while true:
  nodeTotal = nextInt(inputData, scanPos)
  edgeTotal = nextInt(inputData, scanPos)
  if nodeTotal == 0 and edgeTotal == 0:
    break
  testNumber += 1
  var totalPrice = 0
  for edgeIndex in 0 .. edgeTotal - 1:
    edgeStart[edgeIndex] = nextInt(inputData, scanPos) - 1
    edgeEnd[edgeIndex] = nextInt(inputData, scanPos) - 1
    edgePrice[edgeIndex] = nextInt(inputData, scanPos)
    totalPrice += edgePrice[edgeIndex]
  var bestPrice = totalPrice + 1
  if nodeTotal == 1:
    bestPrice = 0
  var lowBitPosition = newSeq[int](1 shl edgeTotal)
  for edgeIndex in 0 .. edgeTotal - 1:
    lowBitPosition[1 shl edgeIndex] = edgeIndex
  var subsetPrice = newSeq[int](1 shl edgeTotal)
  for mask in 1 .. (1 shl edgeTotal) - 1:
    let lowBit = mask and (-mask)
    subsetPrice[mask] = subsetPrice[mask xor lowBit] + edgePrice[lowBitPosition[lowBit]]
    if subsetPrice[mask] < bestPrice and isReliable(mask):
      bestPrice = subsetPrice[mask]
  if bestPrice > totalPrice:
    appendOutput("There is no reliable net possible for test case ")
    appendOutput($testNumber)
    appendOutput(".\n")
  else:
    appendOutput("The minimal cost for test case ")
    appendOutput($testNumber)
    appendOutput(" is ")
    appendOutput($bestPrice)
    appendOutput(".\n")

stdout.write outputBuffer
outputBuffer.setLen 0
