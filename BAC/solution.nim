const
  maxSamples = 100
  maxPolygonVertices = maxSamples + 8
  flushBlockBytes = 1 shl 18

type
  Point = object
    x: float64
    y: float64

proc nextInt(inputData: string, scanPos: var int): int =
  var value = 0
  while scanPos < inputData.len and (inputData[scanPos] < '0' or inputData[scanPos] > '9'):
    inc scanPos
  while scanPos < inputData.len and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    value = value * 10 + (ord(inputData[scanPos]) - 48)
    inc scanPos
  value

proc clipToHalfPlane(sourcePoly: array[maxPolygonVertices, Point], sourceCount: int,
                     destPoly: var array[maxPolygonVertices, Point], coefA: float64,
                     coefB: float64, coefC: float64): int =
  var outCount = 0
  var vertIndex = 0
  while vertIndex < sourceCount:
    let curPoint = sourcePoly[vertIndex]
    let nextPoint = sourcePoly[(vertIndex + 1) mod sourceCount]
    let curSide = coefC - (coefA * curPoint.x + coefB * curPoint.y)
    let nextSide = coefC - (coefA * nextPoint.x + coefB * nextPoint.y)
    if curSide >= 0:
      destPoly[outCount] = curPoint
      inc outCount
    if (curSide >= 0) != (nextSide >= 0):
      let ratio = curSide / (curSide - nextSide)
      destPoly[outCount].x = curPoint.x + ratio * (nextPoint.x - curPoint.x)
      destPoly[outCount].y = curPoint.y + ratio * (nextPoint.y - curPoint.y)
      inc outCount
    inc vertIndex
  outCount

proc polygonArea(poly: array[maxPolygonVertices, Point], vertexCount: int): float64 =
  if vertexCount < 3:
    return 0.0
  var doubled = 0.0
  var vertIndex = 0
  while vertIndex < vertexCount:
    let curPoint = poly[vertIndex]
    let nextPoint = poly[(vertIndex + 1) mod vertexCount]
    doubled += curPoint.x * nextPoint.y - nextPoint.x * curPoint.y
    inc vertIndex
  if doubled < 0:
    doubled = -doubled
  doubled * 0.5

proc farthestRadiusSquared(poly: array[maxPolygonVertices, Point], vertexCount: int,
                           siteX: float64, siteY: float64): float64 =
  var biggest = 0.0
  var vertIndex = 0
  while vertIndex < vertexCount:
    let deltaX = poly[vertIndex].x - siteX
    let deltaY = poly[vertIndex].y - siteY
    let distanceSquared = deltaX * deltaX + deltaY * deltaY
    if distanceSquared > biggest:
      biggest = distanceSquared
    inc vertIndex
  biggest

proc appendResultLine(outBuf: var string, sampleId: int, areaValue: float64) =
  outBuf.add char(48 + sampleId div 100)
  outBuf.add char(48 + (sampleId div 10) mod 10)
  outBuf.add char(48 + sampleId mod 10)
  let scaledArea = areaValue * 100.0
  var hundredths = int64(scaledArea)
  let remainder = scaledArea - float64(hundredths)
  if remainder > 0.5 + 1e-6:
    inc hundredths
  elif remainder >= 0.5 - 1e-6 and (hundredths and 1) == 1:
    inc hundredths
  var wholePart = hundredths div 100
  let fracPart = hundredths mod 100
  var digitStore: array[16, char]
  var digitCount = 0
  if wholePart == 0:
    digitStore[digitCount] = '0'
    inc digitCount
  else:
    while wholePart > 0:
      digitStore[digitCount] = char(48 + int(wholePart mod 10))
      inc digitCount
      wholePart = wholePart div 10
  var padCount = 14 - digitCount - 3
  while padCount > 0:
    outBuf.add ' '
    dec padCount
  var digitIndex = digitCount - 1
  while digitIndex >= 0:
    outBuf.add digitStore[digitIndex]
    dec digitIndex
  outBuf.add '.'
  outBuf.add char(48 + int(fracPart div 10))
  outBuf.add char(48 + int(fracPart mod 10))
  outBuf.add '\n'

var inputData = readAll(stdin)
var scanPos = 0
var outputBuffer = ""
var siteXs: array[maxSamples, float64]
var siteYs: array[maxSamples, float64]
var areas: array[maxSamples, float64]
var sampleIds: array[maxSamples, int]
var poly: array[maxPolygonVertices, Point]
var nextPoly: array[maxPolygonVertices, Point]

while true:
  let plateWidth = nextInt(inputData, scanPos)
  let plateHeight = nextInt(inputData, scanPos)
  if plateWidth == 0 or plateHeight == 0:
    break
  let sampleCount = nextInt(inputData, scanPos)
  var siteIndex = 0
  while siteIndex < sampleCount:
    siteXs[siteIndex] = float64(nextInt(inputData, scanPos))
    siteYs[siteIndex] = float64(nextInt(inputData, scanPos))
    inc siteIndex

  siteIndex = 0
  while siteIndex < sampleCount:
    let currentX = siteXs[siteIndex]
    let currentY = siteYs[siteIndex]
    poly[0].x = 0.0
    poly[0].y = 0.0
    poly[1].x = float64(plateWidth)
    poly[1].y = 0.0
    poly[2].x = float64(plateWidth)
    poly[2].y = float64(plateHeight)
    poly[3].x = 0.0
    poly[3].y = float64(plateHeight)
    var polyCount = 4
    var maxRadiusSq = farthestRadiusSquared(poly, polyCount, currentX, currentY)
    var otherIndex = 0
    while otherIndex < sampleCount:
      if otherIndex != siteIndex and polyCount >= 3:
        let deltaX = siteXs[otherIndex] - currentX
        let deltaY = siteYs[otherIndex] - currentY
        let distanceSquared = deltaX * deltaX + deltaY * deltaY
        if distanceSquared <= 4.0 * maxRadiusSq:
          let coefA = 2.0 * deltaX
          let coefB = 2.0 * deltaY
          let coefC = siteXs[otherIndex] * siteXs[otherIndex] +
                      siteYs[otherIndex] * siteYs[otherIndex] -
                      currentX * currentX - currentY * currentY
          polyCount = clipToHalfPlane(poly, polyCount, nextPoly, coefA, coefB, coefC)
          var copyIndex = 0
          while copyIndex < polyCount:
            poly[copyIndex] = nextPoly[copyIndex]
            inc copyIndex
          if polyCount >= 3:
            maxRadiusSq = farthestRadiusSquared(poly, polyCount, currentX, currentY)
      inc otherIndex
    areas[siteIndex] = polygonArea(poly, polyCount)
    sampleIds[siteIndex] = siteIndex + 1
    inc siteIndex

  var rank = 1
  while rank < sampleCount:
    let heldArea = areas[rank]
    let heldId = sampleIds[rank]
    var prev = rank - 1
    while prev >= 0 and areas[prev] < heldArea:
      areas[prev + 1] = areas[prev]
      sampleIds[prev + 1] = sampleIds[prev]
      dec prev
    areas[prev + 1] = heldArea
    sampleIds[prev + 1] = heldId
    inc rank

  rank = 0
  while rank < sampleCount:
    appendResultLine(outputBuffer, sampleIds[rank], areas[rank])
    inc rank
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

if outputBuffer.len > 0:
  stdout.write outputBuffer
