const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const rootLow = -100.0
const rootHigh = 100.0
const mergeTolerance = 1e-4
const residualFactor = 1e-9
const residualFloor = 1e-300

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPosition = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int(data[position]) - firstDigitValue
    position += 1
  return value

proc nextPolynomial(data: string, position: var int): string =
  while position < data.len and (data[position] == '\n' or data[position] == '\r' or data[position] == ' '):
    position += 1
  result = ""
  while position < data.len and data[position] != '\n' and data[position] != '\r':
    result.add data[position]
    position += 1

proc parsePolynomial(text: string): array[7, float64] =
  var coefficients: array[7, float64]
  var termSign = 1.0
  var position = 0
  while position < text.len:
    let currentChar = text[position]
    if currentChar == '+':
      termSign = 1.0
      position += 1
      continue
    if currentChar == '-':
      termSign = -1.0
      position += 1
      continue
    if currentChar == ' ':
      position += 1
      continue
    let termStart = position
    var coefficientValue = 1.0
    var monomialDegree = 0
    let numberStart = position
    while position < text.len and text[position] >= '0' and text[position] <= '9':
      position += 1
    if position > numberStart:
      coefficientValue = 0.0
      for i in numberStart ..< position:
        coefficientValue = coefficientValue * 10.0 + float64(int(text[i]) - firstDigitValue)
    if position < text.len and text[position] == '*':
      position += 1
    if position < text.len and text[position] == 'x':
      position += 1
      monomialDegree = 1
      if position < text.len and text[position] == '^':
        position += 1
        monomialDegree = 0
        while position < text.len and text[position] >= '0' and text[position] <= '9':
          monomialDegree = monomialDegree * 10 + int(text[position]) - firstDigitValue
          position += 1
    coefficients[monomialDegree] += termSign * coefficientValue
    if position == termStart:
      position += 1
  return coefficients

proc evaluate(coefficients: array[7, float64], degree: int, value: float64): float64 =
  result = coefficients[degree]
  var powerIndex = degree - 1
  while powerIndex >= 0:
    result = result * value + coefficients[powerIndex]
    powerIndex -= 1

proc magnitude(coefficients: array[7, float64], degree: int, value: float64): float64 =
  result = 0.0
  var power = 1.0
  let absoluteValue = abs(value)
  for powerIndex in 0 .. degree:
    result += abs(coefficients[powerIndex]) * power
    power *= absoluteValue

proc multiplicityAt(coefficients: array[7, float64], degree: int, rootValue: float64): int =
  var workCoefficients: array[7, float64]
  for i in 0 .. 6:
    workCoefficients[i] = coefficients[i]
  let referenceScale = max(magnitude(coefficients, degree, rootValue),
                           max(magnitude(coefficients, degree, rootValue + 0.7),
                               magnitude(coefficients, degree, rootValue - 0.7)))
  var workDegree = degree
  while workDegree >= 1:
    let residualValue = evaluate(workCoefficients, workDegree, rootValue)
    if abs(residualValue) > residualFactor * referenceScale + residualFloor:
      break
    var quotientCoefficients: array[7, float64]
    quotientCoefficients[workDegree - 1] = workCoefficients[workDegree]
    var powerIndex = workDegree - 1
    while powerIndex >= 1:
      quotientCoefficients[powerIndex - 1] = workCoefficients[powerIndex] + rootValue * quotientCoefficients[powerIndex]
      powerIndex -= 1
    for i in 0 ..< workDegree:
      workCoefficients[i] = quotientCoefficients[i]
    workCoefficients[workDegree] = 0.0
    workDegree -= 1
    result += 1

proc bisectRoot(coefficients: array[7, float64], degree: int, leftEdge: float64, rightEdge: float64, leftValue: float64): float64 =
  var lowEdge = leftEdge
  var highEdge = rightEdge
  var lowValue = leftValue
  for i in 0 .. 119:
    let midPoint = (lowEdge + highEdge) / 2.0
    let midValue = evaluate(coefficients, degree, midPoint)
    if (midValue < 0.0) == (lowValue < 0.0):
      lowEdge = midPoint
      lowValue = midValue
    else:
      highEdge = midPoint
  result = (lowEdge + highEdge) / 2.0

