const modulus = 1111111111
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return value

proc normMod(value: int64): int64 =
  let remainder = value mod modulus
  if remainder < 0:
    return remainder + modulus
  return remainder

proc evaluatePolynomial(coefficients: seq[int64], argument: int): int64 =
  var value: int64 = 0
  for indexValue in countDown(coefficients.len - 1, 0):
    value = (value * int64(argument) + coefficients[indexValue]) mod modulus
  return value

proc multiplyPoly(firstPoly, secondPoly, reduction: seq[int64], order: int): seq[int64] =
  var productTerms = newSeq[int64](2 * order - 1)
  for firstIndex in 0 .. order - 1:
    if firstPoly[firstIndex] == 0:
      continue
    for secondIndex in 0 .. order - 1:
      let position = firstIndex + secondIndex
      productTerms[position] = normMod(productTerms[position] +
          firstPoly[firstIndex] * secondPoly[secondIndex])
  for degree in countDown(2 * order - 2, order):
    let highValue = productTerms[degree]
    if highValue == 0:
      continue
    for shift in 1 .. order:
      let position = degree - shift
      productTerms[position] = normMod(productTerms[position] - highValue * reduction[shift])
  return productTerms[0 .. order - 1]

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let targetIndex = nextInt(inputData, scanPos)
let degreeValue = nextInt(inputData, scanPos)
var coefficients = newSeq[int64](degreeValue + 1)
for coefficientIndex in 0 .. degreeValue:
  coefficients[coefficientIndex] = int64(nextInt(inputData, scanPos))

let recurrenceOrder = degreeValue + 3

var polynomialPart = newSeq[int64](1)
polynomialPart[0] = 1
for stepIndex in 0 .. degreeValue:
  var expanded = newSeq[int64](polynomialPart.len + 1)
  for indexValue in 0 .. polynomialPart.len - 1:
    let termValue = polynomialPart[indexValue]
    expanded[indexValue] = normMod(expanded[indexValue] + termValue)
    expanded[indexValue + 1] = normMod(expanded[indexValue + 1] - termValue)
  polynomialPart = expanded

var reduction = newSeq[int64](recurrenceOrder + 1)
for indexValue in 0 .. polynomialPart.len - 1:
  let termValue = polynomialPart[indexValue]
  reduction[indexValue] = normMod(reduction[indexValue] + termValue)
  reduction[indexValue + 1] = normMod(reduction[indexValue + 1] - termValue)
  reduction[indexValue + 2] = normMod(reduction[indexValue + 2] - termValue)

var initialValues = newSeq[int64](recurrenceOrder)
initialValues[0] = 1 mod modulus
initialValues[1] = 1 mod modulus
for indexValue in 2 .. recurrenceOrder - 1:
  let forcingValue = evaluatePolynomial(coefficients, indexValue)
  initialValues[indexValue] = normMod(initialValues[indexValue - 1] +
      initialValues[indexValue - 2] + forcingValue)

var powerPoly = newSeq[int64](recurrenceOrder)
powerPoly[0] = 1
var basePoly = newSeq[int64](recurrenceOrder)
basePoly[1] = 1
var remainingSteps = int64(targetIndex)
while remainingSteps > 0:
  if (remainingSteps and 1) == 1:
    powerPoly = multiplyPoly(powerPoly, basePoly, reduction, recurrenceOrder)
  remainingSteps = remainingSteps div 2
  if remainingSteps > 0:
    basePoly = multiplyPoly(basePoly, basePoly, reduction, recurrenceOrder)

var answerValue: int64 = 0
for indexValue in 0 .. recurrenceOrder - 1:
  answerValue = normMod(answerValue + powerPoly[indexValue] * initialValues[indexValue])
appendOutput($answerValue)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
