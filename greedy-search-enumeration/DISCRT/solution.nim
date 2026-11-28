import tables
import math

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc gcdValues(firstValue, secondValue: int64): int64 =
  var larger = firstValue
  var smaller = secondValue
  while smaller != 0:
    let remainder = larger mod smaller
    larger = smaller
    smaller = remainder
  return larger

proc extendedGcd(firstValue, secondValue: int64, firstCoeff, secondCoeff: var int64): int64 =
  if secondValue == 0:
    firstCoeff = 1
    secondCoeff = 0
    return firstValue
  var innerFirst: int64 = 0
  var innerSecond: int64 = 0
  let recursiveValue = extendedGcd(secondValue, firstValue mod secondValue, innerFirst, innerSecond)
  firstCoeff = innerSecond
  secondCoeff = innerFirst - (firstValue div secondValue) * innerSecond
  return recursiveValue

proc modInverse(value, modulus: int64): int64 =
  var firstCoeff: int64 = 0
  var secondCoeff: int64 = 0
  discard extendedGcd(value, modulus, firstCoeff, secondCoeff)
  let inverse = firstCoeff mod modulus
  if inverse < 0:
    return inverse + modulus
  return inverse

proc powMod(base, exponent, modulus: int64): int64 =
  var powerResult: int64 = 1
  var runningBase = base mod modulus
  var runningExponent = exponent
  while runningExponent > 0:
    if (runningExponent and 1'i64) != 0:
      powerResult = (powerResult * runningBase) mod modulus
    runningBase = (runningBase * runningBase) mod modulus
    runningExponent = runningExponent div 2
  return powerResult

proc primeFactors(value: int64): seq[int64] =
  var factors = newSeq[int64]()
  var remainder = value
  var candidate: int64 = 2
  while candidate * candidate <= remainder:
    if remainder mod candidate == 0:
      factors.add candidate
      while remainder mod candidate == 0:
        remainder = remainder div candidate
    if candidate == 2:
      candidate = 3
    else:
      candidate += 2
  if remainder > 1:
    factors.add remainder
  return factors

proc primitiveRoot(prime: int64): int64 =
  let factors = primeFactors(prime - 1)
  var candidate: int64 = 2
  while true:
    var isRoot = true
    for factor in factors:
      if powMod(candidate, (prime - 1) div factor, prime) == 1:
        isRoot = false
        break
    if isRoot:
      return candidate
    candidate += 1

proc liftRoot(root, prime, exponent: int64): int64 =
  if exponent == 1:
    return root
  let primeSquare = prime * prime
  if powMod(root, prime - 1, primeSquare) == 1:
    return root + prime
  return root

proc discreteLogarithm(root, target, modulus, groupOrder: int64): int64 =
  let stepCount = int(sqrt(float64(groupOrder))) + 1
  var babyTable = initTable[int64, int]()
  var power: int64 = 1
  for step in 0 .. stepCount - 1:
    if not babyTable.hasKey(power):
      babyTable[power] = step
    power = (power * root) mod modulus
  let stride = modInverse(powMod(root, int64(stepCount), modulus), modulus)
  var current = target mod modulus
  for chunk in 0 .. stepCount:
    if babyTable.hasKey(current):
      let found = int64(chunk * stepCount + babyTable[current])
      return found mod groupOrder
    current = (current * stride) mod modulus
  return -1

proc appendSolutions(solutions: seq[int64]) =
  appendOutput($solutions.len)
  outputBuffer.add '\n'
  for value in solutions:
    appendOutput($value)
    outputBuffer.add '\n'

let modulus = int64(nextInt(inputData, scanPos))
let exponentK = int64(nextInt(inputData, scanPos))
let target = int64(nextInt(inputData, scanPos))

var prime = modulus
var primeExponent: int64 = 0
var trial: int64 = 2
while trial * trial <= prime:
  if prime mod trial == 0:
    prime = trial
    break
  if trial == 2:
    trial = 3
  else:
    trial += 2
var remainderValue = modulus
while remainderValue mod prime == 0:
  remainderValue = remainderValue div prime
  primeExponent += 1
let groupOrder = (modulus div prime) * (prime - 1)

if exponentK == 0:
  var units = newSeq[int64]()
  if target == 1:
    for candidate in 0 .. modulus - 1:
      if gcdValues(candidate, modulus) == 1:
        units.add candidate
  appendSolutions(units)
else:
  let baseRoot = liftRoot(primitiveRoot(prime), prime, primeExponent)
  let logarithm = discreteLogarithm(baseRoot, target, modulus, groupOrder)
  var solutions = newSeq[int64]()
  if logarithm >= 0:
    let divisor = gcdValues(exponentK, groupOrder)
    if logarithm mod divisor == 0:
      let reducedModulus = groupOrder div divisor
      let reducedK = exponentK div divisor
      let reducedLog = logarithm div divisor
      let stepSize = (reducedLog * modInverse(reducedK mod reducedModulus, reducedModulus)) mod reducedModulus
      for count in 0 .. divisor - 1:
        let powerIndex = (stepSize + count * reducedModulus) mod groupOrder
        solutions.add powMod(baseRoot, powerIndex, modulus)
  if solutions.len > 1:
    for outerIndex in 1 .. solutions.len - 1:
      let carried = solutions[outerIndex]
      var innerIndex = outerIndex - 1
      while innerIndex >= 0 and solutions[innerIndex] > carried:
        solutions[innerIndex + 1] = solutions[innerIndex]
        innerIndex -= 1
      solutions[innerIndex + 1] = carried
  appendSolutions(solutions)
stdout.write outputBuffer
outputBuffer.setLen 0
