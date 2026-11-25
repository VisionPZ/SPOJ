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

type
  CountProfile = object
    values: seq[int64]
    amounts: seq[int64]

proc addAmount(profile: var CountProfile, key: int64, amount: int64) =
  var index = 0
  while index < profile.values.len:
    if profile.values[index] == key:
      profile.amounts[index] = profile.amounts[index] + amount
      return
    index += 1
  profile.values.add key
  profile.amounts.add amount

proc buildProfile(firstSide: int64, secondSide: int64): CountProfile =
  if firstSide == 0 or secondSide == 0:
    result.values = @[]
    result.amounts = @[]
    return result
  var largerSide = firstSide
  var smallerSide = secondSide
  if largerSide < smallerSide:
    let temporarySide = largerSide
    largerSide = smallerSide
    smallerSide = temporarySide
  var highestPower = 0
  while (int64(1) shl (highestPower + 1)) <= largerSide:
    highestPower += 1
  let blockSize = int64(1) shl highestPower
  if largerSide == blockSize:
    result.values = @[smallerSide]
    result.amounts = @[blockSize]
    return result
  let largerRemainder = largerSide - blockSize
  if smallerSide > blockSize:
    let smallerRemainder = smallerSide - blockSize
    let childProfile = buildProfile(largerRemainder, smallerRemainder)
    var childTotal: int64 = 0
    for amount in childProfile.amounts:
      childTotal = childTotal + amount
    result.values = @[]
    result.amounts = @[]
    for index in 0 .. childProfile.values.len - 1:
      addAmount(result, childProfile.values[index] + blockSize, childProfile.amounts[index])
    let missingAmount = blockSize - childTotal
    if missingAmount > 0:
      addAmount(result, blockSize, missingAmount)
    addAmount(result, largerRemainder + smallerRemainder, blockSize)
    return result
  let childProfile = buildProfile(largerRemainder, smallerSide)
  var childTotal: int64 = 0
  for amount in childProfile.amounts:
    childTotal = childTotal + amount
  result.values = @[]
  result.amounts = @[]
  for index in 0 .. childProfile.values.len - 1:
    addAmount(result, childProfile.values[index], childProfile.amounts[index])
  let missingAmount = blockSize - childTotal
  if missingAmount > 0:
    addAmount(result, 0, missingAmount)
  addAmount(result, smallerSide, blockSize)
  return result

proc modPow(baseValue: int64, exponentValue: int64, modulus: int64): int64 =
  var currentBase = baseValue mod modulus
  var remainingExponent = exponentValue
  result = 1
  while remainingExponent > 0:
    if (remainingExponent and 1) == 1:
      result = result * currentBase mod modulus
    currentBase = currentBase * currentBase mod modulus
    remainingExponent = remainingExponent shr 1

let caseCount = nextInt(inputData, scanPos)
let primeModulus = int64(nextInt(inputData, scanPos))
var rowCounts = newSeq[int](caseCount)
var columnCounts = newSeq[int](caseCount)
var maximumSmallSide = 0
for caseIndex in 0 .. caseCount - 1:
  rowCounts[caseIndex] = nextInt(inputData, scanPos)
  columnCounts[caseIndex] = nextInt(inputData, scanPos)
  let smallSide = min(rowCounts[caseIndex], columnCounts[caseIndex])
  if smallSide > maximumSmallSide:
    maximumSmallSide = smallSide

var factorials = newSeq[int64](maximumSmallSide + 1)
factorials[0] = 1
for value in 1 .. maximumSmallSide:
  factorials[value] = factorials[value - 1] * int64(value) mod primeModulus

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

for caseIndex in 0 .. caseCount - 1:
  let valueProfile = buildProfile(int64(rowCounts[caseIndex]), int64(columnCounts[caseIndex]))
  var answer: int64 = 1
  for index in 0 .. valueProfile.values.len - 1:
    let countValue = valueProfile.values[index]
    let multiplicity = valueProfile.amounts[index]
    if countValue == 0:
      continue
    answer = answer * modPow(factorials[int(countValue)], multiplicity, primeModulus) mod primeModulus
  appendOutput($answer)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
