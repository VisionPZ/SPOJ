import algorithm

const flushBlockBytes = 1 shl 18
const firstDigitValue = 48

var inputData = newStringOfCap(1 shl 20)
var lineBuffer = ""
var scanPos = 0
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
  while scanPos < inputData.len and (inputData[scanPos] < '0' or inputData[scanPos] > '9'):
    scanPos += 1
  var value = 0
  while scanPos < inputData.len and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    value = value * 10 + (int(inputData[scanPos]) - firstDigitValue)
    scanPos += 1
  return value

proc findCoordIndex(value: int): int =
  var lowIndex = 0
  var highIndex = coordinateCount - 1
  while lowIndex <= highIndex:
    let midIndex = (lowIndex + highIndex) div 2
    if coordinateList[midIndex] == value:
      return midIndex
    if coordinateList[midIndex] < value:
      lowIndex = midIndex + 1
    else:
      highIndex = midIndex - 1
  return lowIndex

proc yNumerator(segIndex: int): int64 =
  let span = int64(rightX[segIndex] - leftX[segIndex])
  let slope = int64(rightY[segIndex] - leftY[segIndex])
  result = int64(leftY[segIndex]) * span + slope * int64(currentX - leftX[segIndex])

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
  for segIndex in 0 ..< segmentCount:
    leftX[segIndex] = nextInt()
    leftY[segIndex] = nextInt()
    rightX[segIndex] = nextInt()
    rightY[segIndex] = nextInt()
    coordinateValues[2 * segIndex] = leftX[segIndex]
    coordinateValues[2 * segIndex + 1] = rightX[segIndex]
    if leftY[segIndex] < rightY[segIndex]:
      lowerEndX[segIndex] = leftX[segIndex]
      lowerEndY[segIndex] = leftY[segIndex]
    else:
      lowerEndX[segIndex] = rightX[segIndex]
      lowerEndY[segIndex] = rightY[segIndex]

  coordinateValues.sort(compareInt)
  coordinateList = newSeq[int](2 * segmentCount)
  coordinateCount = 0
  for coordIndex in 0 ..< 2 * segmentCount:
    if coordIndex == 0 or coordinateValues[coordIndex] != coordinateValues[coordIndex - 1]:
      coordinateList[coordinateCount] = coordinateValues[coordIndex]
      coordinateCount += 1
  coordinateList.setLen(coordinateCount)

  startHead = newSeq[int](coordinateCount)
  streamHead = newSeq[int](coordinateCount)
  for coordIndex in 0 ..< coordinateCount:
    startHead[coordIndex] = -1
    streamHead[coordIndex] = -1

  for segIndex in 0 ..< segmentCount:
    let startIndex = findCoordIndex(leftX[segIndex])
    startNext[segIndex] = startHead[startIndex]
    startHead[startIndex] = segIndex

    let finishIndex = findCoordIndex(rightX[segIndex])
    endCoordIndex[segIndex] = finishIndex

    let streamIndex = findCoordIndex(lowerEndX[segIndex])
    streamNext[segIndex] = streamHead[streamIndex]
    streamHead[streamIndex] = segIndex

  activeList = @[]
  nextActiveList = @[]
  coverList = newSeq[int](segmentCount + 4)

  for coordIndex in 0 ..< coordinateCount:
    currentX = coordinateList[coordIndex]
    var coverCount = 0
    for segIndex in activeList:
      coverList[coverCount] = segIndex
      coverCount += 1
    var startSeg = startHead[coordIndex]
    while startSeg != -1:
      coverList[coverCount] = startSeg
      coverCount += 1
      startSeg = startNext[startSeg]

    for sortIndex in 1 ..< coverCount:
      let keySeg = coverList[sortIndex]
      var posIndex = sortIndex - 1
      while posIndex >= 0 and higherAtX(keySeg, coverList[posIndex]):
        coverList[posIndex + 1] = coverList[posIndex]
        posIndex -= 1
      coverList[posIndex + 1] = keySeg

    var streamSeg = streamHead[coordIndex]
    while streamSeg != -1:
      var receiverSeg = -1
      let sourceHeight = int64(lowerEndY[streamSeg])
      for coverIndex in 0 ..< coverCount:
        let candidateSeg = coverList[coverIndex]
        let span = int64(rightX[candidateSeg] - leftX[candidateSeg])
        if yNumerator(candidateSeg) < sourceHeight * span:
          receiverSeg = candidateSeg
          break
      receiverIndex[streamSeg] = receiverSeg
      streamSeg = streamNext[streamSeg]

    if coordIndex < coordinateCount - 1:
      for coverIndex in 0 ..< coverCount:
        let candidateSeg = coverList[coverIndex]
        if endCoordIndex[candidateSeg] != coordIndex:
          directWater[candidateSeg] += int64(coordinateList[coordIndex + 1] - currentX)
          break

    nextActiveList.setLen(0)
    for coverIndex in 0 ..< coverCount:
      let candidateSeg = coverList[coverIndex]
      if endCoordIndex[candidateSeg] != coordIndex:
        nextActiveList.add candidateSeg
    swap activeList, nextActiveList

  for segIndex in 0 ..< segmentCount:
    answerWater[segIndex] = directWater[segIndex]
    pendingChildren[segIndex] = 0
  for segIndex in 0 ..< segmentCount:
    let receiverSeg = receiverIndex[segIndex]
    if receiverSeg != -1:
      pendingChildren[receiverSeg] += 1

  queueList = @[]
  for segIndex in 0 ..< segmentCount:
    if pendingChildren[segIndex] == 0:
      queueList.add segIndex
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

  for segIndex in 0 ..< segmentCount:
    appendOutputLine(answerWater[segIndex])

stdout.write outputBuffer
outputBuffer.setLen 0
