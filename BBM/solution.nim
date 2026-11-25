const flushBlockBytes = 1 shl 17
const modulusValue = 1000000007'u64
const blockStride = 262144
const directLimit = 200000

proc mulmod128(leftValue, rightValue, modulusValue: uint64): uint64 {.importc: "mulmod128_c", nodecl.}
{.emit: """
static inline unsigned long long mulmod128_c(unsigned long long leftValue, unsigned long long rightValue, unsigned long long modulusValue) {
  return (unsigned long long)(((unsigned __int128)leftValue * (unsigned __int128)rightValue) % (unsigned __int128)modulusValue);
}
""".}

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

proc powerMod(baseValue, exponentValue: uint64): uint64 =
  var powerResult = 1'u64
  var currentBase = baseValue mod modulusValue
  var currentExponent = exponentValue
  while currentExponent > 0'u64:
    if (currentExponent and 1'u64) == 1'u64:
      powerResult = mulmod128(powerResult, currentBase, modulusValue)
    currentBase = mulmod128(currentBase, currentBase, modulusValue)
    currentExponent = currentExponent shr 1
  return powerResult

var precomputedFactorials = newSeq[uint64](4096)
for blockIndex in 0 .. 4095:
  precomputedFactorials[blockIndex] = uint64(nextInt(inputData, scanPos))
let caseCount = nextInt(inputData, scanPos)

var busCounts = newSeq[int](caseCount)
var busCapacities = newSeq[int](caseCount)
var largestSize = 0
for caseIndex in 0 .. caseCount - 1:
  busCounts[caseIndex] = nextInt(inputData, scanPos)
  busCapacities[caseIndex] = nextInt(inputData, scanPos)
  let candidateSize = busCounts[caseIndex] * busCapacities[caseIndex]
  if candidateSize > largestSize:
    largestSize = candidateSize

var directFactorials = newSeq[uint64](directLimit + 1)
directFactorials[0] = 1'u64
for numberValue in 1 .. directLimit:
  directFactorials[numberValue] = mulmod128(directFactorials[numberValue - 1], uint64(numberValue), modulusValue)

proc factorialModulo(argument: int): uint64 =
  if argument <= directLimit:
    return directFactorials[argument]
  let blockIndex = argument div blockStride
  var factorialResult = precomputedFactorials[blockIndex]
  var numberValue = blockIndex * blockStride + 1
  while numberValue <= argument:
    factorialResult = mulmod128(factorialResult, uint64(numberValue), modulusValue)
    numberValue += 1
  return factorialResult

for caseIndex in 0 .. caseCount - 1:
  let totalSize = busCounts[caseIndex] * busCapacities[caseIndex]
  let totalFactorial = factorialModulo(totalSize)
  var answer = 0'u64
  for divisor in 1 .. totalSize:
    if totalSize mod divisor == 0:
      let groupCount = totalSize div divisor
      let divisorFactorial = factorialModulo(divisor)
      let groupFactorial = factorialModulo(groupCount)
      let denominator = mulmod128(powerMod(divisorFactorial, uint64(groupCount)),
                                  groupFactorial, modulusValue)
      let inverseDenominator = powerMod(denominator, modulusValue - 2'u64)
      let term = mulmod128(totalFactorial, inverseDenominator, modulusValue)
      answer = (answer + term) mod modulusValue
  appendOutput($answer)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
