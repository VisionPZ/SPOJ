import algorithm

const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int64 =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-':
    pos += 1
  var negative = false
  if pos < data.len and data[pos] == '-':
    negative = true
    pos += 1
  var value: int64 = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int64(int(data[pos]) - 48)
    pos += 1
  if negative:
    return -value
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

type
  IndexedPoint = tuple[x: int64, y: int64, originalIndex: int]

proc comparePoints(left: IndexedPoint, right: IndexedPoint): int =
  if left.x < right.x:
    return -1
  if left.x > right.x:
    return 1
  if left.y < right.y:
    return -1
  if left.y > right.y:
    return 1
  return 0

var nodePointX = newSeq[int64]()
var nodePointY = newSeq[int64]()
var nodeOriginal = newSeq[int]()
var leftChild = newSeq[int]()
var rightChild = newSeq[int]()
var boxMinX = newSeq[int64]()
var boxMaxX = newSeq[int64]()
var boxMinY = newSeq[int64]()
var boxMaxY = newSeq[int64]()

proc buildNode(leftBound: int, rightBound: int, points: seq[IndexedPoint]): int =
  if leftBound > rightBound:
    return -1
  let middle = (leftBound + rightBound) div 2
  let nodeIndex = middle
  nodePointX[nodeIndex] = points[middle].x
  nodePointY[nodeIndex] = points[middle].y
  nodeOriginal[nodeIndex] = points[middle].originalIndex
  leftChild[nodeIndex] = buildNode(leftBound, middle - 1, points)
  rightChild[nodeIndex] = buildNode(middle + 1, rightBound, points)
  var lowX = nodePointX[nodeIndex]
  var highX = nodePointX[nodeIndex]
  var lowY = nodePointY[nodeIndex]
  var highY = nodePointY[nodeIndex]
  let nearChild = leftChild[nodeIndex]
  let farChild = rightChild[nodeIndex]
  if nearChild >= 0:
    if boxMinX[nearChild] < lowX: lowX = boxMinX[nearChild]
    if boxMaxX[nearChild] > highX: highX = boxMaxX[nearChild]
    if boxMinY[nearChild] < lowY: lowY = boxMinY[nearChild]
    if boxMaxY[nearChild] > highY: highY = boxMaxY[nearChild]
  if farChild >= 0:
    if boxMinX[farChild] < lowX: lowX = boxMinX[farChild]
    if boxMaxX[farChild] > highX: highX = boxMaxX[farChild]
    if boxMinY[farChild] < lowY: lowY = boxMinY[farChild]
    if boxMaxY[farChild] > highY: highY = boxMaxY[farChild]
  boxMinX[nodeIndex] = lowX
  boxMaxX[nodeIndex] = highX
  boxMinY[nodeIndex] = lowY
  boxMaxY[nodeIndex] = highY
  return nodeIndex

proc boxDistance(queryX: int64, queryY: int64, nodeIndex: int): int64 =
  var deltaX: int64 = 0
  if queryX < boxMinX[nodeIndex]:
    deltaX = boxMinX[nodeIndex] - queryX
  elif queryX > boxMaxX[nodeIndex]:
    deltaX = queryX - boxMaxX[nodeIndex]
  var deltaY: int64 = 0
  if queryY < boxMinY[nodeIndex]:
    deltaY = boxMinY[nodeIndex] - queryY
  elif queryY > boxMaxY[nodeIndex]:
    deltaY = queryY - boxMaxY[nodeIndex]
  return deltaX * deltaX + deltaY * deltaY

proc searchNearest(nodeIndex: int, queryX: int64, queryY: int64,
                   selfIndex: int, bestDistance: var int64,
                   bestPoint: var int) =
  if nodeIndex < 0:
    return
  if boxDistance(queryX, queryY, nodeIndex) >= bestDistance:
    return
  let deltaX = queryX - nodePointX[nodeIndex]
  let deltaY = queryY - nodePointY[nodeIndex]
  let candidateDistance = deltaX * deltaX + deltaY * deltaY
  if nodeOriginal[nodeIndex] != selfIndex and candidateDistance < bestDistance:
    bestDistance = candidateDistance
    bestPoint = nodeOriginal[nodeIndex]
  var nearChild = leftChild[nodeIndex]
  var farChild = rightChild[nodeIndex]
  if queryX >= nodePointX[nodeIndex]:
    nearChild = rightChild[nodeIndex]
    farChild = leftChild[nodeIndex]
  searchNearest(nearChild, queryX, queryY, selfIndex, bestDistance, bestPoint)
  searchNearest(farChild, queryX, queryY, selfIndex, bestDistance, bestPoint)

let testCount = int(nextInt(inputData, scanPos))
for testIndex in 0 .. testCount - 1:
  let pointCount = int(nextInt(inputData, scanPos))
  var pointX = newSeq[int64](pointCount)
  var pointY = newSeq[int64](pointCount)
  var points = newSeq[IndexedPoint](pointCount)
  for pointIndex in 0 .. pointCount - 1:
    let xValue = nextInt(inputData, scanPos)
    let yValue = nextInt(inputData, scanPos)
    pointX[pointIndex] = xValue
    pointY[pointIndex] = yValue
    points[pointIndex] = (x: xValue, y: yValue, originalIndex: pointIndex)
  points.sort(comparePoints)
  nodePointX.setLen pointCount
  nodePointY.setLen pointCount
  nodeOriginal.setLen pointCount
  leftChild.setLen pointCount
  rightChild.setLen pointCount
  boxMinX.setLen pointCount
  boxMaxX.setLen pointCount
  boxMinY.setLen pointCount
  boxMaxY.setLen pointCount
  let rootIndex = buildNode(0, pointCount - 1, points)
  for pointIndex in 0 .. pointCount - 1:
    var bestDistance: int64 = high(int64)
    var bestPoint = -1
    searchNearest(rootIndex, pointX[pointIndex], pointY[pointIndex],
                  pointIndex, bestDistance, bestPoint)
    appendOutput($bestDistance)
    outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
