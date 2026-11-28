const firstDigitValue = 48
const flushBlockBytes = 1 shl 18

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

var headEdge: seq[int]
var edgeTo: seq[int]
var edgeNext: seq[int]
var edgeMate: seq[int]
var edgeAlive: seq[bool]
var edgeSlotCount = 0
var degree: seq[int]
var keyTable: seq[int]
var keyMask = 0
var keyStride = 0
var removedVertex: seq[bool]
var earVertex: seq[int]
var earLeft: seq[int]
var earRight: seq[int]
var nextVertex: seq[int]
var prevVertex: seq[int]

proc addGraphEdge(firstVertex, secondVertex: int) =
  let i = edgeSlotCount
  let j = i + 1
  edgeTo[i] = secondVertex
  edgeNext[i] = headEdge[firstVertex]
  headEdge[firstVertex] = i
  edgeMate[i] = j
  edgeAlive[i] = true
  edgeTo[j] = firstVertex
  edgeNext[j] = headEdge[secondVertex]
  headEdge[secondVertex] = j
  edgeMate[j] = i
  edgeAlive[j] = true
  edgeSlotCount = j + 1
  degree[firstVertex] += 1
  degree[secondVertex] += 1

proc killGraphEdge(i, j, firstVertex, secondVertex: int) =
  edgeAlive[i] = false
  edgeAlive[j] = false
  degree[firstVertex] -= 1
  degree[secondVertex] -= 1

proc edgeKeyOf(firstVertex, secondVertex: int): int =
  if firstVertex < secondVertex:
    return firstVertex * keyStride + secondVertex
  return secondVertex * keyStride + firstVertex

proc hasGraphEdge(firstVertex, secondVertex: int): bool =
  let wanted = edgeKeyOf(firstVertex, secondVertex)
  var k = wanted and keyMask
  while keyTable[k] != 0:
    if keyTable[k] == wanted:
      return true
    k = (k + 1) and keyMask
  return false

proc markGraphEdge(firstVertex, secondVertex: int) =
  let wanted = edgeKeyOf(firstVertex, secondVertex)
  var k = wanted and keyMask
  while keyTable[k] != 0:
    if keyTable[k] == wanted:
      return
    k = (k + 1) and keyMask
  keyTable[k] = wanted

