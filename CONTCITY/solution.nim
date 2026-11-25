const flushBlockBytes = 1 shl 17
const infiniteDistance = 1 shl 28
const finalDay = 1000

type
  FlowEdge = object
    destination: int
    reverseIndex: int
    capacity: int

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

var flowGraph = newSeq[seq[FlowEdge]]()
var levelGraph = newSeq[int]()
var edgeCursor = newSeq[int]()

proc addFlowEdge(sourceIndex, targetIndex, capacityValue: int) =
  let forwardIndex = flowGraph[sourceIndex].len
  flowGraph[sourceIndex].add FlowEdge(destination: targetIndex, reverseIndex: flowGraph[targetIndex].len, capacity: capacityValue)
  flowGraph[targetIndex].add FlowEdge(destination: sourceIndex, reverseIndex: forwardIndex, capacity: 0)

proc sendFlow(nodeIndex, availableFlow, sinkIndex: int): int =
  if nodeIndex == sinkIndex:
    return availableFlow
  while edgeCursor[nodeIndex] < flowGraph[nodeIndex].len:
    let edgeIndex = edgeCursor[nodeIndex]
    let edgeDestination = flowGraph[nodeIndex][edgeIndex].destination
    if flowGraph[nodeIndex][edgeIndex].capacity > 0 and levelGraph[edgeDestination] == levelGraph[nodeIndex] + 1:
      let pushedFlow = sendFlow(edgeDestination, min(availableFlow, flowGraph[nodeIndex][edgeIndex].capacity), sinkIndex)
      if pushedFlow > 0:
        flowGraph[nodeIndex][edgeIndex].capacity -= pushedFlow
        flowGraph[edgeDestination][flowGraph[nodeIndex][edgeIndex].reverseIndex].capacity += pushedFlow
        return pushedFlow
    edgeCursor[nodeIndex] += 1
  return 0

proc maximumFlow(sourceIndex, sinkIndex: int): int =
  var totalFlow = 0
  while true:
    let nodeCount = flowGraph.len
    levelGraph = newSeq[int](nodeCount)
    for nodeIndex in 0 .. nodeCount - 1:
      levelGraph[nodeIndex] = -1
    levelGraph[sourceIndex] = 0
    var queue = newSeq[int]()
    queue.add sourceIndex
    var queueHead = 0
    while queueHead < queue.len:
      let currentNode = queue[queueHead]
      queueHead += 1
      for edgeIndex in 0 .. flowGraph[currentNode].len - 1:
        let edge = flowGraph[currentNode][edgeIndex]
        if edge.capacity > 0 and levelGraph[edge.destination] == -1:
          levelGraph[edge.destination] = levelGraph[currentNode] + 1
          queue.add edge.destination
    if levelGraph[sinkIndex] == -1:
      break
    edgeCursor = newSeq[int](nodeCount)
    while true:
      let pushedFlow = sendFlow(sourceIndex, infiniteDistance, sinkIndex)
      if pushedFlow == 0:
        break
      totalFlow += pushedFlow
  return totalFlow

proc rescuedByDay(dayLimit: int, placeCount, helicopterCount: int, survivorCounts: seq[int], rescueTimes: seq[seq[int]], helicopterCapacities: seq[int]): int =
  let sourceNode = 0
  let sinkNode = placeCount + helicopterCount + 1
  flowGraph = newSeq[seq[FlowEdge]](sinkNode + 1)
  for nodeIndex in 0 .. sinkNode:
    flowGraph[nodeIndex] = newSeq[FlowEdge]()
  for placeIndex in 1 .. placeCount:
    if survivorCounts[placeIndex] > 0:
      addFlowEdge(sourceNode, placeIndex, survivorCounts[placeIndex])
      for heliIndex in 1 .. helicopterCount:
        if rescueTimes[placeIndex][heliIndex] <= dayLimit:
          addFlowEdge(placeIndex, placeCount + heliIndex, survivorCounts[placeIndex])
  for heliIndex in 1 .. helicopterCount:
    addFlowEdge(placeCount + heliIndex, sinkNode, helicopterCapacities[heliIndex])
  return maximumFlow(sourceNode, sinkNode)

