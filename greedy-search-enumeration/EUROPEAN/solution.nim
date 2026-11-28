import sets

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const maxRailCount = 5
const maxGaugeCount = 8
const maxGaugeValue = 5000
const maxCandidateCount = 128

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

proc nextInt(data: string, scanPos: var int): int =
  while scanPos < data.len and data[scanPos] <= ' ':
    scanPos += 1
  var value = 0
  while scanPos < data.len and data[scanPos] >= '0' and data[scanPos] <= '9':
    value = value * 10 + int(data[scanPos]) - firstDigitValue
    scanPos += 1
  return value

var gaugeCount = 0
var gaugeValues: array[maxGaugeCount, int]
var gaugeIndexByValue: array[maxGaugeValue + 1, int]
var gaugeStamp: array[maxGaugeValue + 1, int]
var currentStamp = 0
var allGaugeMask = 0
var positionLimit = 0
var railPositions: array[maxRailCount, int]
var sortedPositions: array[maxRailCount, int]
var candidateStamp: array[maxGaugeCount * maxGaugeValue + 1, int]
var candidateMark = 0
var bestPositions: array[maxRailCount, int]
var bestRailCount = 0
var bestFound = false
var visitedSets = initSet[(int64, int64)](512)

proc countMaskBits(maskValue: int): int =
  var count = 0
  var remaining = maskValue
  while remaining > 0:
    remaining = remaining and (remaining - 1)
    count += 1
  return count

proc coveredWithMarks(coveredMask, newPosition, markCount: int): int =
  var coveredResult = coveredMask
  for markIndex in 0 ..< markCount:
    let basePosition = railPositions[markIndex]
    var difference = 0
    if newPosition >= basePosition:
      difference = newPosition - basePosition
    else:
      difference = basePosition - newPosition
    if difference <= maxGaugeValue and gaugeStamp[difference] == currentStamp:
      coveredResult = coveredResult or (1 shl gaugeIndexByValue[difference])
  return coveredResult

proc searchRails(markCount, coveredMask, targetRails: int) =
  for markIndex in 0 ..< markCount:
    sortedPositions[markIndex] = railPositions[markIndex]
  for sortIndex in 1 ..< markCount:
    let keyPosition = sortedPositions[sortIndex]
    var previousIndex = sortIndex - 1
    while previousIndex >= 0 and sortedPositions[previousIndex] > keyPosition:
      sortedPositions[previousIndex + 1] = sortedPositions[previousIndex]
      previousIndex -= 1
    sortedPositions[previousIndex + 1] = keyPosition

  var keyLow: int64 = 0
  var keyHigh: int64 = 0
  for markIndex in 0 ..< markCount:
    if markIndex < 3:
      keyLow = keyLow or (int64(sortedPositions[markIndex]) shl (markIndex * 16))
    else:
      keyHigh = keyHigh or (int64(sortedPositions[markIndex]) shl ((markIndex - 3) * 16))
  let stateKey = (keyLow, keyHigh)
  if stateKey in visitedSets:
    return
  visitedSets.incl stateKey

  if coveredMask == allGaugeMask:
    var isBetter = not bestFound
    if not isBetter:
      for markIndex in 0 ..< markCount:
        if sortedPositions[markIndex] < bestPositions[markIndex]:
          isBetter = true
          break
        if sortedPositions[markIndex] > bestPositions[markIndex]:
          break
    if isBetter:
      for markIndex in 0 ..< markCount:
        bestPositions[markIndex] = sortedPositions[markIndex]
      bestRailCount = markCount
      bestFound = true
    return

  if markCount >= targetRails:
    return

  let remainingPairs = targetRails * (targetRails - 1) div 2 - markCount * (markCount - 1) div 2
  if countMaskBits(allGaugeMask and not coveredMask) > remainingPairs:
    return

  candidateMark += 1
  var candidateList: array[maxCandidateCount, int]
  var candidateCount = 0
  for existingIndex in 0 ..< markCount:
    candidateStamp[railPositions[existingIndex]] = candidateMark
  for markIndex in 0 ..< markCount:
    let basePosition = railPositions[markIndex]
    for gaugeIndex in 0 ..< gaugeCount:
      let gaugeValue = gaugeValues[gaugeIndex]
      let rightPosition = basePosition + gaugeValue
      if rightPosition <= positionLimit and candidateStamp[rightPosition] != candidateMark:
        candidateStamp[rightPosition] = candidateMark
        candidateList[candidateCount] = rightPosition
        candidateCount += 1
      let leftPosition = basePosition - gaugeValue
      if leftPosition >= 0 and candidateStamp[leftPosition] != candidateMark:
        candidateStamp[leftPosition] = candidateMark
        candidateList[candidateCount] = leftPosition
        candidateCount += 1

  for candidateIndex in 0 ..< candidateCount:
    let newPosition = candidateList[candidateIndex]
    let newCovered = coveredWithMarks(coveredMask, newPosition, markCount)
    railPositions[markCount] = newPosition
    searchRails(markCount + 1, newCovered, targetRails)

var scanPos = 0
let caseCount = nextInt(inputData, scanPos)
var outputBuffer = ""
for caseIndex in 1 .. caseCount:
  let inputCount = nextInt(inputData, scanPos)
  gaugeCount = 0
  for inputIndex in 0 ..< inputCount:
    let gaugeValue = nextInt(inputData, scanPos)
    var isDuplicate = false
    for existingIndex in 0 ..< gaugeCount:
      if gaugeValues[existingIndex] == gaugeValue:
        isDuplicate = true
        break
    if not isDuplicate:
      gaugeValues[gaugeCount] = gaugeValue
      gaugeCount += 1

  currentStamp += 1
  allGaugeMask = 0
  positionLimit = 0
  for gaugeIndex in 0 ..< gaugeCount:
    let gaugeValue = gaugeValues[gaugeIndex]
    gaugeIndexByValue[gaugeValue] = gaugeIndex
    gaugeStamp[gaugeValue] = currentStamp
    allGaugeMask = allGaugeMask or (1 shl gaugeIndex)
    positionLimit += gaugeValue

  bestFound = false
  bestRailCount = 0
  for targetRails in 1 .. maxRailCount:
    if targetRails * (targetRails - 1) div 2 < gaugeCount:
      continue
    visitedSets.clear()
    railPositions[0] = 0
    searchRails(1, 0, targetRails)
    if bestFound:
      break

  outputBuffer.add "Scenario #"
  outputBuffer.add $caseIndex
  outputBuffer.add '\n'
  outputBuffer.add $bestRailCount
  outputBuffer.add ':'
  for markIndex in 0 ..< bestRailCount:
    outputBuffer.add ' '
    outputBuffer.add $bestPositions[markIndex]
  outputBuffer.add '\n'
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

stdout.write outputBuffer