let datasetCount = nextInt(inputData, i)
for j in 0..<datasetCount:
  let vertexCount = nextInt(inputData, i)
  let diagonalCount = nextInt(inputData, i)
  let edgePairCount = vertexCount + diagonalCount
  let maxSlots = 2 * (edgePairCount + vertexCount) + 10

  headEdge.setLen(vertexCount + 1)
  for vertex in 0..vertexCount:
    headEdge[vertex] = -1
  edgeTo.setLen(maxSlots)
  edgeNext.setLen(maxSlots)
  edgeMate.setLen(maxSlots)
  edgeAlive.setLen(maxSlots)
  degree.setLen(vertexCount + 1)
  for vertex in 0..vertexCount:
    degree[vertex] = 0
  edgeSlotCount = 0

  var tableSize = 1
  while tableSize < 4 * (edgePairCount + vertexCount + 4):
    tableSize = tableSize shl 1
  keyTable.setLen(tableSize)
  for k in 0..<tableSize:
    keyTable[k] = 0
  keyMask = tableSize - 1
  keyStride = vertexCount + 1

  for k in 0..<edgePairCount:
    let firstVertex = nextInt(inputData, i)
    let secondVertex = nextInt(inputData, i)
    addGraphEdge(firstVertex, secondVertex)
    markGraphEdge(firstVertex, secondVertex)

  removedVertex.setLen(vertexCount + 1)
  for vertex in 0..vertexCount:
    removedVertex[vertex] = false
  earVertex.setLen 0
  earLeft.setLen 0
  earRight.setLen 0

  var queue: seq[int] = @[]
  for vertex in 1..vertexCount:
    if degree[vertex] == 2:
      queue.add vertex
  var queueHead = 0
  var remainingCount = vertexCount
  var k = 0
  while queueHead < queue.len and remainingCount > 3:
    let vertex = queue[queueHead]
    queueHead += 1
    if removedVertex[vertex] or degree[vertex] != 2:
      continue
    var firstNeighbor = 0
    var secondNeighbor = 0
    var firstSlotFound = -1
    var secondSlotFound = -1
    k = headEdge[vertex]
    while k != -1:
      if edgeAlive[k]:
        if firstNeighbor == 0:
          firstNeighbor = edgeTo[k]
          firstSlotFound = k
        else:
          secondNeighbor = edgeTo[k]
          secondSlotFound = k
      k = edgeNext[k]
    if secondNeighbor == 0:
      continue
    removedVertex[vertex] = true
    remainingCount -= 1
    earVertex.add vertex
    earLeft.add firstNeighbor
    earRight.add secondNeighbor
    killGraphEdge(firstSlotFound, edgeMate[firstSlotFound], vertex, firstNeighbor)
    killGraphEdge(secondSlotFound, edgeMate[secondSlotFound], vertex, secondNeighbor)
    if not hasGraphEdge(firstNeighbor, secondNeighbor):
      addGraphEdge(firstNeighbor, secondNeighbor)
      markGraphEdge(firstNeighbor, secondNeighbor)
    if not removedVertex[firstNeighbor] and degree[firstNeighbor] == 2:
      queue.add firstNeighbor
    if not removedVertex[secondNeighbor] and degree[secondNeighbor] == 2:
      queue.add secondNeighbor

  var startSurvivor = 0
  for vertex in 1..vertexCount:
    if not removedVertex[vertex]:
      startSurvivor = vertex
      break
  nextVertex.setLen(vertexCount + 1)
  prevVertex.setLen(vertexCount + 1)
  var secondSurvivor = 0
  k = headEdge[startSurvivor]
  while k != -1:
    if edgeAlive[k] and not removedVertex[edgeTo[k]]:
      secondSurvivor = edgeTo[k]
      break
    k = edgeNext[k]
  var thirdSurvivor = 0
  k = headEdge[secondSurvivor]
  while k != -1:
    if edgeAlive[k] and edgeTo[k] != startSurvivor and not removedVertex[edgeTo[k]]:
      thirdSurvivor = edgeTo[k]
      break
    k = edgeNext[k]
  nextVertex[startSurvivor] = secondSurvivor
  prevVertex[secondSurvivor] = startSurvivor
  nextVertex[secondSurvivor] = thirdSurvivor
  prevVertex[thirdSurvivor] = secondSurvivor
  nextVertex[thirdSurvivor] = startSurvivor
  prevVertex[startSurvivor] = thirdSurvivor

  for i in 0..<earVertex.len:
    let j = earVertex.len - 1 - i
    let vertex = earVertex[j]
    let leftNeighbor = earLeft[j]
    let rightNeighbor = earRight[j]
    if nextVertex[leftNeighbor] == rightNeighbor:
      prevVertex[vertex] = leftNeighbor
      nextVertex[vertex] = rightNeighbor
      nextVertex[leftNeighbor] = vertex
      prevVertex[rightNeighbor] = vertex
    else:
      prevVertex[vertex] = rightNeighbor
      nextVertex[vertex] = leftNeighbor
      nextVertex[rightNeighbor] = vertex
      prevVertex[leftNeighbor] = vertex

  var anchor = startSurvivor
  while anchor != 1:
    anchor = nextVertex[anchor]
  let forwardNeighbor = nextVertex[1]
  let backwardNeighbor = prevVertex[1]
  var walk = forwardNeighbor
  var goBackward = false
  if backwardNeighbor < forwardNeighbor:
    walk = backwardNeighbor
    goBackward = true
  outputBuffer.add '1'
  for i in 1..<vertexCount:
    outputBuffer.add ' '
    appendOutput($walk)
    if goBackward:
      walk = prevVertex[walk]
    else:
      walk = nextVertex[walk]
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
