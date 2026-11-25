const flushBlockBytes = 1 shl 17
const maxCableCost = 100
const lambdaLowerBound = -1000
const lambdaUpperBound = 1000

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

proc hasMoreTokens(data: string, pos: int): bool =
  var cursor = pos
  while cursor < data.len:
    if data[cursor] >= '0' and data[cursor] <= '9':
      return true
    cursor += 1
  return false

proc findRoot(parent: var seq[int], node: int): int =
  var current = node
  while parent[current] != current:
    parent[current] = parent[parent[current]]
    current = parent[current]
  return current

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var edgeFrom = newSeq[int]()
var edgeTo = newSeq[int]()
var edgeCost = newSeq[int]()
var edgeIsTelecom = newSeq[bool]()
var telecomOrder = newSeq[int]()
var unicomOrder = newSeq[int]()
var parent = newSeq[int]()
var caseParent = newSeq[int]()

proc buildCostOrder(isTelecom: bool): seq[int] =
  var bucketCounts = newSeq[int](maxCableCost + 1)
  for edgeIndex in 0 .. edgeCost.len - 1:
    if edgeIsTelecom[edgeIndex] == isTelecom:
      bucketCounts[edgeCost[edgeIndex]] += 1
  var startPositions = newSeq[int](maxCableCost + 2)
  for costValue in 1 .. maxCableCost:
    startPositions[costValue + 1] = startPositions[costValue] + bucketCounts[costValue]
  var resultOrder = newSeq[int](startPositions[maxCableCost + 1])
  var cursors = newSeq[int](maxCableCost + 1)
  for costValue in 1 .. maxCableCost:
    cursors[costValue] = startPositions[costValue]
  for edgeIndex in 0 .. edgeCost.len - 1:
    if edgeIsTelecom[edgeIndex] == isTelecom:
      let costValue = edgeCost[edgeIndex]
      resultOrder[cursors[costValue]] = edgeIndex
      cursors[costValue] += 1
  return resultOrder

proc kruskalPass(lambdaValue: int, telecomPicked: var int, adjustedTotal: var int64) =
  for city in 0 .. caseParent.len - 1:
    parent[city] = city
  var telecomPos = 0
  var unicomPos = 0
  telecomPicked = 0
  adjustedTotal = 0
  while telecomPos < telecomOrder.len or unicomPos < unicomOrder.len:
    var takeTelecom = false
    var edgeAdjustedCost = 0
    if telecomPos < telecomOrder.len and unicomPos < unicomOrder.len:
      let telecomAdjusted = edgeCost[telecomOrder[telecomPos]] - lambdaValue
      let unicomAdjusted = edgeCost[unicomOrder[unicomPos]]
      if telecomAdjusted <= unicomAdjusted:
        takeTelecom = true
        edgeAdjustedCost = telecomAdjusted
      else:
        edgeAdjustedCost = unicomAdjusted
    elif telecomPos < telecomOrder.len:
      takeTelecom = true
      edgeAdjustedCost = edgeCost[telecomOrder[telecomPos]] - lambdaValue
    else:
      edgeAdjustedCost = edgeCost[unicomOrder[unicomPos]]
    var edgeIndex = 0
    if takeTelecom:
      edgeIndex = telecomOrder[telecomPos]
      telecomPos += 1
    else:
      edgeIndex = unicomOrder[unicomPos]
      unicomPos += 1
    let firstRoot = findRoot(parent, edgeFrom[edgeIndex])
    let secondRoot = findRoot(parent, edgeTo[edgeIndex])
    if firstRoot != secondRoot:
      parent[firstRoot] = secondRoot
      adjustedTotal = adjustedTotal + int64(edgeAdjustedCost)
      if takeTelecom:
        telecomPicked += 1

var caseNumber = 1
while hasMoreTokens(inputData, scanPos):
  let cityCount = nextInt(inputData, scanPos)
  let cableCount = nextInt(inputData, scanPos)
  let requiredTelecom = nextInt(inputData, scanPos)
  edgeFrom.setLen(cableCount)
  edgeTo.setLen(cableCount)
  edgeCost.setLen(cableCount)
  edgeIsTelecom.setLen(cableCount)
  for edgeIndex in 0 .. cableCount - 1:
    edgeFrom[edgeIndex] = nextInt(inputData, scanPos)
    edgeTo[edgeIndex] = nextInt(inputData, scanPos)
    edgeCost[edgeIndex] = nextInt(inputData, scanPos)
    edgeIsTelecom[edgeIndex] = nextInt(inputData, scanPos) == 0
  telecomOrder = buildCostOrder(true)
  unicomOrder = buildCostOrder(false)
  caseParent = newSeq[int](cityCount)
  parent = newSeq[int](cityCount)
  var lowLambda = lambdaLowerBound
  var highLambda = lambdaUpperBound
  var pickedCount = 0
  var ignoredTotal: int64 = 0
  while lowLambda < highLambda:
    let middleLambda = lowLambda + (highLambda - lowLambda) div 2
    kruskalPass(middleLambda, pickedCount, ignoredTotal)
    if pickedCount >= requiredTelecom:
      highLambda = middleLambda
    else:
      lowLambda = middleLambda + 1
  var adjustedTotal: int64 = 0
  kruskalPass(lowLambda, pickedCount, adjustedTotal)
  let minimumCost = adjustedTotal + int64(lowLambda) * int64(requiredTelecom)
  appendOutput("Case " & $caseNumber & ": " & $minimumCost & "\n")
  caseNumber += 1

stdout.write outputBuffer
outputBuffer.setLen 0
