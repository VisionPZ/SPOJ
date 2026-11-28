{.push checks: off.}
{.push overflowChecks: off.}
{.push rangeChecks: off.}
{.push boundChecks: off.}
{.push stackTrace: off.}

import algorithm

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18

type Point = tuple[x: int, y: int]
type Direction = tuple[x: int, y: int]

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9') and data[position] != '-':
    position += 1
  var sign = 1
  if position < data.len and data[position] == '-':
    sign = -1
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int(data[position]) - firstDigitValue
    position += 1
  return value * sign

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc comparePoints(left, right: Point): int =
  if left.x < right.x: return -1
  if left.x > right.x: return 1
  if left.y < right.y: return -1
  if left.y > right.y: return 1
  return 0

proc findPoint(points: seq[Point], target: Point): int =
  var i = 0
  var j = points.len - 1
  while i <= j:
    let k = (i + j) div 2
    let order = comparePoints(points[k], target)
    if order == 0: return k
    if order < 0: i = k + 1
    else: j = k - 1
  return -1

proc crossAround(origin, first, second: Point): int64 =
  let firstX = int64(first.x - origin.x)
  let firstY = int64(first.y - origin.y)
  let secondX = int64(second.x - origin.x)
  let secondY = int64(second.y - origin.y)
  return firstX * secondY - firstY * secondX

proc crossDirections(left, right: Direction): int64 =
  return int64(left.x) * int64(right.y) - int64(left.y) * int64(right.x)

proc upperHalf(direction: Direction): bool =
  return direction.y > 0 or (direction.y == 0 and direction.x >= 0)

proc compareAngles(left, right: Direction): int =
  let leftUpper = upperHalf(left)
  let rightUpper = upperHalf(right)
  if leftUpper != rightUpper:
    if leftUpper: return -1
    return 1
  let turn = crossDirections(left, right)
  if turn > 0: return -1
  if turn < 0: return 1
  return 0

proc rotateQuarter(direction: Direction): Direction =
  return (-direction.y, direction.x)

proc greatestCommonDivisor(left, right: int): int =
  var first = left
  var second = right
  while second != 0:
    let remainder = first mod second
    first = second
    second = remainder
  return first

proc buildHull(uniquePoints: seq[Point]): seq[Point] =
  if uniquePoints.len <= 2:
    return uniquePoints
  var lower: seq[Point] = @[]
  for point in uniquePoints:
    while lower.len >= 2 and crossAround(lower[lower.len - 2], lower[lower.len - 1], point) <= 0:
      lower.setLen(lower.len - 1)
    lower.add point
  var upper: seq[Point] = @[]
  for i in countdown(uniquePoints.len - 1, 0):
    let point = uniquePoints[i]
    while upper.len >= 2 and crossAround(upper[upper.len - 2], upper[upper.len - 1], point) <= 0:
      upper.setLen(upper.len - 1)
    upper.add point
  result = lower
  result.setLen(lower.len - 1)
  for i in 0 ..< upper.len - 1:
    result.add upper[i]
  return result

proc faceIsGood(target: Direction, normals: seq[Direction], endCounts: seq[int]): bool =
  var i = 0
  var j = normals.len
  while i < j:
    let k = (i + j) div 2
    if compareAngles(normals[k], target) < 0:
      i = k + 1
    else:
      j = k
  if i < normals.len and compareAngles(normals[i], target) == 0:
    return true
  var l = i - 1
  if l < 0:
    l = normals.len - 1
  return endCounts[l] >= 2

let caseCount = nextInt(inputData, scanPos)
for i in 0 ..< caseCount:
  let dabCount = nextInt(inputData, scanPos)
  var dabPoints = newSeq[Point](dabCount)
  for j in 0 ..< dabCount:
    dabPoints[j] = (nextInt(inputData, scanPos), nextInt(inputData, scanPos))
  dabPoints.sort(comparePoints)

  var uniquePoints: seq[Point] = @[]
  var pointCounts: seq[int] = @[]
  for point in dabPoints:
    if uniquePoints.len > 0 and comparePoints(uniquePoints[uniquePoints.len - 1], point) == 0:
      pointCounts[pointCounts.len - 1] += 1
    else:
      uniquePoints.add point
      pointCounts.add 1

  let hull = buildHull(uniquePoints)
  if hull.len < 3:
    appendOutput("0")
    outputBuffer.add '\n'
    continue

  let hullSize = hull.len
  var normals: seq[Direction] = @[]
  var endCounts: seq[int] = @[]
  for k in 0 ..< hullSize:
    let l = (k + 1) mod hullSize
    let deltaX = hull[l].x - hull[k].x
    let deltaY = hull[l].y - hull[k].y
    let divisor = greatestCommonDivisor(abs(deltaX), abs(deltaY))
    normals.add (deltaY div divisor, -(deltaX div divisor))
    endCounts.add pointCounts[findPoint(uniquePoints, hull[l])]

  var order = newSeq[int](hullSize)
  for k in 0 ..< hullSize:
    order[k] = k
  order.sort(proc(left, right: int): int = compareAngles(normals[left], normals[right]))

  var sortedNormals: seq[Direction] = @[]
  var sortedEndCounts: seq[int] = @[]
  for k in order:
    sortedNormals.add normals[k]
    sortedEndCounts.add endCounts[k]

  var candidates: seq[Direction] = @[]
  for normal in sortedNormals:
    var current = normal
    for l in 0 ..< 4:
      candidates.add current
      current = rotateQuarter(current)
  candidates.sort(compareAngles)

  var orientations: seq[Direction] = @[]
  for candidate in candidates:
    if orientations.len == 0 or compareAngles(orientations[orientations.len - 1], candidate) != 0:
      orientations.add candidate

  var validCount = 0
  for orientation in orientations:
    var current = orientation
    var allGood = true
    for l in 0 ..< 4:
      if not faceIsGood(current, sortedNormals, sortedEndCounts):
        allGood = false
        break
      current = rotateQuarter(current)
    if allGood:
      validCount += 1

  appendOutput($(validCount div 4))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
