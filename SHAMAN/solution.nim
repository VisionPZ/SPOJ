import algorithm

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18

type
  Point = object
    x: int64
    y: int64

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and data[pos] != '-' and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var negative = false
  if pos < data.len and data[pos] == '-':
    negative = true
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  if negative:
    return -value
  return value

proc comparePoint(left, right: Point): int =
  if left.x < right.x: return -1
  if left.x > right.x: return 1
  if left.y < right.y: return -1
  if left.y > right.y: return 1
  return 0

proc crossAt(origin, first, second: Point): int64 =
  let deltaX = first.x - origin.x
  let deltaY = first.y - origin.y
  let spanX = second.x - origin.x
  let spanY = second.y - origin.y
  return deltaX * spanY - deltaY * spanX

proc convexHull(points: var seq[Point]): seq[Point] =
  points.sort(comparePoint)
  var uniquePoints: seq[Point] = @[]
  for i in 0..<points.len:
    if i == 0 or points[i].x != points[i - 1].x or points[i].y != points[i - 1].y:
      uniquePoints.add points[i]
  if uniquePoints.len <= 1:
    return uniquePoints
  var lower: seq[Point] = @[]
  for i in 0..<uniquePoints.len:
    let current = uniquePoints[i]
    while lower.len >= 2 and crossAt(lower[lower.len - 2], lower[lower.len - 1], current) <= 0:
      lower.setLen(lower.len - 1)
    lower.add current
  var upper: seq[Point] = @[]
  var j = uniquePoints.len - 1
  while j >= 0:
    let current = uniquePoints[j]
    while upper.len >= 2 and crossAt(upper[upper.len - 2], upper[upper.len - 1], current) <= 0:
      upper.setLen(upper.len - 1)
    upper.add current
    j -= 1
  result = @[]
  for i in 0..<lower.len - 1:
    result.add lower[i]
  for i in 0..<upper.len - 1:
    result.add upper[i]

proc quadArea2(hull: seq[Point], leftIndex, lowerIndex, rightIndex, upperIndex: int): int64 =
  let diagonalX = hull[rightIndex].x - hull[leftIndex].x
  let diagonalY = hull[rightIndex].y - hull[leftIndex].y
  let spreadX = hull[upperIndex].x - hull[lowerIndex].x
  let spreadY = hull[upperIndex].y - hull[lowerIndex].y
  let value = diagonalX * spreadY - diagonalY * spreadX
  if value < 0:
    return -value
  return value

proc maxQuadArea2(hull: seq[Point]): int64 =
  let hullSize = hull.len
  var lowest = hull[0].y
  var highest = hull[0].y
  for i in 1..<hullSize:
    if hull[i].y < lowest: lowest = hull[i].y
    if hull[i].y > highest: highest = hull[i].y
  var firstIndex = -1
  var lastIndex = -1
  for i in 0..<hullSize:
    if hull[i].y == lowest:
      if firstIndex < 0 or hull[i].x < hull[firstIndex].x: firstIndex = i
    if hull[i].y == highest:
      if lastIndex < 0 or hull[i].x > hull[lastIndex].x: lastIndex = i
  var leftIndex = firstIndex
  var lowerIndex = firstIndex
  var rightIndex = lastIndex
  var upperIndex = lastIndex
  var best = 0.int64
  var steps = 0
  while true:
    while true:
      let nextLower = (lowerIndex + 1) mod hullSize
      if crossAt(hull[rightIndex], hull[leftIndex], hull[nextLower]) >
         crossAt(hull[rightIndex], hull[leftIndex], hull[lowerIndex]):
        lowerIndex = nextLower
      else:
        break
    while true:
      let nextUpper = (upperIndex + 1) mod hullSize
      if crossAt(hull[leftIndex], hull[rightIndex], hull[nextUpper]) >
         crossAt(hull[leftIndex], hull[rightIndex], hull[upperIndex]):
        upperIndex = nextUpper
      else:
        break
    let current = quadArea2(hull, leftIndex, lowerIndex, rightIndex, upperIndex)
    if current > best: best = current
    let nextLeft = (leftIndex + 1) mod hullSize
    let nextRight = (rightIndex + 1) mod hullSize
    if crossAt(hull[leftIndex], hull[nextLeft], hull[nextRight]) <=
       crossAt(hull[leftIndex], hull[nextLeft], hull[rightIndex]):
      leftIndex = nextLeft
    else:
      rightIndex = nextRight
    steps += 1
    if steps > hullSize + 2: break
    if leftIndex == lastIndex and rightIndex == firstIndex: break
  return best

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
var outputBuffer = ""

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let peakCount = nextInt(inputData, scanPos)
  var points: seq[Point] = @[]
  for i in 0..<peakCount:
    let peakX = nextInt(inputData, scanPos)
    let peakY = nextInt(inputData, scanPos)
    points.add Point(x: peakX.int64, y: peakY.int64)
  var hull = convexHull(points)
  let hullSize = hull.len
  var area2 = 0.int64
  if hullSize == 3:
    area2 = crossAt(hull[0], hull[1], hull[2])
    if area2 < 0: area2 = -area2
  elif hullSize > 3:
    area2 = maxQuadArea2(hull)
  let wholePart = area2 div 2
  let digitPart = if area2 mod 2 == 0: '0' else: '5'
  outputBuffer.add $(wholePart)
  outputBuffer.add '.'
  outputBuffer.add digitPart
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

stdout.write outputBuffer
outputBuffer.setLen 0
