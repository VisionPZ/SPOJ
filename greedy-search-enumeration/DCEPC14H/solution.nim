const flushBlockBytes = 1 shl 17
const flowInfinity: int64 = 1 shl 40

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

proc nextToken(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  var token = ""
  while pos < data.len and data[pos] > ' ':
    token.add data[pos]
    pos += 1
  return token

proc isBlocker(character: char): bool =
  return character == '#' or character == 'T'

type
  FlowEdge = object
    target: int
    reverseIndex: int
    capacity: int64

var flowGraph = newSeq[seq[FlowEdge]](0)

proc addFlowEdge(fromNode: int, toNode: int, capacity: int64) =
  let forwardIndex = flowGraph[fromNode].len
  flowGraph[fromNode].add FlowEdge(target: toNode, reverseIndex: flowGraph[toNode].len, capacity: capacity)
  flowGraph[toNode].add FlowEdge(target: fromNode, reverseIndex: forwardIndex, capacity: 0)

proc buildLevels(sourceNode: int, level: var seq[int]): bool =
  for node in 0 .. level.len - 1:
    level[node] = -1
  var queue = newSeq[int](flowGraph.len)
  var queueHead = 0
  var queueTail = 0
  level[sourceNode] = 0
  queue[queueTail] = sourceNode
  queueTail += 1
  while queueHead < queueTail:
    let node = queue[queueHead]
    queueHead += 1
    for edge in flowGraph[node]:
      if edge.capacity > 0 and level[edge.target] < 0:
        level[edge.target] = level[node] + 1
        queue[queueTail] = edge.target
        queueTail += 1
  return level[flowGraph.len - 1] >= 0

proc pushFlow(node: int, sinkNode: int, pushed: int64, level: seq[int], progress: var seq[int]): int64 =
  if node == sinkNode:
    return pushed
  while progress[node] < flowGraph[node].len:
    let edgeIndex = progress[node]
    let edge = flowGraph[node][edgeIndex]
    if edge.capacity > 0 and level[edge.target] == level[node] + 1:
      let accepted = pushFlow(edge.target, sinkNode, min(pushed, edge.capacity), level, progress)
      if accepted > 0:
        flowGraph[node][edgeIndex].capacity -= accepted
        flowGraph[edge.target][edge.reverseIndex].capacity += accepted
        return accepted
    progress[node] += 1
  return 0

proc maximumFlow(sourceNode: int): int64 =
  var level = newSeq[int](flowGraph.len)
  var total: int64 = 0
  while buildLevels(sourceNode, level):
    var progress = newSeq[int](flowGraph.len)
    while true:
      let pushed = pushFlow(sourceNode, flowGraph.len - 1, flowInfinity, level, progress)
      if pushed == 0:
        break
      total += pushed
  return total

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let gridSize = nextInt(inputData, scanPos)
var grid = newSeq[string](gridSize)
for rowIndex in 0 .. gridSize - 1:
  grid[rowIndex] = nextToken(inputData, scanPos)

let cellCount = gridSize * gridSize
var horizontalSegmentId = newSeq[int](cellCount)
var verticalSegmentId = newSeq[int](cellCount)
for cellIndex in 0 .. cellCount - 1:
  horizontalSegmentId[cellIndex] = -1
  verticalSegmentId[cellIndex] = -1
var horizontalWeights = newSeq[int64](0)
var verticalWeights = newSeq[int64](0)

for rowIndex in 0 .. gridSize - 1:
  let rowText = grid[rowIndex]
  var columnIndex = 0
  while columnIndex < gridSize:
    if isBlocker(rowText[columnIndex]):
      columnIndex += 1
      continue
    let startColumn = columnIndex
    var segmentWeight: int64 = 0
    while columnIndex < gridSize and not isBlocker(rowText[columnIndex]):
      let cellValue = rowText[columnIndex]
      if cellValue != '0':
        segmentWeight += int64(int(cellValue) - 48)
      columnIndex += 1
    let endColumn = columnIndex - 1
    var hasTower = false
    if startColumn > 0 and rowText[startColumn - 1] == 'T':
      hasTower = true
    if endColumn < gridSize - 1 and rowText[endColumn + 1] == 'T':
      hasTower = true
    if hasTower:
      let segmentId = horizontalWeights.len
      horizontalWeights.add segmentWeight
      for column in startColumn .. endColumn:
        horizontalSegmentId[rowIndex * gridSize + column] = segmentId

for columnIndex in 0 .. gridSize - 1:
  var rowIndex = 0
  while rowIndex < gridSize:
    if isBlocker(grid[rowIndex][columnIndex]):
      rowIndex += 1
      continue
    let startRow = rowIndex
    var segmentWeight: int64 = 0
    while rowIndex < gridSize and not isBlocker(grid[rowIndex][columnIndex]):
      let cellValue = grid[rowIndex][columnIndex]
      if cellValue != '0':
        segmentWeight += int64(int(cellValue) - 48)
      rowIndex += 1
    let endRow = rowIndex - 1
    var hasTower = false
    if startRow > 0 and grid[startRow - 1][columnIndex] == 'T':
      hasTower = true
    if endRow < gridSize - 1 and grid[endRow + 1][columnIndex] == 'T':
      hasTower = true
    if hasTower:
      let segmentId = verticalWeights.len
      verticalWeights.add segmentWeight
      for row in startRow .. endRow:
        verticalSegmentId[row * gridSize + columnIndex] = segmentId

let horizontalCount = horizontalWeights.len
let verticalCount = verticalWeights.len
let sourceNode = 0
let sinkNode = horizontalCount + verticalCount + 1
flowGraph = newSeq[seq[FlowEdge]](sinkNode + 1)
for node in 0 .. sinkNode:
  flowGraph[node] = newSeq[FlowEdge](0)
var totalWeight: int64 = 0
for weight in horizontalWeights:
  totalWeight += weight
for weight in verticalWeights:
  totalWeight += weight
for segmentId in 0 .. horizontalCount - 1:
  addFlowEdge(sourceNode, segmentId + 1, horizontalWeights[segmentId])
for segmentId in 0 .. verticalCount - 1:
  addFlowEdge(horizontalCount + 1 + segmentId, sinkNode, verticalWeights[segmentId])
for cellIndex in 0 .. cellCount - 1:
  let horizontalId = horizontalSegmentId[cellIndex]
  let verticalId = verticalSegmentId[cellIndex]
  if horizontalId >= 0 and verticalId >= 0:
    addFlowEdge(horizontalId + 1, horizontalCount + 1 + verticalId, flowInfinity)

let answer = totalWeight - maximumFlow(sourceNode)
appendOutput($answer)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
