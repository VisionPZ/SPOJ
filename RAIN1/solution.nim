import algorithm

const flushBlockBytes = 1 shl 18
const firstDigitValue = 48

var inputData = newStringOfCap(1 shl 20)
var lineBuffer = ""
var i = 0
var outputBuffer = newStringOfCap(flushBlockBytes)

var testCount = 0
var segmentCount = 0
var leftX: seq[int]
var leftY: seq[int]
var rightX: seq[int]
var rightY: seq[int]
var lowerEndX: seq[int]
var lowerEndY: seq[int]
var directWater: seq[int64]
var answerWater: seq[int64]
var receiverIndex: seq[int]
var pendingChildren: seq[int]
var endCoordIndex: seq[int]
var coordinateValues: seq[int]
var coordinateList: seq[int]
var coordinateCount = 0
var currentX = 0
var startHead: seq[int]
var startNext: seq[int]
var streamHead: seq[int]
var streamNext: seq[int]
var activeList: seq[int]
var nextActiveList: seq[int]
var coverList: seq[int]
var queueList: seq[int]

proc compareInt(firstValue: int, secondValue: int): int =
  if firstValue < secondValue:
    return -1
  if firstValue > secondValue:
    return 1
  return 0

proc nextInt(): int =
  while i < inputData.len and (inputData[i] < '0' or inputData[i] > '9'):
    i += 1
  var value = 0
  while i < inputData.len and inputData[i] >= '0' and inputData[i] <= '9':
    value = value * 10 + (int(inputData[i]) - firstDigitValue)
    i += 1
  return value

proc findCoordIndex(value: int): int =
  var i = 0
  var j = coordinateCount - 1
  while i <= j:
    let k = (i + j) div 2
    if coordinateList[k] == value:
      return k
    if coordinateList[k] < value:
      i = k + 1
    else:
      j = k - 1
  return i

proc yNumerator(i: int): int64 =
  let span = int64(rightX[i] - leftX[i])
  let slope = int64(rightY[i] - leftY[i])
  result = int64(leftY[i]) * span + slope * int64(currentX - leftX[i])

proc higherAtX(firstSeg: int, secondSeg: int): bool =
  let firstSpan = int64(rightX[firstSeg] - leftX[firstSeg])
  let secondSpan = int64(rightX[secondSeg] - leftX[secondSeg])
  result = yNumerator(firstSeg) * secondSpan > yNumerator(secondSeg) * firstSpan

proc appendOutputLine(value: int64) =
  outputBuffer.add $value
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while readLine(stdin, lineBuffer):
  inputData.add lineBuffer
  inputData.add '\n'

testCount = nextInt()

