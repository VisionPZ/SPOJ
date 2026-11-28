const flushBlockBytes = 1 shl 17
const maxAdjacencySlots = 64010

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

var cityCount = 0
var headEdge = newSeq[int](maxAdjacencySlots)
var edgeTarget = newSeq[int](maxAdjacencySlots)
var edgeNumber = newSeq[int](maxAdjacencySlots)
var nextEdge = newSeq[int](maxAdjacencySlots)
var discoveryTime = newSeq[int](maxAdjacencySlots)
var lowReach = newSeq[int](maxAdjacencySlots)
var vertexMark = newSeq[int](maxAdjacencySlots)
var currentMark = 0
var clockTime = 0
var pendingEdges: seq[int] = @[]
var regionSupplies: seq[int] = @[]
var energySupply = newSeq[int](maxAdjacencySlots)

proc collectComponent(lastEdge: int) =
  currentMark += 1
  var supplyTotal = 0
  while true:
    let currentEdge = pendingEdges[pendingEdges.len - 1]
    pendingEdges.setLen(pendingEdges.len - 1)
    let firstCity = edgeTarget[currentEdge * 2 - 1]
    let secondCity = edgeTarget[currentEdge * 2]
    if vertexMark[firstCity] != currentMark:
      vertexMark[firstCity] = currentMark
      supplyTotal += energySupply[firstCity]
    if vertexMark[secondCity] != currentMark:
      vertexMark[secondCity] = currentMark
      supplyTotal += energySupply[secondCity]
    if currentEdge == lastEdge:
      break
  regionSupplies.add supplyTotal

proc exploreCity(cityHere: int, incomingEdge: int) =
  clockTime += 1
  discoveryTime[cityHere] = clockTime
  lowReach[cityHere] = clockTime
  var edgeSlot = headEdge[cityHere]
  while edgeSlot != 0:
    let neighborCity = edgeTarget[edgeSlot]
    let roadNumber = edgeNumber[edgeSlot]
    if roadNumber != incomingEdge:
      if discoveryTime[neighborCity] == 0:
        pendingEdges.add roadNumber
        exploreCity(neighborCity, roadNumber)
        if lowReach[neighborCity] < lowReach[cityHere]:
          lowReach[cityHere] = lowReach[neighborCity]
        if lowReach[neighborCity] >= discoveryTime[cityHere]:
          collectComponent(roadNumber)
      elif discoveryTime[neighborCity] < discoveryTime[cityHere]:
        if discoveryTime[neighborCity] < lowReach[cityHere]:
          lowReach[cityHere] = discoveryTime[neighborCity]
        pendingEdges.add roadNumber
    edgeSlot = nextEdge[edgeSlot]

var toyDemands: seq[int] = @[]
var toyCount = 0
var assignedToy: seq[int] = @[]
var visitedToy: seq[int] = @[]
var allowedDeviation = 0
var visitVersion = 0

proc canAssign(regionIndex: int): bool =
  for toyIndex in 0 .. toyCount - 1:
    let difference = toyDemands[toyIndex] - regionSupplies[regionIndex]
    if (difference < 0 and -difference <= allowedDeviation) or
       (difference >= 0 and difference <= allowedDeviation):
      if visitedToy[toyIndex] != visitVersion:
        visitedToy[toyIndex] = visitVersion
        if assignedToy[toyIndex] == -1 or canAssign(assignedToy[toyIndex]):
          assignedToy[toyIndex] = regionIndex
          return true
  return false

proc feasible(deviation: int): bool =
  allowedDeviation = deviation
  for toyIndex in 0 .. toyCount - 1:
    assignedToy[toyIndex] = -1
  for regionIndex in 0 .. regionSupplies.len - 1:
    visitVersion += 1
    if not canAssign(regionIndex):
      return false
  return true

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  cityCount = nextInt(inputData, scanPos)
  let roadCount = nextInt(inputData, scanPos)
  toyCount = nextInt(inputData, scanPos)

  for cityIndex in 1 .. cityCount:
    energySupply[cityIndex] = nextInt(inputData, scanPos)

  toyDemands = newSeq[int](toyCount)
  for toyIndex in 0 .. toyCount - 1:
    toyDemands[toyIndex] = nextInt(inputData, scanPos)

  for cityIndex in 0 .. cityCount:
    headEdge[cityIndex] = 0
    discoveryTime[cityIndex] = 0
    lowReach[cityIndex] = 0
    vertexMark[cityIndex] = 0
  var slotCount = 0
  var degreeCounts = newSeq[int](cityCount + 1)
  for roadIndex in 1 .. roadCount:
    let roadStart = nextInt(inputData, scanPos)
    let roadEnd = nextInt(inputData, scanPos)
    slotCount += 1
    edgeTarget[slotCount] = roadEnd
    edgeNumber[slotCount] = roadIndex
    nextEdge[slotCount] = headEdge[roadStart]
    headEdge[roadStart] = slotCount
    degreeCounts[roadStart] += 1
    slotCount += 1
    edgeTarget[slotCount] = roadStart
    edgeNumber[slotCount] = roadIndex
    nextEdge[slotCount] = headEdge[roadEnd]
    headEdge[roadEnd] = slotCount
    degreeCounts[roadEnd] += 1

  clockTime = 0
  currentMark = 0
  pendingEdges = @[]
  regionSupplies = @[]
  for cityIndex in 1 .. cityCount:
    if degreeCounts[cityIndex] > 0 and discoveryTime[cityIndex] == 0:
      exploreCity(cityIndex, 0)
  for cityIndex in 1 .. cityCount:
    if degreeCounts[cityIndex] == 0:
      regionSupplies.add energySupply[cityIndex]

  let regionCount = regionSupplies.len
  appendOutput("Buzz Mission " & $(caseIndex + 1) & ": " & $regionCount & " ")
  if regionCount > toyCount:
    appendOutput("No")
  else:
    var largestGap = 0
    for regionIndex in 0 .. regionCount - 1:
      for toyIndex in 0 .. toyCount - 1:
        let difference = toyDemands[toyIndex] - regionSupplies[regionIndex]
        if difference > largestGap:
          largestGap = difference
        elif -difference > largestGap:
          largestGap = -difference
    assignedToy = newSeq[int](toyCount)
    visitedToy = newSeq[int](toyCount)
    visitVersion = 0
    var lowBound = 0
    var highBound = largestGap
    while lowBound < highBound:
      let middle = (lowBound + highBound) div 2
      if feasible(middle):
        highBound = middle
      else:
        lowBound = middle + 1
    appendOutput($lowBound)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
