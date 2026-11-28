import math

const flushBlockBytes = 1 shl 17
const sieveLimit = 110000000
const tableBits = 16

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

let caseCount = nextInt(inputData, scanPos)
var queryValues = newSeq[int](caseCount)
for caseIndex in 0 .. caseCount - 1:
  queryValues[caseIndex] = nextInt(inputData, scanPos)

var popcountTable = newSeq[uint8](1 shl tableBits)
for tableIndex in 1 .. (1 shl tableBits) - 1:
  popcountTable[tableIndex] = popcountTable[tableIndex shr 1] + uint8(tableIndex and 1)

let halfLimit = sieveLimit div 2
var compositeBits = newSeq[uint64]((halfLimit shr 6) + 1)
let rootValue = int(sqrt(float(sieveLimit))) + 1
let rootHalf = rootValue div 2

for index in 1 .. rootHalf:
  if (compositeBits[index shr 6] and (1'u64 shl (index and 63))) == 0'u64:
    let primeValue = 2 * index + 1
    var multipleIndex = (primeValue * primeValue) shr 1
    while multipleIndex <= halfLimit:
      compositeBits[multipleIndex shr 6] = compositeBits[multipleIndex shr 6] or (1'u64 shl (multipleIndex and 63))
      multipleIndex += primeValue

var primeValues = newSeq[int32](1)
primeValues[0] = 2'i32
var cumulativeBits = newSeq[int32](2)
cumulativeBits[0] = 0'i32
cumulativeBits[1] = 2'i32
var cumulativeOnes = newSeq[int32](2)
cumulativeOnes[0] = 0'i32
cumulativeOnes[1] = 1'i32
var currentBitLength = 2
var nextBitBoundary = 4
var bitsSoFar: int32 = 2
var onesSoFar: int32 = 1

for index in 1 .. halfLimit:
  if (compositeBits[index shr 6] and (1'u64 shl (index and 63))) != 0'u64:
    continue
  let primeValue = 2 * index + 1
  if primeValue >= nextBitBoundary:
    currentBitLength += 1
    nextBitBoundary = 1 shl currentBitLength
  let onesInPrime = int(popcountTable[primeValue and ((1 shl tableBits) - 1)]) +
                    int(popcountTable[primeValue shr tableBits])
  bitsSoFar += int32(currentBitLength)
  onesSoFar += int32(onesInPrime)
  primeValues.add int32(primeValue)
  cumulativeBits.add bitsSoFar
  cumulativeOnes.add onesSoFar

let primeCount = cumulativeBits.len - 1
for caseIndex in 0 .. caseCount - 1:
  let targetBits = queryValues[caseIndex]
  var lowIndex = 0
  var highIndex = primeCount
  while lowIndex < highIndex:
    let middleIndex = (lowIndex + highIndex + 1) div 2
    if int(cumulativeBits[middleIndex]) <= targetBits:
      lowIndex = middleIndex
    else:
      highIndex = middleIndex - 1
  var answerValue = int(cumulativeOnes[lowIndex])
  var remainingBits = targetBits - int(cumulativeBits[lowIndex])
  if remainingBits > 0:
    let nextPrime = int(primeValues[lowIndex])
    var valueBits = 0
    var scanValue = nextPrime
    while scanValue > 0:
      valueBits += 1
      scanValue = scanValue shr 1
    var shiftCount = valueBits - 1
    while remainingBits > 0 and shiftCount >= 0:
      if ((nextPrime shr shiftCount) and 1) != 0:
        answerValue += 1
      shiftCount -= 1
      remainingBits -= 1
  appendOutput($answerValue)
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