while testCount > 0:
  testCount -= 1
  segmentCount = nextInt()

  leftX = newSeq[int](segmentCount)
  leftY = newSeq[int](segmentCount)
  rightX = newSeq[int](segmentCount)
  rightY = newSeq[int](segmentCount)
  lowerEndX = newSeq[int](segmentCount)
  lowerEndY = newSeq[int](segmentCount)
  directWater = newSeq[int64](segmentCount)
  answerWater = newSeq[int64](segmentCount)
  receiverIndex = newSeq[int](segmentCount)
  pendingChildren = newSeq[int](segmentCount)
  endCoordIndex = newSeq[int](segmentCount)
  startNext = newSeq[int](segmentCount)
  streamNext = newSeq[int](segmentCount)

  coordinateValues = newSeq[int](2 * segmentCount)
  for j in 0 ..< segmentCount:
    leftX[j] = nextInt()
    leftY[j] = nextInt()
    rightX[j] = nextInt()
    rightY[j] = nextInt()
    coordinateValues[2 * j] = leftX[j]
    coordinateValues[2 * j + 1] = rightX[j]
    if leftY[j] < rightY[j]:
      lowerEndX[j] = leftX[j]
      lowerEndY[j] = leftY[j]
    else:
      lowerEndX[j] = rightX[j]
      lowerEndY[j] = rightY[j]

  coordinateValues.sort(compareInt)
  coordinateList = newSeq[int](2 * segmentCount)
  coordinateCount = 0
  for j in 0 ..< 2 * segmentCount:
    if j == 0 or coordinateValues[j] != coordinateValues[j - 1]:
      coordinateList[coordinateCount] = coordinateValues[j]
      coordinateCount += 1
  coordinateList.setLen(coordinateCount)

  startHead = newSeq[int](coordinateCount)
  streamHead = newSeq[int](coordinateCount)
  for j in 0 ..< coordinateCount:
    startHead[j] = -1
    streamHead[j] = -1

  for j in 0 ..< segmentCount:
    let startIndex = findCoordIndex(leftX[j])
    startNext[j] = startHead[startIndex]
    startHead[startIndex] = j

    let finishIndex = findCoordIndex(rightX[j])
    endCoordIndex[j] = finishIndex

    let streamIndex = findCoordIndex(lowerEndX[j])
    streamNext[j] = streamHead[streamIndex]
    streamHead[streamIndex] = j

  activeList = @[]
  nextActiveList = @[]
  coverList = newSeq[int](segmentCount + 4)

  for j in 0 ..< coordinateCount:
    currentX = coordinateList[j]
    var coverCount = 0
    for segIndex in activeList:
      coverList[coverCount] = segIndex
      coverCount += 1
    var startSeg = startHead[j]
    while startSeg != -1:
      coverList[coverCount] = startSeg
      coverCount += 1
      startSeg = startNext[startSeg]

    for k in 1 ..< coverCount:
      let keySeg = coverList[k]
      var l = k - 1
      while l >= 0 and higherAtX(keySeg, coverList[l]):
        coverList[l + 1] = coverList[l]
        l -= 1
      coverList[l + 1] = keySeg

    var streamSeg = streamHead[j]
    while streamSeg != -1:
      var receiverSeg = -1
      let sourceHeight = int64(lowerEndY[streamSeg])
      for k in 0 ..< coverCount:
        let candidateSeg = coverList[k]
        let span = int64(rightX[candidateSeg] - leftX[candidateSeg])
        if yNumerator(candidateSeg) < sourceHeight * span:
          receiverSeg = candidateSeg
          break
      receiverIndex[streamSeg] = receiverSeg
      streamSeg = streamNext[streamSeg]

    if j < coordinateCount - 1:
      for k in 0 ..< coverCount:
        let candidateSeg = coverList[k]
        if endCoordIndex[candidateSeg] != j:
          directWater[candidateSeg] += int64(coordinateList[j + 1] - currentX)
          break

    nextActiveList.setLen(0)
    for k in 0 ..< coverCount:
      let candidateSeg = coverList[k]
      if endCoordIndex[candidateSeg] != j:
        nextActiveList.add candidateSeg
    swap activeList, nextActiveList

  for j in 0 ..< segmentCount:
    answerWater[j] = directWater[j]
    pendingChildren[j] = 0
  for j in 0 ..< segmentCount:
    let receiverSeg = receiverIndex[j]
    if receiverSeg != -1:
      pendingChildren[receiverSeg] += 1

  queueList = @[]
  for j in 0 ..< segmentCount:
    if pendingChildren[j] == 0:
      queueList.add j
  var queueHead = 0
  while queueHead < queueList.len:
    let currentSeg = queueList[queueHead]
    queueHead += 1
    let receiverSeg = receiverIndex[currentSeg]
    if receiverSeg != -1:
      answerWater[receiverSeg] += answerWater[currentSeg]
      pendingChildren[receiverSeg] -= 1
      if pendingChildren[receiverSeg] == 0:
        queueList.add receiverSeg

  for j in 0 ..< segmentCount:
    appendOutputLine(answerWater[j])

stdout.write outputBuffer
outputBuffer.setLen 0
