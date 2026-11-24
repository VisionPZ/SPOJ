{.checks: off.}
{.optimization: speed.}

import math
import strutils

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const containmentEpsilon = 1e-6

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int(data[position]) - firstDigitValue
    position += 1
  return value

proc nextDouble(data: string, position: var int): float =
  while position < data.len and (data[position] == ' ' or data[position] == '\n' or
      data[position] == '\t' or data[position] == '\r'):
    position += 1
  var sign = 1.0
  if position < data.len and data[position] == '-':
    sign = -1.0
    position += 1
  elif position < data.len and data[position] == '+':
    position += 1
  var whole = 0.0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    whole = whole * 10.0 + float(int(data[position]) - firstDigitValue)
    position += 1
  var fraction = 0.0
  var scale = 1.0
  if position < data.len and data[position] == '.':
    position += 1
    while position < data.len and data[position] >= '0' and data[position] <= '9':
      scale *= 10.0
      fraction = fraction * 10.0 + float(int(data[position]) - firstDigitValue)
      position += 1
  var exponent = 0
  if position < data.len and (data[position] == 'e' or data[position] == 'E'):
    position += 1
    var exponentSign = 1
    if position < data.len and data[position] == '-':
      exponentSign = -1
      position += 1
    elif position < data.len and data[position] == '+':
      position += 1
    while position < data.len and data[position] >= '0' and data[position] <= '9':
      exponent = exponent * 10 + int(data[position]) - firstDigitValue
      position += 1
    exponent *= exponentSign
  var multiplier = 1.0
  if exponent > 0:
    for i in 0..<exponent:
      multiplier *= 10.0
  elif exponent < 0:
    for i in 0..<(-exponent):
      multiplier /= 10.0
  return sign * (whole + fraction / scale) * multiplier

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc formatNumber(value: float): string =
  var formatted = formatFloat(value, ffDecimal, 2)
  if formatted == "-0.00":
    formatted = "0.00"
  return formatted

type Circle = object
  centerX: float
  centerY: float
  radiusSquared: float

proc makeCircle(centerX, centerY, radiusSquared: float): Circle =
  result.centerX = centerX
  result.centerY = centerY
  result.radiusSquared = radiusSquared

proc contains(circle: Circle, pointX, pointY: float): bool =
  let dx = pointX - circle.centerX
  let dy = pointY - circle.centerY
  (dx * dx + dy * dy) <= circle.radiusSquared * (1.0 + 1e-12) + containmentEpsilon

proc circleFromDiameter(pointX1, pointY1, pointX2, pointY2: float): Circle =
  let centerX = (pointX1 + pointX2) / 2.0
  let centerY = (pointY1 + pointY2) / 2.0
  let dx = pointX1 - pointX2
  let dy = pointY1 - pointY2
  return makeCircle(centerX, centerY, (dx * dx + dy * dy) / 4.0)

proc circleFromThree(pointX1, pointY1, pointX2, pointY2, pointX3, pointY3: float): Circle =
  let determinant = 2.0 * (pointX1 * (pointY2 - pointY3) +
                           pointX2 * (pointY3 - pointY1) +
                           pointX3 * (pointY1 - pointY2))
  if abs(determinant) > 1e-12:
    let square1 = pointX1 * pointX1 + pointY1 * pointY1
    let square2 = pointX2 * pointX2 + pointY2 * pointY2
    let square3 = pointX3 * pointX3 + pointY3 * pointY3
    let centerX = (square1 * (pointY2 - pointY3) +
                   square2 * (pointY3 - pointY1) +
                   square3 * (pointY1 - pointY2)) / determinant
    let centerY = (square1 * (pointX3 - pointX2) +
                   square2 * (pointX1 - pointX3) +
                   square3 * (pointX2 - pointX1)) / determinant
    let dx = pointX1 - centerX
    let dy = pointY1 - centerY
    return makeCircle(centerX, centerY, dx * dx + dy * dy)
  let distance12 = (pointX1 - pointX2) * (pointX1 - pointX2) +
                   (pointY1 - pointY2) * (pointY1 - pointY2)
  let distance13 = (pointX1 - pointX3) * (pointX1 - pointX3) +
                   (pointY1 - pointY3) * (pointY1 - pointY3)
  let distance23 = (pointX2 - pointX3) * (pointX2 - pointX3) +
                   (pointY2 - pointY3) * (pointY2 - pointY3)
  if distance12 >= distance13 and distance12 >= distance23:
    return circleFromDiameter(pointX1, pointY1, pointX2, pointY2)
  elif distance13 >= distance23:
    return circleFromDiameter(pointX1, pointY1, pointX3, pointY3)
  return circleFromDiameter(pointX2, pointY2, pointX3, pointY3)

var randomState: uint64 = 88172645463325252'u64

proc randomIndex(bound: int): int =
  randomState = randomState xor (randomState shl 13'u64)
  randomState = randomState xor (randomState shr 7'u64)
  randomState = randomState xor (randomState shl 17'u64)
  return int(randomState mod uint64(bound))

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let pointCount = nextInt(inputData, scanPos)
  var pointXs = newSeq[float](pointCount)
  var pointYs = newSeq[float](pointCount)
  for i in 0..<pointCount:
    pointXs[i] = nextDouble(inputData, scanPos)
    pointYs[i] = nextDouble(inputData, scanPos)
  var i = pointCount - 1
  while i > 0:
    let j = randomIndex(i + 1)
    swap pointXs[i], pointXs[j]
    swap pointYs[i], pointYs[j]
    i -= 1
  var enclosing = makeCircle(0.0, 0.0, -1.0)
  for i in 0..<pointCount:
    if not enclosing.contains(pointXs[i], pointYs[i]):
      enclosing = makeCircle(pointXs[i], pointYs[i], 0.0)
      for j in 0..<i:
        if not enclosing.contains(pointXs[j], pointYs[j]):
          enclosing = circleFromDiameter(pointXs[i], pointYs[i], pointXs[j], pointYs[j])
          for k in 0..<j:
            if not enclosing.contains(pointXs[k], pointYs[k]):
              enclosing = circleFromThree(pointXs[i], pointYs[i],
                                          pointXs[j], pointYs[j],
                                          pointXs[k], pointYs[k])
  appendOutput(formatNumber(sqrt(enclosing.radiusSquared)))
  outputBuffer.add '\n'
  appendOutput(formatNumber(enclosing.centerX))
  outputBuffer.add ' '
  appendOutput(formatNumber(enclosing.centerY))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
