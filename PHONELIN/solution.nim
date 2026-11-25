const flushBlockBytes = 1 shl 17
const flowInfinity: int64 = 1 shl 60

type FlowEdge = object
  target: int
  nextEdge: int
  capacity: int64

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextSignedInt(data: string, pos: var int): int =
  while pos < data.len and data[pos] != '-' and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var negative = false
  if pos < data.len and data[pos] == '-':
    negative = true
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  if negative:
    return -value
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc bestProfit(rangeLimit: int, cityPositions: seq[int], towerLocations: seq[int],
                towerCosts: seq[int]): int64 =
  let towerCount = towerLocations.len
  var nodeWeight = newSeq[int64](towerCount)
  for towerIndex in 0 .. towerCount - 1:
    nodeWeight[towerIndex] = -int64(towerCosts[towerIndex])
  var laterTowers = newSeq[int](0)
  var earlierTowers = newSeq[int](0)
  for cityIndex in 0 .. cityPositions.len - 1:
    let cityX = cityPositions[cityIndex]
    var nearestIndex = -1
    for towerIndex in 0 .. towerCount - 1:
      if towerLocations[towerIndex] < cityX:
        nearestIndex = towerIndex
      else:
        break
    var chainIndex = nearestIndex
    while chainIndex >= 0:
      let distance = cityX - towerLocations[chainIndex]
      if distance > rangeLimit:
        break
      nodeWeight[chainIndex] = nodeWeight[chainIndex] + int64(rangeLimit - distance)
      let nextIndex = chainIndex - 4
      if nextIndex >= 0 and cityX - towerLocations[nextIndex] <= rangeLimit:
        laterTowers.add nextIndex
        earlierTowers.add chainIndex
      chainIndex = nextIndex
  let sourceNode = towerCount
  let sinkNode = towerCount + 1
  let nodeCount = towerCount + 2
  var edgeHead = newSeq[int](nodeCount)
  for nodeIndex in 0 .. nodeCount - 1:
    edgeHead[nodeIndex] = -1
  var edges = newSeq[FlowEdge](0)
  proc addDirected(frm: int, to: int, capacity: int64) =
    edges.add FlowEdge(target: to, nextEdge: edgeHead[frm], capacity: capacity)
    edgeHead[frm] = edges.len - 1
  proc addLink(frm: int, to: int, capacity: int64) =
    addDirected(frm, to, capacity)
    addDirected(to, frm, 0)
  var positiveTotal: int64 = 0
  for towerIndex in 0 .. towerCount - 1:
    if nodeWeight[towerIndex] > 0:
      positiveTotal = positiveTotal + nodeWeight[towerIndex]
      addLink(sourceNode, towerIndex, nodeWeight[towerIndex])
    elif nodeWeight[towerIndex] < 0:
      addLink(towerIndex, sinkNode, -nodeWeight[towerIndex])
  for linkIndex in 0 .. laterTowers.len - 1:
    addLink(laterTowers[linkIndex], earlierTowers[linkIndex], flowInfinity)
  var level = newSeq[int](nodeCount)
  var iteratorEdge = newSeq[int](nodeCount)
  proc breadthFirst(): bool =
    for nodeIndex in 0 .. nodeCount - 1:
      level[nodeIndex] = -1
    var queue = newSeq[int](nodeCount)
    var queueHead = 0
    var queueTail = 0
    level[sourceNode] = 0
    queue[queueTail] = sourceNode
    queueTail += 1
    while queueHead < queueTail:
      let currentNode = queue[queueHead]
      queueHead += 1
      var edgeIndex = edgeHead[currentNode]
      while edgeIndex != -1:
        let targetNode = edges[edgeIndex].target
        if edges[edgeIndex].capacity > 0 and level[targetNode] == -1:
          level[targetNode] = level[currentNode] + 1
          queue[queueTail] = targetNode
          queueTail += 1
        edgeIndex = edges[edgeIndex].nextEdge
    return level[sinkNode] != -1
  proc sendFlow(currentNode: int, pushed: int64): int64 =
    if currentNode == sinkNode:
      return pushed
    while iteratorEdge[currentNode] != -1:
      let edgeIndex = iteratorEdge[currentNode]
      let targetNode = edges[edgeIndex].target
      if edges[edgeIndex].capacity > 0 and level[targetNode] == level[currentNode] + 1:
        let accepted = sendFlow(targetNode, min(pushed, edges[edgeIndex].capacity))
        if accepted > 0:
          edges[edgeIndex].capacity = edges[edgeIndex].capacity - accepted
          edges[edgeIndex xor 1].capacity = edges[edgeIndex xor 1].capacity + accepted
          return accepted
      iteratorEdge[currentNode] = edges[edgeIndex].nextEdge
    return 0
  var totalFlow: int64 = 0
  while breadthFirst():
    for nodeIndex in 0 .. nodeCount - 1:
      iteratorEdge[nodeIndex] = edgeHead[nodeIndex]
    while true:
      let pushed = sendFlow(sourceNode, flowInfinity)
      if pushed == 0:
        break
      totalFlow = totalFlow + pushed
  return positiveTotal - totalFlow

while true:
  let rangeLimit = nextSignedInt(inputData, scanPos)
  let cityCount = nextSignedInt(inputData, scanPos)
  let towerCount = nextSignedInt(inputData, scanPos)
  if rangeLimit == -1 and cityCount == -1 and towerCount == -1:
    break
  var cityPositions = newSeq[int](cityCount)
  for cityIndex in 0 .. cityCount - 1:
    cityPositions[cityIndex] = nextSignedInt(inputData, scanPos)
  var towerLocations = newSeq[int](towerCount)
  var towerCosts = newSeq[int](towerCount)
  for towerIndex in 0 .. towerCount - 1:
    towerLocations[towerIndex] = nextSignedInt(inputData, scanPos)
    towerCosts[towerIndex] = nextSignedInt(inputData, scanPos)
  for towerIndex in 1 .. towerCount - 1:
    var earlierIndex = towerIndex
    while earlierIndex > 0 and towerLocations[earlierIndex - 1] > towerLocations[earlierIndex]:
      swap towerLocations[earlierIndex - 1], towerLocations[earlierIndex]
      swap towerCosts[earlierIndex - 1], towerCosts[earlierIndex]
      earlierIndex -= 1
  let profit = bestProfit(rangeLimit, cityPositions, towerLocations, towerCosts)
  appendOutput($profit)
  appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0
