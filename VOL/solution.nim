const firstDigitValue = 48
const flushBlockBytes = 1 shl 17
const infiniteCapacity = int64(1) shl 60
const unreachableCost = int64(1) shl 62

type
  FlowEdge = object
    targetNode: int
    reverseIndex: int
    capacity: int64
    unitCost: int64

  Volunteer = object
    startDay: int
    endDay: int
    dailyCost: int64

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

var adjacency: seq[seq[FlowEdge]]

proc addDirectedEdge(fromNode: int, toNode: int, capacityValue: int64, costValue: int64) =
  let forwardEdge = FlowEdge(targetNode: toNode, reverseIndex: adjacency[toNode].len,
                             capacity: capacityValue, unitCost: costValue)
  let backwardEdge = FlowEdge(targetNode: fromNode, reverseIndex: adjacency[fromNode].len,
                              capacity: 0, unitCost: -costValue)
  adjacency[fromNode].add forwardEdge
  adjacency[toNode].add backwardEdge

proc minCostFlow(sourceNode: int, sinkNode: int, requiredFlow: int64, nodeCount: int): int64 =
  var remainingFlow = requiredFlow
  var totalCost: int64 = 0
  while remainingFlow > 0:
    var shortestCost = newSeq[int64](nodeCount)
    var previousNode = newSeq[int](nodeCount)
    var previousEdge = newSeq[int](nodeCount)
    var queued = newSeq[bool](nodeCount)
    for nodeIndex in 0 .. nodeCount - 1:
      shortestCost[nodeIndex] = unreachableCost
    var queue = newSeq[int]()
    shortestCost[sourceNode] = 0
    queue.add sourceNode
    queued[sourceNode] = true
    var queueHead = 0
    while queueHead < queue.len:
      let currentNode = queue[queueHead]
      queueHead += 1
      queued[currentNode] = false
      for edgeIndex in 0 .. adjacency[currentNode].len - 1:
        let candidateEdge = adjacency[currentNode][edgeIndex]
        let candidateCost = shortestCost[currentNode] + candidateEdge.unitCost
        if candidateEdge.capacity > 0 and candidateCost < shortestCost[candidateEdge.targetNode]:
          shortestCost[candidateEdge.targetNode] = candidateCost
          previousNode[candidateEdge.targetNode] = currentNode
          previousEdge[candidateEdge.targetNode] = edgeIndex
          if not queued[candidateEdge.targetNode]:
            queued[candidateEdge.targetNode] = true
            queue.add candidateEdge.targetNode
    if shortestCost[sinkNode] == unreachableCost:
      break
    var augmentAmount = remainingFlow
    var walkNode = sinkNode
    while walkNode != sourceNode:
      let flowEdge = adjacency[previousNode[walkNode]][previousEdge[walkNode]]
      augmentAmount = min(augmentAmount, flowEdge.capacity)
      walkNode = previousNode[walkNode]
    walkNode = sinkNode
    while walkNode != sourceNode:
      let fromNode = previousNode[walkNode]
      let edgeIndex = previousEdge[walkNode]
      var flowEdge = adjacency[fromNode][edgeIndex]
      flowEdge.capacity -= augmentAmount
      adjacency[fromNode][edgeIndex] = flowEdge
      adjacency[walkNode][flowEdge.reverseIndex].capacity += augmentAmount
      totalCost += augmentAmount * flowEdge.unitCost
      walkNode = fromNode
    remainingFlow -= augmentAmount
  return totalCost

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while true:
  let dayCount = nextInt(inputData, scanPos)
  if dayCount == 0:
    break
  let volunteerCount = nextInt(inputData, scanPos)
  var dailyNeeds = newSeq[int](dayCount)
  var largestNeed = 0
  for dayIndex in 0 .. dayCount - 1:
    dailyNeeds[dayIndex] = nextInt(inputData, scanPos)
    if dailyNeeds[dayIndex] > largestNeed:
      largestNeed = dailyNeeds[dayIndex]
  var volunteers = newSeq[Volunteer](volunteerCount)
  for volunteerIndex in 0 .. volunteerCount - 1:
    volunteers[volunteerIndex].startDay = nextInt(inputData, scanPos)
    volunteers[volunteerIndex].endDay = nextInt(inputData, scanPos)
    volunteers[volunteerIndex].dailyCost = int64(nextInt(inputData, scanPos))
  let flowTarget = int64(largestNeed + 1) * int64(volunteerCount + 1)
  adjacency = newSeq[seq[FlowEdge]](dayCount + 1)
  for dayIndex in 0 .. dayCount - 1:
    addDirectedEdge(dayIndex, dayIndex + 1, flowTarget - int64(dailyNeeds[dayIndex]), 0)
  for volunteerIndex in 0 .. volunteerCount - 1:
    let currentVolunteer = volunteers[volunteerIndex]
    addDirectedEdge(currentVolunteer.startDay - 1, currentVolunteer.endDay,
                    infiniteCapacity, currentVolunteer.dailyCost)
  let minimumCost = minCostFlow(0, dayCount, flowTarget, dayCount + 1)
  appendOutput($minimumCost)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
