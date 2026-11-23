const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int(data[position]) - firstDigitValue
    position += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc depthFirstOrder(startVertex: int, adjacency: seq[seq[int]],
                     visited: var seq[bool], finishOrder: var seq[int]) =
  var stackVertices = @[startVertex]
  var stackIndices = @[0]
  visited[startVertex] = true
  while stackVertices.len > 0:
    let currentVertex = stackVertices[^1]
    var neighborIndex = stackIndices[^1]
    if neighborIndex < adjacency[currentVertex].len:
      stackIndices[^1] = neighborIndex + 1
      let neighbor = adjacency[currentVertex][neighborIndex]
      if not visited[neighbor]:
        visited[neighbor] = true
        stackVertices.add neighbor
        stackIndices.add 0
    else:
      finishOrder.add currentVertex
      stackVertices.setLen(stackVertices.len - 1)
      stackIndices.setLen(stackIndices.len - 1)

proc assignComponents(startVertex: int, adjacency: seq[seq[int]],
                      componentOf: var seq[int], componentIndex: int) =
  var stackVertices = @[startVertex]
  componentOf[startVertex] = componentIndex
  while stackVertices.len > 0:
    let currentVertex = stackVertices.pop
    for neighbor in adjacency[currentVertex]:
      if componentOf[neighbor] < 0:
        componentOf[neighbor] = componentIndex
        stackVertices.add neighbor

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 1..caseCount:
  let participantCount = nextInt(inputData, scanPos)
  var adjacency = newSeq[seq[int]](participantCount)
  var reverseAdjacency = newSeq[seq[int]](participantCount)
  for vertexIndex in 0..<participantCount:
    adjacency[vertexIndex] = @[]
    reverseAdjacency[vertexIndex] = @[]
  for victimIndex in 0..<participantCount:
    let betterCount = nextInt(inputData, scanPos)
    for entryIndex in 0..<betterCount:
      let betterIndex = nextInt(inputData, scanPos) - 1
      adjacency[betterIndex].add victimIndex
      reverseAdjacency[victimIndex].add betterIndex
  var visited = newSeq[bool](participantCount)
  var finishOrder = newSeq[int]()
  for vertexIndex in 0..<participantCount:
    if not visited[vertexIndex]:
      depthFirstOrder(vertexIndex, adjacency, visited, finishOrder)
  var componentOf = newSeq[int](participantCount)
  for vertexIndex in 0..<participantCount:
    componentOf[vertexIndex] = -1
  var componentTotal = 0
  for orderIndex in countdown(finishOrder.len - 1, 0):
    let vertexIndex = finishOrder[orderIndex]
    if componentOf[vertexIndex] < 0:
      assignComponents(vertexIndex, reverseAdjacency, componentOf, componentTotal)
      componentTotal += 1
  var inDegree = newSeq[int](componentTotal)
  for sourceIndex in 0..<participantCount:
    for targetIndex in adjacency[sourceIndex]:
      let sourceComponent = componentOf[sourceIndex]
      let targetComponent = componentOf[targetIndex]
      if sourceComponent != targetComponent:
        inDegree[targetComponent] += 1
  var sourceComponentCount = 0
  var sourceComponentIndex = -1
  for componentIndex in 0..<componentTotal:
    if inDegree[componentIndex] == 0:
      sourceComponentCount += 1
      sourceComponentIndex = componentIndex
  var winnerCount = 0
  if sourceComponentCount == 1:
    for vertexIndex in 0..<participantCount:
      if componentOf[vertexIndex] == sourceComponentIndex:
        winnerCount += 1
  appendOutput($winnerCount)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
