const flushBlockBytes = 1 shl 17
const infiniteCost = high(int64) div 4

type
  Tunnel = object
    destination: int
    openingTime: int
    collapseTime: int
    tunnelLength: int
    travelTime: int

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

var heapTime = newSeq[int64]()
var heapDistance = newSeq[int64]()
var heapRoom = newSeq[int]()
var heapUsed = newSeq[int]()

proc swapHeapEntries(firstIndex: int, secondIndex: int) =
  swap heapTime[firstIndex], heapTime[secondIndex]
  swap heapDistance[firstIndex], heapDistance[secondIndex]
  swap heapRoom[firstIndex], heapRoom[secondIndex]
  swap heapUsed[firstIndex], heapUsed[secondIndex]

proc precedes(firstIndex: int, secondIndex: int): bool =
  if heapTime[firstIndex] != heapTime[secondIndex]:
    return heapTime[firstIndex] < heapTime[secondIndex]
  return heapDistance[firstIndex] < heapDistance[secondIndex]

proc heapPush(arrivalTime: int64, travelDistance: int64, roomIndex: int, hammerCount: int) =
  heapTime.add arrivalTime
  heapDistance.add travelDistance
  heapRoom.add roomIndex
  heapUsed.add hammerCount
  var childIndex = heapTime.len - 1
  while childIndex > 0:
    let parentIndex = (childIndex - 1) div 2
    if precedes(childIndex, parentIndex):
      swapHeapEntries(childIndex, parentIndex)
      childIndex = parentIndex
    else:
      break

proc heapPop(arrivalResult: var int64, distanceResult: var int64, roomResult: var int, usedResult: var int) =
  arrivalResult = heapTime[0]
  distanceResult = heapDistance[0]
  roomResult = heapRoom[0]
  usedResult = heapUsed[0]
  let finalIndex = heapTime.len - 1
  if finalIndex > 0:
    swapHeapEntries(0, finalIndex)
  heapTime.setLen finalIndex
  heapDistance.setLen finalIndex
  heapRoom.setLen finalIndex
  heapUsed.setLen finalIndex
  var parentIndex = 0
  while true:
    let leftChild = parentIndex * 2 + 1
    if leftChild >= heapTime.len:
      break
    let rightChild = leftChild + 1
    var smallerChild = leftChild
    if rightChild < heapTime.len and precedes(rightChild, leftChild):
      smallerChild = rightChild
    if precedes(smallerChild, parentIndex):
      swapHeapEntries(parentIndex, smallerChild)
      parentIndex = smallerChild
    else:
      break

let caseTotal = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseTotal - 1:
  let roomCount = nextInt(inputData, scanPos)
  let tunnelCount = nextInt(inputData, scanPos)
  let hammerSupply = nextInt(inputData, scanPos)
  var adjacency = newSeq[seq[Tunnel]](roomCount)
  var tunnelIndex = 0
  while tunnelIndex < tunnelCount:
    let originRoom = nextInt(inputData, scanPos)
    let targetRoom = nextInt(inputData, scanPos)
    let openingTime = nextInt(inputData, scanPos)
    let collapseTime = nextInt(inputData, scanPos)
    let tunnelLength = nextInt(inputData, scanPos)
    let travelTime = nextInt(inputData, scanPos)
    adjacency[originRoom].add Tunnel(destination: targetRoom, openingTime: openingTime, collapseTime: collapseTime, tunnelLength: tunnelLength, travelTime: travelTime)
    adjacency[targetRoom].add Tunnel(destination: originRoom, openingTime: openingTime, collapseTime: collapseTime, tunnelLength: tunnelLength, travelTime: travelTime)
    tunnelIndex += 1
  let stateWidth = hammerSupply + 1
  let stateTotal = roomCount * stateWidth
  var bestTimes = newSeq[int64](stateTotal)
  var bestDistances = newSeq[int64](stateTotal)
  var stateIndex = 0
  while stateIndex < stateTotal:
    bestTimes[stateIndex] = infiniteCost
    bestDistances[stateIndex] = infiniteCost
    stateIndex += 1
  bestTimes[0] = 0
  bestDistances[0] = 0
  heapTime.setLen 0
  heapDistance.setLen 0
  heapRoom.setLen 0
  heapUsed.setLen 0
  heapPush(0, 0, 0, 0)
  var foundTime = int64(-1)
  var foundDistance = int64(0)
  while heapTime.len > 0:
    var currentTime: int64 = 0
    var currentDistance: int64 = 0
    var currentRoom = 0
    var currentUsed = 0
    heapPop(currentTime, currentDistance, currentRoom, currentUsed)
    let currentState = currentRoom * stateWidth + currentUsed
    if currentTime != bestTimes[currentState] or currentDistance != bestDistances[currentState]:
      continue
    if currentRoom == roomCount - 1:
      foundTime = currentTime
      foundDistance = currentDistance
      break
    var tunnelPosition = 0
    while tunnelPosition < adjacency[currentRoom].len:
      let tunnel = adjacency[currentRoom][tunnelPosition]
      var departureTime = currentTime
      var hammerNeed = 0
      if currentTime < tunnel.openingTime:
        let waitingArrival = int64(tunnel.openingTime + tunnel.travelTime)
        if waitingArrival > int64(tunnel.collapseTime):
          hammerNeed = 1
        else:
          hammerNeed = 0
        let waitingState = tunnel.destination * stateWidth + currentUsed + hammerNeed
        if currentUsed + hammerNeed <= hammerSupply and (waitingArrival < bestTimes[waitingState] or (waitingArrival == bestTimes[waitingState] and currentDistance + int64(tunnel.tunnelLength) < bestDistances[waitingState])):
          bestTimes[waitingState] = waitingArrival
          bestDistances[waitingState] = currentDistance + int64(tunnel.tunnelLength)
          heapPush(waitingArrival, currentDistance + int64(tunnel.tunnelLength), tunnel.destination, currentUsed + hammerNeed)
        departureTime = currentTime
        hammerNeed = 1
      elif currentTime <= int64(tunnel.collapseTime):
        hammerNeed = 0
      else:
        hammerNeed = 1
      let directArrival = departureTime + int64(tunnel.travelTime)
      if currentTime < tunnel.openingTime and directArrival > int64(tunnel.collapseTime):
        hammerNeed += 1
      elif currentTime >= tunnel.openingTime and currentTime <= int64(tunnel.collapseTime) and directArrival > int64(tunnel.collapseTime):
        hammerNeed = 1
      let nextUsed = currentUsed + hammerNeed
      if nextUsed <= hammerSupply:
        let nextState = tunnel.destination * stateWidth + nextUsed
        let nextDistance = currentDistance + int64(tunnel.tunnelLength)
        if directArrival < bestTimes[nextState] or (directArrival == bestTimes[nextState] and nextDistance < bestDistances[nextState]):
          bestTimes[nextState] = directArrival
          bestDistances[nextState] = nextDistance
          heapPush(directArrival, nextDistance, tunnel.destination, nextUsed)
      tunnelPosition += 1
  appendOutput("Scenario #" & $(caseIndex + 1) & ": ")
  if foundTime < 0:
    appendOutput("-1")
  else:
    appendOutput($foundTime & " " & $foundDistance)
  appendOutput("\n")
stdout.write outputBuffer
outputBuffer.setLen 0
