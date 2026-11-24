const flushBlockBytes = 1 shl 18
const firstDigitValue = 48

var inputData = readAll(stdin)
var i = 0

proc moreInput(): bool =
  let dataLength = inputData.len
  while i < dataLength and inputData[i] <= ' ':
    i.inc
  return i < dataLength

proc scanInt(): int =
  let dataLength = inputData.len
  while i < dataLength and (inputData[i] < '0' or inputData[i] > '9'):
    i.inc
  result = 0
  while i < dataLength and inputData[i] >= '0' and inputData[i] <= '9':
    result = result * 10 + int(inputData[i]) - firstDigitValue
    i.inc

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

proc compressPath(k: int) =
  let parentNumber = ancestorNumber[k]
  if ancestorNumber[parentNumber] != 0:
    compressPath(parentNumber)
    if semiNumber[labelNumber[parentNumber]] < semiNumber[labelNumber[k]]:
      labelNumber[k] = labelNumber[parentNumber]
    ancestorNumber[k] = ancestorNumber[parentNumber]

proc evaluateVertex(k: int): int =
  if ancestorNumber[k] == 0:
    return k
  compressPath(k)
  return labelNumber[k]

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
  for l in 0 .. vertexCount:
    forwardHead[l] = 0
  for i in 0 ..< edgeCount:
    let sourceVertex = scanInt()
    let targetVertex = scanInt()
    let j = i + 1
    edgeFrom[i] = sourceVertex
    edgeTo[i] = targetVertex
    forwardTo[j] = targetVertex
    forwardNext[j] = forwardHead[sourceVertex]
    forwardHead[sourceVertex] = j

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
  for l in 0 .. vertexCount:
    dfsNumber[l] = 0
  var numberCount = 1
  dfsNumber[1] = numberCount
  vertexAtNumber[numberCount] = 1
  parentNumber[numberCount] = 0
  var depth = 0
  stackVertex[0] = 1
  stackEdge[0] = forwardHead[1]
  while depth >= 0:
    let currentVertex = stackVertex[depth]
    var i = stackEdge[depth]
    while i != 0 and dfsNumber[forwardTo[i]] != 0:
      i = forwardNext[i]
    if i == 0:
      depth.dec
    else:
      stackEdge[depth] = forwardNext[i]
      let nextVertex = forwardTo[i]
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
  for k in 0 .. numberCount:
    predHead[k] = 0
  for i in 0 ..< edgeCount:
    let j = i + 1
    let fromNumber = dfsNumber[edgeFrom[i]]
    let toNumber = dfsNumber[edgeTo[i]]
    predSource[j] = fromNumber
    predNext[j] = predHead[toNumber]
    predHead[toNumber] = j

  semiNumber.setLen(numberCount + 1)
  labelNumber.setLen(numberCount + 1)
  ancestorNumber.setLen(numberCount + 1)
  immediateDominator.setLen(numberCount + 1)
  var bucketHead: seq[int] = @[]
  var bucketNext: seq[int] = @[]
  bucketHead.setLen(numberCount + 1)
  bucketNext.setLen(numberCount + 1)
  for k in 0 .. numberCount:
    semiNumber[k] = k
    labelNumber[k] = k
    ancestorNumber[k] = 0
    immediateDominator[k] = 0
    bucketHead[k] = 0
    bucketNext[k] = 0

  for k in countdown(numberCount, 2):
    var i = predHead[k]
    while i != 0:
      let candidate = evaluateVertex(predSource[i])
      if semiNumber[candidate] < semiNumber[k]:
        semiNumber[k] = semiNumber[candidate]
      i = predNext[i]
    bucketNext[k] = bucketHead[semiNumber[k]]
    bucketHead[semiNumber[k]] = k
    let parent = parentNumber[k]
    linkVertex(parent, k)
    var bucketVertex = bucketHead[parent]
    while bucketVertex != 0:
      let candidate = evaluateVertex(bucketVertex)
      if semiNumber[candidate] < semiNumber[bucketVertex]:
        immediateDominator[bucketVertex] = candidate
      else:
        immediateDominator[bucketVertex] = parent
      bucketVertex = bucketNext[bucketVertex]
    bucketHead[parent] = 0

  for k in 2 .. numberCount:
    if immediateDominator[k] != semiNumber[k]:
      immediateDominator[k] = immediateDominator[immediateDominator[k]]

  var childCount: seq[int] = @[]
  childCount.setLen(numberCount + 1)
  for k in 0 .. numberCount:
    childCount[k] = 0
  for k in 2 .. numberCount:
    childCount[immediateDominator[k]].inc

  var criticalCount = 0
  var criticalList: seq[int] = @[]
  for originalVertex in 1 .. vertexCount:
    let k = dfsNumber[originalVertex]
    if childCount[k] >= 1:
      criticalCount.inc
      criticalList.add originalVertex

  emitInt(criticalCount)
  emitChar('\n')
  for i in 0 ..< criticalList.len:
    if i > 0:
      emitChar(' ')
    emitInt(criticalList[i])
  emitChar('\n')

while moreInput():
  let vertexCount = scanInt()
  let edgeCount = scanInt()
  solveCase(vertexCount, edgeCount)

stdout.write outputBuffer
