const flushBlockBytes = 1 shl 17
const infinity = 2305843009213693951'i64

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

proc dijkstra(edges: seq[int64], source: int, nodeCount: int): seq[int64] =
  var distances = newSeq[int64](nodeCount)
  var settled = newSeq[bool](nodeCount)
  for node in 0 .. nodeCount - 1:
    distances[node] = edges[source * nodeCount + node]
  distances[source] = 0'i64
  settled[source] = true
  for stepIndex in 1 .. nodeCount - 1:
    var bestNode = -1
    var bestDistance = infinity
    for node in 0 .. nodeCount - 1:
      if not settled[node] and distances[node] < bestDistance:
        bestDistance = distances[node]
        bestNode = node
    if bestNode < 0:
      break
    settled[bestNode] = true
    for node in 0 .. nodeCount - 1:
      if not settled[node]:
        let edgeCost = edges[bestNode * nodeCount + node]
        if edgeCost < infinity:
          let candidate = bestDistance + edgeCost
          if candidate < distances[node]:
            distances[node] = candidate
  return distances

let farmCount = nextInt(inputData, scanPos)
let flightCount = nextInt(inputData, scanPos)
let hubCount = nextInt(inputData, scanPos)
let tripCount = nextInt(inputData, scanPos)
var forwardEdges = newSeq[int64](farmCount * farmCount)
var reverseEdges = newSeq[int64](farmCount * farmCount)
for edgeIndex in 0 .. farmCount * farmCount - 1:
  forwardEdges[edgeIndex] = infinity
  reverseEdges[edgeIndex] = infinity
for flightIndex in 0 .. flightCount - 1:
  let origin = nextInt(inputData, scanPos) - 1
  let destination = nextInt(inputData, scanPos) - 1
  let cost = int64(nextInt(inputData, scanPos))
  let forwardIndex = origin * farmCount + destination
  let reverseIndex = destination * farmCount + origin
  if cost < forwardEdges[forwardIndex]:
    forwardEdges[forwardIndex] = cost
  if cost < reverseEdges[reverseIndex]:
    reverseEdges[reverseIndex] = cost
var tripStarts = newSeq[int](tripCount)
var tripEnds = newSeq[int](tripCount)
for tripIndex in 0 .. tripCount - 1:
  tripStarts[tripIndex] = nextInt(inputData, scanPos) - 1
  tripEnds[tripIndex] = nextInt(inputData, scanPos) - 1
var distancesToHub = newSeq[int64](hubCount * farmCount)
var distancesFromHub = newSeq[int64](hubCount * farmCount)
for hubIndex in 0 .. hubCount - 1:
  let toHub = dijkstra(reverseEdges, hubIndex, farmCount)
  let fromHub = dijkstra(forwardEdges, hubIndex, farmCount)
  for node in 0 .. farmCount - 1:
    distancesToHub[hubIndex * farmCount + node] = toHub[node]
    distancesFromHub[hubIndex * farmCount + node] = fromHub[node]
var possibleTrips = 0
var totalCost: int64 = 0
for tripIndex in 0 .. tripCount - 1:
  let startFarm = tripStarts[tripIndex]
  let endFarm = tripEnds[tripIndex]
  var bestCost = infinity
  for hubIndex in 0 .. hubCount - 1:
    let firstLeg = distancesToHub[hubIndex * farmCount + startFarm]
    let secondLeg = distancesFromHub[hubIndex * farmCount + endFarm]
    if firstLeg < infinity and secondLeg < infinity:
      let candidate = firstLeg + secondLeg
      if candidate < bestCost:
        bestCost = candidate
  if bestCost < infinity:
    possibleTrips += 1
    totalCost += bestCost
appendOutput($(possibleTrips))
outputBuffer.add '\n'
appendOutput($(totalCost))
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
