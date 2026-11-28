const flushBlockBytes = 1 shl 17
const firstDigitValue = 48
const maxPrimeLimit = 100000
const splitShift = 20
const splitBase = 1 shl splitShift
const splitMask = splitBase - 1

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

proc nextInt64(data: string, pos: var int): int64 =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value: int64 = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int64(int(data[pos]) - firstDigitValue)
    pos += 1
  return value

var compositeFlags = newSeq[bool](maxPrimeLimit + 1)
var primeList: seq[int] = @[]
for candidate in 2..maxPrimeLimit:
  if not compositeFlags[candidate]:
    primeList.add candidate
    if int64(candidate) * int64(candidate) <= int64(maxPrimeLimit):
      var multiple = candidate * candidate
      while multiple <= maxPrimeLimit:
        compositeFlags[multiple] = true
        multiple += candidate

proc multiplyModulo(leftValue, rightValue, modulus: int64): int64 =
  let leftLow = leftValue and int64(splitMask)
  let leftHigh = leftValue shr splitShift
  let rightLow = rightValue and int64(splitMask)
  let rightHigh = rightValue shr splitShift
  let lowProduct = leftLow * rightLow
  let midProduct = leftLow * rightHigh + leftHigh * rightLow
  let highProduct = leftHigh * rightHigh
  var reducedValue = highProduct mod modulus
  reducedValue = (reducedValue * int64(splitBase) + midProduct) mod modulus
  reducedValue = (reducedValue * int64(splitBase) + lowProduct) mod modulus
  return reducedValue

proc powerModulo(baseValue, exponentValue, modulus: int64): int64 =
  var accumulated: int64 = 1 mod modulus
  var baseReduced = baseValue mod modulus
  var exponent = exponentValue
  while exponent > 0:
    if (exponent and 1) == 1:
      accumulated = multiplyModulo(accumulated, baseReduced, modulus)
    baseReduced = multiplyModulo(baseReduced, baseReduced, modulus)
    exponent = exponent shr 1
  return accumulated

proc binomialModulo(nValue, kValue: int, modulus: int64): int64 =
  if modulus == 1:
    return 0
  if kValue < 0 or kValue > nValue:
    return 0
  if kValue == 0:
    return 1 mod modulus
  let complement = nValue - kValue
  var answerValue: int64 = 1
  for prime in primeList:
    if prime > nValue:
      break
    var primePower: int64 = int64(prime)
    var exponent: int64 = 0
    while primePower <= int64(nValue):
      exponent += int64(nValue) div primePower - int64(kValue) div primePower -
                  int64(complement) div primePower
      primePower *= int64(prime)
    if exponent > 0:
      let primeFactor = powerModulo(int64(prime), exponent, modulus)
      answerValue = multiplyModulo(answerValue, primeFactor, modulus)
  return answerValue

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var scanPos = 0
let caseCount = nextInt(inputData, scanPos)
for _ in 0..<caseCount:
  let totalKnives = nextInt(inputData, scanPos)
  let chosenKnives = nextInt(inputData, scanPos)
  let modulus = nextInt64(inputData, scanPos)
  let reducedChoice = min(chosenKnives, totalKnives - chosenKnives)
  let answer = binomialModulo(totalKnives, reducedChoice, modulus)
  appendOutput($(answer))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
