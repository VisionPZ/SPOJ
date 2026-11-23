import strutils, math

const flushBlockBytes = 1 shl 16

proc readAllInput(): string =
  var currentLine = ""
  while readLine(stdin, currentLine):
    result.add currentLine
    result.add '\n'

proc nextInteger(inputData: string, scanPos: var int): int =
  while scanPos < inputData.len and inputData[scanPos] <= ' ':
    inc scanPos
  var value = 0
  while scanPos < inputData.len and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    value = value * 10 + (ord(inputData[scanPos]) - 48)
    inc scanPos
  return value

proc nextDecimal(inputData: string, scanPos: var int): float =
  while scanPos < inputData.len and inputData[scanPos] <= ' ':
    inc scanPos
  var sign = 1.0
  if scanPos < inputData.len and inputData[scanPos] == '-':
    sign = -1.0
    inc scanPos
  elif scanPos < inputData.len and inputData[scanPos] == '+':
    inc scanPos
  var significand = 0.0
  var decimalDigits = 0
  while scanPos < inputData.len and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    significand = significand * 10.0 + float(ord(inputData[scanPos]) - 48)
    inc scanPos
  if scanPos < inputData.len and inputData[scanPos] == '.':
    inc scanPos
    while scanPos < inputData.len and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
      significand = significand * 10.0 + float(ord(inputData[scanPos]) - 48)
      inc decimalDigits
      inc scanPos
  var scale = 1.0
  var digitIndex = 0
  while digitIndex < decimalDigits:
    scale = scale * 10.0
    inc digitIndex
  result = sign * (significand / scale)
  if scanPos < inputData.len and (inputData[scanPos] == 'e' or inputData[scanPos] == 'E'):
    inc scanPos
    var exponentSign = 1
    if scanPos < inputData.len and inputData[scanPos] == '-':
      exponentSign = -1
      inc scanPos
    elif scanPos < inputData.len and inputData[scanPos] == '+':
      inc scanPos
    var exponentValue = 0
    while scanPos < inputData.len and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
      exponentValue = exponentValue * 10 + (ord(inputData[scanPos]) - 48)
      inc scanPos
    var exponentScale = 1.0
    digitIndex = 0
    while digitIndex < exponentValue:
      exponentScale = exponentScale * 10.0
      inc digitIndex
    if exponentSign > 0:
      result = result * exponentScale
    else:
      result = result / exponentScale

proc main() =
  let inputData = readAllInput()
  var scanPos = 0
  let caseCount = nextInteger(inputData, scanPos)
  var outputBuffer = ""
  var caseIndex = 0
  while caseIndex < caseCount:
    let sideLength = nextDecimal(inputData, scanPos)
    let distToSideA = nextDecimal(inputData, scanPos)
    let distToSideB = nextDecimal(inputData, scanPos)
    let distToSideC = nextDecimal(inputData, scanPos)
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
    inc caseIndex
  stdout.write outputBuffer

main()
