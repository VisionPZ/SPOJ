const flushBlockBytes = 1 shl 17

type GridPoint = tuple[x: int, y: int]

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-':
    pos += 1
  var negativeValue = false
  if pos < data.len and data[pos] == '-':
    negativeValue = true
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  if negativeValue:
    return -value
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc turnValue(first: GridPoint, second: GridPoint, third: GridPoint): int64 =
  return int64(second.x - first.x) * int64(third.y - first.y) -
         int64(second.y - first.y) * int64(third.x - first.x)

proc squaredDistance(first: GridPoint, second: GridPoint): int64 =
  let deltaX = int64(second.x - first.x)
  let deltaY = int64(second.y - first.y)
  return deltaX * deltaX + deltaY * deltaY

proc blocksView(observer: GridPoint, first: GridPoint, second: GridPoint,
                radiusSquared: int64): bool =
  let deltaX = int64(second.x - first.x)
  let deltaY = int64(second.y - first.y)
  let lengthSquared = deltaX * deltaX + deltaY * deltaY
  if lengthSquared == 0:
    return true
  let observerX = int64(observer.x - first.x)
  let observerY = int64(observer.y - first.y)
  let projection = observerX * deltaX + observerY * deltaY
  if projection <= 0:
    return squaredDistance(observer, first) < radiusSquared
  if projection >= lengthSquared:
    return squaredDistance(observer, second) < radiusSquared
  let crossProduct = deltaX * observerY - deltaY * observerX
  return crossProduct * crossProduct < radiusSquared * lengthSquared

proc appendArea(hundredths: int64) =
  appendOutput($int(hundredths div 100))
  appendOutput(".")
  let fractionPart = hundredths mod 100
  if fractionPart < 10:
    appendOutput("0")
  appendOutput($fractionPart)
  outputBuffer.add '\n'

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let antennaCount = nextInt(inputData, scanPos)
  let radius = nextInt(inputData, scanPos)
  var antennaPoints = newSeq[GridPoint](antennaCount)
  antennaPoints[0] = (x: 0, y: 0)
  for antennaIndex in 1 .. antennaCount - 1:
    let pointX = nextInt(inputData, scanPos)
    let pointY = nextInt(inputData, scanPos)
    antennaPoints[antennaIndex] = (x: pointX, y: pointY)
  let radiusSquared = int64(radius) * int64(radius)
  var visibilityFails = false
  for firstAntenna in 0 .. antennaCount - 1:
    for secondAntenna in firstAntenna + 1 .. antennaCount - 1:
      for thirdAntenna in 0 .. antennaCount - 1:
        if thirdAntenna == firstAntenna or thirdAntenna == secondAntenna:
          continue
        if blocksView(antennaPoints[thirdAntenna], antennaPoints[firstAntenna],
                      antennaPoints[secondAntenna], radiusSquared):
          visibilityFails = true
          break
      if visibilityFails:
        break
    if visibilityFails:
      break
  if visibilityFails:
    appendOutput("NO CONTEST")
    outputBuffer.add '\n'
    continue
  for outerIndex in 1 .. antennaCount - 1:
    let heldPoint = antennaPoints[outerIndex]
    var innerIndex = outerIndex
    while innerIndex > 0:
      let previousPoint = antennaPoints[innerIndex - 1]
      if previousPoint.x < heldPoint.x or
         (previousPoint.x == heldPoint.x and previousPoint.y < heldPoint.y):
        break
      antennaPoints[innerIndex] = previousPoint
      innerIndex -= 1
    antennaPoints[innerIndex] = heldPoint
  var lowerHull = newSeq[GridPoint]()
  for pointIndex in 0 .. antennaCount - 1:
    let currentPoint = antennaPoints[pointIndex]
    while lowerHull.len >= 2:
      let secondLast = lowerHull[lowerHull.len - 2]
      let lastPoint = lowerHull[lowerHull.len - 1]
      if turnValue(secondLast, lastPoint, currentPoint) > 0:
        break
      lowerHull.setLen(lowerHull.len - 1)
    lowerHull.add currentPoint
  var upperHull = newSeq[GridPoint]()
  for pointIndex in countdown(antennaCount - 1, 0):
    let currentPoint = antennaPoints[pointIndex]
    while upperHull.len >= 2:
      let secondLast = upperHull[upperHull.len - 2]
      let lastPoint = upperHull[upperHull.len - 1]
      if turnValue(secondLast, lastPoint, currentPoint) > 0:
        break
      upperHull.setLen(upperHull.len - 1)
    upperHull.add currentPoint
  lowerHull.setLen(lowerHull.len - 1)
  upperHull.setLen(upperHull.len - 1)
  lowerHull.add upperHull
  var doubledArea: int64 = 0
  for hullIndex in 0 .. lowerHull.len - 1:
    let currentPoint = lowerHull[hullIndex]
    let nextPoint = lowerHull[(hullIndex + 1) mod lowerHull.len]
    doubledArea += int64(currentPoint.x) * int64(nextPoint.y) -
                   int64(nextPoint.x) * int64(currentPoint.y)
  if doubledArea < 0:
    doubledArea = -doubledArea
  appendArea(doubledArea * 50)
stdout.write outputBuffer
outputBuffer.setLen 0