proc sortAscending(values: var seq[float64]) =
  for i in 1 ..< values.len:
    let currentValue = values[i]
    var position = i - 1
    while position >= 0 and values[position] > currentValue:
      values[position + 1] = values[position]
      position -= 1
    values[position + 1] = currentValue

proc findRoots(coefficients: array[7, float64], degree: int): seq[float64] =
  if degree == 0:
    return @[]
  if degree == 1:
    result.add -coefficients[0] / coefficients[1]
    return
  var derivative: array[7, float64]
  for i in 0 ..< degree:
    derivative[i] = coefficients[i + 1] * float64(i + 1)
  var criticalRoots = findRoots(derivative, degree - 1)
  sortAscending(criticalRoots)
  var distinctCriticals: seq[float64] = @[]
  for rootValue in criticalRoots:
    if distinctCriticals.len == 0 or abs(rootValue - distinctCriticals[distinctCriticals.len - 1]) > mergeTolerance:
      distinctCriticals.add rootValue
  for criticalValue in distinctCriticals:
    let rootMultiplicity = multiplicityAt(coefficients, degree, criticalValue)
    for i in 0 ..< rootMultiplicity:
      result.add criticalValue
  for boundaryValue in [rootLow, rootHigh]:
    var alreadyFound = false
    for criticalValue in distinctCriticals:
      if abs(boundaryValue - criticalValue) <= mergeTolerance:
        alreadyFound = true
    if not alreadyFound:
      let rootMultiplicity = multiplicityAt(coefficients, degree, boundaryValue)
      for i in 0 ..< rootMultiplicity:
        result.add boundaryValue
  var splitPoints: seq[float64] = @[]
  splitPoints.add rootLow
  for criticalValue in distinctCriticals:
    splitPoints.add criticalValue
  splitPoints.add rootHigh
  for i in 0 ..< splitPoints.len - 1:
    let leftEdge = splitPoints[i]
    let rightEdge = splitPoints[i + 1]
    if rightEdge - leftEdge < mergeTolerance:
      continue
    if multiplicityAt(coefficients, degree, leftEdge) > 0:
      continue
    if multiplicityAt(coefficients, degree, rightEdge) > 0:
      continue
    let leftValue = evaluate(coefficients, degree, leftEdge)
    let rightValue = evaluate(coefficients, degree, rightEdge)
    if (leftValue < 0.0 and rightValue > 0.0) or (leftValue > 0.0 and rightValue < 0.0):
      result.add bisectRoot(coefficients, degree, leftEdge, rightEdge, leftValue)
  sortAscending(result)

proc formatRoot(value: float64): string =
  var scaledValue = value * 100.0
  if abs(scaledValue) < 0.5:
    scaledValue = 0.0
  var roundedValue: int64
  if scaledValue >= 0.0:
    roundedValue = int64(scaledValue + 0.5)
  else:
    roundedValue = int64(scaledValue - 0.5)
  let negativeRoot = roundedValue < 0
  let wholePart = abs(roundedValue) div 100
  let fracPart = abs(roundedValue) mod 100
  result = ""
  if negativeRoot:
    result.add '-'
  result.add $wholePart
  result.add '.'
  if fracPart < 10:
    result.add '0'
  result.add $fracPart

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPosition)
for caseIndex in 0 ..< caseCount:
  let polynomialText = nextPolynomial(inputData, scanPosition)
  let coefficients = parsePolynomial(polynomialText)
  var degree = 0
  for i in 0 .. 6:
    if coefficients[i] != 0.0:
      degree = i
  let roots = findRoots(coefficients, degree)
  var firstRoot = true
  for rootValue in roots:
    if not firstRoot:
      appendOutput " "
    appendOutput formatRoot(rootValue)
    firstRoot = false
  appendOutput "\n"

stdout.write outputBuffer
outputBuffer.setLen 0
