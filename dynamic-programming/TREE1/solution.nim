const baseValue = 1000000000
const flushBlockBytes = 1 shl 18
const firstDigitValue = 48
const limbDigitCount = 9

proc nextInt(inputData: string, i: var int): int =
  while i < inputData.len and (inputData[i] < '0' or inputData[i] > '9'):
    i += 1
  var numberValue = 0
  while i < inputData.len and inputData[i] >= '0' and inputData[i] <= '9':
    numberValue = numberValue * 10 + int(inputData[i]) - firstDigitValue
    i += 1
  return numberValue

proc binomialCoefficient(groupSize: int, chooseCount: int): int =
  var coefficient = 1
  for j in 1 .. chooseCount:
    coefficient = coefficient * (groupSize - chooseCount + j) div j
  return coefficient

proc collectInterleaveFactors(prefixKeys: seq[int], i: int, lowKey: int, highKey: int, factors: var seq[int]) =
  let pivotKey = prefixKeys[i]
  let leftKeyCount = pivotKey - lowKey
  let rightKeyCount = highKey - pivotKey
  if leftKeyCount > 0:
    collectInterleaveFactors(prefixKeys, i + 1, lowKey, pivotKey - 1, factors)
  if rightKeyCount > 0:
    collectInterleaveFactors(prefixKeys, i + 1 + leftKeyCount, pivotKey + 1, highKey, factors)
  factors.add binomialCoefficient(leftKeyCount + rightKeyCount, leftKeyCount)

proc multiplyBySmall(bigValue: var seq[int], factor: int) =
  var carry = 0
  for j in 0 .. bigValue.high:
    let product = bigValue[j] * factor + carry
    bigValue[j] = product mod baseValue
    carry = product div baseValue
  while carry > 0:
    bigValue.add(carry mod baseValue)
    carry = carry div baseValue

proc appendPaddedLimb(outputBuffer: var string, limbValue: int) =
  var placeValue = 1
  for j in 1 .. limbDigitCount:
    placeValue = placeValue * 10
  var remaining = limbValue
  for j in 1 .. limbDigitCount:
    placeValue = placeValue div 10
    let digitValue = remaining div placeValue
    outputBuffer.add char(firstDigitValue + digitValue)
    remaining = remaining mod placeValue

proc appendBigAnswer(outputBuffer: var string, bigValue: seq[int]) =
  outputBuffer.add $bigValue[bigValue.high]
  for j in countdown(bigValue.high - 1, 0):
    appendPaddedLimb(outputBuffer, bigValue[j])
  outputBuffer.add '\n'

var inputData = ""
var oneLine = ""
while readLine(stdin, oneLine):
  inputData.add oneLine
  inputData.add '\n'

var i = 0
let dataSetCount = nextInt(inputData, i)
var outputBuffer = ""
for j in 0 .. dataSetCount - 1:
  let treeSize = nextInt(inputData, i)
  var prefixKeys = newSeq[int](treeSize)
  for k in 0 .. treeSize - 1:
    prefixKeys[k] = nextInt(inputData, i)
  var interleaveFactors: seq[int] = @[]
  collectInterleaveFactors(prefixKeys, 0, 1, treeSize, interleaveFactors)
  var bigAnswer = @[1]
  for factor in interleaveFactors:
    multiplyBySmall(bigAnswer, factor)
  appendBigAnswer(outputBuffer, bigAnswer)
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

if outputBuffer.len > 0:
  stdout.write outputBuffer
