const flushBlockBytes = 1 shl 17
const primeModulus: int64 = 1000000007
const largePrime: int64 = 500000003
const smallPrimePower: int64 = 1681
const smallPrime: int64 = 41
const largePrimePower: int64 = 148721

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

proc modPow(baseValue, exponentValue, modulus: int64): int64 =
  var powerResult: int64 = 1
  var current = baseValue mod modulus
  var powerLeft = exponentValue
  while powerLeft > 0:
    if (powerLeft and 1) != 0:
      powerResult = powerResult * current mod modulus
    current = current * current mod modulus
    powerLeft = powerLeft div 2
  return powerResult

proc modInverse(value, modulus: int64): int64 =
  var oldRemainder = value mod modulus
  var newRemainder = modulus
  var oldCoefficient: int64 = 1
  var newCoefficient: int64 = 0
  while newRemainder != 0:
    let quotient = oldRemainder div newRemainder
    let nextRemainder = oldRemainder - quotient * newRemainder
    oldRemainder = newRemainder
    newRemainder = nextRemainder
    let nextCoefficient = oldCoefficient - quotient * newCoefficient
    oldCoefficient = newCoefficient
    newCoefficient = nextCoefficient
  return ((oldCoefficient mod modulus) + modulus) mod modulus

proc combineResidues(firstResidue, firstModulus, secondResidue, secondModulus: int64): int64 =
  let inverseFactor = modInverse(firstModulus mod secondModulus, secondModulus)
  var difference = (secondResidue - firstResidue) mod secondModulus
  if difference < 0:
    difference += secondModulus
  let offset = difference * inverseFactor mod secondModulus
  return (firstResidue + firstModulus * offset) mod (firstModulus * secondModulus)

proc buildPrefix(prime, primePower: int64): seq[int64] =
  var prefixProduct = newSeq[int64](int(primePower))
  prefixProduct[0] = 1
  for index in 1 .. int(primePower) - 1:
    var factor = int64(index)
    if int64(index) mod prime == 0:
      factor = 1
    prefixProduct[index] = prefixProduct[index - 1] * factor mod primePower
  return prefixProduct

proc pFreeFactorial(value, prime, primePower: int64, prefixProduct: seq[int64]): int64 =
  var factorialPart: int64 = 1
  var current = value
  let blockProduct = prefixProduct[int(primePower) - 1]
  while current > 0:
    factorialPart = factorialPart * modPow(blockProduct, current div primePower, primePower) mod primePower
    factorialPart = factorialPart * prefixProduct[int(current mod primePower)] mod primePower
    current = current div prime
  return factorialPart

proc centralModuloPrimePower(combinValue, prime, primePower: int64, prefixProduct: seq[int64]): int64 =
  let doubled = 2 * combinValue
  var valuation: int64 = 0
  var power = prime
  while power <= doubled:
    valuation += doubled div power - 2 * (combinValue div power)
    power *= prime
  var threshold: int64 = 1
  if primePower != prime:
    threshold = 2
  if valuation >= threshold:
    return 0
  let numerator = pFreeFactorial(doubled, prime, primePower, prefixProduct)
  let denominator = pFreeFactorial(combinValue, prime, primePower, prefixProduct)
  let inverseDenominator = modInverse(denominator, primePower)
  var binomialResidue = numerator * inverseDenominator mod primePower
  binomialResidue = binomialResidue * inverseDenominator mod primePower
  binomialResidue = binomialResidue * modPow(prime, valuation, primePower) mod primePower
  return binomialResidue

let prefixSmallPrime = buildPrefix(smallPrime, smallPrimePower)
let prefixLargePrime = buildPrefix(largePrimePower, largePrimePower)

let testCount = nextInt(inputData, scanPos)
for testIndex in 0 .. testCount - 1:
  let baseValue = int64(nextInt(inputData, scanPos))
  let powerBase = int64(nextInt(inputData, scanPos))
  let combinValue = int64(nextInt(inputData, scanPos))
  var answer: int64 = 0
  if baseValue == 0:
    if powerBase == 0:
      answer = 1
    else:
      answer = 0
  elif powerBase == 0:
    answer = 1
  else:
    let parityResidue: int64 = if combinValue == 0: 1 else: 0
    let smallResidue = centralModuloPrimePower(combinValue, smallPrime, smallPrimePower, prefixSmallPrime)
    let largeResidue = centralModuloPrimePower(combinValue, largePrimePower, largePrimePower, prefixLargePrime)
    var exponentResidue = combineResidues(parityResidue, 2, smallResidue, smallPrimePower)
    exponentResidue = combineResidues(exponentResidue, 2 * smallPrimePower, largeResidue, largePrimePower)
    let oddResidue: int64 = if (powerBase and 1) != 0: 1 else: 0
    let primeResidue = modPow(powerBase, exponentResidue, largePrime)
    let reducedExponent = combineResidues(oddResidue, 2, primeResidue, largePrime)
    answer = modPow(baseValue, reducedExponent, primeModulus)
  appendOutput($answer)
  appendOutput("\n")
stdout.write outputBuffer
outputBuffer.setLen 0
