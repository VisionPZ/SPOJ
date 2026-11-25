const flushBlockBytes = 1 shl 17
const firstDigitValue = 48

import algorithm
import tables

type CountPair = tuple[gapLength: int64, gapCount: int64]
type Gap = tuple[leftEdge: int64, gapLength: int64]
type RootCount = tuple[rootIndex: int, gapCount: int64]

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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc compareLengths(firstValue: int64, secondValue: int64): int =
  if firstValue > secondValue:
    return -1
  elif firstValue < secondValue:
    return 1
  return 0

proc comparePairs(firstPair: CountPair, secondPair: CountPair): int =
  return compareLengths(firstPair.gapLength, secondPair.gapLength)

const maxDistinctLengths = 128

var lengthBuffer = newSeq[int64](maxDistinctLengths)
var frequencyBuffer = newSeq[int64](maxDistinctLengths)
var distinctLengthCount = 0

proc registerLength(value: int64): int =
  for bufferIndex in 0 .. distinctLengthCount - 1:
    if lengthBuffer[bufferIndex] == value:
      return bufferIndex
  lengthBuffer[distinctLengthCount] = value
  frequencyBuffer[distinctLengthCount] = 0
  distinctLengthCount += 1
  return distinctLengthCount - 1

proc findLengthIndex(target: int64): int =
  var lowIndex = 0
  var highIndex = distinctLengthCount - 1
  while lowIndex <= highIndex:
    let middleIndex = (lowIndex + highIndex) div 2
    if lengthBuffer[middleIndex] == target:
      return middleIndex
    elif lengthBuffer[middleIndex] > target:
      lowIndex = middleIndex + 1
    else:
      highIndex = middleIndex - 1
  return distinctLengthCount

proc collectFrequencies(rootLength: int64): int =
  distinctLengthCount = 0
  discard registerLength(rootLength)
  var scanIndex = 0
  while scanIndex < distinctLengthCount:
    let currentLength = lengthBuffer[scanIndex]
    if currentLength > 1:
      let firstLength = (currentLength - 1) div 2
      let secondLength = currentLength - 1 - firstLength
      discard registerLength(firstLength)
      discard registerLength(secondLength)
    scanIndex += 1
  for bufferIndex in 1 .. distinctLengthCount - 1:
    let currentLength = lengthBuffer[bufferIndex]
    let currentFrequency = frequencyBuffer[bufferIndex]
    var insertionIndex = bufferIndex
    while insertionIndex > 0 and lengthBuffer[insertionIndex - 1] < currentLength:
      lengthBuffer[insertionIndex] = lengthBuffer[insertionIndex - 1]
      frequencyBuffer[insertionIndex] = frequencyBuffer[insertionIndex - 1]
      insertionIndex -= 1
    lengthBuffer[insertionIndex] = currentLength
    frequencyBuffer[insertionIndex] = currentFrequency
  for bufferIndex in 0 .. distinctLengthCount - 1:
    frequencyBuffer[bufferIndex] = 0
  frequencyBuffer[0] = 1
  for bufferIndex in 0 .. distinctLengthCount - 1:
    let currentLength = lengthBuffer[bufferIndex]
    let currentFrequency = frequencyBuffer[bufferIndex]
    if currentFrequency > 0 and currentLength > 1:
      let firstLength = (currentLength - 1) div 2
      let secondLength = currentLength - 1 - firstLength
      let firstIndex = findLengthIndex(firstLength)
      let secondIndex = findLengthIndex(secondLength)
      if firstIndex < distinctLengthCount:
        frequencyBuffer[firstIndex] = frequencyBuffer[firstIndex] + currentFrequency
      if secondIndex < distinctLengthCount:
        frequencyBuffer[secondIndex] = frequencyBuffer[secondIndex] + currentFrequency
  return distinctLengthCount

let washbasinCount = int64(nextInt(inputData, scanPos))
let initialLadyCount = nextInt(inputData, scanPos)
let queryCount = nextInt(inputData, scanPos)

