const flushBlockBytes = 1 shl 18
const firstDigitValue = 48

var inputData = readAll(stdin)
var scanPos = 0

proc moreInput(): bool =
  let dataLength = inputData.len
  while scanPos < dataLength and inputData[scanPos] <= ' ':
    scanPos.inc
  return scanPos < dataLength

proc scanInt(): int =
  let dataLength = inputData.len
  while scanPos < dataLength and (inputData[scanPos] < '0' or inputData[scanPos] > '9'):
    scanPos.inc
  result = 0
  while scanPos < dataLength and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    result = result * 10 + int(inputData[scanPos]) - firstDigitValue
    scanPos.inc

var outputBuffer = ""

proc emitInt(value: int) =
  outputBuffer.add $value
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc emitChar(value: char) =
  outputBuffer.add value
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var semiNumber: seq[int] = @[]
var labelNumber: seq[int] = @[]
var ancestorNumber: seq[int] = @[]
var immediateDominator: seq[int] = @[]

proc compressPath(vertexNumber: int) =
  let parentNumber = ancestorNumber[vertexNumber]
  if ancestorNumber[parentNumber] != 0:
    compressPath(parentNumber)
    if semiNumber[labelNumber[parentNumber]] < semiNumber[labelNumber[vertexNumber]]:
      labelNumber[vertexNumber] = labelNumber[parentNumber]
    ancestorNumber[vertexNumber] = ancestorNumber[parentNumber]

proc evaluateVertex(vertexNumber: int): int =
  if ancestorNumber[vertexNumber] == 0:
    return vertexNumber
  compressPath(vertexNumber)
  return labelNumber[vertexNumber]

proc linkVertex(parentNumber: int, childNumber: int) =
  ancestorNumber[childNumber] = parentNumber

