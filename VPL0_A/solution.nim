const flushBlockBytes = 1 shl 17
const impossibleCost = 1000000000

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and data[pos] != '-' and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var sign = 1
  if pos < data.len and data[pos] == '-':
    sign = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return sign * value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc floorWalkCost(walkRows: seq[int], walkCols: seq[int]): int =
  let pointCount = walkRows.len
  if pointCount == 0:
    return 0
  let stateCount = 1 shl pointCount
  var bestCosts = newSeq[int](stateCount * pointCount)
  for entryIndex in 0 .. bestCosts.len - 1:
    bestCosts[entryIndex] = impossibleCost
  for pointIndex in 0 .. pointCount - 1:
    let stateIndex = (1 shl pointIndex) * pointCount + pointIndex
    bestCosts[stateIndex] = abs(walkRows[pointIndex]) + abs(walkCols[pointIndex])
  for visitedMask in 1 .. stateCount - 1:
    for lastPoint in 0 .. pointCount - 1:
      if (visitedMask and (1 shl lastPoint)) == 0:
        continue
      let stateIndex = visitedMask * pointCount + lastPoint
      let currentCost = bestCosts[stateIndex]
      if currentCost >= impossibleCost:
        continue
      for nextPoint in 0 .. pointCount - 1:
        if (visitedMask and (1 shl nextPoint)) != 0:
          continue
        let stepCost = abs(walkRows[nextPoint] - walkRows[lastPoint]) +
                       abs(walkCols[nextPoint] - walkCols[lastPoint])
        let nextMask = visitedMask or (1 shl nextPoint)
        let nextIndex = nextMask * pointCount + nextPoint
        let candidate = currentCost + stepCost
        if candidate < bestCosts[nextIndex]:
          bestCosts[nextIndex] = candidate
  let fullMask = stateCount - 1
  var shortestWalk = impossibleCost
  for lastPoint in 0 .. pointCount - 1:
    let returnCost = abs(walkRows[lastPoint]) + abs(walkCols[lastPoint])
    let candidate = bestCosts[fullMask * pointCount + lastPoint] + returnCost
    if candidate < shortestWalk:
      shortestWalk = candidate
  return shortestWalk

proc floorDistances(sourceFloor: int, floorTotal: int, elevatorOffsets: seq[int]): seq[int] =
  var distances = newSeq[int](floorTotal)
  var queue = newSeq[int](floorTotal)
  for floorNumber in 0 .. floorTotal - 1:
    distances[floorNumber] = -1
  var queueHead = 0
  var queueTail = 0
  distances[sourceFloor] = 0
  queue[queueTail] = sourceFloor
  queueTail += 1
  while queueHead < queueTail:
    let currentFloor = queue[queueHead]
    queueHead += 1
    for elevatorOffset in elevatorOffsets:
      let nextFloor = currentFloor + elevatorOffset
      if nextFloor >= 0 and nextFloor < floorTotal and distances[nextFloor] == -1:
        distances[nextFloor] = distances[currentFloor] + 1
        queue[queueTail] = nextFloor
        queueTail += 1
  return distances

let testCount = nextInt(inputData, scanPos)
for caseIndex in 1 .. testCount:
  let floorTotal = nextInt(inputData, scanPos)
  let elevatorTotal = nextInt(inputData, scanPos)
  let giftTotal = nextInt(inputData, scanPos)
  let gridSize = nextInt(inputData, scanPos)

  var elevatorOffsets = newSeq[int](elevatorTotal)
  for elevatorIndex in 0 .. elevatorTotal - 1:
    elevatorOffsets[elevatorIndex] = nextInt(inputData, scanPos)

  var giftFloorNumbers = newSeq[int](giftTotal)
  var giftRows = newSeq[int](giftTotal)
  var giftCols = newSeq[int](giftTotal)
  var giftFloorIds = newSeq[int](giftTotal)
  for giftIndex in 0 .. giftTotal - 1:
    giftFloorNumbers[giftIndex] = nextInt(inputData, scanPos)
    giftRows[giftIndex] = nextInt(inputData, scanPos)
    giftCols[giftIndex] = nextInt(inputData, scanPos)

  var relevantFloors = newSeq[int]()
  relevantFloors.add 0
  for giftIndex in 0 .. giftTotal - 1:
    let floorNumber = giftFloorNumbers[giftIndex]
    var matchingId = -1
    for floorId in 1 .. relevantFloors.len - 1:
      if relevantFloors[floorId] == floorNumber:
        matchingId = floorId
        break
    if matchingId == -1:
      relevantFloors.add floorNumber
      matchingId = relevantFloors.len - 1
    giftFloorIds[giftIndex] = matchingId

  let relevantCount = relevantFloors.len
  var walkCosts = newSeq[int](relevantCount)
  for floorId in 1 .. relevantCount - 1:
    var walkRows = newSeq[int]()
    var walkCols = newSeq[int]()
    for giftIndex in 0 .. giftTotal - 1:
      if giftFloorIds[giftIndex] == floorId:
        walkRows.add giftRows[giftIndex]
        walkCols.add giftCols[giftIndex]
    walkCosts[floorId] = floorWalkCost(walkRows, walkCols)

  var rideMatrix = newSeq[seq[int]](relevantCount)
  for sourceId in 0 .. relevantCount - 1:
    let distances = floorDistances(relevantFloors[sourceId], floorTotal, elevatorOffsets)
    var rideRow = newSeq[int](relevantCount)
    for targetId in 0 .. relevantCount - 1:
      rideRow[targetId] = distances[relevantFloors[targetId]]
    rideMatrix[sourceId] = rideRow

  let giftFloorCount = relevantCount - 1
  let routeStates = 1 shl giftFloorCount
  var routeCosts = newSeq[int](routeStates * relevantCount)
  for entryIndex in 0 .. routeCosts.len - 1:
    routeCosts[entryIndex] = impossibleCost
  routeCosts[0] = 0
  for visitedMask in 0 .. routeStates - 1:
    for currentId in 0 .. relevantCount - 1:
      let stateIndex = visitedMask * relevantCount + currentId
      let currentCost = routeCosts[stateIndex]
      if currentCost >= impossibleCost:
        continue
      for targetId in 1 .. relevantCount - 1:
        let targetBit = 1 shl (targetId - 1)
        if (visitedMask and targetBit) != 0:
          continue
        let rideCost = rideMatrix[currentId][targetId]
        if rideCost < 0:
          continue
        let nextMask = visitedMask or targetBit
        let nextIndex = nextMask * relevantCount + targetId
        let candidate = currentCost + rideCost + walkCosts[targetId]
        if candidate < routeCosts[nextIndex]:
          routeCosts[nextIndex] = candidate

  let fullMask = routeStates - 1
  var bestTime = impossibleCost
  for currentId in 0 .. relevantCount - 1:
    let candidate = routeCosts[fullMask * relevantCount + currentId]
    if candidate < bestTime:
      bestTime = candidate

  appendOutput("Scenario #" & $(caseIndex) & ": " & $(bestTime) & "\n")

stdout.write outputBuffer
outputBuffer.setLen 0
