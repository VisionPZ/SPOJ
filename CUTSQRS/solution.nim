import math

const
  firstDigitValue = 48
  flushBlockBytes = 1 shl 18
  splitFactor = 134217729.0
  logTenTwoHigh = 0.30102999566398119521373889472449302677
  logTenTwoLow = -2.8037281277851704e-18

proc nextInt(inputData: string, scanPos: var int): int =
  let dataLength = inputData.len
  while scanPos < dataLength and inputData[scanPos] < '0':
    inc scanPos
  result = 0
  while scanPos < dataLength and inputData[scanPos] >= '0':
    result = result * 10 + (int(inputData[scanPos]) - firstDigitValue)
    inc scanPos

proc splitDouble(value: float): tuple[highPart, lowPart: float] =
  let scaled = splitFactor * value
  result.highPart = scaled - (scaled - value)
  result.lowPart = value - result.highPart

proc highPrecisionProduct(factorLeft, factorRight: float): tuple[product, error: float] =
  let product = factorLeft * factorRight
  let leftParts = splitDouble(factorLeft)
  let rightParts = splitDouble(factorRight)
  result.product = product
  result.error = ((leftParts.highPart * rightParts.highPart - product) +
                   leftParts.highPart * rightParts.lowPart +
                   leftParts.lowPart * rightParts.highPart) +
                   leftParts.lowPart * rightParts.lowPart

proc powerOfTwoDigitCount(exponent: int): int =
  let productParts = highPrecisionProduct(float(exponent), logTenTwoHigh)
  let correction = productParts.error + float(exponent) * logTenTwoLow
  let wholePart = floor(productParts.product)
  let fractionalPart = productParts.product - wholePart
  result = int(wholePart) + int(floor(fractionalPart + correction)) + 1

proc solveCase(sideLeft, sideRight: int): int =
  if sideLeft == sideRight:
    return 7
  var shorterSide = sideLeft
  var longerSide = sideRight
  var quotientSum = 0
  var leadingOnes = 0
  var countingLeadingOnes = true
  while shorterSide != 0:
    let quotient = longerSide div shorterSide
    if countingLeadingOnes:
      if quotient == 1:
        inc leadingOnes
      else:
        countingLeadingOnes = false
    quotientSum += quotient - 1
    let remainder = longerSide mod shorterSide
    longerSide = shorterSide
    shorterSide = remainder
  let sequenceDigits = powerOfTwoDigitCount(quotientSum)
  let winningDigits = powerOfTwoDigitCount(quotientSum - 1)
  let wordLength = if leadingOnes mod 2 == 0: 5 else: 6
  result = sequenceDigits + winningDigits + wordLength

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
let caseCount = nextInt(inputData, scanPos)
var outputBuffer = ""
var caseIndex = 0
while caseIndex < caseCount:
  let sideLeft = nextInt(inputData, scanPos)
  let sideRight = nextInt(inputData, scanPos)
  outputBuffer.add $solveCase(sideLeft, sideRight)
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
  inc caseIndex
if outputBuffer.len > 0:
  stdout.write outputBuffer
