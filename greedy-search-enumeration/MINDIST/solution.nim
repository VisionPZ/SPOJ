const flushBlockBytes = 1 shl 17
const firstDigitValue = 48
const absentNode = -1
const absentLength = -1000000000

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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let testCount = nextInt(inputData, scanPos)

proc solveCase() =
  let nodeCount = nextInt(inputData, scanPos)
  let pathBudget = nextInt(inputData, scanPos)
  var edgeHead = newSeq[int](nodeCount)
  var edgeTo = newSeq[int](2 * (nodeCount - 1))
  var edgeWeight = newSeq[int](2 * (nodeCount - 1))
  var edgeNext = newSeq[int](2 * (nodeCount - 1))
  for nodeIndex in 0 .. nodeCount - 1:
    edgeHead[nodeIndex] = absentNode
  var edgeCount = 0
  for edgeIndex in 0 .. nodeCount - 2:
    let firstNode = nextInt(inputData, scanPos) - 1
    let secondNode = nextInt(inputData, scanPos) - 1
    let bridgeWeight = nextInt(inputData, scanPos)
    edgeTo[edgeCount] = secondNode
    edgeWeight[edgeCount] = bridgeWeight
    edgeNext[edgeCount] = edgeHead[firstNode]
    edgeHead[firstNode] = edgeCount
    edgeCount += 1
    edgeTo[edgeCount] = firstNode
    edgeWeight[edgeCount] = bridgeWeight
    edgeNext[edgeCount] = edgeHead[secondNode]
    edgeHead[secondNode] = edgeCount
    edgeCount += 1

  var parentNode = newSeq[int](nodeCount)
  var traversalOrder: seq[int] = @[]
  var stackNodes: seq[int] = @[0]
  for nodeIndex in 0 .. nodeCount - 1:
    parentNode[nodeIndex] = absentNode
  while stackNodes.len > 0:
    let currentNode = stackNodes[stackNodes.len - 1]
    stackNodes.setLen(stackNodes.len - 1)
    traversalOrder.add currentNode
    var edgeIndex = edgeHead[currentNode]
    while edgeIndex != absentNode:
      let neighborNode = edgeTo[edgeIndex]
      if neighborNode != parentNode[currentNode]:
        parentNode[neighborNode] = currentNode
        stackNodes.add neighborNode
      edgeIndex = edgeNext[edgeIndex]

  var downReach = newSeq[int](nodeCount)
  for orderIndex in countdown(traversalOrder.len - 1, 0):
    let currentNode = traversalOrder[orderIndex]
    var deepest = 0
    var edgeIndex = edgeHead[currentNode]
    while edgeIndex != absentNode:
      let neighborNode = edgeTo[edgeIndex]
      if parentNode[neighborNode] == currentNode:
        let candidate = edgeWeight[edgeIndex] + downReach[neighborNode]
        if candidate > deepest:
          deepest = candidate
      edgeIndex = edgeNext[edgeIndex]
    downReach[currentNode] = deepest

  var outsideReach = newSeq[int](nodeCount)
  for orderIndex in 0 .. traversalOrder.len - 1:
    let currentNode = traversalOrder[orderIndex]
    var bestBranch = absentLength
    var secondBranch = absentLength
    var edgeIndex = edgeHead[currentNode]
    while edgeIndex != absentNode:
      let neighborNode = edgeTo[edgeIndex]
      if parentNode[neighborNode] == currentNode:
        let branchReach = edgeWeight[edgeIndex] + downReach[neighborNode]
        if branchReach > bestBranch:
          secondBranch = bestBranch
          bestBranch = branchReach
        elif branchReach > secondBranch:
          secondBranch = branchReach
      edgeIndex = edgeNext[edgeIndex]
    edgeIndex = edgeHead[currentNode]
    while edgeIndex != absentNode:
      let neighborNode = edgeTo[edgeIndex]
      if parentNode[neighborNode] == currentNode:
        let branchReach = edgeWeight[edgeIndex] + downReach[neighborNode]
        var otherReach = outsideReach[currentNode]
        if branchReach == bestBranch:
          if secondBranch > otherReach:
            otherReach = secondBranch
        else:
          if bestBranch > otherReach:
            otherReach = bestBranch
        outsideReach[neighborNode] = edgeWeight[edgeIndex] + otherReach
      edgeIndex = edgeNext[edgeIndex]

  proc canCover(radiusValue: int): bool =
    var requiredLength = newSeq[int64](nodeCount)
    var chainFits = newSeq[bool](nodeCount)
    var pathFits = newSeq[bool](nodeCount)
    for orderIndex in countdown(traversalOrder.len - 1, 0):
      let currentNode = traversalOrder[orderIndex]
      var requiredChildren = 0
      var subtreeLength: int64 = 0
      var chainResult = true
      var pathResult = true
      var edgeIndex = edgeHead[currentNode]
      while edgeIndex != absentNode:
        let neighborNode = edgeTo[edgeIndex]
        if parentNode[neighborNode] == currentNode:
          if edgeWeight[edgeIndex] + downReach[neighborNode] > radiusValue:
            requiredChildren += 1
            subtreeLength = subtreeLength + int64(edgeWeight[edgeIndex]) + requiredLength[neighborNode]
            if not chainFits[neighborNode]:
              chainResult = false
              pathResult = false
        edgeIndex = edgeNext[edgeIndex]
      requiredLength[currentNode] = subtreeLength
      chainFits[currentNode] = (requiredChildren <= 1) and chainResult
      pathFits[currentNode] = (requiredChildren <= 2) and pathResult
    for nodeIndex in 0 .. nodeCount - 1:
      if outsideReach[nodeIndex] <= radiusValue and pathFits[nodeIndex] and requiredLength[nodeIndex] <= int64(pathBudget):
        return true
    return false

  var lowerBound = 0
  var upperBound = downReach[0]
  while lowerBound < upperBound:
    let middleValue = (lowerBound + upperBound) div 2
    if canCover(middleValue):
      upperBound = middleValue
    else:
      lowerBound = middleValue + 1
  appendOutput($lowerBound)
  outputBuffer.add '\n'

for testIndex in 0 .. testCount - 1:
  solveCase()

stdout.write outputBuffer
outputBuffer.setLen 0
