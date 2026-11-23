const firstDigitValue = 48
const flushBlockBytes = 1 shl 18

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
  let firstSlot = edgeSlotCount
  let secondSlot = firstSlot + 1
  edgeTo[firstSlot] = secondVertex
  edgeNext[firstSlot] = headEdge[firstVertex]
  headEdge[firstVertex] = firstSlot
  edgeMate[firstSlot] = secondSlot
  edgeAlive[firstSlot] = true
  edgeTo[secondSlot] = firstVertex
  edgeNext[secondSlot] = headEdge[secondVertex]
  headEdge[secondVertex] = secondSlot
  edgeMate[secondSlot] = firstSlot
  edgeAlive[secondSlot] = true
  edgeSlotCount = secondSlot + 1
  degree[firstVertex] += 1
  degree[secondVertex] += 1

proc killGraphEdge(firstSlot, secondSlot, firstVertex, secondVertex: int) =
  edgeAlive[firstSlot] = false
  edgeAlive[secondSlot] = false
  degree[firstVertex] -= 1
  degree[secondVertex] -= 1

proc edgeKeyOf(firstVertex, secondVertex: int): int =
  if firstVertex < secondVertex:
    return firstVertex * keyStride + secondVertex
  return secondVertex * keyStride + firstVertex

proc hasGraphEdge(firstVertex, secondVertex: int): bool =
  let wanted = edgeKeyOf(firstVertex, secondVertex)
  var slot = wanted and keyMask
  while keyTable[slot] != 0:
    if keyTable[slot] == wanted:
      return true
    slot = (slot + 1) and keyMask
  return false

proc markGraphEdge(firstVertex, secondVertex: int) =
  let wanted = edgeKeyOf(firstVertex, secondVertex)
  var slot = wanted and keyMask
  while keyTable[slot] != 0:
    if keyTable[slot] == wanted:
      return
    slot = (slot + 1) and keyMask
  keyTable[slot] = wanted

let datasetCount = nextInt(inputData, scanPos)
for datasetIndex in 0..<datasetCount:
  let vertexCount = nextInt(inputData, scanPos)
  let diagonalCount = nextInt(inputData, scanPos)
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
  for slot in 0..<tableSize:
    keyTable[slot] = 0
  keyMask = tableSize - 1
  keyStride = vertexCount + 1

  for edgeIndex in 0..<edgePairCount:
    let firstVertex = nextInt(inputData, scanPos)
    let secondVertex = nextInt(inputData, scanPos)
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
  var slot = 0
  while queueHead < queue.len and remainingCount > 3:
    let vertex = queue[queueHead]
    queueHead += 1
    if removedVertex[vertex] or degree[vertex] != 2:
      continue
    var firstNeighbor = 0
    var secondNeighbor = 0
    var firstSlotFound = -1
    var secondSlotFound = -1
    slot = headEdge[vertex]
    while slot != -1:
      if edgeAlive[slot]:
        if firstNeighbor == 0:
          firstNeighbor = edgeTo[slot]
          firstSlotFound = slot
        else:
          secondNeighbor = edgeTo[slot]
          secondSlotFound = slot
      slot = edgeNext[slot]
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
  slot = headEdge[startSurvivor]
  while slot != -1:
    if edgeAlive[slot] and not removedVertex[edgeTo[slot]]:
      secondSurvivor = edgeTo[slot]
      break
    slot = edgeNext[slot]
  var thirdSurvivor = 0
  slot = headEdge[secondSurvivor]
  while slot != -1:
    if edgeAlive[slot] and edgeTo[slot] != startSurvivor and not removedVertex[edgeTo[slot]]:
      thirdSurvivor = edgeTo[slot]
      break
    slot = edgeNext[slot]
  nextVertex[startSurvivor] = secondSurvivor
  prevVertex[secondSurvivor] = startSurvivor
  nextVertex[secondSurvivor] = thirdSurvivor
  prevVertex[thirdSurvivor] = secondSurvivor
  nextVertex[thirdSurvivor] = startSurvivor
  prevVertex[startSurvivor] = thirdSurvivor

  for step in 0..<earVertex.len:
    let earIndex = earVertex.len - 1 - step
    let vertex = earVertex[earIndex]
    let leftNeighbor = earLeft[earIndex]
    let rightNeighbor = earRight[earIndex]
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
  for position in 1..<vertexCount:
    outputBuffer.add ' '
    appendOutput($walk)
    if goBackward:
      walk = prevVertex[walk]
    else:
      walk = nextVertex[walk]
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
