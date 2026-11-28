const flushBlockBytes = 1 shl 17
const charterPenalty: int64 = 100000
const infiniteDistance = high(int64) div 4

type FlightEdge = object
  targetNode: int
  reverseIndex: int
  remainingCapacity: int
  traversalCost: int64

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

var graph: seq[seq[FlightEdge]] = @[]
var distanceValues: seq[int64] = @[]
var parentNodes: seq[int] = @[]
var parentEdges: seq[int] = @[]
var nodePotentials: seq[int64] = @[]
var heapNodes: seq[int] = @[]
var heapDistances: seq[int64] = @[]

proc addFlight(sourceNode: int, targetNode: int, costValue: int64) =
  let forwardIndex = graph[sourceNode].len
  let backwardIndex = graph[targetNode].len
  graph[sourceNode].add FlightEdge(targetNode: targetNode,
    reverseIndex: backwardIndex, remainingCapacity: 1, traversalCost: costValue)
  graph[targetNode].add FlightEdge(targetNode: sourceNode,
    reverseIndex: forwardIndex, remainingCapacity: 0, traversalCost: -costValue)

proc heapPush(distanceValue: int64, nodeIndex: int) =
  heapDistances.add distanceValue
  heapNodes.add nodeIndex
  var childIndex = heapDistances.len - 1
  while childIndex > 0:
    let ancestorIndex = (childIndex - 1) div 2
    if heapDistances[ancestorIndex] <= heapDistances[childIndex]:
      break
    swap heapDistances[ancestorIndex], heapDistances[childIndex]
    swap heapNodes[ancestorIndex], heapNodes[childIndex]
    childIndex = ancestorIndex

proc heapPop(): tuple[nodeIndex: int, distanceValue: int64] =
  result.nodeIndex = heapNodes[0]
  result.distanceValue = heapDistances[0]
  let lastNode = heapNodes[heapNodes.len - 1]
  let lastDistance = heapDistances[heapDistances.len - 1]
  heapNodes.setLen(heapNodes.len - 1)
  heapDistances.setLen(heapDistances.len - 1)
  if heapNodes.len > 0:
    heapNodes[0] = lastNode
    heapDistances[0] = lastDistance
    var ancestorIndex = 0
    while true:
      let leftIndex = ancestorIndex * 2 + 1
      let rightIndex = leftIndex + 1
      var smallestIndex = ancestorIndex
      if leftIndex < heapDistances.len and
         heapDistances[leftIndex] < heapDistances[smallestIndex]:
        smallestIndex = leftIndex
      if rightIndex < heapDistances.len and
         heapDistances[rightIndex] < heapDistances[smallestIndex]:
        smallestIndex = rightIndex
      if smallestIndex == ancestorIndex:
        break
      swap heapDistances[ancestorIndex], heapDistances[smallestIndex]
      swap heapNodes[ancestorIndex], heapNodes[smallestIndex]
      ancestorIndex = smallestIndex

proc shortestPath(sourceNode: int, sinkNode: int): bool =
  for nodeIndex in 0 .. distanceValues.len - 1:
    distanceValues[nodeIndex] = infiniteDistance
  distanceValues[sourceNode] = 0
  heapNodes.setLen 0
  heapDistances.setLen 0
  heapPush(0, sourceNode)
  while heapNodes.len > 0:
    let current = heapPop()
    if current.distanceValue > distanceValues[current.nodeIndex]:
      continue
    for edgeIndex in 0 .. graph[current.nodeIndex].len - 1:
      let edge = graph[current.nodeIndex][edgeIndex]
      if edge.remainingCapacity <= 0:
        continue
      let nextNode = edge.targetNode
      let reducedCost = edge.traversalCost + nodePotentials[current.nodeIndex] -
                        nodePotentials[nextNode]
      let candidateDistance = distanceValues[current.nodeIndex] + reducedCost
      if candidateDistance < distanceValues[nextNode]:
        distanceValues[nextNode] = candidateDistance
        parentNodes[nextNode] = current.nodeIndex
        parentEdges[nextNode] = edgeIndex
        heapPush(candidateDistance, nextNode)
  return distanceValues[sinkNode] < infiniteDistance

while true:
  let airportCount = nextInt(inputData, scanPos)
  let regularCount = nextInt(inputData, scanPos)
  let charterCount = nextInt(inputData, scanPos)
  if airportCount == 0 and regularCount == 0 and charterCount == 0:
    break
  graph = newSeq[seq[FlightEdge]](airportCount)
  for flightIndex in 1 .. regularCount:
    let departure = nextInt(inputData, scanPos)
    let arrival = nextInt(inputData, scanPos)
    let fare = int64(nextInt(inputData, scanPos))
    addFlight(departure, arrival, fare)
  for flightIndex in 1 .. charterCount:
    let departure = nextInt(inputData, scanPos)
    let arrival = nextInt(inputData, scanPos)
    let fare = int64(nextInt(inputData, scanPos))
    addFlight(departure, arrival, charterPenalty + fare)
  distanceValues = newSeq[int64](airportCount)
  parentNodes = newSeq[int](airportCount)
  parentEdges = newSeq[int](airportCount)
  nodePotentials = newSeq[int64](airportCount)
  var totalCost: int64 = 0
  var flowValue = 0
  let destination = airportCount - 1
  while flowValue < 2:
    if not shortestPath(0, destination):
      break
    for nodeIndex in 0 .. airportCount - 1:
      if distanceValues[nodeIndex] < infiniteDistance:
        nodePotentials[nodeIndex] += distanceValues[nodeIndex]
    var currentNode = destination
    while currentNode != 0:
      let previousNode = parentNodes[currentNode]
      let edgeIndex = parentEdges[currentNode]
      totalCost += graph[previousNode][edgeIndex].traversalCost
      graph[previousNode][edgeIndex].remainingCapacity -= 1
      let reverseIndex = graph[previousNode][edgeIndex].reverseIndex
      graph[currentNode][reverseIndex].remainingCapacity += 1
      currentNode = previousNode
    flowValue += 1
  if flowValue < 2:
    appendOutput("Boa viagem, Roim")
  else:
    appendOutput($(totalCost div charterPenalty))
    appendOutput(" ")
    appendOutput($(totalCost mod charterPenalty))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
