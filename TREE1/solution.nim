const baseValue = 1000000000
const flushBlockBytes = 1 shl 18
const firstDigitValue = 48
const limbDigitCount = 9

proc nextInt(inputData: string, scanPos: var int): int =
  while scanPos < inputData.len and (inputData[scanPos] < '0' or inputData[scanPos] > '9'):
    scanPos += 1
  var numberValue = 0
  while scanPos < inputData.len and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    numberValue = numberValue * 10 + int(inputData[scanPos]) - firstDigitValue
    scanPos += 1
  return numberValue

proc binomialCoefficient(groupSize: int, chooseCount: int): int =
  var coefficient = 1
  for step in 1 .. chooseCount:
    coefficient = coefficient * (groupSize - chooseCount + step) div step
  return coefficient

proc collectInterleaveFactors(prefixKeys: seq[int], startIndex: int, lowKey: int, highKey: int, factors: var seq[int]) =
  let pivotKey = prefixKeys[startIndex]
  let leftKeyCount = pivotKey - lowKey
  let rightKeyCount = highKey - pivotKey
  if leftKeyCount > 0:
    collectInterleaveFactors(prefixKeys, startIndex + 1, lowKey, pivotKey - 1, factors)
  if rightKeyCount > 0:
    collectInterleaveFactors(prefixKeys, startIndex + 1 + leftKeyCount, pivotKey + 1, highKey, factors)
  factors.add binomialCoefficient(leftKeyCount + rightKeyCount, leftKeyCount)

proc multiplyBySmall(bigValue: var seq[int], factor: int) =
  var carry = 0
  for limbIndex in 0 .. bigValue.high:
    let product = bigValue[limbIndex] * factor + carry
    bigValue[limbIndex] = product mod baseValue
    carry = product div baseValue
  while carry > 0:
    bigValue.add(carry mod baseValue)
    carry = carry div baseValue

proc appendPaddedLimb(outputBuffer: var string, limbValue: int) =
  var placeValue = 1
  for digitIndex in 1 .. limbDigitCount:
    placeValue = placeValue * 10
  var remaining = limbValue
  for digitIndex in 1 .. limbDigitCount:
    placeValue = placeValue div 10
    let digitValue = remaining div placeValue
    outputBuffer.add char(firstDigitValue + digitValue)
    remaining = remaining mod placeValue

proc appendBigAnswer(outputBuffer: var string, bigValue: seq[int]) =
  outputBuffer.add $bigValue[bigValue.high]
  for limbIndex in countdown(bigValue.high - 1, 0):
    appendPaddedLimb(outputBuffer, bigValue[limbIndex])
  outputBuffer.add '\n'

var inputData = ""
var oneLine = ""
while readLine(stdin, oneLine):
  inputData.add oneLine
  inputData.add '\n'

var scanPos = 0
let dataSetCount = nextInt(inputData, scanPos)
var outputBuffer = ""
for dataSetIndex in 0 .. dataSetCount - 1:
  let treeSize = nextInt(inputData, scanPos)
  var prefixKeys = newSeq[int](treeSize)
  for keyIndex in 0 .. treeSize - 1:
    prefixKeys[keyIndex] = nextInt(inputData, scanPos)
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
