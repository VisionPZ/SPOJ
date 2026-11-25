import hashes

const flushBlockBytes = 1 shl 17
const nameTableSize = 1 shl 15
const edgeTableSize = 1 shl 19

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
  while pos < data.len and (data[pos] == ' ' or data[pos] == '\n' or data[pos] == '\r' or data[pos] == '\t'):
    pos += 1
  let tokenStart = pos
  while pos < data.len and data[pos] != ' ' and data[pos] != '\n' and data[pos] != '\r' and data[pos] != '\t':
    pos += 1
  return data[tokenStart .. pos - 1]

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var nameSlots = newSeq[int](nameTableSize)
var storedNames = newSeq[string](0)

proc nameSlotFor(name: string): int =
  result = int(hash(name)) and (nameTableSize - 1)
  while nameSlots[result] != 0 and storedNames[nameSlots[result] - 1] != name:
    result = (result + 1) and (nameTableSize - 1)

proc getIdFor(name: string): int =
  let slot = nameSlotFor(name)
  if nameSlots[slot] == 0:
    storedNames.add name
    nameSlots[slot] = storedNames.len
    return storedNames.len - 1
  return nameSlots[slot] - 1

discard nextInt(inputData, scanPos)
let notedRelationships = nextInt(inputData, scanPos)
var edgeFirst = newSeq[int](notedRelationships)
var edgeSecond = newSeq[int](notedRelationships)
for edgeIndex in 0 .. notedRelationships - 1:
  let firstPerson = nextToken(inputData, scanPos)
  let secondPerson = nextToken(inputData, scanPos)
  edgeFirst[edgeIndex] = getIdFor(firstPerson)
  edgeSecond[edgeIndex] = getIdFor(secondPerson)

let queryCount = nextInt(inputData, scanPos)
var queryKinds = newSeq[int](queryCount)
var queryFirst = newSeq[int](queryCount)
var querySecond = newSeq[int](queryCount)
var queryThird = newSeq[int](queryCount)
var queryFourth = newSeq[int](queryCount)
for queryIndex in 0 .. queryCount - 1:
  queryKinds[queryIndex] = nextInt(inputData, scanPos)
  queryFirst[queryIndex] = getIdFor(nextToken(inputData, scanPos))
  querySecond[queryIndex] = getIdFor(nextToken(inputData, scanPos))
  queryThird[queryIndex] = getIdFor(nextToken(inputData, scanPos))
  queryFourth[queryIndex] = if queryKinds[queryIndex] == 1: getIdFor(nextToken(inputData, scanPos)) else: -1

let vertexCount = storedNames.len
var adjacency = newSeq[seq[int]](vertexCount)
var adjacencyEdges = newSeq[seq[int]](vertexCount)
for vertexIndex in 0 .. vertexCount - 1:
  adjacency[vertexIndex] = newSeq[int](0)
  adjacencyEdges[vertexIndex] = newSeq[int](0)
for edgeIndex in 0 .. notedRelationships - 1:
  let firstVertex = edgeFirst[edgeIndex]
  let secondVertex = edgeSecond[edgeIndex]
  adjacency[firstVertex].add secondVertex
  adjacencyEdges[firstVertex].add edgeIndex
  adjacency[secondVertex].add firstVertex
  adjacencyEdges[secondVertex].add edgeIndex

var edgeSlots = newSeq[int](edgeTableSize)
proc edgeKeyFor(firstVertex, secondVertex: int): int =
  if firstVertex < secondVertex:
    return firstVertex * vertexCount + secondVertex + 1
  return secondVertex * vertexCount + firstVertex + 1
proc edgeSlotFor(key: int): int =
  result = int(hash(key)) and (edgeTableSize - 1)
  while edgeSlots[result] != 0 and edgeSlots[result] != key:
    result = (result + 1) and (edgeTableSize - 1)
proc hasEdge(firstVertex, secondVertex: int): bool =
  let key = edgeKeyFor(firstVertex, secondVertex)
  return edgeSlots[edgeSlotFor(key)] == key
