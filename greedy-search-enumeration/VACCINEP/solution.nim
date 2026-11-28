const flushBlockBytes = 1 shl 17
const meetingRadius = 10

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc lowerBound(values: seq[int], target: int): int =
  var lowIndex = 0
  var highIndex = values.len
  while lowIndex < highIndex:
    let middleIndex = (lowIndex + highIndex) div 2
    if values[middleIndex] < target:
      lowIndex = middleIndex + 1
    else:
      highIndex = middleIndex
  return lowIndex

proc upperBound(values: seq[int], target: int): int =
  var lowIndex = 0
  var highIndex = values.len
  while lowIndex < highIndex:
    let middleIndex = (lowIndex + highIndex) div 2
    if values[middleIndex] <= target:
      lowIndex = middleIndex + 1
    else:
      highIndex = middleIndex
  return lowIndex

proc mergeRanges(keys: seq[int], indexes: var seq[int], buffer: var seq[int], lowIndex, highIndex: int) =
  if lowIndex >= highIndex:
    return
  let middleIndex = (lowIndex + highIndex) div 2
  mergeRanges(keys, indexes, buffer, lowIndex, middleIndex)
  mergeRanges(keys, indexes, buffer, middleIndex + 1, highIndex)
  var leftPos = lowIndex
  var rightPos = middleIndex + 1
  var writePos = lowIndex
  while leftPos <= middleIndex and rightPos <= highIndex:
    if keys[indexes[leftPos]] <= keys[indexes[rightPos]]:
      buffer[writePos] = indexes[leftPos]
      leftPos += 1
    else:
      buffer[writePos] = indexes[rightPos]
      rightPos += 1
    writePos += 1
  while leftPos <= middleIndex:
    buffer[writePos] = indexes[leftPos]
    leftPos += 1
    writePos += 1
  while rightPos <= highIndex:
    buffer[writePos] = indexes[rightPos]
    rightPos += 1
    writePos += 1
  for position in lowIndex .. highIndex:
    indexes[position] = buffer[position]

proc sortIndicesByKey(keys: seq[int]): seq[int] =
  result = newSeq[int](keys.len)
  for index in 0 .. keys.len - 1:
    result[index] = index
  if keys.len > 1:
    var buffer = newSeq[int](keys.len)
    mergeRanges(keys, result, buffer, 0, keys.len - 1)

let townCount = nextInt(inputData, scanPos)
let outbreakCount = nextInt(inputData, scanPos)
var townXs = newSeq[int](townCount + 1)
var townYs = newSeq[int](townCount + 1)
for townIndex in 1 .. townCount:
  townXs[townIndex] = nextInt(inputData, scanPos)
  townYs[townIndex] = nextInt(inputData, scanPos)
var outbreakTowns = newSeq[int](outbreakCount)
for outbreakIndex in 0 .. outbreakCount - 1:
  outbreakTowns[outbreakIndex] = nextInt(inputData, scanPos)

var outbreakYs = newSeq[int](outbreakCount)
for outbreakIndex in 0 .. outbreakCount - 1:
  outbreakYs[outbreakIndex] = townYs[outbreakTowns[outbreakIndex]]
let sortedYIndices = sortIndicesByKey(outbreakYs)
var compressedYs = newSeq[int](outbreakCount)
var compressedCount = 0
for sortPosition in 0 .. outbreakCount - 1:
  let yValue = outbreakYs[sortedYIndices[sortPosition]]
  if compressedCount == 0 or compressedYs[compressedCount - 1] != yValue:
    compressedYs[compressedCount] = yValue
    compressedCount += 1
compressedYs.setLen(compressedCount)

var eventCount = 2 * outbreakCount
var eventXs = newSeq[int](eventCount)
var eventYIndexes = newSeq[int](eventCount)
var eventDeltas = newSeq[int](eventCount)
for outbreakIndex in 0 .. outbreakCount - 1:
  let outbreakTown = outbreakTowns[outbreakIndex]
  let entryIndex = 2 * outbreakIndex
  eventXs[entryIndex] = townXs[outbreakTown] - meetingRadius
  eventDeltas[entryIndex] = 1
  eventXs[entryIndex + 1] = townXs[outbreakTown] + meetingRadius + 1
  eventDeltas[entryIndex + 1] = -1
  let yIndex = lowerBound(compressedYs, townYs[outbreakTown]) + 1
  eventYIndexes[entryIndex] = yIndex
  eventYIndexes[entryIndex + 1] = yIndex
let sortedEventIndices = sortIndicesByKey(eventXs)

var queryKeys = newSeq[int](townCount)
for townIndex in 1 .. townCount:
  queryKeys[townIndex - 1] = townXs[townIndex]
let sortedQueryIndices = sortIndicesByKey(queryKeys)

var fenwickTree = newSeq[int](compressedCount + 1)

proc bitAdd(position: int, delta: int) =
  var current = position
  while current <= compressedCount:
    fenwickTree[current] += delta
    current += current and (-current)

proc bitPrefix(position: int): int =
  var current = position
  var total = 0
  while current > 0:
    total += fenwickTree[current]
    current -= current and (-current)
  return total

var priorities = newSeq[int](townCount + 1)
var eventPosition = 0
for queryPosition in 0 .. townCount - 1:
  let townIndex = sortedQueryIndices[queryPosition] + 1
  let townX = townXs[townIndex]
  while eventPosition < eventCount:
    let eventIndex = sortedEventIndices[eventPosition]
    if eventXs[eventIndex] > townX:
      break
    bitAdd(eventYIndexes[eventIndex], eventDeltas[eventIndex])
    eventPosition += 1
  let lowY = townYs[townIndex] - meetingRadius
  let highY = townYs[townIndex] + meetingRadius
  let leftCount = lowerBound(compressedYs, lowY)
  let rightCount = upperBound(compressedYs, highY)
  priorities[townIndex] = bitPrefix(rightCount) - bitPrefix(leftCount)

var priorityCounts = newSeq[int](outbreakCount + 2)
for townIndex in 1 .. townCount:
  priorityCounts[priorities[townIndex]] += 1
var bucketStarts = newSeq[int](outbreakCount + 2)
for priorityValue in 0 .. outbreakCount:
  bucketStarts[priorityValue + 1] = bucketStarts[priorityValue] + priorityCounts[priorityValue]
var bucketCursors = newSeq[int](outbreakCount + 1)
for priorityValue in 0 .. outbreakCount:
  bucketCursors[priorityValue] = bucketStarts[priorityValue]
var orderedTowns = newSeq[int](townCount)
for townIndex in 1 .. townCount:
  let priorityValue = priorities[townIndex]
  orderedTowns[bucketCursors[priorityValue]] = townIndex
  bucketCursors[priorityValue] += 1

var currentPriority = outbreakCount
var firstTownWritten = true
while currentPriority >= 0:
  var bucketPosition = bucketStarts[currentPriority]
  while bucketPosition < bucketStarts[currentPriority + 1]:
    let townIndex = orderedTowns[bucketPosition]
    if firstTownWritten:
      firstTownWritten = false
    else:
      outputBuffer.add ' '
    appendOutput($townIndex)
    bucketPosition += 1
  currentPriority -= 1
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
