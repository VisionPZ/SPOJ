import algorithm, math, strutils

const flushBlockBytes = 1 shl 18

type
  Point = object
    x: int
    y: int
    idx: int

proc comparePoint(left, right: Point): int =
  if left.x < right.x: return -1
  if left.x > right.x: return 1
  if left.y < right.y: return -1
  if left.y > right.y: return 1
  if left.idx < right.idx: return -1
  if left.idx > right.idx: return 1
  result = 0

proc crossProduct(origin, first, second: Point): int64 =
  result = int64(first.x - origin.x) * int64(second.y - origin.y) -
           int64(first.y - origin.y) * int64(second.x - origin.x)

proc distanceBetween(first, second: Point): float =
  var deltaX = int64(first.x) - int64(second.x)
  var deltaY = int64(first.y) - int64(second.y)
  result = sqrt(float(deltaX * deltaX + deltaY * deltaY))

proc nextInt(inputData: string, scanPos: var int): int =
  var currentChar = ' '
  while scanPos < inputData.len:
    currentChar = inputData[scanPos]
    if (currentChar >= '0' and currentChar <= '9') or currentChar == '-': break
    scanPos += 1
  var sign = 1
  if currentChar == '-':
    sign = -1
    scanPos += 1
  var value = 0
  while scanPos < inputData.len:
    currentChar = inputData[scanPos]
    if currentChar < '0' or currentChar > '9': break
    value = value * 10 + (int(currentChar) - 48)
    scanPos += 1
  result = sign * value

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add(inputLine)
  inputData.add('\n')

var scanPos = 0
var testCount = nextInt(inputData, scanPos)
var outputBuffer = ""

for testIndex in 0 ..< testCount:
  var sheepCount = nextInt(inputData, scanPos)
  var points: seq[Point] = @[]
  points.setLen(sheepCount)
  for pointIndex in 0 ..< sheepCount:
    var pointX = nextInt(inputData, scanPos)
    var pointY = nextInt(inputData, scanPos)
    points[pointIndex] = Point(x: pointX, y: pointY, idx: pointIndex + 1)

  points.sort(comparePoint)

  var uniqueCount = 0
  for pointIndex in 0 ..< sheepCount:
    if pointIndex == 0 or points[pointIndex].x != points[pointIndex - 1].x or
       points[pointIndex].y != points[pointIndex - 1].y:
      points[uniqueCount] = points[pointIndex]
      uniqueCount += 1
  points.setLen(uniqueCount)

  var hull: seq[Point] = @[]
  if uniqueCount == 1:
    hull.setLen(1)
    hull[0] = points[0]
  else:
    var lower: seq[Point] = @[]
    lower.setLen(uniqueCount + 1)
    var lowerSize = 0
    for pointIndex in 0 ..< uniqueCount:
      var currentPoint = points[pointIndex]
      while lowerSize >= 2 and
            crossProduct(lower[lowerSize - 2], lower[lowerSize - 1], currentPoint) <= 0:
        lowerSize -= 1
      lower[lowerSize] = currentPoint
      lowerSize += 1

    var upper: seq[Point] = @[]
    upper.setLen(uniqueCount + 1)
    var upperSize = 0
    for reverseIndex in 0 ..< uniqueCount:
      var currentPoint = points[uniqueCount - 1 - reverseIndex]
      while upperSize >= 2 and
            crossProduct(upper[upperSize - 2], upper[upperSize - 1], currentPoint) <= 0:
        upperSize -= 1
      upper[upperSize] = currentPoint
      upperSize += 1

    hull.setLen(lowerSize + upperSize - 2)
    var hullIndex = 0
    for lowerIndex in 0 ..< (lowerSize - 1):
      hull[hullIndex] = lower[lowerIndex]
      hullIndex += 1
    for upperIndex in 0 ..< (upperSize - 1):
      hull[hullIndex] = upper[upperIndex]
      hullIndex += 1

  var hullSize = hull.len
  var startPos = 0
  for hullIndex in 1 ..< hullSize:
    if hull[hullIndex].y < hull[startPos].y or
       (hull[hullIndex].y == hull[startPos].y and hull[hullIndex].x < hull[startPos].x):
      startPos = hullIndex

  var perimeter = 0.0
  for hullIndex in 0 ..< hullSize:
    var nextHullIndex = (hullIndex + 1) mod hullSize
    perimeter += distanceBetween(hull[hullIndex], hull[nextHullIndex])

  outputBuffer.add(formatFloat(perimeter, ffDecimal, 2))
  outputBuffer.add('\n')
  for step in 0 ..< hullSize:
    var hullIndex = (startPos + step) mod hullSize
    if step > 0: outputBuffer.add(' ')
    outputBuffer.add($hull[hullIndex].idx)
  outputBuffer.add('\n')
  outputBuffer.add('\n')

  if outputBuffer.len >= flushBlockBytes:
    stdout.write(outputBuffer)
    outputBuffer.setLen(0)

if outputBuffer.len > 0:
  stdout.write(outputBuffer)
