import algorithm

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const maxEdge = 1000000

type
  Point = object
    coordX: int
    coordY: int
    coordZ: int

proc nextInt(data: string, position: var int): int =
  let dataLength = data.len
  while position < dataLength and (data[position] < '0' or data[position] > '9'):
    position += 1
  var value = 0
  while position < dataLength and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int(data[position]) - firstDigitValue
    position += 1
  return value

var yValues: seq[int]
var treeMax: seq[int64]
var treeArg: seq[int]
var treeLazy: seq[int]

proc applyValue(nodeIndex, rightBound, value: int) =
  treeMax[nodeIndex] = int64(value) * int64(yValues[rightBound])
  treeArg[nodeIndex] = rightBound
  treeLazy[nodeIndex] = value

proc buildTree(nodeIndex, leftBound, rightBound: int) =
  treeLazy[nodeIndex] = -1
  if leftBound == rightBound:
    treeMax[nodeIndex] = int64(maxEdge) * int64(yValues[leftBound])
    treeArg[nodeIndex] = leftBound
    return
  let middle = (leftBound + rightBound) div 2
  buildTree(nodeIndex * 2, leftBound, middle)
  buildTree(nodeIndex * 2 + 1, middle + 1, rightBound)
  if treeMax[nodeIndex * 2 + 1] >= treeMax[nodeIndex * 2]:
    treeMax[nodeIndex] = treeMax[nodeIndex * 2 + 1]
    treeArg[nodeIndex] = treeArg[nodeIndex * 2 + 1]
  else:
    treeMax[nodeIndex] = treeMax[nodeIndex * 2]
    treeArg[nodeIndex] = treeArg[nodeIndex * 2]

proc pushDown(nodeIndex, leftBound, rightBound: int) =
  let pending = treeLazy[nodeIndex]
  if pending != -1:
    let middle = (leftBound + rightBound) div 2
    applyValue(nodeIndex * 2, middle, pending)
    applyValue(nodeIndex * 2 + 1, rightBound, pending)
    treeLazy[nodeIndex] = -1

proc valueAt(nodeIndex, leftBound, rightBound, target: int): int =
  if treeLazy[nodeIndex] != -1:
    return treeLazy[nodeIndex]
  if leftBound == rightBound:
    return int(treeMax[nodeIndex] div int64(yValues[leftBound]))
  let middle = (leftBound + rightBound) div 2
  if target <= middle:
    return valueAt(nodeIndex * 2, leftBound, middle, target)
  return valueAt(nodeIndex * 2 + 1, middle + 1, rightBound, target)

proc assignRange(nodeIndex, leftBound, rightBound, queryLeft, queryRight, value: int) =
  if queryLeft <= leftBound and rightBound <= queryRight:
    applyValue(nodeIndex, rightBound, value)
    return
  pushDown(nodeIndex, leftBound, rightBound)
  let middle = (leftBound + rightBound) div 2
  if queryLeft <= middle:
    assignRange(nodeIndex * 2, leftBound, middle, queryLeft, queryRight, value)
  if queryRight > middle:
    assignRange(nodeIndex * 2 + 1, middle + 1, rightBound, queryLeft, queryRight, value)
  if treeMax[nodeIndex * 2 + 1] >= treeMax[nodeIndex * 2]:
    treeMax[nodeIndex] = treeMax[nodeIndex * 2 + 1]
    treeArg[nodeIndex] = treeArg[nodeIndex * 2 + 1]
  else:
    treeMax[nodeIndex] = treeMax[nodeIndex * 2]
    treeArg[nodeIndex] = treeArg[nodeIndex * 2]

proc insertPoint(pointY, pointZ: int) =
  let lastIndex = yValues.len - 1
  var low = 0
  var high = lastIndex
  while low < high:
    let middle = (low + high) div 2
    if yValues[middle] < pointY:
      low = middle + 1
    else:
      high = middle
  let firstAffected = low + 1
  if firstAffected > lastIndex:
    return
  if valueAt(1, 0, lastIndex, firstAffected) <= pointZ:
    return
  var leftIndex = firstAffected
  var rightIndex = lastIndex
  while leftIndex < rightIndex:
    let middle = (leftIndex + rightIndex + 1) div 2
    if valueAt(1, 0, lastIndex, middle) > pointZ:
      leftIndex = middle
    else:
      rightIndex = middle - 1
  assignRange(1, 0, lastIndex, firstAffected, leftIndex, pointZ)

proc considerEdge(edgeX: int, bestVolume: var int64, answerX, answerY, answerZ: var int) =
  let product = treeMax[1]
  let winningIndex = treeArg[1]
  let winningY = yValues[winningIndex]
  let winningZ = valueAt(1, 0, yValues.len - 1, winningIndex)
  let volume = int64(edgeX) * product
  if volume > bestVolume:
    bestVolume = volume
    answerX = edgeX
    answerY = winningY
    answerZ = winningZ

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var i = 0
let caseCount = nextInt(inputData, i)
var outputBuffer = ""

var caseIndex = 0
while caseIndex < caseCount:
  let pointCount = nextInt(inputData, i)
  var points = newSeq[Point](pointCount)
  for j in 0..<pointCount:
    points[j].coordX = nextInt(inputData, i)
    points[j].coordY = nextInt(inputData, i)
    points[j].coordZ = nextInt(inputData, i)

  points.sort(proc (left, right: Point): int = left.coordX - right.coordX)

  yValues = @[maxEdge]
  for j in 0..<pointCount:
    yValues.add points[j].coordY
  yValues.sort(proc (left, right: int): int = left - right)
  var yCount = 0
  for j in 0..<yValues.len:
    if j == 0 or yValues[j] != yValues[j - 1]:
      yValues[yCount] = yValues[j]
      yCount += 1
  yValues.setLen yCount

  let lastIndex = yValues.len - 1
  treeMax = newSeq[int64](lastIndex * 4 + 9)
  treeArg = newSeq[int](lastIndex * 4 + 9)
  treeLazy = newSeq[int](lastIndex * 4 + 9)
  buildTree(1, 0, lastIndex)

  var bestVolume: int64 = -1
  var answerX = maxEdge
  var answerY = maxEdge
  var answerZ = maxEdge

  var scanIndex = 0
  while scanIndex < pointCount:
    let edgeX = points[scanIndex].coordX
    considerEdge(edgeX, bestVolume, answerX, answerY, answerZ)
    while scanIndex < pointCount and points[scanIndex].coordX == edgeX:
      insertPoint(points[scanIndex].coordY, points[scanIndex].coordZ)
      scanIndex += 1
  considerEdge(maxEdge, bestVolume, answerX, answerY, answerZ)

  outputBuffer.add $(answerX)
  outputBuffer.add ' '
  outputBuffer.add $(answerY)
  outputBuffer.add ' '
  outputBuffer.add $(answerZ)
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
  caseIndex += 1

stdout.write outputBuffer
outputBuffer.setLen 0
