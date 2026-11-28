import algorithm

const flushBlockBytes = 1 shl 17

type Point = object
  x: int64
  y: int64

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] != '-' and (data[pos] < '0' or data[pos] > '9')):
    pos += 1
  var signValue = 1
  if pos < data.len and data[pos] == '-':
    signValue = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return signValue * value

proc comparePoints(leftPoint: Point, rightPoint: Point): int =
  if leftPoint.x < rightPoint.x:
    return -1
  if leftPoint.x > rightPoint.x:
    return 1
  if leftPoint.y < rightPoint.y:
    return -1
  if leftPoint.y > rightPoint.y:
    return 1
  return 0

proc crossProduct(originPoint: Point, firstPoint: Point, secondPoint: Point): int64 =
  return (firstPoint.x - originPoint.x) * (secondPoint.y - originPoint.y) - (firstPoint.y - originPoint.y) * (secondPoint.x - originPoint.x)

proc formatArea(doubleArea: int64): string =
  result = $(doubleArea div 2)
  if (doubleArea mod 2) == 0:
    result.add ".00\n"
  else:
    result.add ".50\n"

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while scanPos < inputData.len:
  let pointCount = nextInt(inputData, scanPos)
  if pointCount == -1:
    break
  var sortedPoints = newSeq[Point](pointCount)
  for pointIndex in 0 .. pointCount - 1:
    sortedPoints[pointIndex].x = int64(nextInt(inputData, scanPos))
    sortedPoints[pointIndex].y = int64(nextInt(inputData, scanPos))
  sortedPoints.sort(comparePoints)
  var hullPoints = newSeq[Point](pointCount * 2)
  var hullSize = 0
  for pointIndex in 0 .. pointCount - 1:
    while hullSize >= 2 and crossProduct(hullPoints[hullSize - 2], hullPoints[hullSize - 1], sortedPoints[pointIndex]) <= 0:
      hullSize -= 1
    hullPoints[hullSize] = sortedPoints[pointIndex]
    hullSize += 1
  let lowerSize = hullSize
  for pointIndex in countDown(pointCount - 2, 0):
    while hullSize > lowerSize and crossProduct(hullPoints[hullSize - 2], hullPoints[hullSize - 1], sortedPoints[pointIndex]) <= 0:
      hullSize -= 1
    hullPoints[hullSize] = sortedPoints[pointIndex]
    hullSize += 1
  hullSize -= 1
  var bestDoubleArea: int64 = 0
  if hullSize >= 3:
    var firstIndex = 0
    while firstIndex <= hullSize - 3:
      var secondIndex = firstIndex + 1
      var thirdIndex = firstIndex + 2
      while secondIndex <= hullSize - 2:
        while thirdIndex + 1 <= hullSize - 1 and crossProduct(hullPoints[firstIndex], hullPoints[secondIndex], hullPoints[thirdIndex + 1]) > crossProduct(hullPoints[firstIndex], hullPoints[secondIndex], hullPoints[thirdIndex]):
          thirdIndex += 1
        let areaValue = crossProduct(hullPoints[firstIndex], hullPoints[secondIndex], hullPoints[thirdIndex])
        if areaValue > bestDoubleArea:
          bestDoubleArea = areaValue
        secondIndex += 1
      firstIndex += 1
  appendOutput(formatArea(bestDoubleArea))

stdout.write outputBuffer
outputBuffer.setLen 0
