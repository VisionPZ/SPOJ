const flushBlockBytes = 1 shl 17
const firstDigitValue = 48
const modulusValue: int64 = 1000000007
const exponentForInverse = 1000000005

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextBinaryString(data: string, pos: var int): string =
  while pos < data.len and data[pos] != '0' and data[pos] != '1':
    pos += 1
  var binaryText = ""
  while pos < data.len and (data[pos] == '0' or data[pos] == '1'):
    binaryText.add data[pos]
    pos += 1
  return binaryText

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc powerMod(baseValue, exponentValue: int64): int64 =
  var baseRemainder = baseValue mod modulusValue
  var exponentLeft = exponentValue
  var resultValue: int64 = 1
  while exponentLeft > 0:
    if (exponentLeft and 1) == 1:
      resultValue = (resultValue * baseRemainder) mod modulusValue
    baseRemainder = (baseRemainder * baseRemainder) mod modulusValue
    exponentLeft = exponentLeft div 2
  return resultValue

proc combination(totalCount, chooseCount: int, factorial, inverseFactorial: seq[int64]): int64 =
  if chooseCount < 0 or chooseCount > totalCount:
    return 0
  let firstProduct = (factorial[totalCount] * inverseFactorial[chooseCount]) mod modulusValue
  return (firstProduct * inverseFactorial[totalCount - chooseCount]) mod modulusValue

let firstHound = nextBinaryString(inputData, scanPos)
let secondHound = nextBinaryString(inputData, scanPos)
let thirdHound = nextBinaryString(inputData, scanPos)
let dimension = firstHound.len
var minorityCounts = newSeq[int](3)
var freePositions = 0
for position in 0 .. dimension - 1:
  let firstBit = int(firstHound[position]) - firstDigitValue
  let secondBit = int(secondHound[position]) - firstDigitValue
  let thirdBit = int(thirdHound[position]) - firstDigitValue
  if firstBit == secondBit and secondBit == thirdBit:
    freePositions += 1
  elif firstBit != secondBit and firstBit != thirdBit:
    minorityCounts[0] += 1
  elif secondBit != firstBit and secondBit != thirdBit:
    minorityCounts[1] += 1
  else:
    minorityCounts[2] += 1

var factorial = newSeq[int64](dimension + 1)
var inverseFactorial = newSeq[int64](dimension + 1)
factorial[0] = 1
for position in 1 .. dimension:
  factorial[position] = (factorial[position - 1] * int64(position)) mod modulusValue
inverseFactorial[dimension] = powerMod(factorial[dimension], int64(exponentForInverse))
for position in 0 .. dimension - 1:
  inverseFactorial[dimension - 1 - position] =
    (inverseFactorial[dimension - position] * int64(dimension - position)) mod modulusValue

let smallestCount = min(min(minorityCounts[0], minorityCounts[1]), minorityCounts[2])
var safeTotal: int64 = 0
for balance in -smallestCount .. smallestCount:
  var skipBalance = false
  for houndIndex in 0 .. 2:
    if (balance - minorityCounts[houndIndex]) mod 2 != 0:
      skipBalance = true
  if skipBalance:
    continue
  var ways: int64 = 1
  for houndIndex in 0 .. 2:
    let chosenCount = (minorityCounts[houndIndex] + balance) div 2
    ways = (ways * combination(minorityCounts[houndIndex], chosenCount, factorial, inverseFactorial)) mod modulusValue
  safeTotal = (safeTotal + ways) mod modulusValue
safeTotal = (safeTotal * powerMod(2, int64(freePositions))) mod modulusValue
appendOutput($safeTotal)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
