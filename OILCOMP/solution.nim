const flushBlockBytes = 1 shl 17
const infiniteCapacity: int64 = 1_000_000_000_000

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

type FlowEdge = object
  target: int
  reverseIndex: int
  capacity: int64

var gridWidth = 0
var gridHeight = 0
var sourceNode = 0
var sinkNode = 0
var flowGraph: seq[seq[FlowEdge]]
var levelValues: seq[int]
var nextEdges: seq[int]

proc addFlowEdge(fromNode: int, toNode: int, capacity: int64) =
  let forwardIndex = flowGraph[fromNode].len
  let backwardIndex = flowGraph[toNode].len
  flowGraph[fromNode].add FlowEdge(target: toNode, reverseIndex: backwardIndex,
                                  capacity: capacity)
  flowGraph[toNode].add FlowEdge(target: fromNode, reverseIndex: forwardIndex,
                                 capacity: 0'i64)

proc buildLevels(): bool =
  for nodeIndex in 0 .. levelValues.len - 1:
    levelValues[nodeIndex] = -1
  var queue = newSeq[int](flowGraph.len)
  var head = 0
  var tail = 0
  levelValues[sourceNode] = 0
  queue[tail] = sourceNode
  tail += 1
  while head < tail:
    let nodeIndex = queue[head]
    head += 1
    for edge in flowGraph[nodeIndex]:
      if edge.capacity > 0'i64 and levelValues[edge.target] < 0:
        levelValues[edge.target] = levelValues[nodeIndex] + 1
        queue[tail] = edge.target
        tail += 1
  return levelValues[sinkNode] >= 0

proc pushFlow(nodeIndex: int, available: int64): int64 =
  if nodeIndex == sinkNode:
    return available
  while nextEdges[nodeIndex] < flowGraph[nodeIndex].len:
    let edgeIndex = nextEdges[nodeIndex]
    let edge = flowGraph[nodeIndex][edgeIndex]
    if edge.capacity > 0'i64 and levelValues[edge.target] == levelValues[nodeIndex] + 1:
      let pushed = pushFlow(edge.target, min(available, edge.capacity))
      if pushed > 0'i64:
        flowGraph[nodeIndex][edgeIndex].capacity -= pushed
        flowGraph[edge.target][edge.reverseIndex].capacity += pushed
        return pushed
    nextEdges[nodeIndex] += 1
  return 0'i64

proc maximumFlow(): int64 =
  var totalFlow = 0'i64
  while buildLevels():
    for nodeIndex in 0 .. nextEdges.len - 1:
      nextEdges[nodeIndex] = 0
    while true:
      let pushed = pushFlow(sourceNode, infiniteCapacity)
      if pushed == 0'i64:
        break
      totalFlow += pushed
  return totalFlow

let caseCount = nextInt(inputData, scanPos)
for caseNumber in 1 .. caseCount:
  gridWidth = nextInt(inputData, scanPos)
  gridHeight = nextInt(inputData, scanPos)
  let cellCount = gridWidth * gridHeight
  sourceNode = cellCount
  sinkNode = cellCount + 1
  flowGraph = newSeq[seq[FlowEdge]](cellCount + 2)
  for nodeIndex in 0 .. flowGraph.len - 1:
    flowGraph[nodeIndex] = newSeq[FlowEdge](0)
  var totalOil = 0'i64
  for row in 0 .. gridHeight - 1:
    for column in 0 .. gridWidth - 1:
      let reserve = nextInt(inputData, scanPos)
      totalOil += int64(reserve)
      let cellIndex = row * gridWidth + column
      if (row + column) mod 2 == 0:
        addFlowEdge(sourceNode, cellIndex, int64(reserve))
      else:
        addFlowEdge(cellIndex, sinkNode, int64(reserve))
      if column + 1 < gridWidth:
        let neighborIndex = row * gridWidth + column + 1
        if (row + column) mod 2 == 0:
          addFlowEdge(cellIndex, neighborIndex, infiniteCapacity)
        else:
          addFlowEdge(neighborIndex, cellIndex, infiniteCapacity)
      if row + 1 < gridHeight:
        let neighborIndex = (row + 1) * gridWidth + column
        if (row + column) mod 2 == 0:
          addFlowEdge(cellIndex, neighborIndex, infiniteCapacity)
        else:
          addFlowEdge(neighborIndex, cellIndex, infiniteCapacity)
  levelValues = newSeq[int](flowGraph.len)
  nextEdges = newSeq[int](flowGraph.len)
  let minimumCover = maximumFlow()
  appendOutput("Case " & $caseNumber & ": " & $(totalOil - minimumCover))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
