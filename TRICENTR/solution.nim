import strutils, math

const flushBlockBytes = 1 shl 16

proc readAllInput(): string =
  var currentLine = ""
  while readLine(stdin, currentLine):
    result.add currentLine
    result.add '\n'

proc nextInteger(inputData: string, i: var int): int =
  while i < inputData.len and inputData[i] <= ' ':
    inc i
  var value = 0
  while i < inputData.len and inputData[i] >= '0' and inputData[i] <= '9':
    value = value * 10 + (ord(inputData[i]) - 48)
    inc i
  return value

proc nextDecimal(inputData: string, i: var int): float =
  while i < inputData.len and inputData[i] <= ' ':
    inc i
  var sign = 1.0
  if i < inputData.len and inputData[i] == '-':
    sign = -1.0
    inc i
  elif i < inputData.len and inputData[i] == '+':
    inc i
  var significand = 0.0
  var decimalDigits = 0
  while i < inputData.len and inputData[i] >= '0' and inputData[i] <= '9':
    significand = significand * 10.0 + float(ord(inputData[i]) - 48)
    inc i
  if i < inputData.len and inputData[i] == '.':
    inc i
    while i < inputData.len and inputData[i] >= '0' and inputData[i] <= '9':
      significand = significand * 10.0 + float(ord(inputData[i]) - 48)
      inc decimalDigits
      inc i
  var scale = 1.0
  var j = 0
  while j < decimalDigits:
    scale = scale * 10.0
    inc j
  result = sign * (significand / scale)
  if i < inputData.len and (inputData[i] == 'e' or inputData[i] == 'E'):
    inc i
    var exponentSign = 1
    if i < inputData.len and inputData[i] == '-':
      exponentSign = -1
      inc i
    elif i < inputData.len and inputData[i] == '+':
      inc i
    var exponentValue = 0
    while i < inputData.len and inputData[i] >= '0' and inputData[i] <= '9':
      exponentValue = exponentValue * 10 + (ord(inputData[i]) - 48)
      inc i
    var exponentScale = 1.0
    j = 0
    while j < exponentValue:
      exponentScale = exponentScale * 10.0
      inc j
    if exponentSign > 0:
      result = result * exponentScale
    else:
      result = result / exponentScale

proc main() =
  let inputData = readAllInput()
  var i = 0
  let caseCount = nextInteger(inputData, i)
  var outputBuffer = ""
  var j = 0
  while j < caseCount:
    let sideLength = nextDecimal(inputData, i)
    let distToSideA = nextDecimal(inputData, i)
    let distToSideB = nextDecimal(inputData, i)
    let distToSideC = nextDecimal(inputData, i)
    let triangleArea = 1.5 * sideLength * distToSideA
    let otherSideB = sideLength * distToSideA / distToSideB
    let otherSideC = sideLength * distToSideA / distToSideC
    let circumRadius = sideLength * otherSideB * otherSideC / (4.0 * triangleArea)
    var eulerSquared = 9.0 * circumRadius * circumRadius - (sideLength * sideLength + otherSideB * otherSideB + otherSideC * otherSideC)
    if eulerSquared < 0.0:
      eulerSquared = 0.0
    let centroidToOrthocenter = (2.0 / 3.0) * sqrt(eulerSquared)
    outputBuffer.add formatFloat(triangleArea, ffDecimal, 3)
    outputBuffer.add ' '
    outputBuffer.add formatFloat(centroidToOrthocenter, ffDecimal, 3)
    outputBuffer.add '\n'
    if outputBuffer.len >= flushBlockBytes:
      stdout.write outputBuffer
      outputBuffer.setLen 0
    inc j
  stdout.write outputBuffer

main()
