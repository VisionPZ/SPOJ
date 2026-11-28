import algorithm

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const maxTriangleCount = 2000
const primeCount = 12
const hypotenuseLimit = int64(9223372036854775807)

const oneModFourPrimes: array[0..primeCount - 1, int64] = [int64(5), int64(13), int64(17), int64(29), int64(37), int64(41), int64(53), int64(61), int64(73), int64(89), int64(97), int64(101)]
const primeRealParts: array[0..primeCount - 1, int64] = [int64(2), int64(3), int64(4), int64(5), int64(6), int64(5), int64(7), int64(6), int64(8), int64(8), int64(9), int64(10)]
const primeImagParts: array[0..primeCount - 1, int64] = [int64(1), int64(2), int64(1), int64(2), int64(1), int64(4), int64(2), int64(5), int64(3), int64(5), int64(4), int64(1)]

var bestRadius: array[0..maxTriangleCount, int64]
var exponentTable: array[0..maxTriangleCount, array[0..primeCount - 1, int]]
var exponentScratch: array[0..primeCount - 1, int]

proc limitedPower(baseValue: int64, exponentValue: int, limitValue: int64): int64 =
  result = 1'i64
  for _ in 1..exponentValue:
    if result > limitValue div baseValue:
      return -1'i64
    result = result * baseValue

proc searchPartitions(remainingValue, previousFactor, depth: int, currentProduct: int64, representationProduct: int) =
  if remainingValue == 1:
    let triangleCount = (representationProduct - 1) div 2
    if triangleCount >= 1 and triangleCount <= maxTriangleCount:
      if bestRadius[triangleCount] == 0 or currentProduct < bestRadius[triangleCount]:
        bestRadius[triangleCount] = currentProduct
        for factorIndex in depth..<primeCount:
          exponentScratch[factorIndex] = 0
        for factorIndex in 0..<primeCount:
          exponentTable[triangleCount][factorIndex] = exponentScratch[factorIndex]
    return
  if depth >= primeCount: return
  var factorCandidate = 3
  while factorCandidate <= remainingValue:
    if factorCandidate <= previousFactor and remainingValue mod factorCandidate == 0:
      let exponentValue = (factorCandidate - 1) div 2
      let powerValue = limitedPower(oneModFourPrimes[depth], exponentValue, hypotenuseLimit div currentProduct)
      if powerValue > 0:
        exponentScratch[depth] = exponentValue
        searchPartitions(remainingValue div factorCandidate, factorCandidate, depth + 1, currentProduct * powerValue, representationProduct * (2 * exponentValue + 1))
    factorCandidate += 2

for triangleIndex in 1..maxTriangleCount:
  searchPartitions(2 * triangleIndex + 1, 2 * triangleIndex + 1, 0, 1'i64, 1)

proc nextInt(inputData: string, scanPos: var int): int =
  while scanPos < inputData.len and (inputData[scanPos] < '0' or inputData[scanPos] > '9'):
    scanPos += 1
  var value = 0
  while scanPos < inputData.len and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    value = value * 10 + int(inputData[scanPos]) - firstDigitValue
    scanPos += 1
  return value

type ComplexValue = tuple[realPart: int64, imagPart: int64]

proc makeComplex(realValue, imagValue: int64): ComplexValue =
  result.realPart = realValue
  result.imagPart = imagValue

proc multiplyComplex(leftValue, rightValue: ComplexValue): ComplexValue =
  result.realPart = leftValue.realPart * rightValue.realPart - leftValue.imagPart * rightValue.imagPart
  result.imagPart = leftValue.realPart * rightValue.imagPart + leftValue.imagPart * rightValue.realPart

proc compareLegs(leftValue, rightValue: int64): int =
  if leftValue < rightValue: return -1
  if leftValue > rightValue: return 1
  return 0

var legValues: seq[int64]
var stateValues: seq[ComplexValue]
var nextStateValues: seq[ComplexValue]
var plusPowers: seq[ComplexValue]
var minusPowers: seq[ComplexValue]

proc collectLegValues(triangleCount: int) =
  legValues.setLen 0
  stateValues.setLen 0
  stateValues.add makeComplex(1'i64, 0'i64)
  for factorIndex in 0..<primeCount:
    let exponentValue = exponentTable[triangleCount][factorIndex]
    if exponentValue == 0: continue
    plusPowers.setLen 0
    minusPowers.setLen 0
    plusPowers.add makeComplex(1'i64, 0'i64)
    minusPowers.add makeComplex(1'i64, 0'i64)
    for powerIndex in 1..2 * exponentValue:
      plusPowers.add multiplyComplex(plusPowers[powerIndex - 1], makeComplex(primeRealParts[factorIndex], primeImagParts[factorIndex]))
      minusPowers.add multiplyComplex(minusPowers[powerIndex - 1], makeComplex(primeRealParts[factorIndex], -primeImagParts[factorIndex]))
    nextStateValues.setLen 0
    for stateValue in stateValues:
      for choiceIndex in 0..2 * exponentValue:
        let factorValue = multiplyComplex(plusPowers[choiceIndex], minusPowers[2 * exponentValue - choiceIndex])
        nextStateValues.add multiplyComplex(stateValue, factorValue)
    swap(stateValues, nextStateValues)
  for stateValue in stateValues:
    if stateValue.imagPart != 0:
      legValues.add min(abs(stateValue.realPart), abs(stateValue.imagPart))
  legValues.sort(compareLegs)

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let triangleCount = nextInt(inputData, scanPos)
  let radiusValue = bestRadius[triangleCount]
  appendOutput($radiusValue)
  outputBuffer.add '\n'
  collectLegValues(triangleCount)
  var previousLeg = int64(-1)
  for legValue in legValues:
    if legValue != previousLeg:
      appendOutput($legValue)
      outputBuffer.add '\n'
      previousLeg = legValue

stdout.write outputBuffer
