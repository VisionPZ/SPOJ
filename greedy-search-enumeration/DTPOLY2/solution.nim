const flushBlockBytes = 1 shl 17

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

proc powerMod(baseValue, exponentValue, modulusValue: uint64): uint64 =
  var powerResult = 1'u64
  var currentBase = baseValue mod modulusValue
  var currentExponent = exponentValue
  while currentExponent > 0'u64:
    if (currentExponent and 1'u64) == 1'u64:
      powerResult = mulmod128(powerResult, currentBase, modulusValue)
    currentBase = mulmod128(currentBase, currentBase, modulusValue)
    currentExponent = currentExponent shr 1
  return powerResult

proc primeFactorCount(factorialArgument, primeValue: int): int =
  var totalCount = 0
  var primePower = primeValue
  while primePower <= factorialArgument:
    totalCount += factorialArgument div primePower
    if primePower > factorialArgument div primeValue:
      break
    primePower *= primeValue
  return totalCount

proc integerFactorCount(value, primeValue: int): int =
  var remaining = value
  var totalCount = 0
  while remaining mod primeValue == 0:
    remaining = remaining div primeValue
    totalCount += 1
  return totalCount

var polygonSizes = newSeq[int]()
var pieceCounts = newSeq[int]()
var moduli = newSeq[int]()
var largestArgument = 0
while scanPos < inputData.len:
  let polygonSize = nextInt(inputData, scanPos)
  let pieceCount = nextInt(inputData, scanPos)
  let modulusValue = nextInt(inputData, scanPos)
  if polygonSize == 0 and pieceCount == 0 and modulusValue == 0:
    break
  polygonSizes.add polygonSize
  pieceCounts.add pieceCount
  moduli.add modulusValue
  let upperArgument = polygonSize + pieceCount - 2
  if upperArgument > largestArgument:
    largestArgument = upperArgument

var isComposite = newSeq[bool](largestArgument + 1)
var primes = newSeq[int]()
for candidate in 2 .. largestArgument:
  if not isComposite[candidate]:
    primes.add candidate
    if int64(candidate) * int64(candidate) <= int64(largestArgument):
      var multiple = candidate * candidate
      while multiple <= largestArgument:
        isComposite[multiple] = true
        multiple += candidate

for caseIndex in 0 .. polygonSizes.len - 1:
  let polygonSize = polygonSizes[caseIndex]
  let pieceCount = pieceCounts[caseIndex]
  let modulusValue = uint64(moduli[caseIndex])
  var answer = 1'u64
  for primeIndex in 0 .. primes.len - 1:
    let primeValue = primes[primeIndex]
    if primeValue > largestArgument:
      break
    if primeValue > polygonSize + pieceCount - 2:
      break
    let firstBinomialExponent = primeFactorCount(polygonSize + pieceCount - 2, primeValue) -
                                primeFactorCount(pieceCount - 1, primeValue) -
                                primeFactorCount(polygonSize - 1, primeValue)
    let secondBinomialExponent = primeFactorCount(polygonSize - 3, primeValue) -
                                 primeFactorCount(pieceCount - 1, primeValue) -
                                 primeFactorCount(polygonSize - pieceCount - 2, primeValue)
    let pieceExponent = integerFactorCount(pieceCount, primeValue)
    let netExponent = firstBinomialExponent + secondBinomialExponent - pieceExponent
    if netExponent > 0:
      answer = mulmod128(answer, powerMod(uint64(primeValue), uint64(netExponent), modulusValue), modulusValue)
  appendOutput($answer)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