var occupiedLabels = newSeq[int64](initialLadyCount + 1)
for ladyIndex in 1 .. initialLadyCount:
  occupiedLabels[ladyIndex] = int64(nextInt(inputData, scanPos))

var requestedLadies = newSeq[int64](queryCount)
for queryIndex in 0 .. queryCount - 1:
  requestedLadies[queryIndex] = int64(nextInt(inputData, scanPos))

var initialGaps = newSeq[Gap]()
if occupiedLabels[1] > 1:
  initialGaps.add((1.int64, occupiedLabels[1] - 1))
for ladyIndex in 1 .. initialLadyCount - 1:
  let gapLength = occupiedLabels[ladyIndex + 1] - occupiedLabels[ladyIndex] - 1
  if gapLength > 0:
    initialGaps.add((occupiedLabels[ladyIndex] + 1, gapLength))
if occupiedLabels[initialLadyCount] < washbasinCount:
  initialGaps.add((occupiedLabels[initialLadyCount] + 1, washbasinCount - occupiedLabels[initialLadyCount]))

var pairLengths = newSeq[int64]()
var pairCounts = newSeq[int64]()
var rootStarts = newSeq[int](initialGaps.len)
var rootPairCounts = newSeq[int](initialGaps.len)
for rootIndex in 0 .. initialGaps.len - 1:
  rootStarts[rootIndex] = pairLengths.len
  let distinctCount = collectFrequencies(initialGaps[rootIndex].gapLength)
  var recordedPairs = 0
  for bufferIndex in 0 .. distinctCount - 1:
    if frequencyBuffer[bufferIndex] > 0:
      pairLengths.add lengthBuffer[bufferIndex]
      pairCounts.add frequencyBuffer[bufferIndex]
      recordedPairs += 1
  rootPairCounts[rootIndex] = recordedPairs

var allPairs = newSeq[CountPair](pairLengths.len)
for pairIndex in 0 .. pairLengths.len - 1:
  allPairs[pairIndex] = (pairLengths[pairIndex], pairCounts[pairIndex])
allPairs.sort(comparePairs)

var bucketLengths = newSeq[int64]()
var bucketCounts = newSeq[int64]()
var bucketBefore = newSeq[int64]()
if allPairs.len > 0:
  var currentLength = allPairs[0].gapLength
  var currentTotal: int64 = 0
  for pairIndex in 0 .. allPairs.len - 1:
    let pairLength = allPairs[pairIndex].gapLength
    if pairLength != currentLength:
      bucketLengths.add currentLength
      bucketCounts.add currentTotal
      if bucketBefore.len == 0:
        bucketBefore.add 0
      else:
        bucketBefore.add bucketBefore[bucketBefore.len - 1] + bucketCounts[bucketCounts.len - 2]
      currentLength = pairLength
      currentTotal = 0
    currentTotal = currentTotal + allPairs[pairIndex].gapCount
  bucketLengths.add currentLength
  bucketCounts.add currentTotal
  if bucketBefore.len == 0:
    bucketBefore.add 0
  else:
    bucketBefore.add bucketBefore[bucketBefore.len - 1] + bucketCounts[bucketCounts.len - 2]

proc bucketOfLength(gapLength: int64): int =
  var lowIndex = 0
  var highIndex = bucketLengths.len - 1
  while lowIndex <= highIndex:
    let middleIndex = (lowIndex + highIndex) div 2
    if bucketLengths[middleIndex] == gapLength:
      return middleIndex
    elif bucketLengths[middleIndex] > gapLength:
      lowIndex = middleIndex + 1
    else:
      highIndex = middleIndex - 1
  return bucketLengths.len

var bucketRoots = newSeq[seq[RootCount]](bucketLengths.len)
for rootIndex in 0 .. initialGaps.len - 1:
  for pairOffset in 0 .. rootPairCounts[rootIndex] - 1:
    let pairIndex = rootStarts[rootIndex] + pairOffset
    let bucketIndex = bucketOfLength(pairLengths[pairIndex])
    bucketRoots[bucketIndex].add((rootIndex, pairCounts[pairIndex]))

