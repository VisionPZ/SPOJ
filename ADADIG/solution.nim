const flushBlockBytes = 1 shl 17
const modulusValue: int64 = 1000000007
const maxTarget = 300000

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

var factorials = newSeq[int64](maxTarget + 40)
var inverseFactorials = newSeq[int64](maxTarget + 40)

proc powerMod(baseValue: int64, exponentValue: int64): int64 =
  var basePart = baseValue
  var exponentPart = exponentValue
  var powerResult = 1'i64
  while exponentPart > 0:
    if (exponentPart and 1) == 1:
      powerResult = powerResult * basePart mod modulusValue
    basePart = basePart * basePart mod modulusValue
    exponentPart = exponentPart div 2
  return powerResult

factorials[0] = 1
for factIndex in 1 .. factorials.high:
  factorials[factIndex] = factorials[factIndex - 1] * int64(factIndex) mod modulusValue
inverseFactorials[factorials.high] = powerMod(factorials[factorials.high], modulusValue - 2)
var downIndex = factorials.high - 1
while downIndex >= 0:
  inverseFactorials[downIndex] = inverseFactorials[downIndex + 1] * int64(downIndex + 1) mod modulusValue
  downIndex -= 1

var currentTarget = 0
var digitMultiplicity = newSeq[int](10)
var accumulatedAnswer: int64 = 0

proc collectFactorizations(remaining: int, smallestDigit: int,
                           usedSum: int, usedCount: int) =
  if remaining == 1:
    let onesCount = currentTarget - usedSum
    if onesCount >= 0:
      var ways = factorials[usedCount + onesCount] * inverseFactorials[onesCount] mod modulusValue
      for digit in 2 .. 9:
        ways = ways * inverseFactorials[digitMultiplicity[digit]] mod modulusValue
      accumulatedAnswer = (accumulatedAnswer + ways) mod modulusValue
    return
  var digit = smallestDigit
  while digit <= 9:
    if remaining mod digit == 0:
      digitMultiplicity[digit] += 1
      collectFactorizations(remaining div digit, digit, usedSum + digit, usedCount + 1)
      digitMultiplicity[digit] -= 1
    digit += 1

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  currentTarget = nextInt(inputData, scanPos)
  accumulatedAnswer = 0
  for digit in 0 .. 9:
    digitMultiplicity[digit] = 0
  collectFactorizations(currentTarget, 2, 0, 0)
  appendOutput($accumulatedAnswer)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
