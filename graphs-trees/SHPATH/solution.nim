import tables
import sequtils

const flushBlockBytes = 1 shl 17
const unreachableDistance: int32 = 1000000000
const guaranteedPathCost: int32 = 200000
const bucketTotal = int(guaranteedPathCost) + 2
const wordTotal = (bucketTotal shr 6) + 1

var lineBuffer: string
var i = 0
var inputDone = false

proc refillLine(): bool =
  while true:
    if i < lineBuffer.len: return true
    if inputDone: return false
    if not readLine(stdin, lineBuffer):
      inputDone = true
      lineBuffer.setLen 0
      return false
    lineBuffer.add "\n"
    i = 0

proc skipSpace() =
  while true:
    while i < lineBuffer.len and lineBuffer[i] <= ' ': i = i + 1
    if i < lineBuffer.len: return
    if not refillLine(): return

proc readInt32(): int32 =
  skipSpace()
  var value: int32 = 0
  while i < lineBuffer.len and lineBuffer[i] >= '0' and lineBuffer[i] <= '9':
    value = value * 10 + int32(int(lineBuffer[i]) - 48)
    i = i + 1
  return value

var wordText: string
var lowBitPosition = newSeq[int](1 shl 16)
var positionProbe = 1
while positionProbe < (1 shl 16):
  var shiftedValue = positionProbe
  var i = 0
  while (shiftedValue and 1) == 0:
    shiftedValue = shiftedValue shr 1
    i = i + 1
  lowBitPosition[positionProbe] = i
  positionProbe = positionProbe + 1
lowBitPosition[0] = 16

proc lowestSetBitPosition(value: uint64): int =
  var chunk = cast[int](value and cast[uint64](0xFFFF))
  if chunk != 0: return lowBitPosition[chunk]
  chunk = cast[int]((value shr 16) and cast[uint64](0xFFFF))
  if chunk != 0: return 16 + lowBitPosition[chunk]
  chunk = cast[int]((value shr 32) and cast[uint64](0xFFFF))
  if chunk != 0: return 32 + lowBitPosition[chunk]
  chunk = cast[int]((value shr 48) and cast[uint64](0xFFFF))
  return 48 + lowBitPosition[chunk]

var edgeStart: seq[int]
var edgeTarget: seq[int32]
var edgeCost: seq[int32]
var distanceValue: seq[int32]
var bucketHead = repeat(-1, bucketTotal)
var bucketWords: seq[uint64]
var usedDistanceList: seq[int]
var usedWordList: seq[int]
var nodeVertex: seq[int32]
var nodeNext: seq[int]
var nodeTotal = 0
var targetStamp: seq[int]
var searchStamp = 0

proc clearBuckets() =
  for i in usedDistanceList:
    bucketHead[i] = -1
  for j in usedWordList:
    bucketWords[j] = 0

proc enqueueBucket(distance: int32, vertex: int32) =
  var i = int(distance)
  if bucketHead[i] == -1: usedDistanceList.add i
  var j = i shr 6
  if bucketWords[j] == 0: usedWordList.add j
  bucketWords[j] = bucketWords[j] or (cast[uint64](1) shl (i and 63))
  nodeNext[nodeTotal] = bucketHead[i]
  bucketHead[i] = nodeTotal
  nodeVertex[nodeTotal] = vertex
  nodeTotal = nodeTotal + 1

