const flushBlockBytes = 1 shl 17
const firstDigitValue = 48

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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc modMultiply(leftValue: int64, rightValue: int64, modulus: int64): int64 =
  var product: int64 = 0
  var baseValue = leftValue mod modulus
  var factor = rightValue
  while factor > 0:
    if (factor and 1) == 1:
      product = product + baseValue
      if product >= modulus:
        product = product - modulus
    baseValue = baseValue + baseValue
    if baseValue >= modulus:
      baseValue = baseValue - modulus
    factor = factor div 2
  return product

proc modPower(baseValue: int64, exponent: int64, modulus: int64): int64 =
  var power = exponent
  var current = baseValue mod modulus
  var powerResult: int64 = 1
  while power > 0:
    if (power and 1) == 1:
      powerResult = modMultiply(powerResult, current, modulus)
    current = modMultiply(current, current, modulus)
    power = power div 2
  return powerResult

proc isPrime(candidate: int64): bool =
  if candidate < 2:
    return false
  let smallPrimes = [int64(2), 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37]
  for primeValue in smallPrimes:
    if candidate == primeValue:
      return true
    if candidate mod primeValue == 0:
      return false
  var oddPart = candidate - 1
  var powerOfTwo = 0
  while (oddPart and 1) == 0:
    oddPart = oddPart div 2
    powerOfTwo += 1
  let witnessValues = [int64(2), 3, 5, 7, 11, 13, 17]
  for witness in witnessValues:
    var observed = modPower(witness, oddPart, candidate)
    if observed == 1 or observed == candidate - 1:
      continue
    var isWitness = true
    for roundIndex in 1 .. powerOfTwo - 1:
      observed = modMultiply(observed, observed, candidate)
      if observed == candidate - 1:
        isWitness = false
        break
    if isWitness:
      return false
  return true

let testCount = nextInt(inputData, scanPos)
for testIndex in 0 .. testCount - 1:
  let threshold = int64(nextInt(inputData, scanPos))
  var candidate = threshold + 2
  if candidate > 2 and (candidate mod 2) == 0:
    candidate += 1
  while not isPrime(candidate):
    candidate += 2
  appendOutput($candidate)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
