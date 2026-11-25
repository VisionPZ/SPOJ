import algorithm

const flushBlockBytes = 1 shl 17
const flowInfinity = int64(1) shl 60

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

var flowNodeCount = 0
var flowSource = 0
var flowSink = 0
var flowHead = newSeq[int]()
var flowTarget = newSeq[int]()
var flowCapacity = newSeq[int64]()
var flowNext = newSeq[int]()
var flowLevel = newSeq[int]()
var flowCursor = newSeq[int]()

proc addFlowEdge(fromVertex: int, toVertex: int, capacity: int64) =
  flowTarget.add toVertex
  flowCapacity.add capacity
  flowNext.add flowHead[fromVertex]
  flowHead[fromVertex] = flowTarget.len - 1
  flowTarget.add fromVertex
  flowCapacity.add capacity
  flowNext.add flowHead[toVertex]
  flowHead[toVertex] = flowTarget.len - 1

proc flowBfs(): bool =
  flowLevel = newSeq[int](flowNodeCount)
  for vertexIndex in 0 .. flowNodeCount - 1:
    flowLevel[vertexIndex] = -1
  var queue = newSeq[int]()
  flowLevel[flowSource] = 0
  queue.add flowSource
  var queuePos = 0
  while queuePos < queue.len:
    let current = queue[queuePos]
    queuePos += 1
    var edgeIndex = flowHead[current]
    while edgeIndex != -1:
      let nextVertex = flowTarget[edgeIndex]
      if flowCapacity[edgeIndex] > 0 and flowLevel[nextVertex] < 0:
        flowLevel[nextVertex] = flowLevel[current] + 1
        queue.add nextVertex
      edgeIndex = flowNext[edgeIndex]
  return flowLevel[flowSink] >= 0

proc flowDfs(current: int, available: int64): int64 =
  if current == flowSink:
    return available
  var edgeIndex = flowCursor[current]
  while edgeIndex != -1:
    flowCursor[current] = flowNext[edgeIndex]
    let nextVertex = flowTarget[edgeIndex]
    if flowCapacity[edgeIndex] > 0 and flowLevel[nextVertex] == flowLevel[current] + 1:
      let pushed = flowDfs(nextVertex, min(available, flowCapacity[edgeIndex]))
      if pushed > 0:
        flowCapacity[edgeIndex] = flowCapacity[edgeIndex] - pushed
        flowCapacity[edgeIndex xor 1] = flowCapacity[edgeIndex xor 1] + pushed
        return pushed
    edgeIndex = flowCursor[current]
  return 0

proc computeMinCut(vertexCount: int, capacity: seq[seq[int64]],
                   source: int, sink: int): (int64, seq[bool]) =
  flowNodeCount = vertexCount
  flowSource = source
  flowSink = sink
  flowHead = newSeq[int](vertexCount)
  for vertexIndex in 0 .. vertexCount - 1:
    flowHead[vertexIndex] = -1
  flowTarget.setLen 0
  flowCapacity.setLen 0
  flowNext.setLen 0
  for fromVertex in 0 .. vertexCount - 1:
    for toVertex in fromVertex + 1 .. vertexCount - 1:
      if capacity[fromVertex][toVertex] > 0:
        addFlowEdge(fromVertex, toVertex, capacity[fromVertex][toVertex])
  var totalFlow: int64 = 0
  while flowBfs():
    flowCursor = flowHead
    while true:
      let pushed = flowDfs(source, flowInfinity)
      if pushed == 0:
        break
      totalFlow = totalFlow + pushed
  var reachable = newSeq[bool](vertexCount)
  reachable[source] = true
  var queue = newSeq[int]()
  queue.add source
  var queuePos = 0
  while queuePos < queue.len:
    let current = queue[queuePos]
    queuePos += 1
    var edgeIndex = flowHead[current]
    while edgeIndex != -1:
      let nextVertex = flowTarget[edgeIndex]
      if flowCapacity[edgeIndex] > 0 and not reachable[nextVertex]:
        reachable[nextVertex] = true
        queue.add nextVertex
      edgeIndex = flowNext[edgeIndex]
  return (totalFlow, reachable)

proc pairComparator(first: int64, second: int64): int =
  if first < second:
    return -1
  if first > second:
    return 1
  return 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let vertexCount = nextInt(inputData, scanPos)
  let edgeCount = nextInt(inputData, scanPos)
  var capacity = newSeq[seq[int64]](vertexCount)
  for vertexIndex in 0 .. vertexCount - 1:
    capacity[vertexIndex] = newSeq[int64](vertexCount)
  for edgeIndex in 0 .. edgeCount - 1:
    let firstVertex = nextInt(inputData, scanPos) - 1
    let secondVertex = nextInt(inputData, scanPos) - 1
    let edgeCapacity = int64(nextInt(inputData, scanPos))
    capacity[firstVertex][secondVertex] = capacity[firstVertex][secondVertex] + edgeCapacity
    capacity[secondVertex][firstVertex] = capacity[secondVertex][firstVertex] + edgeCapacity
  var parent = newSeq[int](vertexCount)
  var treeWeight = newSeq[int64](vertexCount)
  for source in 1 .. vertexCount - 1:
    let sink = parent[source]
    let cutResult = computeMinCut(vertexCount, capacity, source, sink)
    let reachable = cutResult[1]
    for vertexIndex in source + 1 .. vertexCount - 1:
      if parent[vertexIndex] == sink and reachable[vertexIndex]:
        parent[vertexIndex] = source
    if reachable[parent[sink]]:
      parent[source] = parent[sink]
      parent[sink] = source
      treeWeight[source] = treeWeight[sink]
      treeWeight[sink] = cutResult[0]
    else:
      treeWeight[source] = cutResult[0]
  var pairValues = newSeq[int64]()
  for source in 0 .. vertexCount - 1:
    for sink in source + 1 .. vertexCount - 1:
      var ancestor = newSeq[bool](vertexCount)
      var current = source
      while true:
        ancestor[current] = true
        if parent[current] == current:
          break
        current = parent[current]
      current = sink
      while not ancestor[current]:
        current = parent[current]
      let commonAncestor = current
      var minimumCut = flowInfinity
      current = source
      while current != commonAncestor:
        minimumCut = min(minimumCut, treeWeight[current])
        current = parent[current]
      current = sink
      while current != commonAncestor:
        minimumCut = min(minimumCut, treeWeight[current])
        current = parent[current]
      pairValues.add minimumCut
  sort(pairValues, pairComparator)
  let queryCount = nextInt(inputData, scanPos)
  if caseIndex > 0:
    appendOutput("\n")
  for queryIndex in 0 .. queryCount - 1:
    let limitValue = int64(nextInt(inputData, scanPos))
    var lowIndex = 0
    var highIndex = pairValues.len
    while lowIndex < highIndex:
      let middle = (lowIndex + highIndex) div 2
      if pairValues[middle] <= limitValue:
        lowIndex = middle + 1
      else:
        highIndex = middle
    appendOutput($lowIndex & "\n")

stdout.write outputBuffer
outputBuffer.setLen 0
