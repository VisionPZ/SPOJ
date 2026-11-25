const flushBlockBytes = 1 shl 17

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

var knightCount = 0
var adjacency: seq[seq[int]] = @[]
var discovery = newSeq[int](0)
var lowLink = newSeq[int](0)
var parentVertex = newSeq[int](0)
var colorValue = newSeq[int](0)
var componentMark = newSeq[int](0)
var canSit = newSeq[bool](0)
var edgeStack: seq[tuple[firstVertex, secondVertex: int]] = @[]
var discoveryTimer = 0
var componentId = 0

proc examineComponent(componentVertices: seq[int]) =
  componentId += 1
  for vertex in componentVertices:
    componentMark[vertex] = componentId
  var vertexQueue = newSeq[int](componentVertices.len)
  var queueHead = 0
  var queueTail = 0
  colorValue[componentVertices[0]] = 0
  vertexQueue[queueTail] = componentVertices[0]
  queueTail += 1
  var oddCycle = false
  while queueHead < queueTail and not oddCycle:
    let currentVertex = vertexQueue[queueHead]
    queueHead += 1
    for neighbor in adjacency[currentVertex]:
      if componentMark[neighbor] != componentId:
        continue
      if colorValue[neighbor] == -1:
        colorValue[neighbor] = 1 - colorValue[currentVertex]
        vertexQueue[queueTail] = neighbor
        queueTail += 1
      elif colorValue[neighbor] == colorValue[currentVertex]:
        oddCycle = true
        break
  if oddCycle:
    for vertex in componentVertices:
      canSit[vertex] = true
  for vertex in componentVertices:
    colorValue[vertex] = -1

proc visitVertex(startVertex: int) =
  discovery[startVertex] = discoveryTimer
  lowLink[startVertex] = discoveryTimer
  discoveryTimer += 1
  for neighbor in adjacency[startVertex]:
    if discovery[neighbor] == -1:
      parentVertex[neighbor] = startVertex
      edgeStack.add((startVertex, neighbor))
      visitVertex(neighbor)
      if lowLink[neighbor] < lowLink[startVertex]:
        lowLink[startVertex] = lowLink[neighbor]
      if lowLink[neighbor] >= discovery[startVertex]:
        var componentVertices: seq[int] = @[]
        while true:
          let savedEdge = edgeStack[edgeStack.len - 1]
          edgeStack.setLen(edgeStack.len - 1)
          componentVertices.add(savedEdge.firstVertex)
          componentVertices.add(savedEdge.secondVertex)
          if savedEdge.firstVertex == startVertex and savedEdge.secondVertex == neighbor:
            break
        examineComponent(componentVertices)
    elif neighbor != parentVertex[startVertex] and discovery[neighbor] < discovery[startVertex]:
      edgeStack.add((startVertex, neighbor))
      if discovery[neighbor] < lowLink[startVertex]:
        lowLink[startVertex] = discovery[neighbor]

while true:
  let requestedKnights = nextInt(inputData, scanPos)
  let requestedPairs = nextInt(inputData, scanPos)
  if requestedKnights == 0 and requestedPairs == 0:
    break
  knightCount = requestedKnights
  var hates = newSeq[bool](knightCount * knightCount)
  for pairIndex in 0 .. requestedPairs - 1:
    let firstKnight = nextInt(inputData, scanPos) - 1
    let secondKnight = nextInt(inputData, scanPos) - 1
    hates[firstKnight * knightCount + secondKnight] = true
    hates[secondKnight * knightCount + firstKnight] = true

  adjacency = newSeq[seq[int]](knightCount)
  for firstKnight in 0 .. knightCount - 1:
    adjacency[firstKnight] = @[]
  for firstKnight in 0 .. knightCount - 1:
    for secondKnight in firstKnight + 1 .. knightCount - 1:
      if not hates[firstKnight * knightCount + secondKnight]:
        adjacency[firstKnight].add(secondKnight)
        adjacency[secondKnight].add(firstKnight)

  discovery = newSeq[int](knightCount)
  lowLink = newSeq[int](knightCount)
  parentVertex = newSeq[int](knightCount)
  colorValue = newSeq[int](knightCount)
  componentMark = newSeq[int](knightCount)
  canSit = newSeq[bool](knightCount)
  for vertex in 0 .. knightCount - 1:
    discovery[vertex] = -1
    parentVertex[vertex] = -1
    colorValue[vertex] = -1
    componentMark[vertex] = 0
  discoveryTimer = 0
  componentId = 0
  edgeStack = @[]

  for vertex in 0 .. knightCount - 1:
    if discovery[vertex] == -1:
      visitVertex(vertex)
    if edgeStack.len > 0:
      edgeStack.setLen(0)

  var expelledCount = 0
  for vertex in 0 .. knightCount - 1:
    if not canSit[vertex]:
      expelledCount += 1
  appendOutput($expelledCount)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
