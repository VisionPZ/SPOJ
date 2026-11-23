import math

const flushBlockBytes = 1 shl 18
const firstDigitValue = 48
const magnitudeTolerance = 1e-9
const coefficientTolerance = 1e-7
const limitZero = 0
const limitPosInf = 1
const limitNegInf = 2
const limitNoLimit = 3

const answerBalance = "Ecological balance will develop."
const answerHaresDie = "Hares will die out while foxes will overgrow."
const answerHaresOver = "Hares will overgrow while foxes will die out."
const answerBothDie = "Both hares and foxes will die out."
const answerBothOver = "Both hares and foxes will overgrow."
const answerChaos = "Chaos will develop."

proc isSpaceChar(ch: char): bool =
  return ch == ' ' or ch == '\n' or ch == '\r' or ch == '\t'

proc nextIntValue(data: string, scanPos: var int): int =
  while scanPos < data.len and (data[scanPos] < char(firstDigitValue) or data[scanPos] > '9'):
    scanPos += 1
  var value = 0
  while scanPos < data.len and data[scanPos] >= char(firstDigitValue) and data[scanPos] <= '9':
    value = value * 10 + (ord(data[scanPos]) - firstDigitValue)
    scanPos += 1
  return value

proc nextRealValue(data: string, scanPos: var int): float =
  while scanPos < data.len and isSpaceChar(data[scanPos]):
    scanPos += 1
  var signValue = 1.0
  if scanPos < data.len and data[scanPos] == '-':
    signValue = -1.0
    scanPos += 1
  elif scanPos < data.len and data[scanPos] == '+':
    scanPos += 1
  var wholePart = 0.0
  while scanPos < data.len and data[scanPos] >= char(firstDigitValue) and data[scanPos] <= '9':
    wholePart = wholePart * 10.0 + float(ord(data[scanPos]) - firstDigitValue)
    scanPos += 1
  var fractionPart = 0.0
  var placeValue = 1.0
  if scanPos < data.len and data[scanPos] == '.':
    scanPos += 1
    while scanPos < data.len and data[scanPos] >= char(firstDigitValue) and data[scanPos] <= '9':
      placeValue *= 10.0
      fractionPart += float(ord(data[scanPos]) - firstDigitValue) / placeValue
      scanPos += 1
  return signValue * (wholePart + fractionPart)

