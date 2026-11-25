import algorithm

const flushBlockBytes = 1 shl 17
const answerModulus = 1000000007
const maxFieldValue = 100000
const maxPrimeExponent = 16

type QueryRecord = object
  leftIndex: int
  rightIndex: int
  suppressedPrime: int
  resultIndex: int

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

proc modPow(baseValue: int64, exponentValue: int64, modulusValue: int64): int64 =
  result = 1
  var current = baseValue mod modulusValue
  var remaining = exponentValue
  while remaining > 0:
    if (remaining and 1) == 1:
      result = result * current mod modulusValue
    current = current * current mod modulusValue
    remaining = remaining div 2

var primes = newSeq[int](0)
var compositeFlags = newSeq[bool](maxFieldValue + 1)
var primeIndexByValue = newSeq[int](maxFieldValue + 1)
for primeValue in 2 .. maxFieldValue:
  primeIndexByValue[primeValue] = -1
for candidate in 2 .. maxFieldValue:
  if not compositeFlags[candidate]:
    primeIndexByValue[candidate] = primes.len
    primes.add candidate
    var multiple = candidate * 2
    while multiple <= maxFieldValue:
      compositeFlags[multiple] = true
      multiple += candidate

let fieldCount = nextInt(inputData, scanPos)
let eventCount = nextInt(inputData, scanPos)
var factorsByPosition = newSeq[seq[int]](fieldCount + 1)
var exponentsByPosition = newSeq[seq[int]](fieldCount + 1)
for position in 1 .. fieldCount:
  var fieldValue = nextInt(inputData, scanPos)
  var primeIndexes = newSeq[int](0)
  var primeExponents = newSeq[int](0)
  for primeValue in primes:
    if primeValue * primeValue > fieldValue:
      break
    if fieldValue mod primeValue == 0:
      var exponent = 0
      while fieldValue mod primeValue == 0:
        fieldValue = fieldValue div primeValue
        exponent += 1
      primeIndexes.add primeIndexByValue[primeValue]
      primeExponents.add exponent
  if fieldValue > 1:
    primeIndexes.add primeIndexByValue[fieldValue]
    primeExponents.add 1
  factorsByPosition[position] = primeIndexes
  exponentsByPosition[position] = primeExponents

var queries = newSeq[QueryRecord](0)
var suppressedPrime = 1
for eventIndex in 0 .. eventCount - 1:
  let eventType = nextInt(inputData, scanPos)
  if eventType == 1:
    suppressedPrime = nextInt(inputData, scanPos)
  else:
    let leftIndex = nextInt(inputData, scanPos)
    let rightIndex = nextInt(inputData, scanPos)
    queries.add QueryRecord(leftIndex: leftIndex, rightIndex: rightIndex, suppressedPrime: suppressedPrime, resultIndex: queries.len)

let primeCount = primes.len
let exponentStride = maxPrimeExponent + 1
var powerByPrime = newSeq[seq[int64]](primeCount)
var inversePowerByPrime = newSeq[seq[int64]](primeCount)
for primeIndex in 0 .. primeCount - 1:
  var powers = newSeq[int64](exponentStride)
  var inversePowers = newSeq[int64](exponentStride)
  powers[0] = 1
  inversePowers[0] = 1
  var runningPower: int64 = int64(primes[primeIndex]) mod int64(answerModulus)
  let primeInverse = modPow(int64(primes[primeIndex]), int64(answerModulus - 2), int64(answerModulus))
  var runningInverse: int64 = 1
  for exponent in 1 .. maxPrimeExponent:
    powers[exponent] = runningPower
    runningInverse = runningInverse * primeInverse mod int64(answerModulus)
    inversePowers[exponent] = runningInverse
    runningPower = runningPower * int64(primes[primeIndex]) mod int64(answerModulus)
  powerByPrime[primeIndex] = powers
  inversePowerByPrime[primeIndex] = inversePowers

var moBlockSize = 1
while moBlockSize * moBlockSize < fieldCount:
  moBlockSize += 1

proc compareQueries(leftQuery, rightQuery: QueryRecord): int =
  let leftBlock = leftQuery.leftIndex div moBlockSize
  let rightBlock = rightQuery.leftIndex div moBlockSize
  if leftBlock != rightBlock:
    return leftBlock - rightBlock
  if leftBlock mod 2 == 0:
    return leftQuery.rightIndex - rightQuery.rightIndex
  return rightQuery.rightIndex - leftQuery.rightIndex

sort(queries, compareQueries)

var frequencies = newSeq[int](primeCount * exponentStride)
var maximumExponents = newSeq[int](primeCount)
var fullProduct: int64 = 1

proc addPosition(position: int) =
  for factorIndex in 0 .. factorsByPosition[position].len - 1:
    let primeIndex = factorsByPosition[position][factorIndex]
    let exponent = exponentsByPosition[position][factorIndex]
    let slot = primeIndex * exponentStride + exponent
    frequencies[slot] += 1
    if exponent > maximumExponents[primeIndex]:
      let previousMaximum = maximumExponents[primeIndex]
      fullProduct = fullProduct * powerByPrime[primeIndex][exponent] mod int64(answerModulus)
      if previousMaximum > 0:
        fullProduct = fullProduct * inversePowerByPrime[primeIndex][previousMaximum] mod int64(answerModulus)
      maximumExponents[primeIndex] = exponent

proc removePosition(position: int) =
  for factorIndex in 0 .. factorsByPosition[position].len - 1:
    let primeIndex = factorsByPosition[position][factorIndex]
    let exponent = exponentsByPosition[position][factorIndex]
    let slot = primeIndex * exponentStride + exponent
    frequencies[slot] -= 1
    if exponent == maximumExponents[primeIndex] and frequencies[slot] == 0:
      var newMaximum = exponent - 1
      while newMaximum > 0 and frequencies[primeIndex * exponentStride + newMaximum] == 0:
        newMaximum -= 1
      fullProduct = fullProduct * inversePowerByPrime[primeIndex][exponent] mod int64(answerModulus)
      if newMaximum > 0:
        fullProduct = fullProduct * powerByPrime[primeIndex][newMaximum] mod int64(answerModulus)
      maximumExponents[primeIndex] = newMaximum

var answers = newSeq[int64](queries.len)
var currentLeft = 1
var currentRight = 0
for queryIndex in 0 .. queries.len - 1:
  let currentQuery = queries[queryIndex]
  while currentLeft > currentQuery.leftIndex:
    currentLeft -= 1
    addPosition(currentLeft)
  while currentRight < currentQuery.rightIndex:
    currentRight += 1
    addPosition(currentRight)
  while currentLeft < currentQuery.leftIndex:
    removePosition(currentLeft)
    currentLeft += 1
  while currentRight > currentQuery.rightIndex:
    removePosition(currentRight)
    currentRight -= 1
  var answer = fullProduct
  if currentQuery.suppressedPrime != 1:
    let primeIndex = primeIndexByValue[currentQuery.suppressedPrime]
    if primeIndex >= 0:
      answer = answer * inversePowerByPrime[primeIndex][maximumExponents[primeIndex]] mod int64(answerModulus)
  answers[currentQuery.resultIndex] = answer

for answerIndex in 0 .. answers.len - 1:
  appendOutput($answers[answerIndex])
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
