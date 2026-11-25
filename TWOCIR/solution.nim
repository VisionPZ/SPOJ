import math

const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and data[pos] != '-' and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var negative = false
  if pos < data.len and data[pos] == '-':
    negative = true
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  if negative:
    return -value
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

type Vec3 = object
  x: float64
  y: float64
  z: float64

type CircleData = object
  center: Vec3
  radius: float64
  normal: Vec3

proc vecAdd(left: Vec3, right: Vec3): Vec3 =
  return Vec3(x: left.x + right.x, y: left.y + right.y, z: left.z + right.z)

proc vecSub(left: Vec3, right: Vec3): Vec3 =
  return Vec3(x: left.x - right.x, y: left.y - right.y, z: left.z - right.z)

proc vecScale(value: Vec3, factor: float64): Vec3 =
  return Vec3(x: value.x * factor, y: value.y * factor, z: value.z * factor)

proc vecDot(left: Vec3, right: Vec3): float64 =
  return left.x * right.x + left.y * right.y + left.z * right.z

proc vecCross(left: Vec3, right: Vec3): Vec3 =
  return Vec3(x: left.y * right.z - left.z * right.y,
              y: left.z * right.x - left.x * right.z,
              z: left.x * right.y - left.y * right.x)

proc vecNorm2(value: Vec3): float64 =
  return vecDot(value, value)

proc nextVec(): Vec3 =
  let xValue = float64(nextInt(inputData, scanPos))
  let yValue = float64(nextInt(inputData, scanPos))
  let zValue = float64(nextInt(inputData, scanPos))
  return Vec3(x: xValue, y: yValue, z: zValue)

proc circleFrom(first: Vec3, second: Vec3, third: Vec3): CircleData =
  let edgeOne = vecSub(second, first)
  let edgeTwo = vecSub(third, first)
  let planeNormal = vecCross(edgeOne, edgeTwo)
  let denominator = 2.0 * vecNorm2(planeNormal)
  let weightedOne = vecScale(vecCross(edgeTwo, planeNormal), vecNorm2(edgeOne))
  let weightedTwo = vecScale(vecCross(planeNormal, edgeOne), vecNorm2(edgeTwo))
  let center = vecAdd(first, vecScale(vecAdd(weightedOne, weightedTwo), 1.0 / denominator))
  let radius = sqrt(vecNorm2(vecSub(center, first)))
  let normal = vecScale(planeNormal, 1.0 / sqrt(vecNorm2(planeNormal)))
  return CircleData(center: center, radius: radius, normal: normal)

proc circlesLinked(first: CircleData, second: CircleData): bool =
  let alignment = vecDot(first.normal, second.normal)
  let squaredCross = 1.0 - alignment * alignment
  if squaredCross <= 1e-12:
    return false
  let firstOffset = vecDot(first.normal, first.center)
  let secondOffset = vecDot(second.normal, second.center)
  let basePoint = vecScale(
    vecAdd(vecScale(first.normal, firstOffset - alignment * secondOffset),
           vecScale(second.normal, secondOffset - alignment * firstOffset)),
    1.0 / squaredCross)
  let lineDirection = vecScale(vecCross(first.normal, second.normal), 1.0 / sqrt(squaredCross))
  let chordCenter = vecAdd(basePoint,
    vecScale(lineDirection, vecDot(vecSub(first.center, basePoint), lineDirection)))
  let centerDistanceSq = vecNorm2(vecSub(first.center, chordCenter))
  let radiusScale = max(first.radius, second.radius)
  let tolerance = 1e-9 * radiusScale * radiusScale + 1e-7
  if centerDistanceSq > first.radius * first.radius + tolerance:
    return false
  let halfChord = sqrt(max(0.0, first.radius * first.radius - centerDistanceSq))
  let plusPoint = vecAdd(chordCenter, vecScale(lineDirection, halfChord))
  let minusPoint = vecSub(chordCenter, vecScale(lineDirection, halfChord))
  let plusInside = vecNorm2(vecSub(plusPoint, second.center)) < second.radius * second.radius - tolerance
  let minusInside = vecNorm2(vecSub(minusPoint, second.center)) < second.radius * second.radius - tolerance
  return plusInside != minusInside

let caseCount = nextInt(inputData, scanPos)
var caseIndex = 1
while caseIndex <= caseCount:
  let firstCircle = circleFrom(nextVec(), nextVec(), nextVec())
  let secondCircle = circleFrom(nextVec(), nextVec(), nextVec())
  if circlesLinked(firstCircle, secondCircle) or circlesLinked(secondCircle, firstCircle):
    appendOutput("YES")
  else:
    appendOutput("NO")
  outputBuffer.add '\n'
  caseIndex += 1
stdout.write outputBuffer
outputBuffer.setLen 0