proc classifySequence(initialValue: float, nextValue: float, traceValue: float,
                      determinant: float, discriminant: float, rootGap: float): int =
  if initialValue == 0.0 and nextValue == 0.0:
    return limitZero
  if discriminant < -magnitudeTolerance:
    if determinant < 1.0 - magnitudeTolerance:
      return limitZero
    return limitNoLimit
  let largeRoot = (traceValue + rootGap) * 0.5
  let smallRoot = (traceValue - rootGap) * 0.5
  let largeMag = abs(largeRoot)
  let smallMag = abs(smallRoot)
  if largeMag < 1.0 - magnitudeTolerance and smallMag < 1.0 - magnitudeTolerance:
    return limitZero
  if discriminant > magnitudeTolerance:
    let rootDifference = largeRoot - smallRoot
    let largeCoeff = (nextValue - smallRoot * initialValue) / rootDifference
    let smallCoeff = (largeRoot * initialValue - nextValue) / rootDifference
    let coeffScale = max(abs(largeCoeff), abs(smallCoeff))
    if coeffScale == 0.0:
      return limitZero
    let largeActive = abs(largeCoeff) > coefficientTolerance * coeffScale
    let smallActive = abs(smallCoeff) > coefficientTolerance * coeffScale
    var chosenMag = -1.0
    var chosenRoot = 0.0
    var chosenCoeff = 0.0
    if largeActive:
      chosenMag = largeMag
      chosenRoot = largeRoot
      chosenCoeff = largeCoeff
    if smallActive:
      if smallMag > chosenMag + magnitudeTolerance or
         (abs(smallMag - chosenMag) <= magnitudeTolerance and smallRoot < chosenRoot):
        chosenMag = smallMag
        chosenRoot = smallRoot
        chosenCoeff = smallCoeff
    if chosenMag < 0.0:
      return limitZero
    if chosenMag < 1.0 - magnitudeTolerance:
      return limitZero
    if abs(chosenMag - 1.0) <= magnitudeTolerance:
      return limitNoLimit
    if chosenRoot > 0.0:
      if chosenCoeff > 0.0:
        return limitPosInf
      return limitNegInf
    return limitNoLimit
  let repeatedRoot = traceValue * 0.5
  let rootMagnitude = abs(repeatedRoot)
  if rootMagnitude < 1.0 - magnitudeTolerance:
    return limitZero
  if abs(rootMagnitude - 1.0) <= magnitudeTolerance:
    if abs(repeatedRoot - 1.0) <= magnitudeTolerance:
      let slope = nextValue - initialValue
      let valueScale = max(abs(initialValue), abs(nextValue))
      if valueScale == 0.0 or abs(slope) <= 1e-9 * valueScale:
        if abs(initialValue) <= 1e-9:
          return limitZero
        return limitNoLimit
      if slope > 0.0:
        return limitPosInf
      return limitNegInf
    return limitNoLimit
  if repeatedRoot > 0.0:
    let growthCoeff = nextValue / repeatedRoot - initialValue
    let valueScale = max(abs(initialValue), abs(nextValue / repeatedRoot))
    if valueScale == 0.0 or abs(growthCoeff) <= 1e-9 * valueScale:
      if initialValue > 0.0:
        return limitPosInf
      if initialValue < 0.0:
        return limitNegInf
      return limitZero
    if growthCoeff > 0.0:
      return limitPosInf
    return limitNegInf
  return limitNoLimit

proc answerForCase(coeffA: float, coeffB: float, coeffC: float, coeffD: float,
                   initialHares: float, initialFoxes: float): string =
  let traceValue = coeffA + coeffC
  let determinant = coeffA * coeffC + coeffB * coeffD
  let discriminant = traceValue * traceValue - 4.0 * determinant
  var rootGap = 0.0
  if discriminant > 0.0:
    rootGap = sqrt(discriminant)
  let haresNext = coeffA * initialHares - coeffB * initialFoxes
  let foxesNext = coeffC * initialFoxes + coeffD * initialHares
  let hareLimit = classifySequence(initialHares, haresNext, traceValue,
                                   determinant, discriminant, rootGap)
  let foxLimit = classifySequence(initialFoxes, foxesNext, traceValue,
                                  determinant, discriminant, rootGap)
  if hareLimit == limitZero and foxLimit == limitZero:
    return answerBalance
  if hareLimit == limitPosInf and foxLimit == limitPosInf:
    return answerBothOver
  if hareLimit == limitNegInf and foxLimit == limitNegInf:
    return answerBothDie
  if hareLimit == limitNegInf and foxLimit == limitPosInf:
    return answerHaresDie
  if hareLimit == limitPosInf and foxLimit == limitNegInf:
    return answerHaresOver
  return answerChaos

var inputData = ""
var inputLine: string = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
let caseCount = nextIntValue(inputData, scanPos)
var outputBuffer = ""

for caseIndex in 0 ..< caseCount:
  let coeffA = nextRealValue(inputData, scanPos)
  let coeffB = nextRealValue(inputData, scanPos)
  let coeffC = nextRealValue(inputData, scanPos)
  let coeffD = nextRealValue(inputData, scanPos)
  let initialHares = nextRealValue(inputData, scanPos)
  let initialFoxes = nextRealValue(inputData, scanPos)
  outputBuffer.add answerForCase(coeffA, coeffB, coeffC, coeffD, initialHares, initialFoxes)
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

if outputBuffer.len > 0:
  stdout.write outputBuffer
  outputBuffer.setLen 0
