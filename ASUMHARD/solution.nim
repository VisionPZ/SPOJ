const flushBlockBytes = 1 shl 17
const modulus = 1234567891'i64
const maximumPower = 321
const tableLimit = maximumPower + 3

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

proc powerMod(baseValue: int64, exponent: int64): int64 =
  var powerResult = 1'i64
  var current = baseValue mod modulus
  var powerLeft = exponent
  while powerLeft > 0:
    if (powerLeft and 1'i64) == 1'i64:
      powerResult = powerResult * current mod modulus
    current = current * current mod modulus
    powerLeft = powerLeft shr 1
  return powerResult

var inverseValue = newSeq[int64](tableLimit + 2)
var factorialValue = newSeq[int64](tableLimit + 2)
var inverseFactorial = newSeq[int64](tableLimit + 2)
inverseValue[1] = 1'i64
factorialValue[0] = 1'i64
for index in 2 .. tableLimit + 1:
  inverseValue[index] = modulus - (modulus div int64(index)) * inverseValue[int(modulus mod int64(index))] mod modulus
for index in 1 .. tableLimit + 1:
  factorialValue[index] = factorialValue[index - 1] * int64(index) mod modulus
inverseFactorial[tableLimit + 1] = powerMod(factorialValue[tableLimit + 1], modulus - 2)
var reverseIndex = tableLimit + 1
while reverseIndex >= 1:
  inverseFactorial[reverseIndex - 1] = inverseFactorial[reverseIndex] * int64(reverseIndex) mod modulus
  reverseIndex -= 1

proc binomial(topValue: int, bottomValue: int): int64 =
  if bottomValue < 0 or bottomValue > topValue:
    return 0'i64
  return factorialValue[topValue] * inverseFactorial[bottomValue] mod modulus * inverseFactorial[topValue - bottomValue] mod modulus

var bernoulli = newSeq[int64](tableLimit + 2)
bernoulli[0] = 1'i64
for order in 1 .. tableLimit:
  var runningSum = 0'i64
  for lower in 0 .. order - 1:
    runningSum = (runningSum + binomial(order + 1, lower) * bernoulli[lower]) mod modulus
  bernoulli[order] = (modulus - runningSum) * inverseValue[order + 1] mod modulus

var coefficient = newSeq[seq[int64]](tableLimit)
for powerIndex in 0 .. tableLimit - 1:
  coefficient[powerIndex] = newSeq[int64](powerIndex + 1)
  for lower in 0 .. powerIndex:
    var term = binomial(powerIndex + 1, lower) * bernoulli[lower] mod modulus
    if (lower and 1) == 1:
      term = modulus - term
    coefficient[powerIndex][lower] = term * inverseValue[powerIndex + 1] mod modulus

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let limitValue = int64(nextInt(inputData, scanPos))
  let power = nextInt(inputData, scanPos)
  var powers = newSeq[int64](power + 3)
  powers[0] = 1'i64
  for exponent in 1 .. power + 2:
    powers[exponent] = powers[exponent - 1] * (limitValue mod modulus) mod modulus
  var firstSum = 0'i64
  for lower in 0 .. power:
    firstSum = (firstSum + coefficient[power][lower] * powers[power + 1 - lower]) mod modulus
  var secondSum = 0'i64
  for lower in 0 .. power + 1:
    secondSum = (secondSum + coefficient[power + 1][lower] * powers[power + 2 - lower]) mod modulus
  let answerValue = ((limitValue + 1) mod modulus * firstSum - secondSum) mod modulus
  appendOutput($answerValue)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