for edgeIndex in 0 .. notedRelationships - 1:
  edgeSlots[edgeSlotFor(edgeKeyFor(edgeFirst[edgeIndex], edgeSecond[edgeIndex]))] = edgeKeyFor(edgeFirst[edgeIndex], edgeSecond[edgeIndex])

var discovery = newSeq[int](vertexCount)
var lowValue = newSeq[int](vertexCount)
var treeParent = newSeq[int](vertexCount)
var parentEdge = newSeq[int](vertexCount)
var subtreeEnd = newSeq[int](vertexCount)
var edgeCursor = newSeq[int](vertexCount)
for vertexIndex in 0 .. vertexCount - 1:
  treeParent[vertexIndex] = -1
  parentEdge[vertexIndex] = -1
var searchTimer = 0
for rootVertex in 0 .. vertexCount - 1:
  if discovery[rootVertex] != 0:
    continue
  var dfsStack = newSeq[int](0)
  discovery[rootVertex] = searchTimer + 1
  lowValue[rootVertex] = searchTimer + 1
  searchTimer += 1
  dfsStack.add rootVertex
  while dfsStack.len > 0:
    let currentVertex = dfsStack[dfsStack.len - 1]
    if edgeCursor[currentVertex] < adjacency[currentVertex].len:
      let neighborVertex = adjacency[currentVertex][edgeCursor[currentVertex]]
      let currentEdge = adjacencyEdges[currentVertex][edgeCursor[currentVertex]]
      edgeCursor[currentVertex] += 1
      if currentEdge == parentEdge[currentVertex]:
        continue
      if discovery[neighborVertex] == 0:
        treeParent[neighborVertex] = currentVertex
        parentEdge[neighborVertex] = currentEdge
        discovery[neighborVertex] = searchTimer + 1
        lowValue[neighborVertex] = searchTimer + 1
        searchTimer += 1
        dfsStack.add neighborVertex
      elif discovery[neighborVertex] < lowValue[currentVertex]:
        lowValue[currentVertex] = discovery[neighborVertex]
    else:
      dfsStack.setLen(dfsStack.len - 1)
      subtreeEnd[currentVertex] = searchTimer
      if dfsStack.len > 0:
        let parentVertex = dfsStack[dfsStack.len - 1]
        if lowValue[currentVertex] < lowValue[parentVertex]:
          lowValue[parentVertex] = lowValue[currentVertex]

proc regionLabel(startVertex, cutVertex: int): int =
  var currentVertex = startVertex
  while currentVertex != cutVertex and currentVertex >= 0:
    let parentVertex = treeParent[currentVertex]
    if parentVertex == cutVertex and lowValue[currentVertex] >= discovery[cutVertex]:
      return currentVertex + 1
    currentVertex = parentVertex
  return 0

for queryIndex in 0 .. queryCount - 1:
  let personA = queryFirst[queryIndex]
  let personB = querySecond[queryIndex]
  let personC = queryThird[queryIndex]
  var stable = false
  if queryKinds[queryIndex] == 1:
    let personD = queryFourth[queryIndex]
    if not hasEdge(personC, personD):
      stable = true
    else:
      var separatingChild = -1
      var bridgeParent = -1
      if treeParent[personD] == personC:
        separatingChild = personD
        bridgeParent = personC
      elif treeParent[personC] == personD:
        separatingChild = personC
        bridgeParent = personD
      if separatingChild < 0 or lowValue[separatingChild] <= discovery[bridgeParent]:
        stable = true
      else:
        let firstInside = discovery[personA] >= discovery[separatingChild] and discovery[personA] <= subtreeEnd[separatingChild]
        let secondInside = discovery[personB] >= discovery[separatingChild] and discovery[personB] <= subtreeEnd[separatingChild]
        stable = firstInside == secondInside
  else:
    if personA != personC and personB != personC:
      stable = regionLabel(personA, personC) == regionLabel(personB, personC)
  if stable:
    appendOutput("STABLE\n")
  else:
    appendOutput("NOT STABLE\n")

stdout.write outputBuffer
outputBuffer.setLen 0
