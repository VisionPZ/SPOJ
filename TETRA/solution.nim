import math

const flushBlockBytes = 1 shl 17
const decimalPlaces = 4

proc square(value: float): float =
  return value * value

proc triangleArea(firstEdge, secondEdge, thirdEdge: float): float =
  var halfPerimeter = (firstEdge + secondEdge + thirdEdge) / 2.0
  var areaSquare = halfPerimeter * (halfPerimeter - firstEdge) *
                   (halfPerimeter - secondEdge) * (halfPerimeter - thirdEdge)
  return sqrt(max(0.0, areaSquare))

proc tetraVolume(edgeWX, edgeWY, edgeWZ, edgeXY, edgeXZ, edgeYZ: float): float =
  var squareWX = square(edgeWX)
  var squareWY = square(edgeWY)
  var squareWZ = square(edgeWZ)
  var squareXY = square(edgeXY)
  var squareXZ = square(edgeXZ)
  var squareYZ = square(edgeYZ)
  var termSum = 4.0 * squareWX * squareWY * squareWZ -
    squareWX * square(squareWY + squareWZ - squareYZ) -
    squareWY * square(squareWX + squareWZ - squareXZ) -
    squareWZ * square(squareWX + squareWY - squareXY) +
    (squareWY + squareWZ - squareYZ) * (squareWX + squareWZ - squareXZ) *
    (squareWX + squareWY - squareXY)
  return sqrt(max(0.0, termSum)) / 12.0

proc fixedString(value: float, places: int): string =
  var scale = 1
  for _ in 1 .. places: scale = scale * 10
  var absoluteValue = if value < 0.0: -value else: value
  var rounded = int64(absoluteValue * float(scale) + 0.5)
  var wholePart = rounded div int64(scale)
  var fractionPart = rounded mod int64(scale)
  var fractionText = $fractionPart
  while fractionText.len < places: fractionText = "0" & fractionText
  var result: string
  if value < 0.0 and rounded > 0: result.add "-"
  result.add $wholePart
  result.add "."
  result.add fractionText
  return result

proc nextInt(inputData: string, i: var int): int =
  while i < inputData.len and inputData[i] <= ' ': i = i + 1
  var value = 0
  while i < inputData.len and inputData[i] >= '0' and inputData[i] <= '9':
    value = value * 10 + int(inputData[i]) - 48
    i = i + 1
  return value

var inputData: string
var line: string
while readLine(stdin, line):
  inputData.add line
  inputData.add "\n"
var i = 0
var caseCount = nextInt(inputData, i)
var outputBuffer: string
for _ in 1 .. caseCount:
  var edgeWX = float(nextInt(inputData, i))
  var edgeWY = float(nextInt(inputData, i))
  var edgeWZ = float(nextInt(inputData, i))
  var edgeXY = float(nextInt(inputData, i))
  var edgeXZ = float(nextInt(inputData, i))
  var edgeYZ = float(nextInt(inputData, i))
  var surface = triangleArea(edgeWX, edgeWY, edgeXY) +
                triangleArea(edgeWX, edgeWZ, edgeXZ) +
                triangleArea(edgeWY, edgeWZ, edgeYZ) +
                triangleArea(edgeXY, edgeXZ, edgeYZ)
  var volume = tetraVolume(edgeWX, edgeWY, edgeWZ, edgeXY, edgeXZ, edgeYZ)
  var inradius = if surface > 0.0: 3.0 * volume / surface else: 0.0
  outputBuffer.add fixedString(inradius, decimalPlaces)
  outputBuffer.add "\n"
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
stdout.write outputBuffer
