const flushBlockBytes = 1 shl 17
const primeBases = [int64(2), 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37]

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc gcdIntegers(leftValue: int64, rightValue: int64): int64 =
  var larger = leftValue
  var smaller = rightValue
  if larger < 0:
    larger = -larger
  if smaller < 0:
    smaller = -smaller
  while smaller != 0:
    let remainder = larger mod smaller
    larger = smaller
    smaller = remainder
  return larger

proc multiplyMod(leftValue: int64, rightValue: int64, modulus: int64): int64 =
  var productValue: int64 = 0
  var multiplicand = leftValue mod modulus
  var multiplier = rightValue
  while multiplier > 0:
    if (multiplier and 1) == 1:
      productValue = (productValue + multiplicand) mod modulus
    multiplicand = (multiplicand * 2) mod modulus
    multiplier = multiplier shr 1
  return productValue

proc powerModulo(baseValue: int64, exponentValue: int64, modulus: int64): int64 =
  var powerResult: int64 = 1 mod modulus
  var factor = baseValue mod modulus
  var exponentLeft = exponentValue
  while exponentLeft > 0:
    if (exponentLeft and 1) == 1:
      powerResult = multiplyMod(powerResult, factor, modulus)
    factor = multiplyMod(factor, factor, modulus)
    exponentLeft = exponentLeft shr 1
  return powerResult

proc isPrimeNumber(candidate: int64): bool =
  if candidate < 2:
    return false
  for baseValue in primeBases:
    if candidate == baseValue:
      return true
    if candidate mod baseValue == 0:
      return false
  var oddPart = candidate - 1
  var shiftCount = 0
  while (oddPart and 1) == 0:
    oddPart = oddPart shr 1
    shiftCount += 1
  for baseValue in primeBases:
    var observed = powerModulo(baseValue, oddPart, candidate)
    if observed == 1 or observed == candidate - 1:
      continue
    var roundIndex = 1
    var witnessPassed = false
    while roundIndex < shiftCount:
      observed = multiplyMod(observed, observed, candidate)
      if observed == candidate - 1:
        witnessPassed = true
        break
      roundIndex += 1
    if not witnessPassed:
      return false
  return true

proc pollardFactor(value: int64): int64 =
  if (value and 1) == 0:
    return 2
  if value mod 3 == 0:
    return 3
  var constantValue: int64 = 1
  while true:
    var tortoise: int64 = 2
    var hare: int64 = 2
    var foundFactor: int64 = 1
    var stepCount = 0
    while foundFactor == 1 and stepCount < 200000:
      tortoise = (multiplyMod(tortoise, tortoise, value) + constantValue) mod value
      hare = (multiplyMod(hare, hare, value) + constantValue) mod value
      hare = (multiplyMod(hare, hare, value) + constantValue) mod value
      var difference = tortoise - hare
      if difference < 0:
        difference = -difference
      foundFactor = gcdIntegers(difference, value)
      stepCount += 1
    if foundFactor > 1 and foundFactor < value:
      return foundFactor
    constantValue += 1

proc collectFactors(value: int64, factors: var seq[int64]) =
  if value <= 1:
    return
  if isPrimeNumber(value):
    factors.add value
    return
  let divisor = pollardFactor(value)
  collectFactors(divisor, factors)
  collectFactors(value div divisor, factors)

proc sortFactors(factors: var seq[int64]) =
  for sortIndex in 1 .. factors.len - 1:
    let keyFactor = factors[sortIndex]
    var scanIndex = sortIndex - 1
    while scanIndex >= 0 and factors[scanIndex] > keyFactor:
      factors[scanIndex + 1] = factors[scanIndex]
      scanIndex -= 1
    factors[scanIndex + 1] = keyFactor

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let maxDigits = int64(nextInt(inputData, scanPos))
  let divisorCount = nextInt(inputData, scanPos)
  var divisors = newSeq[int64](divisorCount)
  for divisorIndex in 0 .. divisorCount - 1:
    divisors[divisorIndex] = int64(nextInt(inputData, scanPos))
  var bestLength: int64 = 1
  var bestDigit: int64 = 0
  block searchDone:
    for divisor in divisors:
      for digit in 1 .. 9:
        let sharedFactor = gcdIntegers(divisor, int64(digit))
        let reducedDivisor = divisor div sharedFactor
        if reducedDivisor mod 2 == 0 or reducedDivisor mod 5 == 0:
          continue
        let modulusValue = 9 * reducedDivisor
        var primeFactors = newSeq[int64]()
        collectFactors(reducedDivisor, primeFactors)
        sortFactors(primeFactors)
        var phiValue = modulusValue div 3 * 2
        var previousPrime: int64 = 0
        for primeFactor in primeFactors:
          if primeFactor != previousPrime and primeFactor != 3:
            phiValue = phiValue div primeFactor * (primeFactor - 1)
          previousPrime = primeFactor
        var phiFactors = newSeq[int64]()
        collectFactors(phiValue, phiFactors)
        sortFactors(phiFactors)
        var exponentValue = phiValue
        previousPrime = 0
        for primeFactor in phiFactors:
          if primeFactor == previousPrime:
            continue
          previousPrime = primeFactor
          while exponentValue mod primeFactor == 0 and
                powerModulo(10, exponentValue div primeFactor, modulusValue) == 1:
            exponentValue = exponentValue div primeFactor
        let candidateLength = (maxDigits div exponentValue) * exponentValue
        if candidateLength >= 1 and
              (candidateLength > bestLength or
               (candidateLength == bestLength and int64(digit) > bestDigit)):
          bestLength = candidateLength
          bestDigit = int64(digit)
        if bestLength == maxDigits and bestDigit == 9:
          break searchDone
  appendOutput($(bestLength) & " " & $(bestDigit))
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
