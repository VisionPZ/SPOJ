const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var i = 0

proc nextInt(data: string, i: var int): int =
  while i < data.len and (data[i] < '0' or data[i] > '9'):
    i += 1
  var value = 0
  while i < data.len and data[i] >= '0' and data[i] <= '9':
    value = value * 10 + int(data[i]) - firstDigitValue
    i += 1
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
    var k = stackIndices[^1]
    if k < adjacency[currentVertex].len:
      stackIndices[^1] = k + 1
      let neighbor = adjacency[currentVertex][k]
      if not visited[neighbor]:
        visited[neighbor] = true
        stackVertices.add neighbor
        stackIndices.add 0
    else:
      finishOrder.add currentVertex
      stackVertices.setLen(stackVertices.len - 1)
      stackIndices.setLen(stackIndices.len - 1)

proc assignComponents(startVertex: int, adjacency: seq[seq[int]],
                      componentOf: var seq[int], i: int) =
  var stackVertices = @[startVertex]
  componentOf[startVertex] = i
  while stackVertices.len > 0:
    let currentVertex = stackVertices.pop
    for neighbor in adjacency[currentVertex]:
      if componentOf[neighbor] < 0:
        componentOf[neighbor] = i
        stackVertices.add neighbor

let caseCount = nextInt(inputData, i)
for j in 1..caseCount:
  let participantCount = nextInt(inputData, i)
  var adjacency = newSeq[seq[int]](participantCount)
  var reverseAdjacency = newSeq[seq[int]](participantCount)
  for k in 0..<participantCount:
    adjacency[k] = @[]
    reverseAdjacency[k] = @[]
  for k in 0..<participantCount:
    let betterCount = nextInt(inputData, i)
    for _ in 0..<betterCount:
      let l = nextInt(inputData, i) - 1
      adjacency[l].add k
      reverseAdjacency[k].add l
  var visited = newSeq[bool](participantCount)
  var finishOrder = newSeq[int]()
  for k in 0..<participantCount:
    if not visited[k]:
      depthFirstOrder(k, adjacency, visited, finishOrder)
  var componentOf = newSeq[int](participantCount)
  for k in 0..<participantCount:
    componentOf[k] = -1
  var componentTotal = 0
  for l in countdown(finishOrder.len - 1, 0):
    let k = finishOrder[l]
    if componentOf[k] < 0:
      assignComponents(k, reverseAdjacency, componentOf, componentTotal)
      componentTotal += 1
  var inDegree = newSeq[int](componentTotal)
  for k in 0..<participantCount:
    for l in adjacency[k]:
      let sourceComponent = componentOf[k]
      let targetComponent = componentOf[l]
      if sourceComponent != targetComponent:
        inDegree[targetComponent] += 1
  var sourceComponentCount = 0
  var l = -1
  for k in 0..<componentTotal:
    if inDegree[k] == 0:
      sourceComponentCount += 1
      l = k
  var winnerCount = 0
  if sourceComponentCount == 1:
    for k in 0..<participantCount:
      if componentOf[k] == l:
        winnerCount += 1
  appendOutput($winnerCount)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
