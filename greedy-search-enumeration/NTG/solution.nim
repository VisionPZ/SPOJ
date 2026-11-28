const flushBlockBytes = 1 shl 17
const moduloBase = 1000000007'i64

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

proc powerMod(baseValue: int64, exponentValue: int64): int64 =
  result = 1'i64
  var currentBase = baseValue mod moduloBase
  var remainingExponent = exponentValue
  while remainingExponent > 0'i64:
    if (remainingExponent and 1'i64) == 1'i64:
      result = result * currentBase mod moduloBase
    currentBase = currentBase * currentBase mod moduloBase
    remainingExponent = remainingExponent shr 1

let exponentK = int64(nextInt(inputData, scanPos))
let attackCount = nextInt(inputData, scanPos)
var queryLefts = newSeq[int](attackCount)
var queryRights = newSeq[int](attackCount)
var largestRight = 0
for attackIndex in 0 .. attackCount - 1:
  queryLefts[attackIndex] = nextInt(inputData, scanPos)
  queryRights[attackIndex] = nextInt(inputData, scanPos)
  if queryRights[attackIndex] > largestRight:
    largestRight = queryRights[attackIndex]

var totientValues = newSeq[int](largestRight + 1)
for valueIndex in 0 .. largestRight:
  totientValues[valueIndex] = valueIndex
for primeValue in 2 .. largestRight:
  if totientValues[primeValue] == primeValue:
    var multipleValue = primeValue
    while multipleValue <= largestRight:
      totientValues[multipleValue] = totientValues[multipleValue] div primeValue * (primeValue - 1)
      multipleValue += primeValue

var primePowerValues = newSeq[int64](largestRight + 1)
for baseValue in 1 .. largestRight:
  primePowerValues[baseValue] = powerMod(int64(baseValue), exponentK)

var intervalTotals = newSeq[int64](largestRight + 1)
for divisorValue in 1 .. largestRight:
  let divisorPower = primePowerValues[divisorValue]
  var quotientValue = 1
  while divisorValue * quotientValue <= largestRight:
    let targetIndex = divisorValue * quotientValue
    intervalTotals[targetIndex] = (intervalTotals[targetIndex] + divisorPower * int64(totientValues[quotientValue])) mod moduloBase
    quotientValue += 1

var prefixTotals = newSeq[int64](largestRight + 1)
for valueIndex in 1 .. largestRight:
  prefixTotals[valueIndex] = (prefixTotals[valueIndex - 1] + intervalTotals[valueIndex]) mod moduloBase

for attackIndex in 0 .. attackCount - 1:
  let leftBound = queryLefts[attackIndex]
  let rightBound = queryRights[attackIndex]
  var answerValue = prefixTotals[rightBound] - prefixTotals[leftBound - 1]
  if answerValue < 0'i64:
    answerValue += moduloBase
  appendOutput($answerValue)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
