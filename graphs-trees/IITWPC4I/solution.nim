import algorithm

const flushBlockBytes = 1 shl 17

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

var edgeSource = newSeq[int](0)
var edgeDestination = newSeq[int](0)
var edgeCost = newSeq[int](0)
var edgeOrder = newSeq[int](0)
var parentNode = newSeq[int](0)
var componentSize = newSeq[int](0)

proc compareEdges(leftEdge, rightEdge: int): int =
  if edgeCost[leftEdge] < edgeCost[rightEdge]:
    return -1
  if edgeCost[leftEdge] > edgeCost[rightEdge]:
    return 1
  return 0

proc findRoot(nodeIndex: int): int =
  if parentNode[nodeIndex] != nodeIndex:
    parentNode[nodeIndex] = findRoot(parentNode[nodeIndex])
  return parentNode[nodeIndex]

let testCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. testCount - 1:
  let citizenCount = nextInt(inputData, scanPos)
  let roadCount = nextInt(inputData, scanPos)
  var milkmanFlags = newSeq[int](citizenCount + 1)
  var milkmanCount = 0
  for citizenIndex in 1 .. citizenCount:
    milkmanFlags[citizenIndex] = nextInt(inputData, scanPos)
    if milkmanFlags[citizenIndex] == 1:
      milkmanCount += 1
  let totalEdges = roadCount + milkmanCount
  edgeSource.setLen(totalEdges)
  edgeDestination.setLen(totalEdges)
  edgeCost.setLen(totalEdges)
  edgeOrder.setLen(totalEdges)
  var edgeIndex = 0
  for roadIndex in 0 .. roadCount - 1:
    let firstCitizen = nextInt(inputData, scanPos)
    let secondCitizen = nextInt(inputData, scanPos)
    let repairCost = nextInt(inputData, scanPos)
    edgeSource[edgeIndex] = firstCitizen
    edgeDestination[edgeIndex] = secondCitizen
    edgeCost[edgeIndex] = repairCost
    edgeIndex += 1
  for citizenIndex in 1 .. citizenCount:
    if milkmanFlags[citizenIndex] == 1:
      edgeSource[edgeIndex] = 0
      edgeDestination[edgeIndex] = citizenIndex
      edgeCost[edgeIndex] = 0
      edgeIndex += 1
  for orderIndex in 0 .. totalEdges - 1:
    edgeOrder[orderIndex] = orderIndex
  sort(edgeOrder, compareEdges)
  parentNode.setLen(citizenCount + 1)
  componentSize.setLen(citizenCount + 1)
  for nodeIndex in 0 .. citizenCount:
    parentNode[nodeIndex] = nodeIndex
    componentSize[nodeIndex] = 1
  var unionCount = 0
  var totalCost: int64 = 0
  for orderIndex in 0 .. totalEdges - 1:
    let currentEdge = edgeOrder[orderIndex]
    var rootFirst = findRoot(edgeSource[currentEdge])
    var rootSecond = findRoot(edgeDestination[currentEdge])
    if rootFirst == rootSecond:
      continue
    if componentSize[rootFirst] < componentSize[rootSecond]:
      let swapRoot = rootFirst
      rootFirst = rootSecond
      rootSecond = swapRoot
    parentNode[rootSecond] = rootFirst
    componentSize[rootFirst] = componentSize[rootFirst] + componentSize[rootSecond]
    totalCost = totalCost + int64(edgeCost[currentEdge])
    unionCount += 1
    if unionCount == citizenCount:
      break
  if unionCount < citizenCount:
    appendOutput("impossible")
  else:
    appendOutput($totalCost)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