proc shortestPathsFrom(source: int32, cityCount: int, targetsLeft: var int) =
  for i in 0 .. cityCount - 1: distanceValue[i] = unreachableDistance
  usedDistanceList.setLen 0
  usedWordList.setLen 0
  nodeTotal = 0
  distanceValue[int(source)] = 0
  enqueueBucket(0, source)
  var currentDistance = 0
  while true:
    var i = bucketHead[currentDistance]
    while i >= 0:
      var settledVertex = int(nodeVertex[i])
      i = nodeNext[i]
      if distanceValue[settledVertex] != int32(currentDistance): continue
      if targetStamp[settledVertex] == searchStamp:
        targetStamp[settledVertex] = 0
        targetsLeft = targetsLeft - 1
        if targetsLeft == 0:
          currentDistance = int(guaranteedPathCost) + 1
          break
      var j = edgeStart[settledVertex]
      let walkLimit = edgeStart[settledVertex + 1]
      while j < walkLimit:
        var neighbour = int(edgeTarget[j])
        var candidateDistance = int32(currentDistance) + edgeCost[j]
        if candidateDistance < distanceValue[neighbour] and candidateDistance <= guaranteedPathCost:
          distanceValue[neighbour] = candidateDistance
          enqueueBucket(candidateDistance, int32(neighbour))
        j = j + 1
    if targetsLeft == 0 or currentDistance >= int(guaranteedPathCost): break
    bucketHead[currentDistance] = -1
    var j = (currentDistance + 1) shr 6
    var bitMask = bucketWords[j] and
      not((cast[uint64](1) shl ((currentDistance + 1) and 63)) - 1)
    while true:
      if bitMask != 0: break
      j = j + 1
      if j >= wordTotal: break
      bitMask = bucketWords[j]
    if bitMask == 0:
      currentDistance = int(guaranteedPathCost) + 1
      break
    currentDistance = (j shl 6) + lowestSetBitPosition(bitMask)
    bucketWords[j] = bucketWords[j] and not(cast[uint64](1) shl (currentDistance and 63))
  clearBuckets()

proc readWord(): string =
  skipSpace()
  var collected: string
  while i < lineBuffer.len and lineBuffer[i] > ' ':
    collected.add lineBuffer[i]
    i = i + 1
  return collected

var testCount = int(readInt32())
var outputBuffer: string
for _ in 1 .. testCount:
  var cityCount = int(readInt32())
  var nameToIndex = initTable[string, int]()
  edgeStart = newSeq[int](cityCount + 1)
  edgeTarget = newSeq[int32]()
  edgeCost = newSeq[int32]()
  for i in 0 .. cityCount - 1:
    nameToIndex[readWord()] = i
    var neighbourCount = int(readInt32())
    edgeStart[i] = edgeTarget.len
    for _ in 1 .. neighbourCount:
      edgeTarget.add readInt32() - 1
      edgeCost.add readInt32()
  edgeStart[cityCount] = edgeTarget.len
  var edgeTotal = edgeTarget.len
  distanceValue = repeat(unreachableDistance, cityCount)
  targetStamp = repeat(0, cityCount)
  nodeVertex = newSeq[int32](edgeTotal + 2)
  nodeNext = newSeq[int](edgeTotal + 2)
  bucketWords = repeat(cast[uint64](0), wordTotal)
  var queryCount = int(readInt32())
  var querySource = newSeq[int32](queryCount)
  var queryTarget = newSeq[int32](queryCount)
  for i in 0 .. queryCount - 1:
    querySource[i] = int32(nameToIndex[readWord()])
    queryTarget[i] = int32(nameToIndex[readWord()])
  var answerValue = newSeq[int32](queryCount)
  var sourceUsed = repeat(false, cityCount)
  for i in 0 .. queryCount - 1:
    if sourceUsed[int(querySource[i])]: continue
    sourceUsed[int(querySource[i])] = true
    searchStamp = searchStamp + 1
    var targetsLeft = 0
    for j in 0 .. queryCount - 1:
      if querySource[j] == querySource[i]:
        if targetStamp[int(queryTarget[j])] != searchStamp:
          targetStamp[int(queryTarget[j])] = searchStamp
          targetsLeft = targetsLeft + 1
    shortestPathsFrom(querySource[i], cityCount, targetsLeft)
    for j in 0 .. queryCount - 1:
      if querySource[j] == querySource[i]:
        answerValue[j] = distanceValue[int(queryTarget[j])]
  for i in 0 .. queryCount - 1:
    outputBuffer.add $answerValue[i]
    outputBuffer.add "\n"
    if outputBuffer.len >= flushBlockBytes:
      stdout.write outputBuffer
      outputBuffer.setLen 0
stdout.write outputBuffer
