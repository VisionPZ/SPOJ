{.push checks: off.}
const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const vertexLimit = 1000

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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

var outDeg: array[0..vertexLimit, int]
var inDeg: array[0..vertexLimit, int]
var parent: array[0..vertexLimit, int]
var compImbalance: array[0..vertexLimit, int]
var isTouched: array[0..vertexLimit, bool]
var touchedVertices: seq[int]
for vertex in 0..vertexLimit:
  parent[vertex] = vertex

proc findRoot(vertex: int): int =
  var root = vertex
  while parent[root] != root:
    root = parent[root]
  var walk = vertex
  while parent[walk] != walk:
    let nextVertex = parent[walk]
    parent[walk] = root
    walk = nextVertex
  return root

proc unionVertices(firstVertex: int, secondVertex: int) =
  let firstRoot = findRoot(firstVertex)
  let secondRoot = findRoot(secondVertex)
  if firstRoot != secondRoot:
    parent[secondRoot] = firstRoot

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let featureCount = nextInt(inputData, scanPos)
  touchedVertices.setLen 0
  for edgeIndex in 0..<featureCount:
    let leftVertex = nextInt(inputData, scanPos)
    let rightVertex = nextInt(inputData, scanPos)
    if not isTouched[leftVertex]:
      isTouched[leftVertex] = true
      touchedVertices.add leftVertex
    if not isTouched[rightVertex]:
      isTouched[rightVertex] = true
      touchedVertices.add rightVertex
    outDeg[leftVertex] += 1
    inDeg[rightVertex] += 1
    unionVertices(leftVertex, rightVertex)
  for vertex in touchedVertices:
    let imbalance = outDeg[vertex] - inDeg[vertex]
    if imbalance > 0:
      compImbalance[findRoot(vertex)] += imbalance
  var trailCount = 0
  for vertex in touchedVertices:
    if parent[vertex] == vertex:
      if compImbalance[vertex] > 0:
        trailCount += compImbalance[vertex]
      else:
        trailCount += 1
  appendOutput($(featureCount + trailCount))
  outputBuffer.add '\n'
  for vertex in touchedVertices:
    isTouched[vertex] = false
    outDeg[vertex] = 0
    inDeg[vertex] = 0
    compImbalance[vertex] = 0
    parent[vertex] = vertex

stdout.write outputBuffer
outputBuffer.setLen 0
