const flushBlockBytes = 1 shl 17
const modulusValue: int64 = 100000007

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

proc powerModulo(baseValue: int64, exponentValue: int64): int64 =
  var powerResult: int64 = 1
  var factor = baseValue mod modulusValue
  var exponentLeft = exponentValue
  while exponentLeft > 0:
    if (exponentLeft and 1) == 1:
      powerResult = powerResult * factor mod modulusValue
    factor = factor * factor mod modulusValue
    exponentLeft = exponentLeft shr 1
  return powerResult

let caseCount = nextInt(inputData, scanPos)
var peopleCounts = newSeq[int](caseCount)
var runLimits = newSeq[int](caseCount)
var maximumPeople = 0
for caseIndex in 0 .. caseCount - 1:
  peopleCounts[caseIndex] = nextInt(inputData, scanPos)
  runLimits[caseIndex] = nextInt(inputData, scanPos)
  if peopleCounts[caseIndex] > maximumPeople:
    maximumPeople = peopleCounts[caseIndex]

if maximumPeople < 1:
  maximumPeople = 1

var factorials = newSeq[int64](maximumPeople + 1)
var inverseFactorials = newSeq[int64](maximumPeople + 1)
var inverses = newSeq[int64](maximumPeople + 1)
var powersOfTwo = newSeq[int64](maximumPeople + 1)
var phiValues = newSeq[int](maximumPeople + 1)

factorials[0] = 1
for valueIndex in 1 .. maximumPeople:
  factorials[valueIndex] = factorials[valueIndex - 1] * int64(valueIndex) mod modulusValue
inverseFactorials[maximumPeople] = powerModulo(factorials[maximumPeople], modulusValue - 2)
for valueIndex in countdown(maximumPeople, 1):
  inverseFactorials[valueIndex - 1] = inverseFactorials[valueIndex] * int64(valueIndex) mod modulusValue
for valueIndex in 1 .. maximumPeople:
  inverses[valueIndex] = powerModulo(int64(valueIndex), modulusValue - 2)
powersOfTwo[0] = 1
for valueIndex in 1 .. maximumPeople:
  powersOfTwo[valueIndex] = powersOfTwo[valueIndex - 1] * 2 mod modulusValue
for valueIndex in 0 .. maximumPeople:
  phiValues[valueIndex] = valueIndex
for primeValue in 2 .. maximumPeople:
  if phiValues[primeValue] == primeValue:
    var multiple = primeValue
    while multiple <= maximumPeople:
      phiValues[multiple] = phiValues[multiple] div primeValue * (primeValue - 1)
      multiple = multiple + primeValue

proc binomialCoefficient(groupSize: int, chosenCount: int): int64 =
  if chosenCount < 0 or chosenCount > groupSize:
    return 0
  return factorials[groupSize] * inverseFactorials[chosenCount] mod modulusValue *
         inverseFactorials[groupSize - chosenCount] mod modulusValue

proc circularCount(patternLength: int, runLimit: int): int64 =
  var countValue = powersOfTwo[patternLength] - 1
  if countValue < 0:
    countValue = countValue + modulusValue
  if patternLength <= runLimit:
    countValue = (countValue + 1) mod modulusValue
  var cycleIndex = 1
  while cycleIndex * (runLimit + 2) <= patternLength:
    let remainder = patternLength - cycleIndex * (runLimit + 1) - 1
    var termValue = int64(patternLength) * inverses[cycleIndex] mod modulusValue
    termValue = termValue * binomialCoefficient(remainder, cycleIndex - 1) mod modulusValue
    termValue = termValue * powersOfTwo[remainder - cycleIndex + 1] mod modulusValue
    if (cycleIndex and 1) == 1:
      countValue = countValue - termValue
      if countValue < 0:
        countValue = countValue + modulusValue
    else:
      countValue = (countValue + termValue) mod modulusValue
    cycleIndex += 1
  return countValue mod modulusValue

for caseIndex in 0 .. caseCount - 1:
  let peopleCount = peopleCounts[caseIndex]
  let runLimit = runLimits[caseIndex]
  var rotationTotal: int64 = 0
  var divisor = 1
  while divisor <= peopleCount:
    if peopleCount mod divisor == 0:
      let quotient = peopleCount div divisor
      var fixedCount = circularCount(divisor, runLimit)
      if divisor <= runLimit and peopleCount > runLimit:
        fixedCount = fixedCount - 1
        if fixedCount < 0:
          fixedCount = fixedCount + modulusValue
      rotationTotal = (rotationTotal + int64(phiValues[quotient]) * fixedCount) mod modulusValue
    divisor += 1
  let answer = rotationTotal * inverses[peopleCount] mod modulusValue
  appendOutput($(answer))
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
