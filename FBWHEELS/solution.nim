import algorithm
import strutils

const flushBlockBytes = 1 shl 17
const impossibleCost = 1000000000000000000

type ScoreInterval = tuple[lower: int, upper: int, occurrence: int]

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

proc nextWord(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  while pos < data.len and data[pos] > ' ':
    result.add data[pos]
    pos += 1

proc heapPush(heapOccurrence: var seq[int], heapUpper: var seq[int], heapSize: var int, occurrence: int, upper: int) =
  heapSize += 1
  var position = heapSize
  heapOccurrence[position] = occurrence
  heapUpper[position] = upper
  while position > 1:
    let parentPosition = position div 2
    if heapOccurrence[parentPosition] >= occurrence:
      break
    heapOccurrence[position] = heapOccurrence[parentPosition]
    heapUpper[position] = heapUpper[parentPosition]
    position = parentPosition
  heapOccurrence[position] = occurrence
  heapUpper[position] = upper

proc heapPop(heapOccurrence: var seq[int], heapUpper: var seq[int], heapSize: var int): ScoreInterval =
  result = (0, heapUpper[1], heapOccurrence[1])
  let lastOccurrence = heapOccurrence[heapSize]
  let lastUpper = heapUpper[heapSize]
  heapSize -= 1
  if heapSize == 0:
    return
  var position = 1
  while true:
    let leftChild = position * 2
    if leftChild > heapSize:
      break
    let rightChild = leftChild + 1
    var betterChild = leftChild
    if rightChild <= heapSize and heapOccurrence[rightChild] > heapOccurrence[leftChild]:
      betterChild = rightChild
    if heapOccurrence[betterChild] <= lastOccurrence:
      break
    heapOccurrence[position] = heapOccurrence[betterChild]
    heapUpper[position] = heapUpper[betterChild]
    position = betterChild
  heapOccurrence[position] = lastOccurrence
  heapUpper[position] = lastUpper

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let testCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. testCount - 1:
  let dealCount = nextInt(inputData, scanPos)
  let answerCount = nextInt(inputData, scanPos)
  let combineCost = nextInt(inputData, scanPos)
  let targetLength = nextInt(inputData, scanPos)
  let rewardScale = nextInt(inputData, scanPos)
  let rewardBonus = nextInt(inputData, scanPos)
  let secretWord = nextWord(inputData, scanPos)
  let wordLength = secretWord.len
  var dealCosts = newSeq[int](dealCount)
  var dealLengths = newSeq[int](dealCount)
  for dealIndex in 0 .. dealCount - 1:
    dealCosts[dealIndex] = nextInt(inputData, scanPos)
    dealLengths[dealIndex] = nextInt(inputData, scanPos)
  var minimumCost = newSeq[int64](wordLength)
  for lengthValue in 0 .. wordLength - 1:
    minimumCost[lengthValue] = int64(impossibleCost)
  for dealIndex in 0 .. dealCount - 1:
    if dealLengths[dealIndex] < wordLength:
      minimumCost[dealLengths[dealIndex]] = min(minimumCost[dealLengths[dealIndex]], int64(dealCosts[dealIndex]))
  for lengthValue in 1 .. wordLength - 1:
    for dealIndex in 0 .. dealCount - 1:
      let pieceLength = dealLengths[dealIndex]
      if pieceLength < lengthValue and minimumCost[lengthValue - pieceLength] < int64(impossibleCost):
        let candidateCost = minimumCost[lengthValue - pieceLength] + int64(dealCosts[dealIndex]) + int64(combineCost)
        if candidateCost < minimumCost[lengthValue]:
          minimumCost[lengthValue] = candidateCost
  var smallestCost = int64(impossibleCost)
  for lengthValue in 1 .. wordLength - 1:
    if minimumCost[lengthValue] < smallestCost:
      smallestCost = minimumCost[lengthValue]
  let stateLimit = 2 * wordLength + 2
  var transitions = newSeq[array[26, int]](stateLimit)
  var suffixLinks = newSeq[int](stateLimit)
  var longestLength = newSeq[int](stateLimit)
  var endSize = newSeq[int](stateLimit)
  for stateIndex in 0 .. stateLimit - 1:
    suffixLinks[stateIndex] = -1
  var stateCount = 1
  var lastState = 0
  for position in 0 .. wordLength - 1:
    let letterIndex = int(secretWord[position]) - 65
    let currentState = stateCount
    stateCount += 1
    longestLength[currentState] = longestLength[lastState] + 1
    endSize[currentState] = 1
    var walkState = lastState
    while walkState != -1 and transitions[walkState][letterIndex] == 0:
      transitions[walkState][letterIndex] = currentState
      walkState = suffixLinks[walkState]
    if walkState == -1:
      suffixLinks[currentState] = 0
    else:
      let nextState = transitions[walkState][letterIndex]
      if longestLength[walkState] + 1 == longestLength[nextState]:
        suffixLinks[currentState] = nextState
      else:
        let cloneState = stateCount
        stateCount += 1
        transitions[cloneState] = transitions[nextState]
        longestLength[cloneState] = longestLength[walkState] + 1
        suffixLinks[cloneState] = suffixLinks[nextState]
        while walkState != -1 and transitions[walkState][letterIndex] == nextState:
          transitions[walkState][letterIndex] = cloneState
          walkState = suffixLinks[walkState]
        suffixLinks[nextState] = cloneState
        suffixLinks[currentState] = cloneState
    lastState = currentState
  var lengthCounts = newSeq[int](wordLength + 1)
  for stateIndex in 0 .. stateCount - 1:
    lengthCounts[longestLength[stateIndex]] += 1
  for lengthValue in 1 .. wordLength:
    lengthCounts[lengthValue] += lengthCounts[lengthValue - 1]
  var stateOrder = newSeq[int](stateCount)
  for stateIndex in countdown(stateCount - 1, 0):
    let stateLength = longestLength[stateIndex]
    lengthCounts[stateLength] -= 1
    stateOrder[lengthCounts[stateLength]] = stateIndex
  for orderIndex in countdown(stateCount - 1, 1):
    let stateIndex = stateOrder[orderIndex]
    endSize[suffixLinks[stateIndex]] += endSize[stateIndex]
  var occurrencesByLength = newSeq[seq[int]](wordLength)
  var intervals = newSeq[ScoreInterval]()
  for stateIndex in 1 .. stateCount - 1:
    let lowerBound = longestLength[suffixLinks[stateIndex]] + 1
    var upperBound = longestLength[stateIndex]
    if upperBound >= wordLength:
      upperBound = wordLength - 1
    if lowerBound <= upperBound and endSize[stateIndex] >= 2:
      intervals.add((lowerBound, upperBound, endSize[stateIndex]))
  intervals.sort(proc(leftInterval, rightInterval: ScoreInterval): int =
    if leftInterval.lower < rightInterval.lower:
      return -1
    if leftInterval.lower > rightInterval.lower:
      return 1
    return 0)
  var heapOccurrence = newSeq[int](intervals.len + 2)
  var heapUpper = newSeq[int](intervals.len + 2)
  var heapSize = 0
  var intervalIndex = 0
  var keptIntervals = newSeq[ScoreInterval]()
  for lengthValue in 1 .. wordLength - 1:
    while intervalIndex < intervals.len and intervals[intervalIndex].lower <= lengthValue:
      heapPush(heapOccurrence, heapUpper, heapSize, intervals[intervalIndex].occurrence, intervals[intervalIndex].upper)
      intervalIndex += 1
    keptIntervals.setLen 0
    while heapSize > 0 and keptIntervals.len < answerCount:
      if heapUpper[1] < lengthValue:
        discard heapPop(heapOccurrence, heapUpper, heapSize)
        continue
      let selected = heapPop(heapOccurrence, heapUpper, heapSize)
      occurrencesByLength[lengthValue].add selected.occurrence
      keptIntervals.add selected
    for keptInterval in keptIntervals:
      heapPush(heapOccurrence, heapUpper, heapSize, keptInterval.occurrence, keptInterval.upper)
  var candidateValues = newSeq[float]()
  for lengthValue in 1 .. wordLength - 1:
    if minimumCost[lengthValue] >= int64(impossibleCost):
      continue
    let distance = abs(targetLength - lengthValue)
    let rewardSpan = wordLength - distance
    let rewardValue = float(rewardScale) * float(rewardSpan * rewardSpan) + float(rewardBonus)
    let startCount = wordLength - lengthValue + 1
    for occurrence in occurrencesByLength[lengthValue]:
      if occurrence < 2:
        continue
      let matchFactor = float(occurrence * (occurrence - 1)) / float(startCount * (startCount - 1))
      let expectedValue = rewardValue * matchFactor - float(minimumCost[lengthValue])
      if expectedValue > -float(smallestCost):
        candidateValues.add expectedValue
  candidateValues.sort(proc(leftValue, rightValue: float): int =
    if leftValue > rightValue:
      return -1
    if leftValue < rightValue:
      return 1
    return 0)
  for answerIndex in 0 .. answerCount - 1:
    if answerIndex > 0:
      outputBuffer.add ' '
    if answerIndex < candidateValues.len:
      appendOutput(formatFloat(candidateValues[answerIndex], ffDecimal, 5))
    else:
      appendOutput(formatFloat(-float(smallestCost), ffDecimal, 5))
  outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
