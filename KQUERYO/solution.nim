const flushBlockBytes = 1 shl 17
const firstDigitValue = 48
const maxTreeNodes = 700000

import algorithm

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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc compareValues(firstValue: int, secondValue: int): int =
  if firstValue < secondValue:
    return -1
  elif firstValue > secondValue:
    return 1
  return 0

let elementCount = nextInt(inputData, scanPos)
var sequenceValues = newSeq[int](elementCount)
for elementIndex in 0 .. elementCount - 1:
  sequenceValues[elementIndex] = nextInt(inputData, scanPos)

var sortedValues = newSeq[int](elementCount)
for elementIndex in 0 .. elementCount - 1:
  sortedValues[elementIndex] = sequenceValues[elementIndex]
sortedValues.sort(compareValues)

var distinctValues = newSeq[int](elementCount)
var distinctCount = 0
for elementIndex in 0 .. elementCount - 1:
  if elementIndex == 0 or sortedValues[elementIndex] != sortedValues[elementIndex - 1]:
    distinctValues[distinctCount] = sortedValues[elementIndex]
    distinctCount += 1
distinctValues.setLen(distinctCount)

proc compressedIndex(value: int): int =
  var lowIndex = 0
  var highIndex = distinctCount - 1
  while lowIndex <= highIndex:
    let middleIndex = (lowIndex + highIndex) div 2
    if distinctValues[middleIndex] == value:
      return middleIndex + 1
    elif distinctValues[middleIndex] < value:
      lowIndex = middleIndex + 1
    else:
      highIndex = middleIndex - 1
  return -1

proc firstGreaterIndex(value: int): int =
  var lowIndex = 0
  var highIndex = distinctCount
  while lowIndex < highIndex:
    let middleIndex = (lowIndex + highIndex) div 2
    if distinctValues[middleIndex] <= value:
      lowIndex = middleIndex + 1
    else:
      highIndex = middleIndex
  return lowIndex + 1

var leftBranch = newSeq[int](maxTreeNodes)
var rightBranch = newSeq[int](maxTreeNodes)
var nodeTotal = newSeq[int](maxTreeNodes)
var allocatedNodes = 0

proc insertValue(previousNode: int, lowBound: int, highBound: int, targetIndex: int): int =
  allocatedNodes += 1
  let newNode = allocatedNodes
  leftBranch[newNode] = leftBranch[previousNode]
  rightBranch[newNode] = rightBranch[previousNode]
  nodeTotal[newNode] = nodeTotal[previousNode] + 1
  if lowBound < highBound:
    let middleBound = (lowBound + highBound) div 2
    if targetIndex <= middleBound:
      leftBranch[newNode] = insertValue(leftBranch[previousNode], lowBound, middleBound, targetIndex)
    else:
      rightBranch[newNode] = insertValue(rightBranch[previousNode], middleBound + 1, highBound, targetIndex)
  return newNode

var versionRoots = newSeq[int](elementCount + 1)
for elementIndex in 0 .. elementCount - 1:
  let rankIndex = compressedIndex(sequenceValues[elementIndex])
  versionRoots[elementIndex + 1] = insertValue(versionRoots[elementIndex], 1, distinctCount, rankIndex)

proc countFromIndex(rightVersion: int, leftVersion: int, lowBound: int, highBound: int, thresholdIndex: int): int =
  var rightNode = rightVersion
  var leftNode = leftVersion
  var low = lowBound
  var high = highBound
  var countTotal = 0
  while low < high:
    let middleBound = (low + high) div 2
    if thresholdIndex <= middleBound:
      countTotal += nodeTotal[rightBranch[rightNode]] - nodeTotal[rightBranch[leftNode]]
      rightNode = leftBranch[rightNode]
      leftNode = leftBranch[leftNode]
      high = middleBound
    else:
      rightNode = rightBranch[rightNode]
      leftNode = rightBranch[leftNode]
      low = middleBound + 1
  if thresholdIndex <= low:
    countTotal += nodeTotal[rightNode] - nodeTotal[leftNode]
  return countTotal

let queryCount = nextInt(inputData, scanPos)
var lastAnswer = 0
for queryIndex in 0 .. queryCount - 1:
  let rawLeft = nextInt(inputData, scanPos)
  let rawRight = nextInt(inputData, scanPos)
  let rawThreshold = nextInt(inputData, scanPos)
  var queryLeft = rawLeft xor lastAnswer
  var queryRight = rawRight xor lastAnswer
  let queryThreshold = rawThreshold xor lastAnswer
  if queryLeft < 1:
    queryLeft = 1
  if queryRight > elementCount:
    queryRight = elementCount
  if queryLeft > queryRight:
    lastAnswer = 0
    appendOutput("0")
    outputBuffer.add '\n'
    continue
  let thresholdIndex = firstGreaterIndex(queryThreshold)
  if thresholdIndex > distinctCount:
    lastAnswer = 0
    appendOutput("0")
    outputBuffer.add '\n'
    continue
  let answer = countFromIndex(versionRoots[queryRight], versionRoots[queryLeft - 1], 1, distinctCount, thresholdIndex)
  lastAnswer = answer
  appendOutput($(answer))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
