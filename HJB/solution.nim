import algorithm

const flushBlockBytes = 1 shl 17
const answerMod = 1000000007
const halfMod = 500000004

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

proc positiveMod(value: int64): int =
  var remainder = value mod answerMod
  if remainder < 0:
    remainder += answerMod
  return int(remainder)

proc compareValues(left: int, right: int): int =
  if left < right:
    return -1
  if left > right:
    return 1
  return 0

proc lowerValue(values: seq[int], target: int): int =
  var low = 0
  var high = values.len
  while low < high:
    let middle = (low + high) div 2
    if values[middle] < target:
      low = middle + 1
    else:
      high = middle
  return low

type LeftEvent = object
  valueRank: int
  deltaSlope: int
  deltaConstant: int
  nextEvent: int

type RightEvent = object
  valueRank: int
  groupCount: int
  sign: int
  nextEvent: int

proc addLeftEvent(eventList: var seq[LeftEvent], headList: var seq[int],
                  eventTime: int, valueRank: int, deltaSlope: int,
                  deltaConstant: int) =
  var newEvent: LeftEvent
  newEvent.valueRank = valueRank
  newEvent.deltaSlope = deltaSlope
  newEvent.deltaConstant = deltaConstant
  newEvent.nextEvent = headList[eventTime]
  eventList.add newEvent
  headList[eventTime] = eventList.len - 1

proc addRightEvent(eventList: var seq[RightEvent], headList: var seq[int],
                   eventTime: int, valueRank: int, groupCount: int, sign: int) =
  var newEvent: RightEvent
  newEvent.valueRank = valueRank
  newEvent.groupCount = groupCount
  newEvent.sign = sign
  newEvent.nextEvent = headList[eventTime]
  eventList.add newEvent
  headList[eventTime] = eventList.len - 1

let elementCount = nextInt(inputData, scanPos)
var values = newSeq[int](elementCount)
var sortedValues = newSeq[int](elementCount)
for elementIndex in 0 .. elementCount - 1:
  values[elementIndex] = nextInt(inputData, scanPos)
  sortedValues[elementIndex] = values[elementIndex]

sortedValues.sort(compareValues)
var uniqueCount = 0
for elementIndex in 0 .. elementCount - 1:
  if elementIndex == 0 or sortedValues[elementIndex] != sortedValues[elementIndex - 1]:
    sortedValues[uniqueCount] = sortedValues[elementIndex]
    uniqueCount += 1
sortedValues.setLen(uniqueCount)

var ranks = newSeq[int](elementCount)
for elementIndex in 0 .. elementCount - 1:
  ranks[elementIndex] = lowerValue(sortedValues, values[elementIndex]) + 1

var leftHead = newSeq[int](elementCount + 4)
var rightHead = newSeq[int](elementCount + 4)
for index in 0 .. elementCount + 3:
  leftHead[index] = -1
  rightHead[index] = -1
var leftEvents = newSeq[LeftEvent](0)
var rightEvents = newSeq[RightEvent](0)

var stackValues = newSeq[int](elementCount)
var stackCounts = newSeq[int](elementCount)
var stackStarts = newSeq[int](elementCount)
var stackTop = 0
for boundary in 0 .. elementCount - 1:
  let currentRank = ranks[boundary]
  var groupCount = 1
  while stackTop > 0 and stackValues[stackTop - 1] > currentRank:
    stackTop -= 1
    let oldRank = stackValues[stackTop]
    let oldCount = stackCounts[stackTop]
    let firstBoundary = stackStarts[stackTop]
    let lastBoundary = boundary - 1
    addLeftEvent(leftEvents, leftHead, firstBoundary + 2, oldRank, oldCount,
                 -oldCount * (firstBoundary + 1))
    addLeftEvent(leftEvents, leftHead, lastBoundary + 2, oldRank, -oldCount,
                 oldCount * (lastBoundary + 2))
    groupCount += oldCount
  stackValues[stackTop] = currentRank
  stackCounts[stackTop] = groupCount
  stackStarts[stackTop] = boundary
  stackTop += 1
