const flushBlockBytes = 1 shl 17
const modulusValue = 1000000007
const maxBlockCount = 75

proc powerMod(baseValue: int64, exponentValue: int64): int64 =
  var baseRemainder = baseValue mod modulusValue
  var exponentLeft = exponentValue
  var resultValue = int64(1)
  while exponentLeft > 0:
    if (exponentLeft and 1) == 1:
      resultValue = resultValue * baseRemainder mod modulusValue
    baseRemainder = baseRemainder * baseRemainder mod modulusValue
    exponentLeft = exponentLeft div 2
  return resultValue

var factorialValues = newSeq[int64](maxBlockCount + 1)
var inverseFactorials = newSeq[int64](maxBlockCount + 1)
factorialValues[0] = 1
for indexValue in 1 .. maxBlockCount:
  factorialValues[indexValue] = factorialValues[indexValue - 1] * int64(indexValue) mod modulusValue
inverseFactorials[maxBlockCount] = powerMod(factorialValues[maxBlockCount], modulusValue - 2)
for indexValue in countdown(maxBlockCount - 1, 0):
  inverseFactorials[indexValue] = inverseFactorials[indexValue + 1] * int64(indexValue + 1) mod modulusValue

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

proc countPaintings(blockCounts: seq[int]): int64 =
  var totalBlocks = 0
  for colorCount in blockCounts:
    totalBlocks += colorCount
  var coefficients = newSeq[int64](totalBlocks + 1)
  coefficients[0] = 1
  var degreeNow = 0
  for colorCount in blockCounts:
    var localPoly = newSeq[int64](colorCount)
    for mergeCount in 0 .. colorCount - 1:
      var chooseValue = inverseFactorials[mergeCount] * inverseFactorials[colorCount - 1 - mergeCount] mod modulusValue
      chooseValue = chooseValue * factorialValues[colorCount - 1] mod modulusValue
      chooseValue = chooseValue * inverseFactorials[colorCount - mergeCount] mod modulusValue
      if (mergeCount and 1) == 1:
        localPoly[mergeCount] = modulusValue - chooseValue
      else:
        localPoly[mergeCount] = chooseValue
    var nextCoefficients = newSeq[int64](degreeNow + colorCount + 1)
    for degreeIndex in 0 .. degreeNow:
      if coefficients[degreeIndex] == 0:
        continue
      for mergeCount in 0 .. colorCount - 1:
        var addValue = coefficients[degreeIndex] * localPoly[mergeCount] mod modulusValue
        nextCoefficients[degreeIndex + mergeCount] = (nextCoefficients[degreeIndex + mergeCount] + addValue) mod modulusValue
    coefficients = nextCoefficients
    degreeNow += colorCount - 1
  var answerValue: int64 = 0
  for degreeIndex in 0 .. degreeNow:
    answerValue = (answerValue + coefficients[degreeIndex] * factorialValues[totalBlocks - degreeIndex]) mod modulusValue
  return answerValue

while true:
  let colorKinds = nextInt(inputData, scanPos)
  if colorKinds == 0:
    break
  var blockCounts = newSeq[int](colorKinds)
  for colorIndex in 0 .. colorKinds - 1:
    blockCounts[colorIndex] = nextInt(inputData, scanPos)
  appendOutput($countPaintings(blockCounts))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
