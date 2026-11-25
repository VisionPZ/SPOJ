const flushBlockBytes = 1 shl 17
const resultModulus = 1000000007'i64
const exponentModulus = 1000000006'i64
const primeFactor = 500000003'i64

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

proc powerModulo(baseValue: int64, exponentValue: int64, modulus: int64): int64 =
  var powerResult = 1'i64
  var currentBase = baseValue mod modulus
  var remaining = exponentValue
  while remaining > 0:
    if (remaining and 1) != 0:
      powerResult = (powerResult * currentBase) mod modulus
    currentBase = (currentBase * currentBase) mod modulus
    remaining = remaining shr 1
  return powerResult

let caseCount = nextInt(inputData, scanPos)
var baseValues = newSeq[int](caseCount)
var powerValues = newSeq[int](caseCount)
var combinationNs = newSeq[int](caseCount)
var largestN = 0
for caseIndex in 0 .. caseCount - 1:
  let baseValue = nextInt(inputData, scanPos)
  let powerValue = nextInt(inputData, scanPos)
  let combinationN = nextInt(inputData, scanPos)
  baseValues[caseIndex] = baseValue
  powerValues[caseIndex] = powerValue
  combinationNs[caseIndex] = combinationN
  if combinationN > largestN:
    largestN = combinationN

let factorialLimit = 2 * largestN
var factorials = newSeq[int64](factorialLimit + 1)
var inverseFactorials = newSeq[int64](factorialLimit + 1)
factorials[0] = 1'i64
for index in 1 .. factorialLimit:
  factorials[index] = (factorials[index - 1] * int64(index)) mod primeFactor
inverseFactorials[factorialLimit] = powerModulo(factorials[factorialLimit], primeFactor - 2, primeFactor)
var reverseIndex = factorialLimit
while reverseIndex > 0:
  inverseFactorials[reverseIndex - 1] = (inverseFactorials[reverseIndex] * int64(reverseIndex)) mod primeFactor
  reverseIndex -= 1

for caseIndex in 0 .. caseCount - 1:
  let combinationN = combinationNs[caseIndex]
  let doubledN = 2 * combinationN
  let centralModuloPrime = (factorials[doubledN] * inverseFactorials[combinationN]) mod primeFactor
  let centralValue = (centralModuloPrime * inverseFactorials[combinationN]) mod primeFactor
  var oddParity = 0
  if combinationN == 0:
    oddParity = 1
  else:
    oddParity = 0
  var adjust = oddParity - int(centralValue mod 2'i64)
  if adjust < 0:
    adjust += 2
  adjust = adjust mod 2
  let exponentBase = centralValue + primeFactor * int64(adjust)
  let reducedExponent = powerModulo(exponentBase, int64(powerValues[caseIndex]), exponentModulus)
  let answerValue = powerModulo(int64(baseValues[caseIndex]), reducedExponent, resultModulus)
  appendOutput($answerValue)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
