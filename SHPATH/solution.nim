import tables
import sequtils

const flushBlockBytes = 1 shl 17
const unreachableDistance: int32 = 1000000000
const guaranteedPathCost: int32 = 200000
const bucketTotal = int(guaranteedPathCost) + 2
const wordTotal = (bucketTotal shr 6) + 1

var lineBuffer: string
var linePos = 0
var inputDone = false

proc refillLine(): bool =
  while true:
    if linePos < lineBuffer.len: return true
    if inputDone: return false
    if not readLine(stdin, lineBuffer):
      inputDone = true
      lineBuffer.setLen 0
      return false
    lineBuffer.add "\n"
    linePos = 0

proc skipSpace() =
  while true:
    while linePos < lineBuffer.len and lineBuffer[linePos] <= ' ': linePos = linePos + 1
    if linePos < lineBuffer.len: return
    if not refillLine(): return

proc readInt32(): int32 =
  skipSpace()
  var value: int32 = 0
  while linePos < lineBuffer.len and lineBuffer[linePos] >= '0' and lineBuffer[linePos] <= '9':
    value = value * 10 + int32(int(lineBuffer[linePos]) - 48)
    linePos = linePos + 1
  return value

var wordText: string
var lowBitPosition = newSeq[int](1 shl 16)
var positionProbe = 1
while positionProbe < (1 shl 16):
  var shiftedValue = positionProbe
  var bitIndex = 0
  while (shiftedValue and 1) == 0:
    shiftedValue = shiftedValue shr 1
    bitIndex = bitIndex + 1
  lowBitPosition[positionProbe] = bitIndex
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
  for usedDistance in usedDistanceList:
    bucketHead[usedDistance] = -1
  for usedWord in usedWordList:
    bucketWords[usedWord] = 0

proc enqueueBucket(distance: int32, vertex: int32) =
  var distanceIndex = int(distance)
  if bucketHead[distanceIndex] == -1: usedDistanceList.add distanceIndex
  var wordIndex = distanceIndex shr 6
  if bucketWords[wordIndex] == 0: usedWordList.add wordIndex
  bucketWords[wordIndex] = bucketWords[wordIndex] or (cast[uint64](1) shl (distanceIndex and 63))
  nodeNext[nodeTotal] = bucketHead[distanceIndex]
  bucketHead[distanceIndex] = nodeTotal
  nodeVertex[nodeTotal] = vertex
  nodeTotal = nodeTotal + 1

proc shortestPathsFrom(source: int32, cityCount: int, targetsLeft: var int) =
  for index in 0 .. cityCount - 1: distanceValue[index] = unreachableDistance
  usedDistanceList.setLen 0
  usedWordList.setLen 0
  nodeTotal = 0
  distanceValue[int(source)] = 0
  enqueueBucket(0, source)
  var currentDistance = 0
  while true:
    var nodeIndex = bucketHead[currentDistance]
    while nodeIndex >= 0:
      var settledVertex = int(nodeVertex[nodeIndex])
      nodeIndex = nodeNext[nodeIndex]
      if distanceValue[settledVertex] != int32(currentDistance): continue
      if targetStamp[settledVertex] == searchStamp:
        targetStamp[settledVertex] = 0
        targetsLeft = targetsLeft - 1
        if targetsLeft == 0:
          currentDistance = int(guaranteedPathCost) + 1
          break
      var walkPosition = edgeStart[settledVertex]
      let walkLimit = edgeStart[settledVertex + 1]
      while walkPosition < walkLimit:
        var neighbour = int(edgeTarget[walkPosition])
        var candidateDistance = int32(currentDistance) + edgeCost[walkPosition]
        if candidateDistance < distanceValue[neighbour] and candidateDistance <= guaranteedPathCost:
          distanceValue[neighbour] = candidateDistance
          enqueueBucket(candidateDistance, int32(neighbour))
        walkPosition = walkPosition + 1
    if targetsLeft == 0 or currentDistance >= int(guaranteedPathCost): break
    bucketHead[currentDistance] = -1
    var wordIndex = (currentDistance + 1) shr 6
    var bitMask = bucketWords[wordIndex] and
      not((cast[uint64](1) shl ((currentDistance + 1) and 63)) - 1)
    while true:
      if bitMask != 0: break
      wordIndex = wordIndex + 1
      if wordIndex >= wordTotal: break
      bitMask = bucketWords[wordIndex]
    if bitMask == 0:
      currentDistance = int(guaranteedPathCost) + 1
      break
    currentDistance = (wordIndex shl 6) + lowestSetBitPosition(bitMask)
    bucketWords[wordIndex] = bucketWords[wordIndex] and not(cast[uint64](1) shl (currentDistance and 63))
  clearBuckets()

proc readWord(): string =
  skipSpace()
  var collected: string
  while linePos < lineBuffer.len and lineBuffer[linePos] > ' ':
    collected.add lineBuffer[linePos]
    linePos = linePos + 1
  return collected

var testCount = int(readInt32())
var outputBuffer: string
for _ in 1 .. testCount:
  var cityCount = int(readInt32())
  var nameToIndex = initTable[string, int]()
  edgeStart = newSeq[int](cityCount + 1)
  edgeTarget = newSeq[int32]()
  edgeCost = newSeq[int32]()
  for cityIndex in 0 .. cityCount - 1:
    nameToIndex[readWord()] = cityIndex
    var neighbourCount = int(readInt32())
    edgeStart[cityIndex] = edgeTarget.len
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
  for index in 0 .. queryCount - 1:
    querySource[index] = int32(nameToIndex[readWord()])
    queryTarget[index] = int32(nameToIndex[readWord()])
  var answerValue = newSeq[int32](queryCount)
  var sourceUsed = repeat(false, cityCount)
  for firstQuery in 0 .. queryCount - 1:
    if sourceUsed[int(querySource[firstQuery])]: continue
    sourceUsed[int(querySource[firstQuery])] = true
    searchStamp = searchStamp + 1
    var targetsLeft = 0
    for secondQuery in 0 .. queryCount - 1:
      if querySource[secondQuery] == querySource[firstQuery]:
        if targetStamp[int(queryTarget[secondQuery])] != searchStamp:
          targetStamp[int(queryTarget[secondQuery])] = searchStamp
          targetsLeft = targetsLeft + 1
    shortestPathsFrom(querySource[firstQuery], cityCount, targetsLeft)
    for secondQuery in 0 .. queryCount - 1:
      if querySource[secondQuery] == querySource[firstQuery]:
        answerValue[secondQuery] = distanceValue[int(queryTarget[secondQuery])]
  for index in 0 .. queryCount - 1:
    outputBuffer.add $answerValue[index]
    outputBuffer.add "\n"
    if outputBuffer.len >= flushBlockBytes:
      stdout.write outputBuffer
      outputBuffer.setLen 0
stdout.write outputBuffer
