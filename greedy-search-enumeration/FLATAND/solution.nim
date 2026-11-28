import algorithm
import strutils

const flushBlockBytes = 1 shl 17
const scaleFactor = 10000
const areaScale = 100000000.0

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

proc nextScaled(data: string, pos: var int): int64 =
  while pos < data.len and data[pos] != '-' and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var signValue: int64 = 1
  if pos < data.len and data[pos] == '-':
    signValue = -1
    pos += 1
  var wholeValue: int64 = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    wholeValue = wholeValue * 10 + int64(int(data[pos]) - 48)
    pos += 1
  var fractionValue: int64 = 0
  var fractionCount = 0
  if pos < data.len and data[pos] == '.':
    pos += 1
    while fractionCount < 4 and pos < data.len and data[pos] >= '0' and data[pos] <= '9':
      fractionValue = fractionValue * 10 + int64(int(data[pos]) - 48)
      pos += 1
      fractionCount += 1
  while fractionCount < 4:
    fractionValue *= 10
    fractionCount += 1
  return signValue * (wholeValue * int64(scaleFactor) + fractionValue)

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

type
  Point = object
    x: int64
    y: int64

proc pointCompare(firstPoint, secondPoint: Point): int =
  if firstPoint.x < secondPoint.x:
    return -1
  if firstPoint.x > secondPoint.x:
    return 1
  if firstPoint.y < secondPoint.y:
    return -1
  if firstPoint.y > secondPoint.y:
    return 1
  return 0

proc crossProduct(originPoint, firstPoint, secondPoint: Point): int64 =
  return (firstPoint.x - originPoint.x) * (secondPoint.y - originPoint.y) -
         (firstPoint.y - originPoint.y) * (secondPoint.x - originPoint.x)

proc convexHull(points: seq[Point]): seq[Point] =
  var sortedPoints = points
  sort(sortedPoints, pointCompare)
  var lowerHull = newSeq[Point]()
  for pointValue in sortedPoints:
    while lowerHull.len >= 2 and
          crossProduct(lowerHull[lowerHull.len - 2], lowerHull[lowerHull.len - 1],
                       pointValue) <= 0:
      lowerHull.setLen(lowerHull.len - 1)
    lowerHull.add pointValue
  var upperHull = newSeq[Point]()
  var pointIndex = sortedPoints.len - 1
  while pointIndex >= 0:
    let pointValue = sortedPoints[pointIndex]
    while upperHull.len >= 2 and
          crossProduct(upperHull[upperHull.len - 2], upperHull[upperHull.len - 1],
                       pointValue) <= 0:
      upperHull.setLen(upperHull.len - 1)
    upperHull.add pointValue
    pointIndex -= 1
  result = lowerHull
  for upperIndex in 1 .. upperHull.len - 2:
    result.add upperHull[upperIndex]

proc minimumArea(hullPoints: seq[Point]): float =
  let hullSize = hullPoints.len
  if hullSize < 3:
    return 0.0
  var normalVectors = newSeq[Point](hullSize)
  var widths = newSeq[int64](hullSize)
  for edgeIndex in 0 .. hullSize - 1:
    let firstPoint = hullPoints[edgeIndex]
    let secondPoint = hullPoints[(edgeIndex + 1) mod hullSize]
    let normalX = secondPoint.y - firstPoint.y
    let normalY = firstPoint.x - secondPoint.x
    normalVectors[edgeIndex].x = -normalX
    normalVectors[edgeIndex].y = -normalY
    var smallestProjection: int64 = 0
    var largestProjection: int64 = 0
    for vertexIndex in 0 .. hullSize - 1:
      let vertexPoint = hullPoints[vertexIndex]
      let projection = vertexPoint.x * normalVectors[edgeIndex].x +
                       vertexPoint.y * normalVectors[edgeIndex].y
      if vertexIndex == 0:
        smallestProjection = projection
        largestProjection = projection
      elif projection < smallestProjection:
        smallestProjection = projection
      elif projection > largestProjection:
        largestProjection = projection
    widths[edgeIndex] = largestProjection - smallestProjection
  var bestArea = 1e300
  for firstEdge in 0 .. hullSize - 1:
    for secondEdge in firstEdge + 1 .. hullSize - 1:
      let determinant = normalVectors[firstEdge].x * normalVectors[secondEdge].y -
                        normalVectors[firstEdge].y * normalVectors[secondEdge].x
      if determinant == 0:
        continue
      let candidateArea = float(widths[firstEdge]) * float(widths[secondEdge]) /
                          float(abs(determinant)) / areaScale
      if candidateArea < bestArea:
        bestArea = candidateArea
  return bestArea

let swarmCount = nextInt(inputData, scanPos)
for swarmIndex in 1 .. swarmCount:
  let antCount = nextInt(inputData, scanPos)
  var antPoints = newSeq[Point](antCount)
  for antIndex in 0 .. antCount - 1:
    antPoints[antIndex].x = nextScaled(inputData, scanPos)
    antPoints[antIndex].y = nextScaled(inputData, scanPos)
  let hullPoints = convexHull(antPoints)
  let areaText = formatFloat(minimumArea(hullPoints), ffDecimal, 4)
  appendOutput("Swarm " & $swarmIndex & " Parallelogram Area: " & areaText)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
