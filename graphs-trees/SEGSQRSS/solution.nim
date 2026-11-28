const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and data[pos] != '-' and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var sign = 1
  if pos < data.len and data[pos] == '-':
    sign = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return sign * value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var initialValues = newSeq[int64](0)
var segmentSum = newSeq[int64](0)
var segmentSquareSum = newSeq[int64](0)
var hasPendingSet = newSeq[bool](0)
var pendingSetValue = newSeq[int64](0)
var pendingAddValue = newSeq[int64](0)

proc applySet(nodeIndex: int, leftBound: int, rightBound: int, setValue: int64) {.inline.} =
  let segmentLength = int64(rightBound - leftBound + 1)
  segmentSum[nodeIndex] = setValue * segmentLength
  segmentSquareSum[nodeIndex] = setValue * setValue * segmentLength
  hasPendingSet[nodeIndex] = true
  pendingSetValue[nodeIndex] = setValue
  pendingAddValue[nodeIndex] = 0

proc applyAdd(nodeIndex: int, leftBound: int, rightBound: int, addValue: int64) {.inline.} =
  let segmentLength = int64(rightBound - leftBound + 1)
  let previousSum = segmentSum[nodeIndex]
  segmentSum[nodeIndex] = previousSum + addValue * segmentLength
  segmentSquareSum[nodeIndex] = segmentSquareSum[nodeIndex] + 2'i64 * addValue * previousSum + addValue * addValue * segmentLength
  if hasPendingSet[nodeIndex]:
    pendingSetValue[nodeIndex] = pendingSetValue[nodeIndex] + addValue
  else:
    pendingAddValue[nodeIndex] = pendingAddValue[nodeIndex] + addValue

proc pushDown(nodeIndex: int, leftBound: int, rightBound: int) {.inline.} =
  if leftBound == rightBound:
    return
  let middleIndex = (leftBound + rightBound) div 2
  let leftChild = nodeIndex * 2
  let rightChild = nodeIndex * 2 + 1
  if hasPendingSet[nodeIndex]:
    applySet(leftChild, leftBound, middleIndex, pendingSetValue[nodeIndex])
    applySet(rightChild, middleIndex + 1, rightBound, pendingSetValue[nodeIndex])
    hasPendingSet[nodeIndex] = false
  if pendingAddValue[nodeIndex] != 0:
    applyAdd(leftChild, leftBound, middleIndex, pendingAddValue[nodeIndex])
    applyAdd(rightChild, middleIndex + 1, rightBound, pendingAddValue[nodeIndex])
    pendingAddValue[nodeIndex] = 0

proc buildTree(nodeIndex: int, leftBound: int, rightBound: int) =
  if leftBound == rightBound:
    let currentValue = initialValues[leftBound]
    segmentSum[nodeIndex] = currentValue
    segmentSquareSum[nodeIndex] = currentValue * currentValue
    return
  let middleIndex = (leftBound + rightBound) div 2
  buildTree(nodeIndex * 2, leftBound, middleIndex)
  buildTree(nodeIndex * 2 + 1, middleIndex + 1, rightBound)
  segmentSum[nodeIndex] = segmentSum[nodeIndex * 2] + segmentSum[nodeIndex * 2 + 1]
  segmentSquareSum[nodeIndex] = segmentSquareSum[nodeIndex * 2] + segmentSquareSum[nodeIndex * 2 + 1]

proc updateRange(nodeIndex: int, leftBound: int, rightBound: int, updateLeft: int, updateRight: int, operationType: int, updateValue: int64) =
  if updateLeft <= leftBound and rightBound <= updateRight:
    if operationType == 0:
      applySet(nodeIndex, leftBound, rightBound, updateValue)
    else:
      applyAdd(nodeIndex, leftBound, rightBound, updateValue)
    return
  if hasPendingSet[nodeIndex] or pendingAddValue[nodeIndex] != 0:
    pushDown(nodeIndex, leftBound, rightBound)
  let middleIndex = (leftBound + rightBound) div 2
  if updateLeft <= middleIndex:
    updateRange(nodeIndex * 2, leftBound, middleIndex, updateLeft, updateRight, operationType, updateValue)
  if updateRight > middleIndex:
    updateRange(nodeIndex * 2 + 1, middleIndex + 1, rightBound, updateLeft, updateRight, operationType, updateValue)
  segmentSum[nodeIndex] = segmentSum[nodeIndex * 2] + segmentSum[nodeIndex * 2 + 1]
  segmentSquareSum[nodeIndex] = segmentSquareSum[nodeIndex * 2] + segmentSquareSum[nodeIndex * 2 + 1]

proc queryRange(nodeIndex: int, leftBound: int, rightBound: int, queryLeft: int, queryRight: int): int64 =
  if queryLeft <= leftBound and rightBound <= queryRight:
    return segmentSquareSum[nodeIndex]
  if hasPendingSet[nodeIndex] or pendingAddValue[nodeIndex] != 0:
    pushDown(nodeIndex, leftBound, rightBound)
  let middleIndex = (leftBound + rightBound) div 2
  var total: int64 = 0
  if queryLeft <= middleIndex:
    total = total + queryRange(nodeIndex * 2, leftBound, middleIndex, queryLeft, queryRight)
  if queryRight > middleIndex:
    total = total + queryRange(nodeIndex * 2 + 1, middleIndex + 1, rightBound, queryLeft, queryRight)
  return total

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let elementCount = nextInt(inputData, scanPos)
  let operationCount = nextInt(inputData, scanPos)
  initialValues = newSeq[int64](elementCount + 1)
  for elementIndex in 1 .. elementCount:
    initialValues[elementIndex] = int64(nextInt(inputData, scanPos))
  let nodeCapacity = 4 * elementCount + 5
  segmentSum = newSeq[int64](nodeCapacity)
  segmentSquareSum = newSeq[int64](nodeCapacity)
  hasPendingSet = newSeq[bool](nodeCapacity)
  pendingSetValue = newSeq[int64](nodeCapacity)
  pendingAddValue = newSeq[int64](nodeCapacity)
  buildTree(1, 1, elementCount)
  appendOutput("Case " & $(caseIndex + 1) & ":\n")
  for operationIndex in 0 .. operationCount - 1:
    let operationType = nextInt(inputData, scanPos)
    let updateLeft = nextInt(inputData, scanPos)
    let updateRight = nextInt(inputData, scanPos)
    if operationType == 2:
      appendOutput($queryRange(1, 1, elementCount, updateLeft, updateRight))
      outputBuffer.add '\n'
    else:
      let updateValue = int64(nextInt(inputData, scanPos))
      updateRange(1, 1, elementCount, updateLeft, updateRight, operationType, updateValue)
stdout.write outputBuffer
outputBuffer.setLen 0
