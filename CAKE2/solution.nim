import algorithm

const flushBlockBytes = 1 shl 17
const firstDigitValue = 48

type Fraction = tuple[numerator: int64, denominator: int64]

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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return signValue * value

proc greatestCommonDivisor(firstValue: int64, secondValue: int64): int64 =
  var largerValue = firstValue
  var smallerValue = secondValue
  if largerValue < 0:
    largerValue = -largerValue
  if smallerValue < 0:
    smallerValue = -smallerValue
  while smallerValue != 0:
    let remainderValue = largerValue mod smallerValue
    largerValue = smallerValue
    smallerValue = remainderValue
  return largerValue

proc compareFractions(leftFraction: Fraction, rightFraction: Fraction): int =
  let leftCross = leftFraction.numerator * rightFraction.denominator
  let rightCross = rightFraction.numerator * leftFraction.denominator
  if leftCross < rightCross:
    return -1
  if leftCross > rightCross:
    return 1
  return 0

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let lineCount = nextInt(inputData, scanPos)
var lineA = newSeq[int64](lineCount)
var lineB = newSeq[int64](lineCount)
var lineC = newSeq[int64](lineCount)
var lineDirX = newSeq[int64](lineCount)
var lineDirY = newSeq[int64](lineCount)
var lineX1 = newSeq[int64](lineCount)
var lineY1 = newSeq[int64](lineCount)
for lineIndex in 0 ..< lineCount:
  let firstX = int64(nextInt(inputData, scanPos))
  let firstY = int64(nextInt(inputData, scanPos))
  let secondX = int64(nextInt(inputData, scanPos))
  let secondY = int64(nextInt(inputData, scanPos))
  let directionX = secondX - firstX
  let directionY = secondY - firstY
  lineDirX[lineIndex] = directionX
  lineDirY[lineIndex] = directionY
  lineX1[lineIndex] = firstX
  lineY1[lineIndex] = firstY
  lineA[lineIndex] = directionY
  lineB[lineIndex] = -directionX
  lineC[lineIndex] = directionX * firstY - directionY * firstX

var regionCount: int64 = 1
for lineIndex in 0 ..< lineCount:
  var intersectionParameters = newSeq[Fraction](lineIndex)
  var parameterCount = 0
  for previousLine in 0 ..< lineIndex:
    let denominatorValue = lineA[previousLine] * lineDirX[lineIndex] + lineB[previousLine] * lineDirY[lineIndex]
    if denominatorValue == 0:
      continue
    var numeratorValue = -(lineA[previousLine] * lineX1[lineIndex] + lineB[previousLine] * lineY1[lineIndex] + lineC[previousLine])
    var positiveDenominator = denominatorValue
    if positiveDenominator < 0:
      positiveDenominator = -positiveDenominator
      numeratorValue = -numeratorValue
    let commonDivisor = greatestCommonDivisor(numeratorValue, positiveDenominator)
    intersectionParameters[parameterCount].numerator = numeratorValue div commonDivisor
    intersectionParameters[parameterCount].denominator = positiveDenominator div commonDivisor
    parameterCount += 1
  intersectionParameters.setLen(parameterCount)
  sort(intersectionParameters, compareFractions)
  var distinctPoints = 0
  var scanIndex = 0
  while scanIndex < parameterCount:
    distinctPoints += 1
    while scanIndex + 1 < parameterCount and intersectionParameters[scanIndex] == intersectionParameters[scanIndex + 1]:
      scanIndex += 1
    scanIndex += 1
  regionCount = regionCount + int64(distinctPoints + 1)

appendOutput($regionCount)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
