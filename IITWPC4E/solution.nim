import algorithm

const flushBlockBytes = 1 shl 17

type SweepEvent = object
  eventX: int
  lowerY: int
  upperY: int
  flipDelta: int

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  var negativeValue = false
  if pos < data.len and data[pos] == '-':
    negativeValue = true
    pos += 1
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  if negativeValue:
    return -value
  return value

proc compareIntegers(leftValue: int, rightValue: int): int =
  if leftValue < rightValue:
    return -1
  if leftValue > rightValue:
    return 1
  return 0

proc compareEvents(leftEvent: SweepEvent, rightEvent: SweepEvent): int =
  return compareIntegers(leftEvent.eventX, rightEvent.eventX)

var yCoordinates: seq[int]
var coverCounts: seq[int]
var coveredLengths: seq[int]

proc findYIndex(value: int): int =
  var lowIndex = 0
  var highIndex = yCoordinates.len - 1
  while lowIndex <= highIndex:
    let middleIndex = (lowIndex + highIndex) div 2
    if yCoordinates[middleIndex] < value:
      lowIndex = middleIndex + 1
    elif yCoordinates[middleIndex] > value:
      highIndex = middleIndex - 1
    else:
      return middleIndex
  return lowIndex

proc pullCoverage(nodeIndex: int, leftIndex: int, rightIndex: int) =
  if coverCounts[nodeIndex] > 0:
    coveredLengths[nodeIndex] = yCoordinates[rightIndex + 1] - yCoordinates[leftIndex]
  elif leftIndex == rightIndex:
    coveredLengths[nodeIndex] = 0
  else:
    coveredLengths[nodeIndex] = coveredLengths[nodeIndex * 2] + coveredLengths[nodeIndex * 2 + 1]

proc updateCoverage(nodeIndex: int, leftIndex: int, rightIndex: int,
                    queryLeft: int, queryRight: int, delta: int) =
  if queryLeft <= leftIndex and rightIndex <= queryRight:
    coverCounts[nodeIndex] += delta
    pullCoverage(nodeIndex, leftIndex, rightIndex)
    return
  let middleIndex = (leftIndex + rightIndex) div 2
  if queryLeft <= middleIndex:
    updateCoverage(nodeIndex * 2, leftIndex, middleIndex, queryLeft, queryRight, delta)
  if queryRight > middleIndex:
    updateCoverage(nodeIndex * 2 + 1, middleIndex + 1, rightIndex, queryLeft, queryRight, delta)
  pullCoverage(nodeIndex, leftIndex, rightIndex)

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let panelCount = nextInt(inputData, scanPos)
let powerPerArea = nextInt(inputData, scanPos)
var events = newSeq[SweepEvent](2 * panelCount)
var yValues = newSeq[int](2 * panelCount)
var eventCount = 0
var yValueCount = 0
for panelIndex in 0 .. panelCount - 1:
  let leftX = nextInt(inputData, scanPos)
  let bottomY = nextInt(inputData, scanPos)
  let rightX = nextInt(inputData, scanPos)
  let topY = nextInt(inputData, scanPos)
  if leftX == rightX or bottomY == topY:
    continue
  events[eventCount] = SweepEvent(eventX: leftX, lowerY: bottomY, upperY: topY, flipDelta: 1)
  eventCount += 1
  events[eventCount] = SweepEvent(eventX: rightX, lowerY: bottomY, upperY: topY, flipDelta: -1)
  eventCount += 1
  yValues[yValueCount] = bottomY
  yValueCount += 1
  yValues[yValueCount] = topY
  yValueCount += 1
events.setLen(eventCount)
yValues.setLen(yValueCount)
yValues.sort(compareIntegers)
var compressedYs = newSeq[int](yValueCount)
var compressedCount = 0
for yIndex in 0 .. yValueCount - 1:
  if yIndex == 0 or yValues[yIndex] != yValues[yIndex - 1]:
    compressedYs[compressedCount] = yValues[yIndex]
    compressedCount += 1
compressedYs.setLen(compressedCount)
yCoordinates = compressedYs
coverCounts = newSeq[int](4 * compressedCount + 5)
coveredLengths = newSeq[int](4 * compressedCount + 5)
var unionArea: int64 = 0
if compressedCount >= 2 and eventCount > 0:
  events.sort(compareEvents)
  var previousX = events[0].eventX
  for eventIndex in 0 .. eventCount - 1:
    let currentEvent = events[eventIndex]
    unionArea = unionArea + int64(coveredLengths[1]) * int64(currentEvent.eventX - previousX)
    previousX = currentEvent.eventX
    let lowerIndex = findYIndex(currentEvent.lowerY)
    let upperIndex = findYIndex(currentEvent.upperY) - 1
    if lowerIndex <= upperIndex:
      updateCoverage(1, 0, compressedCount - 1, lowerIndex, upperIndex, currentEvent.flipDelta)
let totalPower = unionArea * int64(powerPerArea)
appendOutput($totalPower)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
