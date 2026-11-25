const flushBlockBytes = 1 shl 17
const infiniteDistance = 2000000000

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

let pointCount = nextInt(inputData, scanPos)
var xCoordinates = newSeq[int](pointCount)
var yCoordinates = newSeq[int](pointCount)
for pointIndex in 0 .. pointCount - 1:
  xCoordinates[pointIndex] = nextInt(inputData, scanPos)
  yCoordinates[pointIndex] = nextInt(inputData, scanPos)

proc coordinateOf(pointIndex: int, axis: int): int =
  if axis == 0:
    return xCoordinates[pointIndex]
  return yCoordinates[pointIndex]

var workingOrder = newSeq[int](pointCount)
for pointIndex in 0 .. pointCount - 1:
  workingOrder[pointIndex] = pointIndex

proc chooseMedian(lowIndex: int, highIndex: int, axis: int): int =
  let targetIndex = lowIndex + (highIndex - lowIndex) div 2
  var leftIndex = lowIndex
  var rightIndex = highIndex - 1
  while true:
    let pivotIndex = workingOrder[(leftIndex + rightIndex) div 2]
    let pivotValue = coordinateOf(pivotIndex, axis)
    var lessEnd = leftIndex
    var greaterStart = rightIndex
    var scanIndex = leftIndex
    while scanIndex <= greaterStart:
      let currentIndex = workingOrder[scanIndex]
      let currentValue = coordinateOf(currentIndex, axis)
      if currentValue < pivotValue or (currentValue == pivotValue and currentIndex < pivotIndex):
        swap workingOrder[scanIndex], workingOrder[lessEnd]
        lessEnd += 1
        scanIndex += 1
      elif currentValue > pivotValue or (currentValue == pivotValue and currentIndex > pivotIndex):
        swap workingOrder[scanIndex], workingOrder[greaterStart]
        greaterStart -= 1
      else:
        scanIndex += 1
    if targetIndex < lessEnd:
      rightIndex = lessEnd - 1
    elif targetIndex > greaterStart:
      leftIndex = greaterStart + 1
    else:
      return workingOrder[targetIndex]

var kdPoint = newSeq[int](pointCount + 1)
var kdAxis = newSeq[int](pointCount + 1)
var kdLeftChild = newSeq[int](pointCount + 1)
var kdRightChild = newSeq[int](pointCount + 1)
var nodeCount = 0

proc buildTree(lowIndex: int, highIndex: int, depth: int): int =
  if lowIndex >= highIndex:
    return 0
  let axis = depth mod 2
  let middleIndex = lowIndex + (highIndex - lowIndex) div 2
  let medianPoint = chooseMedian(lowIndex, highIndex, axis)
  nodeCount += 1
  let nodeIndex = nodeCount
  kdPoint[nodeIndex] = medianPoint
  kdAxis[nodeIndex] = axis
  kdLeftChild[nodeIndex] = buildTree(lowIndex, middleIndex, depth + 1)
  kdRightChild[nodeIndex] = buildTree(middleIndex + 1, highIndex, depth + 1)
  return nodeIndex

let treeRoot = buildTree(0, pointCount, 0)
var boxMinX = newSeq[int](pointCount + 1)
var boxMaxX = newSeq[int](pointCount + 1)
var boxMinY = newSeq[int](pointCount + 1)
var boxMaxY = newSeq[int](pointCount + 1)

proc computeBounds(nodeIndex: int) =
  if nodeIndex == 0:
    return
  let pointIndex = kdPoint[nodeIndex]
  var minimumX = xCoordinates[pointIndex]
  var maximumX = xCoordinates[pointIndex]
  var minimumY = yCoordinates[pointIndex]
  var maximumY = yCoordinates[pointIndex]
  let leftChild = kdLeftChild[nodeIndex]
  let rightChild = kdRightChild[nodeIndex]
  computeBounds(leftChild)
  if leftChild != 0:
    if boxMinX[leftChild] < minimumX:
      minimumX = boxMinX[leftChild]
    if boxMaxX[leftChild] > maximumX:
      maximumX = boxMaxX[leftChild]
    if boxMinY[leftChild] < minimumY:
      minimumY = boxMinY[leftChild]
    if boxMaxY[leftChild] > maximumY:
      maximumY = boxMaxY[leftChild]
  computeBounds(rightChild)
  if rightChild != 0:
    if boxMinX[rightChild] < minimumX:
      minimumX = boxMinX[rightChild]
    if boxMaxX[rightChild] > maximumX:
      maximumX = boxMaxX[rightChild]
    if boxMinY[rightChild] < minimumY:
      minimumY = boxMinY[rightChild]
    if boxMaxY[rightChild] > maximumY:
      maximumY = boxMaxY[rightChild]
  boxMinX[nodeIndex] = minimumX
  boxMaxX[nodeIndex] = maximumX
  boxMinY[nodeIndex] = minimumY
  boxMaxY[nodeIndex] = maximumY

computeBounds(treeRoot)

proc searchTree(nodeIndex: int, queryPoint: int, bestDistance: var int, bestPoint: var int) =
  if nodeIndex == 0:
    return
  let candidatePoint = kdPoint[nodeIndex]
  if candidatePoint != queryPoint:
    let distanceValue = abs(xCoordinates[candidatePoint] - xCoordinates[queryPoint]) +
                        abs(yCoordinates[candidatePoint] - yCoordinates[queryPoint])
    if distanceValue < bestDistance:
      bestDistance = distanceValue
      bestPoint = candidatePoint
  let axis = kdAxis[nodeIndex]
  var nearChild = kdLeftChild[nodeIndex]
  var farChild = kdRightChild[nodeIndex]
  if coordinateOf(queryPoint, axis) >= coordinateOf(candidatePoint, axis):
    nearChild = kdRightChild[nodeIndex]
    farChild = kdLeftChild[nodeIndex]
  searchTree(nearChild, queryPoint, bestDistance, bestPoint)
  if farChild != 0:
    var gapX = 0
    if xCoordinates[queryPoint] < boxMinX[farChild]:
      gapX = boxMinX[farChild] - xCoordinates[queryPoint]
    elif xCoordinates[queryPoint] > boxMaxX[farChild]:
      gapX = xCoordinates[queryPoint] - boxMaxX[farChild]
    var gapY = 0
    if yCoordinates[queryPoint] < boxMinY[farChild]:
      gapY = boxMinY[farChild] - yCoordinates[queryPoint]
    elif yCoordinates[queryPoint] > boxMaxY[farChild]:
      gapY = yCoordinates[queryPoint] - boxMaxY[farChild]
    if gapX + gapY < bestDistance:
      searchTree(farChild, queryPoint, bestDistance, bestPoint)

for pointIndex in 0 .. pointCount - 1:
  var bestDistance = infiniteDistance
  var bestPoint = -1
  searchTree(treeRoot, pointIndex, bestDistance, bestPoint)
  if bestPoint == -1:
    bestDistance = 0
  appendOutput($bestDistance)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
