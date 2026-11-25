const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and data[pos] <= ' ': pos += 1
  var sign = 1
  if pos < data.len and data[pos] == '-':
    sign = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return sign * value

proc rangesOverlap(firstLow, firstHigh, secondLow, secondHigh: int): bool =
  return firstLow <= secondHigh and secondLow <= firstHigh

proc sidesIntersect(edgeX1, edgeY1, edgeX2, edgeY2,
                    sideX1, sideY1, sideX2, sideY2: int): bool =
  var edgeLowX = edgeX1
  var edgeHighX = edgeX2
  if edgeLowX > edgeHighX:
    let swapValue = edgeLowX
    edgeLowX = edgeHighX
    edgeHighX = swapValue
  var edgeLowY = edgeY1
  var edgeHighY = edgeY2
  if edgeLowY > edgeHighY:
    let swapValue = edgeLowY
    edgeLowY = edgeHighY
    edgeHighY = swapValue
  var sideLowX = sideX1
  var sideHighX = sideX2
  if sideLowX > sideHighX:
    let swapValue = sideLowX
    sideLowX = sideHighX
    sideHighX = swapValue
  var sideLowY = sideY1
  var sideHighY = sideY2
  if sideLowY > sideHighY:
    let swapValue = sideLowY
    sideLowY = sideHighY
    sideHighY = swapValue
  if edgeLowX == edgeHighX:
    if sideLowX == sideHighX: return false
    return rangesOverlap(edgeLowY, edgeHighY, sideLowY, sideHighY) and
           edgeLowX >= sideLowX and edgeLowX <= sideHighX
  else:
    if sideLowY == sideHighY: return false
    return rangesOverlap(edgeLowX, edgeHighX, sideLowX, sideHighX) and
           edgeLowY >= sideLowY and edgeLowY <= sideHighY

proc pointInsidePark(queryX, queryY: int, vertexX, vertexY: seq[int],
                     vertexCount: int): bool =
  var inside = false
  for i in 0..<vertexCount:
    let nextIndex = (i + 1) mod vertexCount
    let lowY = 2 * vertexY[i]
    let highY = 2 * vertexY[nextIndex]
    if (lowY > queryY) != (highY > queryY):
      if queryX < 2 * vertexX[i]:
        inside = not inside
  return inside

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

while true:
  let vertexCount = nextInt(inputData, scanPos)
  let plotCount = nextInt(inputData, scanPos)
  if vertexCount == 0 and plotCount == 0: break

  var vertexX = newSeq[int](vertexCount + 1)
  var vertexY = newSeq[int](vertexCount + 1)
  for i in 0..<vertexCount:
    vertexX[i] = nextInt(inputData, scanPos)
    vertexY[i] = nextInt(inputData, scanPos)
  vertexX[vertexCount] = vertexX[0]
  vertexY[vertexCount] = vertexY[0]

  var doubledParkArea: int64 = 0
  var axisAligned = true
  for i in 0..<vertexCount:
    doubledParkArea += int64(vertexX[i + 1] - vertexX[i]) *
                       int64(vertexY[i + 1] + vertexY[i])
    if vertexX[i + 1] != vertexX[i] and vertexY[i + 1] != vertexY[i]:
      axisAligned = false

  var plotAreaTotal: int64 = 0
  for j in 0..<plotCount:
    var firstX = nextInt(inputData, scanPos)
    var firstY = nextInt(inputData, scanPos)
    var secondX = nextInt(inputData, scanPos)
    var secondY = nextInt(inputData, scanPos)
    if firstX > secondX:
      let swapValue = firstX
      firstX = secondX
      secondX = swapValue
    if firstY > secondY:
      let swapValue = firstY
      firstY = secondY
      secondY = swapValue
    if not axisAligned: continue

    var plotInside = true
    for i in 0..<vertexCount:
      let edgeX1 = 2 * vertexX[i]
      let edgeY1 = 2 * vertexY[i]
      let edgeX2 = 2 * vertexX[i + 1]
      let edgeY2 = 2 * vertexY[i + 1]
      if sidesIntersect(edgeX1, edgeY1, edgeX2, edgeY2,
                        2 * firstX + 1, 2 * firstY + 1,
                        2 * secondX - 1, 2 * firstY + 1) or
         sidesIntersect(edgeX1, edgeY1, edgeX2, edgeY2,
                        2 * firstX + 1, 2 * firstY + 1,
                        2 * firstX + 1, 2 * secondY - 1) or
         sidesIntersect(edgeX1, edgeY1, edgeX2, edgeY2,
                        2 * secondX - 1, 2 * secondY - 1,
                        2 * secondX - 1, 2 * firstY + 1) or
         sidesIntersect(edgeX1, edgeY1, edgeX2, edgeY2,
                        2 * secondX - 1, 2 * secondY - 1,
                        2 * firstX + 1, 2 * secondY - 1):
        plotInside = false
        break
    if plotInside:
      plotInside = pointInsidePark(firstX + secondX, firstY + secondY,
                                   vertexX, vertexY, vertexCount)
    if plotInside:
      plotAreaTotal += int64(secondX - firstX) * int64(secondY - firstY)

  if doubledParkArea < 0: doubledParkArea = -doubledParkArea
  if doubledParkArea == 2 * plotAreaTotal and axisAligned:
    appendOutput("YES\n")
  else:
    appendOutput("NO\n")

stdout.write outputBuffer
outputBuffer.setLen 0