proc solveCase(vertexCount: int, edgeCount: int) =
  var forwardHead: seq[int] = @[]
  var forwardTo: seq[int] = @[]
  var forwardNext: seq[int] = @[]
  var edgeFrom: seq[int] = @[]
  var edgeTo: seq[int] = @[]
  forwardHead.setLen(vertexCount + 1)
  forwardTo.setLen(edgeCount + 1)
  forwardNext.setLen(edgeCount + 1)
  edgeFrom.setLen(edgeCount)
  edgeTo.setLen(edgeCount)
  for vertexId in 0 .. vertexCount:
    forwardHead[vertexId] = 0
  for edgeIndex in 0 ..< edgeCount:
    let sourceVertex = scanInt()
    let targetVertex = scanInt()
    let storeIndex = edgeIndex + 1
    edgeFrom[edgeIndex] = sourceVertex
    edgeTo[edgeIndex] = targetVertex
    forwardTo[storeIndex] = targetVertex
    forwardNext[storeIndex] = forwardHead[sourceVertex]
    forwardHead[sourceVertex] = storeIndex

  var dfsNumber: seq[int] = @[]
  var vertexAtNumber: seq[int] = @[]
  var parentNumber: seq[int] = @[]
  var stackVertex: seq[int] = @[]
  var stackEdge: seq[int] = @[]
  dfsNumber.setLen(vertexCount + 1)
  vertexAtNumber.setLen(vertexCount + 1)
  parentNumber.setLen(vertexCount + 1)
  stackVertex.setLen(vertexCount + 1)
  stackEdge.setLen(vertexCount + 1)
  for vertexId in 0 .. vertexCount:
    dfsNumber[vertexId] = 0
  var numberCount = 1
  dfsNumber[1] = numberCount
  vertexAtNumber[numberCount] = 1
  parentNumber[numberCount] = 0
  var depth = 0
  stackVertex[0] = 1
  stackEdge[0] = forwardHead[1]
  while depth >= 0:
    let currentVertex = stackVertex[depth]
    var edgeIndex = stackEdge[depth]
    while edgeIndex != 0 and dfsNumber[forwardTo[edgeIndex]] != 0:
      edgeIndex = forwardNext[edgeIndex]
    if edgeIndex == 0:
      depth.dec
    else:
      stackEdge[depth] = forwardNext[edgeIndex]
      let nextVertex = forwardTo[edgeIndex]
      numberCount.inc
      dfsNumber[nextVertex] = numberCount
      vertexAtNumber[numberCount] = nextVertex
      parentNumber[numberCount] = dfsNumber[currentVertex]
      depth.inc
      stackVertex[depth] = nextVertex
      stackEdge[depth] = forwardHead[nextVertex]

  var predHead: seq[int] = @[]
  var predSource: seq[int] = @[]
  var predNext: seq[int] = @[]
  predHead.setLen(numberCount + 1)
  predSource.setLen(edgeCount + 1)
  predNext.setLen(edgeCount + 1)
  for vertexNumber in 0 .. numberCount:
    predHead[vertexNumber] = 0
  for edgeIndex in 0 ..< edgeCount:
    let storeIndex = edgeIndex + 1
    let fromNumber = dfsNumber[edgeFrom[edgeIndex]]
    let toNumber = dfsNumber[edgeTo[edgeIndex]]
    predSource[storeIndex] = fromNumber
    predNext[storeIndex] = predHead[toNumber]
    predHead[toNumber] = storeIndex

  semiNumber.setLen(numberCount + 1)
  labelNumber.setLen(numberCount + 1)
  ancestorNumber.setLen(numberCount + 1)
  immediateDominator.setLen(numberCount + 1)
  var bucketHead: seq[int] = @[]
  var bucketNext: seq[int] = @[]
  bucketHead.setLen(numberCount + 1)
  bucketNext.setLen(numberCount + 1)
  for vertexNumber in 0 .. numberCount:
    semiNumber[vertexNumber] = vertexNumber
    labelNumber[vertexNumber] = vertexNumber
    ancestorNumber[vertexNumber] = 0
    immediateDominator[vertexNumber] = 0
    bucketHead[vertexNumber] = 0
    bucketNext[vertexNumber] = 0

  for vertexNumber in countdown(numberCount, 2):
    var edgeIndex = predHead[vertexNumber]
    while edgeIndex != 0:
      let candidate = evaluateVertex(predSource[edgeIndex])
      if semiNumber[candidate] < semiNumber[vertexNumber]:
        semiNumber[vertexNumber] = semiNumber[candidate]
      edgeIndex = predNext[edgeIndex]
    bucketNext[vertexNumber] = bucketHead[semiNumber[vertexNumber]]
    bucketHead[semiNumber[vertexNumber]] = vertexNumber
    let parent = parentNumber[vertexNumber]
    linkVertex(parent, vertexNumber)
    var bucketVertex = bucketHead[parent]
    while bucketVertex != 0:
      let candidate = evaluateVertex(bucketVertex)
      if semiNumber[candidate] < semiNumber[bucketVertex]:
        immediateDominator[bucketVertex] = candidate
      else:
        immediateDominator[bucketVertex] = parent
      bucketVertex = bucketNext[bucketVertex]
    bucketHead[parent] = 0

  for vertexNumber in 2 .. numberCount:
    if immediateDominator[vertexNumber] != semiNumber[vertexNumber]:
      immediateDominator[vertexNumber] = immediateDominator[immediateDominator[vertexNumber]]

  var childCount: seq[int] = @[]
  childCount.setLen(numberCount + 1)
  for vertexNumber in 0 .. numberCount:
    childCount[vertexNumber] = 0
  for vertexNumber in 2 .. numberCount:
    childCount[immediateDominator[vertexNumber]].inc

  var criticalCount = 0
  var criticalList: seq[int] = @[]
  for originalVertex in 1 .. vertexCount:
    let vertexNumber = dfsNumber[originalVertex]
    if childCount[vertexNumber] >= 1:
      criticalCount.inc
      criticalList.add originalVertex

  emitInt(criticalCount)
  emitChar('\n')
  for listIndex in 0 ..< criticalList.len:
    if listIndex > 0:
      emitChar(' ')
    emitInt(criticalList[listIndex])
  emitChar('\n')

while moreInput():
  let vertexCount = scanInt()
  let edgeCount = scanInt()
  solveCase(vertexCount, edgeCount)

stdout.write outputBuffer
