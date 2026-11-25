import math

const flushBlockBytes = 1 shl 17
const geometryEpsilon = 1e-9
const farDistanceValue = 1e30

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-':
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

type Point3 = tuple[xPos: float, yPos: float, zPos: float]

proc subtractPoints(firstPoint, secondPoint: Point3): Point3 =
  return (xPos: firstPoint.xPos - secondPoint.xPos,
          yPos: firstPoint.yPos - secondPoint.yPos,
          zPos: firstPoint.zPos - secondPoint.zPos)

proc dotProduct(firstPoint, secondPoint: Point3): float =
  return firstPoint.xPos * secondPoint.xPos +
         firstPoint.yPos * secondPoint.yPos +
         firstPoint.zPos * secondPoint.zPos

proc vectorLength(vectorValue: Point3): float =
  return sqrt(dotProduct(vectorValue, vectorValue))

proc scaleVector(vectorValue: Point3, factor: float): Point3 =
  return (xPos: vectorValue.xPos * factor,
          yPos: vectorValue.yPos * factor,
          zPos: vectorValue.zPos * factor)

proc classifyEclipse(starCenter: Point3, starRadius: float,
                     moonCenter: Point3, moonRadius: float,
                     planetCenter: Point3, planetRadius: float): string =
  let axisVector = subtractPoints(moonCenter, starCenter)
  let centerDistance = vectorLength(axisVector)
  let axisUnit = scaleVector(axisVector, 1.0 / centerDistance)
  let moonToPlanet = subtractPoints(planetCenter, moonCenter)
  let axialPosition = dotProduct(moonToPlanet, axisUnit)
  let sidewaysVector = subtractPoints(moonToPlanet, scaleVector(axisUnit, axialPosition))
  let sidewaysDistance = vectorLength(sidewaysVector)

  let penumbraSlope = (starRadius + moonRadius) / centerDistance
  let penumbraRadius = moonRadius + axialPosition * penumbraSlope
  let penumbraInner = penumbraRadius - sidewaysDistance
  let penumbraDistance = penumbraInner / sqrt(1.0 + penumbraSlope * penumbraSlope)

  var umbraSlope: float = 0.0
  var umbraRadius: float = 0.0
  var umbraApex = farDistanceValue
  if starRadius > moonRadius:
    umbraSlope = -(starRadius - moonRadius) / centerDistance
    umbraApex = moonRadius * centerDistance / (starRadius - moonRadius)
    umbraRadius = moonRadius + umbraSlope * axialPosition
  else:
    umbraSlope = (moonRadius - starRadius) / centerDistance
    umbraRadius = moonRadius + umbraSlope * axialPosition
  let umbraInner = umbraRadius - sidewaysDistance
  let umbraDistance = umbraInner / sqrt(1.0 + umbraSlope * umbraSlope)

  let behindMoon = axialPosition + planetRadius > geometryEpsilon
  let clearOfMoon = axialPosition - planetRadius > -geometryEpsilon
  var beforeApexForEntire = true
  var beforeApexForIntersection = true
  if umbraApex < 1e29:
    if axialPosition + planetRadius > umbraApex + geometryEpsilon:
      beforeApexForEntire = false
    if axialPosition - planetRadius >= umbraApex + geometryEpsilon:
      beforeApexForIntersection = false

  if behindMoon and clearOfMoon and beforeApexForEntire and umbraDistance >= planetRadius - geometryEpsilon:
    return "Entire total solar eclipse"
  if behindMoon and beforeApexForIntersection and umbraDistance > -planetRadius - geometryEpsilon:
    return "Part total solar eclipse"
  if behindMoon and clearOfMoon and penumbraDistance >= planetRadius - geometryEpsilon:
    return "Entire partial solar eclipse"
  if behindMoon and penumbraDistance > -planetRadius - geometryEpsilon:
    return "Part partial solar eclipse"
  return "No solar eclipse"

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while true:
  let firstValue = nextInt(inputData, scanPos)
  if firstValue == -1:
    break
  let secondValue = nextInt(inputData, scanPos)
  let thirdValue = nextInt(inputData, scanPos)
  let fourthValue = nextInt(inputData, scanPos)
  let fifthValue = nextInt(inputData, scanPos)
  let sixthValue = nextInt(inputData, scanPos)
  let seventhValue = nextInt(inputData, scanPos)
  let eighthValue = nextInt(inputData, scanPos)
  let ninthValue = nextInt(inputData, scanPos)
  let tenthValue = nextInt(inputData, scanPos)
  let eleventhValue = nextInt(inputData, scanPos)
  let twelfthValue = nextInt(inputData, scanPos)
  let starCenter: Point3 = (xPos: float(firstValue), yPos: float(secondValue), zPos: float(thirdValue))
  let moonCenter: Point3 = (xPos: float(fifthValue), yPos: float(sixthValue), zPos: float(seventhValue))
  let planetCenter: Point3 = (xPos: float(ninthValue), yPos: float(tenthValue), zPos: float(eleventhValue))
  let verdict = classifyEclipse(starCenter, float(fourthValue),
                                moonCenter, float(eighthValue),
                                planetCenter, float(twelfthValue))
  appendOutput(verdict)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