while stackTop > 0:
  stackTop -= 1
  let lastBoundary = elementCount - 1
  let firstBoundary = stackStarts[stackTop]
  addLeftEvent(leftEvents, leftHead, firstBoundary + 2, stackValues[stackTop],
               stackCounts[stackTop], -stackCounts[stackTop] * (firstBoundary + 1))
  addLeftEvent(leftEvents, leftHead, lastBoundary + 2, stackValues[stackTop],
               -stackCounts[stackTop], stackCounts[stackTop] * (lastBoundary + 2))

var rightValues = newSeq[int](elementCount)
var rightCounts = newSeq[int](elementCount)
var rightStarts = newSeq[int](elementCount)
var rightTop = 0
for position in countdown(elementCount - 1, 0):
  let currentRank = ranks[position]
  var groupCount = 1
  while rightTop > 0 and rightValues[rightTop - 1] > currentRank:
    rightTop -= 1
    let oldRank = rightValues[rightTop]
    let oldCount = rightCounts[rightTop]
    let creationIndex = rightStarts[rightTop]
    let firstStart = position + 2
    let lastStart = creationIndex + 1
    if firstStart - 1 >= 1:
      addRightEvent(rightEvents, rightHead, firstStart - 1, oldRank, oldCount, -1)
    addRightEvent(rightEvents, rightHead, lastStart, oldRank, oldCount, 1)
    groupCount += oldCount
  rightValues[rightTop] = currentRank
  rightCounts[rightTop] = groupCount
  rightStarts[rightTop] = position
  rightTop += 1
while rightTop > 0:
  rightTop -= 1
  addRightEvent(rightEvents, rightHead, rightStarts[rightTop] + 1,
                rightValues[rightTop], rightCounts[rightTop], 1)

let treeSize = uniqueCount + 3
var slopeTree = newSeq[int64](treeSize + 2)
var linearTree = newSeq[int64](treeSize + 2)
var constantTree = newSeq[int64](treeSize + 2)

proc treeAdd(tree: var seq[int64], index: int, delta: int) =
  var cursor = index
  while cursor < tree.len:
    tree[cursor] = (tree[cursor] + int64(delta)) mod answerMod
    if tree[cursor] < 0:
      tree[cursor] += answerMod
    cursor += cursor and -cursor

proc treePrefix(tree: seq[int64], index: int): int64 =
  var total: int64 = 0
  var cursor = index
  while cursor > 0:
    total += tree[cursor]
    if total >= answerMod:
      total -= answerMod
    cursor -= cursor and -cursor
  return total

proc updatePolynomial(valueRank: int, deltaSlope: int, deltaConstant: int,
                      eventTime: int) =
  treeAdd(slopeTree, valueRank, positiveMod(int64(deltaSlope)))
  treeAdd(linearTree, valueRank,
          positiveMod(int64(deltaSlope) + 2 * int64(deltaConstant)))
  treeAdd(constantTree, valueRank,
          positiveMod(-int64(deltaSlope) * int64(eventTime * eventTime - eventTime) +
                      2 * int64(deltaConstant) * int64(1 - eventTime)))

proc doubledPrefixSum(valueRank: int, timeValue: int): int64 =
  let slope = treePrefix(slopeTree, valueRank)
  let linear = treePrefix(linearTree, valueRank)
  let constant = treePrefix(constantTree, valueRank)
  let timeSquare = int64(timeValue) * int64(timeValue)
  return (slope * timeSquare + linear * int64(timeValue) + constant) mod answerMod

var goodness: int64 = 0
for boundary in 1 .. elementCount:
  var leftCursor = leftHead[boundary]
  while leftCursor != -1:
    let currentEvent = leftEvents[leftCursor]
    updatePolynomial(currentEvent.valueRank, currentEvent.deltaSlope,
                     currentEvent.deltaConstant, boundary)
    leftCursor = currentEvent.nextEvent
  var rightCursor = rightHead[boundary]
  while rightCursor != -1:
    let currentEvent = rightEvents[rightCursor]
    let prefixTotal = doubledPrefixSum(currentEvent.valueRank, boundary)
    let contribution = int64(currentEvent.groupCount) * int64(currentEvent.sign) *
                       halfMod mod answerMod * prefixTotal mod answerMod
    goodness = (goodness + contribution) mod answerMod
    if goodness < 0:
      goodness += answerMod
    rightCursor = currentEvent.nextEvent

appendOutput($goodness)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
