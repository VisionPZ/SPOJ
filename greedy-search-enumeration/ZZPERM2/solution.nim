import tables

const flushBlockBytes = 1 shl 17
const alphabetSize = 10
const stateMultiplier = 22'i64

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextWord(data: string, pos: var int): string =
  while pos < data.len and data[pos] <= ' ':
    pos += 1
  result = ""
  while pos < data.len and data[pos] > ' ':
    result.add data[pos]
    pos += 1

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

var letterTotals = newSeq[int](alphabetSize)
var typeLetters = newSeq[int](alphabetSize)
var typeCounts = newSeq[int](alphabetSize)
var radixMultipliers = newSeq[int64](alphabetSize)
var typeCount = 0
var fullState: int64 = 0
var memoTable = initTable[int64, int64]()

proc remainingCount(stateIndex: int64, typeIndex: int): int64 =
  return (stateIndex div radixMultipliers[typeIndex]) mod int64(typeCounts[typeIndex] + 1)

proc countCompletions(stateIndex: int64, lastLetter: int, needUp: bool): int64 =
  if stateIndex == 0:
    return 1
  let cacheKey = stateIndex * stateMultiplier + int64((lastLetter + 1) * 2 + (if needUp: 1 else: 0))
  if memoTable.hasKey(cacheKey):
    return memoTable[cacheKey]
  var totalWays: int64 = 0
  for typeIndex in 0 .. typeCount - 1:
    if remainingCount(stateIndex, typeIndex) == 0:
      continue
    let candidateLetter = typeLetters[typeIndex]
    if lastLetter >= 0:
      if needUp and candidateLetter <= lastLetter:
        continue
      if (not needUp) and candidateLetter >= lastLetter:
        continue
    totalWays = totalWays + countCompletions(stateIndex - radixMultipliers[typeIndex], candidateLetter, not needUp)
  memoTable[cacheKey] = totalWays
  return totalWays

proc pairCompletionCount(firstType: int, secondType: int): int64 =
  let stateAfterPair = fullState - radixMultipliers[firstType] - radixMultipliers[secondType]
  return countCompletions(stateAfterPair, typeLetters[secondType], secondType < firstType)

proc totalZigzags(wordLength: int): int64 =
  if wordLength == 1:
    return 1
  var totalWays: int64 = 0
  for firstType in 0 .. typeCount - 1:
    for secondType in 0 .. typeCount - 1:
      if secondType == firstType:
        continue
      totalWays = totalWays + pairCompletionCount(firstType, secondType)
  return totalWays

proc unrankWord(targetRank: int64, wordLength: int): string =
  if wordLength == 1:
    return $char(typeLetters[0] + int('a'))
  var rankLeft = targetRank
  var chosenFirst = 0
  var chosenSecond = 0
  for firstType in 0 .. typeCount - 1:
    var groupTotal: int64 = 0
    for secondType in 0 .. typeCount - 1:
      if secondType != firstType:
        groupTotal = groupTotal + pairCompletionCount(firstType, secondType)
    if rankLeft > groupTotal:
      rankLeft = rankLeft - groupTotal
    else:
      chosenFirst = firstType
      break
  for secondType in 0 .. typeCount - 1:
    if secondType == chosenFirst:
      continue
    let branchTotal = pairCompletionCount(chosenFirst, secondType)
    if rankLeft > branchTotal:
      rankLeft = rankLeft - branchTotal
    else:
      chosenSecond = secondType
      break
  result = ""
  result.add char(typeLetters[chosenFirst] + int('a'))
  result.add char(typeLetters[chosenSecond] + int('a'))
  var stateIndex = fullState - radixMultipliers[chosenFirst] - radixMultipliers[chosenSecond]
  var lastLetter = typeLetters[chosenSecond]
  var needUp = chosenSecond < chosenFirst
  while stateIndex != 0:
    for typeIndex in 0 .. typeCount - 1:
      if remainingCount(stateIndex, typeIndex) == 0:
        continue
      let candidateLetter = typeLetters[typeIndex]
      if needUp and candidateLetter <= lastLetter:
        continue
      if (not needUp) and candidateLetter >= lastLetter:
        continue
      let branchTotal = countCompletions(stateIndex - radixMultipliers[typeIndex], candidateLetter, not needUp)
      if rankLeft > branchTotal:
        rankLeft = rankLeft - branchTotal
      else:
        result.add char(candidateLetter + int('a'))
        stateIndex = stateIndex - radixMultipliers[typeIndex]
        lastLetter = candidateLetter
        needUp = not needUp
        break

while scanPos < inputData.len:
  let sourceWord = nextWord(inputData, scanPos)
  if sourceWord.len == 0:
    break
  let divisorValue = nextInt(inputData, scanPos)
  for letterIndex in 0 .. alphabetSize - 1:
    letterTotals[letterIndex] = 0
  for charIndex in 0 .. sourceWord.len - 1:
    letterTotals[int(sourceWord[charIndex]) - int('a')] += 1
  typeCount = 0
  fullState = 0
  var multiplierValue: int64 = 1
  for letterIndex in 0 .. alphabetSize - 1:
    if letterTotals[letterIndex] > 0:
      typeLetters[typeCount] = letterIndex
      typeCounts[typeCount] = letterTotals[letterIndex]
      radixMultipliers[typeCount] = multiplierValue
      fullState = fullState + int64(letterTotals[letterIndex]) * multiplierValue
      multiplierValue = multiplierValue * int64(letterTotals[letterIndex] + 1)
      typeCount += 1
  memoTable.clear()
  let permutationTotal = totalZigzags(sourceWord.len)
  var targetRank = int64(divisorValue)
  while targetRank <= permutationTotal:
    appendOutput(unrankWord(targetRank, sourceWord.len))
    outputBuffer.add '\n'
    targetRank = targetRank + int64(divisorValue)
  appendOutput($permutationTotal)
  outputBuffer.add '\n'
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
