import math, algorithm

const flushBlockBytes = 1 shl 17
const maxArrayValue = 100000

type Query = object
  left: int
  right: int
  index: int

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

let elementCount = nextInt(inputData, scanPos)
let queryCount = nextInt(inputData, scanPos)
let differenceLimit = nextInt(inputData, scanPos)
var values = newSeq[int](elementCount)
for elementIndex in 0 .. elementCount - 1:
  values[elementIndex] = nextInt(inputData, scanPos)
var queries = newSeq[Query](queryCount)
for queryIndex in 0 .. queryCount - 1:
  queries[queryIndex].left = nextInt(inputData, scanPos) - 1
  queries[queryIndex].right = nextInt(inputData, scanPos) - 1
  queries[queryIndex].index = queryIndex

let blockSize = max(1, elementCount div max(1, int(sqrt(float64(queryCount)))))

proc compareQueries(firstQuery: Query, secondQuery: Query): int =
  let firstBlock = firstQuery.left div blockSize
  let secondBlock = secondQuery.left div blockSize
  if firstBlock != secondBlock:
    if firstBlock < secondBlock:
      return -1
    return 1
  if (firstBlock and 1) == 0:
    if firstQuery.right < secondQuery.right:
      return -1
    if firstQuery.right > secondQuery.right:
      return 1
    return 0
  if firstQuery.right > secondQuery.right:
    return -1
  if firstQuery.right < secondQuery.right:
    return 1
  return 0

queries.sort(compareQueries)

var fenwickTree = newSeq[int32](maxArrayValue + 2)
var currentLeft = 0
var currentRight = -1
var windowCount = 0
var badPairCount: int64 = 0

proc fenwickAdd(value: int, delta: int32) {.inline.} =
  var treeIndex = value
  while treeIndex <= maxArrayValue:
    fenwickTree[treeIndex] += delta
    treeIndex += treeIndex and (-treeIndex)

proc fenwickPrefix(value: int): int {.inline.} =
  var treeIndex = value
  var total = 0
  while treeIndex > 0:
    total += int(fenwickTree[treeIndex])
    treeIndex -= treeIndex and (-treeIndex)
  return total

proc nearbyCount(value: int): int {.inline.} =
  var lowValue = value - differenceLimit + 1
  var highValue = value + differenceLimit - 1
  if lowValue < 1:
    lowValue = 1
  if highValue > maxArrayValue:
    highValue = maxArrayValue
  if lowValue > highValue:
    return 0
  return fenwickPrefix(highValue) - fenwickPrefix(lowValue - 1)

proc addValue(value: int) =
  badPairCount += int64(nearbyCount(value))
  fenwickAdd(value, 1.int32)
  windowCount += 1

proc removeValue(value: int) =
  fenwickAdd(value, -1.int32)
  badPairCount -= int64(nearbyCount(value))
  windowCount -= 1

var answers = newSeq[int64](queryCount)
for queryIndex in 0 .. queryCount - 1:
  let chosenQuery = queries[queryIndex]
  while currentLeft > chosenQuery.left:
    currentLeft -= 1
    addValue(values[currentLeft])
  while currentRight < chosenQuery.right:
    currentRight += 1
    addValue(values[currentRight])
  while currentLeft < chosenQuery.left:
    removeValue(values[currentLeft])
    currentLeft += 1
  while currentRight > chosenQuery.right:
    removeValue(values[currentRight])
    currentRight -= 1
  let totalPairs = int64(windowCount * (windowCount - 1) div 2)
  answers[chosenQuery.index] = totalPairs - badPairCount

for answerIndex in 0 .. queryCount - 1:
  appendOutput($answers[answerIndex])
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
