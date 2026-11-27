const
  maxSamples = 100
  maxPolygonVertices = maxSamples + 8
  flushBlockBytes = 1 shl 18

type
  Point = object
    x: float64
    y: float64

proc nextInt(inputData: string, i: var int): int =
  var value = 0
  while i < inputData.len and (inputData[i] < '0' or inputData[i] > '9'):
    inc i
  while i < inputData.len and inputData[i] >= '0' and inputData[i] <= '9':
    value = value * 10 + (ord(inputData[i]) - 48)
    inc i
  value

proc clipToHalfPlane(sourcePoly: array[maxPolygonVertices, Point], sourceCount: int,
                     destPoly: var array[maxPolygonVertices, Point], coefA: float64,
                     coefB: float64, coefC: float64): int =
  var outCount = 0
  var i = 0
  while i < sourceCount:
    let curPoint = sourcePoly[i]
    let nextPoint = sourcePoly[(i + 1) mod sourceCount]
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
    inc i
  outCount

proc polygonArea(poly: array[maxPolygonVertices, Point], vertexCount: int): float64 =
  if vertexCount < 3:
    return 0.0
  var doubled = 0.0
  var i = 0
  while i < vertexCount:
    let curPoint = poly[i]
    let nextPoint = poly[(i + 1) mod vertexCount]
    doubled += curPoint.x * nextPoint.y - nextPoint.x * curPoint.y
    inc i
  if doubled < 0:
    doubled = -doubled
  doubled * 0.5

proc farthestRadiusSquared(poly: array[maxPolygonVertices, Point], vertexCount: int,
                           siteX: float64, siteY: float64): float64 =
  var biggest = 0.0
  var i = 0
  while i < vertexCount:
    let deltaX = poly[i].x - siteX
    let deltaY = poly[i].y - siteY
    let distanceSquared = deltaX * deltaX + deltaY * deltaY
    if distanceSquared > biggest:
      biggest = distanceSquared
    inc i
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
  var i = digitCount - 1
  while i >= 0:
    outBuf.add digitStore[i]
    dec i
  outBuf.add '.'
  outBuf.add char(48 + int(fracPart div 10))
  outBuf.add char(48 + int(fracPart mod 10))
  outBuf.add '\n'

proc readStreamBytes(): string =
  var res = ""
  var chunk = newString(1 shl 16)
  while true:
    let got = readBuffer(stdin, addr chunk[0], chunk.len)
    if got <= 0:
      break
    let oldLen = res.len
    res.setLen(oldLen + got)
    copyMem(addr res[oldLen], addr chunk[0], got)
  return res

var inputData = readStreamBytes()
var i = 0
var outputBuffer = ""
var siteXs: array[maxSamples, float64]
var siteYs: array[maxSamples, float64]
var areas: array[maxSamples, float64]
var sampleIds: array[maxSamples, int]
var poly: array[maxPolygonVertices, Point]
var nextPoly: array[maxPolygonVertices, Point]

while true:
  let plateWidth = nextInt(inputData, i)
  let plateHeight = nextInt(inputData, i)
  if plateWidth == 0 or plateHeight == 0:
    break
  let sampleCount = nextInt(inputData, i)
  var j = 0
  while j < sampleCount:
    siteXs[j] = float64(nextInt(inputData, i))
    siteYs[j] = float64(nextInt(inputData, i))
    inc j

  j = 0
  while j < sampleCount:
    let currentX = siteXs[j]
    let currentY = siteYs[j]
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
    var k = 0
    while k < sampleCount:
      if k != j and polyCount >= 3:
        let deltaX = siteXs[k] - currentX
        let deltaY = siteYs[k] - currentY
        let distanceSquared = deltaX * deltaX + deltaY * deltaY
        if distanceSquared <= 4.0 * maxRadiusSq:
          let coefA = 2.0 * deltaX
          let coefB = 2.0 * deltaY
          let coefC = siteXs[k] * siteXs[k] +
                      siteYs[k] * siteYs[k] -
                      currentX * currentX - currentY * currentY
          polyCount = clipToHalfPlane(poly, polyCount, nextPoly, coefA, coefB, coefC)
          var l = 0
          while l < polyCount:
            poly[l] = nextPoly[l]
            inc l
          if polyCount >= 3:
            maxRadiusSq = farthestRadiusSquared(poly, polyCount, currentX, currentY)
      inc k
    areas[j] = polygonArea(poly, polyCount)
    sampleIds[j] = j + 1
    inc j

  var k = 1
  while k < sampleCount:
    let heldArea = areas[k]
    let heldId = sampleIds[k]
    var l = k - 1
    while l >= 0 and areas[l] < heldArea:
      areas[l + 1] = areas[l]
      sampleIds[l + 1] = sampleIds[l]
      dec l
    areas[l + 1] = heldArea
    sampleIds[l + 1] = heldId
    inc k

  k = 0
  while k < sampleCount:
    appendResultLine(outputBuffer, sampleIds[k], areas[k])
    inc k
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

if outputBuffer.len > 0:
  stdout.write outputBuffer