var bucketPrefix = newSeq[seq[int64]](bucketLengths.len)
for bucketIndex in 0 .. bucketLengths.len - 1:
  var prefix = newSeq[int64](bucketRoots[bucketIndex].len + 1)
  prefix[0] = 0
  for rootPosition in 0 .. bucketRoots[bucketIndex].len - 1:
    prefix[rootPosition + 1] = prefix[rootPosition] + bucketRoots[bucketIndex][rootPosition].gapCount
  bucketPrefix[bucketIndex] = prefix

proc mixKey(value: int64): int64 =
  var mixed = value
  mixed = mixed xor (mixed shr 30)
  mixed = mixed *% 6364136223846793005'i64
  mixed = mixed xor (mixed shr 27)
  mixed = mixed *% 1442695040888963407'i64
  mixed = mixed xor (mixed shr 31)
  return mixed

var countMemo = initTable[int64, int64]()

proc countGapsIn(gapLength: int64, targetLength: int64): int64 =
  if gapLength <= 0:
    return 0
  let memoKey = mixKey(gapLength)
  if countMemo.hasKey(memoKey):
    return countMemo[memoKey]
  var total: int64 = 0
  if gapLength == targetLength:
    total = 1
  let firstLength = (gapLength - 1) div 2
  let secondLength = gapLength - 1 - firstLength
  total = total + countGapsIn(firstLength, targetLength)
  total = total + countGapsIn(secondLength, targetLength)
  countMemo[memoKey] = total
  return total

proc selectGap(leftEdge: int64, gapLength: int64, targetLength: int64, rank: int64): int64 =
  var remaining = rank
  if gapLength == targetLength and remaining == 1:
    return leftEdge
  if gapLength == targetLength:
    remaining = remaining - 1
  let firstLength = (gapLength - 1) div 2
  let secondLength = gapLength - 1 - firstLength
  let midpoint = leftEdge + firstLength
  let firstCount = countGapsIn(firstLength, targetLength)
  if remaining <= firstCount:
    return selectGap(leftEdge, firstLength, targetLength, remaining)
  return selectGap(midpoint + 1, secondLength, targetLength, remaining - firstCount)

var answerByQuery = newSeq[int64](queryCount)
var activeMemoBucket = -1

for queryIndex in 0 .. queryCount - 1:
  let ladyLabel = requestedLadies[queryIndex]
  if ladyLabel <= int64(initialLadyCount):
    answerByQuery[queryIndex] = occupiedLabels[int(ladyLabel)]
    continue
  let arrivalRank = ladyLabel - int64(initialLadyCount)
  var lowBucket = 0
  var highBucket = bucketLengths.len - 1
  var foundBucket = -1
  while lowBucket <= highBucket:
    let middleBucket = (lowBucket + highBucket) div 2
    if bucketBefore[middleBucket] < arrivalRank:
      foundBucket = middleBucket
      lowBucket = middleBucket + 1
    else:
      highBucket = middleBucket - 1
  if foundBucket != activeMemoBucket:
    countMemo = initTable[int64, int64]()
    activeMemoBucket = foundBucket
  let gapIndex = arrivalRank - bucketBefore[foundBucket]
  let rootPrefix = bucketPrefix[foundBucket]
  var lowPosition = 0
  var highPosition = rootPrefix.len - 2
  var rootPosition = 0
  while lowPosition <= highPosition:
    let middlePosition = (lowPosition + highPosition) div 2
    if rootPrefix[middlePosition] < gapIndex:
      rootPosition = middlePosition
      lowPosition = middlePosition + 1
    else:
      highPosition = middlePosition - 1
  let rootIndex = bucketRoots[foundBucket][rootPosition].rootIndex
  let localRank = gapIndex - rootPrefix[rootPosition]
  let targetLength = bucketLengths[foundBucket]
  let selectedLeft = selectGap(initialGaps[rootIndex].leftEdge, initialGaps[rootIndex].gapLength, targetLength, localRank)
  answerByQuery[queryIndex] = selectedLeft + (targetLength - 1) div 2

for queryIndex in 0 .. queryCount - 1:
  appendOutput($(answerByQuery[queryIndex]))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
