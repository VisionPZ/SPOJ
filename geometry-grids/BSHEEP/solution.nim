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

proc nextInt(inputData: string, i: var int): int =
  var currentChar = ' '
  while i < inputData.len:
    currentChar = inputData[i]
    if (currentChar >= '0' and currentChar <= '9') or currentChar == '-': break
    i += 1
  var sign = 1
  if currentChar == '-':
    sign = -1
    i += 1
  var value = 0
  while i < inputData.len:
    currentChar = inputData[i]
    if currentChar < '0' or currentChar > '9': break
    value = value * 10 + (int(currentChar) - 48)
    i += 1
  result = sign * value

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add(inputLine)
  inputData.add('\n')

var i = 0
var testCount = nextInt(inputData, i)
var outputBuffer = ""

for j in 0 ..< testCount:
  var sheepCount = nextInt(inputData, i)
  var points: seq[Point] = @[]
  points.setLen(sheepCount)
  for k in 0 ..< sheepCount:
    var pointX = nextInt(inputData, i)
    var pointY = nextInt(inputData, i)
    points[k] = Point(x: pointX, y: pointY, idx: k + 1)

  points.sort(comparePoint)

  var uniqueCount = 0
  for k in 0 ..< sheepCount:
    if k == 0 or points[k].x != points[k - 1].x or
       points[k].y != points[k - 1].y:
      points[uniqueCount] = points[k]
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
    for k in 0 ..< uniqueCount:
      var currentPoint = points[k]
      while lowerSize >= 2 and
            crossProduct(lower[lowerSize - 2], lower[lowerSize - 1], currentPoint) <= 0:
        lowerSize -= 1
      lower[lowerSize] = currentPoint
      lowerSize += 1

    var upper: seq[Point] = @[]
    upper.setLen(uniqueCount + 1)
    var upperSize = 0
    for k in 0 ..< uniqueCount:
      var currentPoint = points[uniqueCount - 1 - k]
      while upperSize >= 2 and
            crossProduct(upper[upperSize - 2], upper[upperSize - 1], currentPoint) <= 0:
        upperSize -= 1
      upper[upperSize] = currentPoint
      upperSize += 1

    hull.setLen(lowerSize + upperSize - 2)
    var l = 0
    for k in 0 ..< (lowerSize - 1):
      hull[l] = lower[k]
      l += 1
    for k in 0 ..< (upperSize - 1):
      hull[l] = upper[k]
      l += 1

  var hullSize = hull.len
  var l = 0
  for k in 1 ..< hullSize:
    if hull[k].y < hull[l].y or
       (hull[k].y == hull[l].y and hull[k].x < hull[l].x):
      l = k

  var perimeter = 0.0
  for k in 0 ..< hullSize:
    var l = (k + 1) mod hullSize
    perimeter += distanceBetween(hull[k], hull[l])

  outputBuffer.add(formatFloat(perimeter, ffDecimal, 2))
  outputBuffer.add('\n')
  for k in 0 ..< hullSize:
    var i = (l + k) mod hullSize
    if k > 0: outputBuffer.add(' ')
    outputBuffer.add($hull[i].idx)
  outputBuffer.add('\n')
  outputBuffer.add('\n')

  if outputBuffer.len >= flushBlockBytes:
    stdout.write(outputBuffer)
    outputBuffer.setLen(0)

if outputBuffer.len > 0:
  stdout.write(outputBuffer)