let testCount = nextInt(inputData, scanPos)
for testIndex in 0 .. testCount - 1:
  let placeCount = nextInt(inputData, scanPos)
  let roadCount = nextInt(inputData, scanPos)
  let helicopterCount = nextInt(inputData, scanPos)
  var survivorCounts = newSeq[int](placeCount + 1)
  var survivorTotal = 0
  for placeIndex in 1 .. placeCount:
    survivorCounts[placeIndex] = nextInt(inputData, scanPos)
    survivorTotal += survivorCounts[placeIndex]
  var distances = newSeq[seq[int]](placeCount + 1)
  for fromPlace in 0 .. placeCount:
    distances[fromPlace] = newSeq[int](placeCount + 1)
    for toPlace in 0 .. placeCount:
      if fromPlace == toPlace:
        distances[fromPlace][toPlace] = 0
      else:
        distances[fromPlace][toPlace] = infiniteDistance
  for roadIndex in 0 .. roadCount - 1:
    let firstPlace = nextInt(inputData, scanPos)
    let secondPlace = nextInt(inputData, scanPos)
    let travelDays = nextInt(inputData, scanPos)
    if travelDays < distances[firstPlace][secondPlace]:
      distances[firstPlace][secondPlace] = travelDays
      distances[secondPlace][firstPlace] = travelDays
  for viaPlace in 1 .. placeCount:
    for fromPlace in 1 .. placeCount:
      if distances[fromPlace][viaPlace] >= infiniteDistance:
        continue
      for toPlace in 1 .. placeCount:
        if distances[viaPlace][toPlace] < infiniteDistance and distances[fromPlace][toPlace] > distances[fromPlace][viaPlace] + distances[viaPlace][toPlace]:
          distances[fromPlace][toPlace] = distances[fromPlace][viaPlace] + distances[viaPlace][toPlace]
  var helicopterDays = newSeq[int](helicopterCount + 1)
  var helicopterPlaces = newSeq[int](helicopterCount + 1)
  var helicopterCapacities = newSeq[int](helicopterCount + 1)
  for heliIndex in 1 .. helicopterCount:
    helicopterDays[heliIndex] = nextInt(inputData, scanPos)
    helicopterPlaces[heliIndex] = nextInt(inputData, scanPos)
    helicopterCapacities[heliIndex] = nextInt(inputData, scanPos)
  var rescueTimes = newSeq[seq[int]](placeCount + 1)
  for placeIndex in 0 .. placeCount:
    rescueTimes[placeIndex] = newSeq[int](helicopterCount + 1)
    for heliIndex in 0 .. helicopterCount:
      rescueTimes[placeIndex][heliIndex] = infiniteDistance
  for placeIndex in 1 .. placeCount:
    for heliIndex in 1 .. helicopterCount:
      let walkingDays = distances[placeIndex][helicopterPlaces[heliIndex]]
      if walkingDays < infiniteDistance:
        rescueTimes[placeIndex][heliIndex] = max(helicopterDays[heliIndex], walkingDays)
  if rescuedByDay(finalDay, placeCount, helicopterCount, survivorCounts, rescueTimes, helicopterCapacities) < survivorTotal:
    let rescuedCount = rescuedByDay(finalDay, placeCount, helicopterCount, survivorCounts, rescueTimes, helicopterCapacities)
    appendOutput($rescuedCount)
    appendOutput(" survivor(s) can be rescued.")
    outputBuffer.add '\n'
  else:
    var lowerDay = 0
    var upperDay = finalDay
    while lowerDay < upperDay:
      let middleDay = (lowerDay + upperDay) div 2
      if rescuedByDay(middleDay, placeCount, helicopterCount, survivorCounts, rescueTimes, helicopterCapacities) == survivorTotal:
        upperDay = middleDay
      else:
        lowerDay = middleDay + 1
    appendOutput("All people can be rescued in ")
    appendOutput($lowerDay)
    appendOutput(" day(s).")
    outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
