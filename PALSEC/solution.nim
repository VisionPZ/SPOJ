{.push checks: off.}

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const maxWordsPerCase = 60
const maxWordSlots = 401
const hashBaseOne = 1000003'u64
const hashBaseTwo = 1000033'u64

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int(data[position]) - firstDigitValue
    position += 1
  return value

proc nextWord(data: string, position: var int): string =
  while position < data.len and (data[position] < 'a' or data[position] > 'z'):
    position += 1
  let wordStart = position
  while position < data.len and data[position] >= 'a' and data[position] <= 'z':
    position += 1
  return data[wordStart ..< position]

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var prefixHashOne = newSeq[uint64](maxWordsPerCase * maxWordSlots)
var prefixHashTwo = newSeq[uint64](maxWordsPerCase * maxWordSlots)
var reversedHashOne = newSeq[uint64](maxWordsPerCase * maxWordSlots)
var reversedHashTwo = newSeq[uint64](maxWordsPerCase * maxWordSlots)
var powerOne: array[maxWordSlots, uint64]
var powerTwo: array[maxWordSlots, uint64]
powerOne[0] = 1'u64
powerTwo[0] = 1'u64
for k in 1..400:
  powerOne[k] = powerOne[k - 1] * hashBaseOne
  powerTwo[k] = powerTwo[k - 1] * hashBaseTwo

proc equalSegments(firstOne, firstTwo, secondOne, secondTwo: seq[uint64],
                   firstBase, firstStart, secondBase, secondStart, segmentLength: int): bool =
  let firstHash = firstOne[firstBase + firstStart + segmentLength] - firstOne[firstBase + firstStart] * powerOne[segmentLength]
  let secondHash = secondOne[secondBase + secondStart + segmentLength] - secondOne[secondBase + secondStart] * powerOne[segmentLength]
  if firstHash != secondHash:
    return false
  let firstHashTwo = firstTwo[firstBase + firstStart + segmentLength] - firstTwo[firstBase + firstStart] * powerTwo[segmentLength]
  let secondHashTwo = secondTwo[secondBase + secondStart + segmentLength] - secondTwo[secondBase + secondStart] * powerTwo[segmentLength]
  return firstHashTwo == secondHashTwo

var reverseMatch: array[maxWordsPerCase, array[maxWordSlots, uint64]]
var backwardMatch: array[maxWordsPerCase, array[maxWordSlots, uint64]]
var prefixMatch: array[maxWordsPerCase, array[maxWordSlots, uint64]]
var suffixMatch: array[maxWordsPerCase, array[maxWordSlots, uint64]]
var waysTable = newSeq[int](1)

proc tableIndex(leftUsed, rightUsed, lengthKey, variant, rowWidth, span: int): int =
  return ((leftUsed * rowWidth + rightUsed) * span + lengthKey) * 2 + variant

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let sequenceLength = nextInt(inputData, scanPos)
  var wordList = newSeq[string](2 * sequenceLength)
  var maxWordLength = 0
  for i in 0..<sequenceLength:
    wordList[2 * i] = nextWord(inputData, scanPos)
  for i in 0..<sequenceLength:
    wordList[2 * i + 1] = nextWord(inputData, scanPos)
  for i in 0..<2 * sequenceLength:
    if wordList[i].len > maxWordLength:
      maxWordLength = wordList[i].len

  if sequenceLength == 1:
    var singleResult = 0
    for i in 0..1:
      let singleWord = wordList[i]
      var isPalindrome = true
      for k in 0 ..< singleWord.len div 2:
        if singleWord[k] != singleWord[singleWord.len - 1 - k]:
          isPalindrome = false
          break
      if isPalindrome:
        singleResult += 1
    appendOutput($singleResult)
    outputBuffer.add '\n'
    continue

  for i in 0..<maxWordsPerCase:
    for j in 0..<maxWordSlots:
      reverseMatch[i][j] = 0'u64
      backwardMatch[i][j] = 0'u64
      prefixMatch[i][j] = 0'u64
      suffixMatch[i][j] = 0'u64

  for i in 0..<2 * sequenceLength:
    let currentWord = wordList[i]
    let wordBase = i * maxWordSlots
    prefixHashOne[wordBase] = 0'u64
    prefixHashTwo[wordBase] = 0'u64
    reversedHashOne[wordBase] = 0'u64
    reversedHashTwo[wordBase] = 0'u64
    for k in 0..<currentWord.len:
      let forwardLetter = uint64(int(currentWord[k]))
      let reverseLetter = uint64(int(currentWord[currentWord.len - 1 - k]))
      prefixHashOne[wordBase + k + 1] = prefixHashOne[wordBase + k] * hashBaseOne + forwardLetter
      prefixHashTwo[wordBase + k + 1] = prefixHashTwo[wordBase + k] * hashBaseTwo + forwardLetter
      reversedHashOne[wordBase + k + 1] = reversedHashOne[wordBase + k] * hashBaseOne + reverseLetter
      reversedHashTwo[wordBase + k + 1] = reversedHashTwo[wordBase + k] * hashBaseTwo + reverseLetter

  for i in 0..<2 * sequenceLength:
    let wordLength = wordList[i].len
    let wordBase = i * maxWordSlots
    for j in 0..<wordLength:
      for otherIndex in 0..<2 * sequenceLength:
        let otherBase = otherIndex * maxWordSlots
        let otherLength = wordList[otherIndex].len
        if j + otherLength <= wordLength and equalSegments(prefixHashOne, prefixHashTwo, reversedHashOne, reversedHashTwo, wordBase, j, otherBase, 0, otherLength):
          reverseMatch[i][j] = reverseMatch[i][j] or (1'u64 shl otherIndex)
        if otherLength <= j + 1 and equalSegments(reversedHashOne, reversedHashTwo, prefixHashOne, prefixHashTwo, wordBase, wordLength - 1 - j, otherBase, 0, otherLength):
          backwardMatch[i][j] = backwardMatch[i][j] or (1'u64 shl otherIndex)
    for l in 1..wordLength:
      for otherIndex in 0..<2 * sequenceLength:
        let otherLength = wordList[otherIndex].len
        if otherLength >= l:
          let otherBase = otherIndex * maxWordSlots
          if equalSegments(reversedHashOne, reversedHashTwo, prefixHashOne, prefixHashTwo, wordBase, wordLength - l, otherBase, 0, l):
            prefixMatch[i][l] = prefixMatch[i][l] or (1'u64 shl otherIndex)
          if equalSegments(prefixHashOne, prefixHashTwo, reversedHashOne, reversedHashTwo, wordBase, wordLength - l, otherBase, 0, l):
            suffixMatch[i][l] = suffixMatch[i][l] or (1'u64 shl otherIndex)

  let rowWidth = sequenceLength + 1
  let span = 2 * maxWordLength + 1
  let biasValue = maxWordLength
  let tableSize = rowWidth * rowWidth * span * 2
  if waysTable.len < tableSize:
    waysTable.setLen(tableSize)
  for k in 0..<tableSize:
    waysTable[k] = 0
  waysTable[tableIndex(0, 0, biasValue, 0, rowWidth, span)] = 1

  for i in 0..<sequenceLength:
    for j in 0 ..< sequenceLength - i:
      for k in 0..<span:
        for leftVariant in 0..1:
          let baseIndex = tableIndex(i, j, k, leftVariant, rowWidth, span)
          let ways = waysTable[baseIndex]
          if ways == 0:
            continue
          let diff = k - biasValue
          if diff > 0:
            let leftWord = 2 * (i - 1) + leftVariant
            let overhangStart = wordList[leftWord].len - diff
            for rightVariant in 0..1:
              let rightWord = 2 * (sequenceLength - j - 1) + rightVariant
              let rightLength = wordList[rightWord].len
              var allowed = false
              if rightLength < diff:
                allowed = ((reverseMatch[leftWord][overhangStart] shr rightWord) and 1'u64) != 0'u64
              else:
                allowed = ((suffixMatch[leftWord][diff] shr rightWord) and 1'u64) != 0'u64
              if allowed:
                let nextDiff = diff - rightLength
                let nextVariant = if nextDiff == 0: 0 elif nextDiff > 0: leftVariant else: rightVariant
                let nextIndex = tableIndex(i, j + 1, biasValue + nextDiff, nextVariant, rowWidth, span)
                waysTable[nextIndex] += ways
          elif diff < 0:
            let overhangLength = -diff
            let rightWord = 2 * (sequenceLength - j) + leftVariant
            let overhangStart = overhangLength - 1
            for rightVariant in 0..1:
              let leftWord = 2 * i + rightVariant
              let leftLength = wordList[leftWord].len
              var allowed = false
              if leftLength < overhangLength:
                allowed = ((backwardMatch[rightWord][overhangStart] shr leftWord) and 1'u64) != 0'u64
              else:
                allowed = ((prefixMatch[rightWord][overhangLength] shr leftWord) and 1'u64) != 0'u64
              if allowed:
                let nextDiff = diff + leftLength
                let nextVariant = if nextDiff == 0: 0 elif nextDiff < 0: leftVariant else: rightVariant
                let nextIndex = tableIndex(i + 1, j, biasValue + nextDiff, nextVariant, rowWidth, span)
                waysTable[nextIndex] += ways
          else:
            for rightVariant in 0..1:
              let leftWord = 2 * i + rightVariant
              let nextIndex = tableIndex(i + 1, j, biasValue + wordList[leftWord].len, rightVariant, rowWidth, span)
              waysTable[nextIndex] += ways

  var result = 0
  for i in 0..sequenceLength:
    let j = sequenceLength - i
    result += waysTable[tableIndex(i, j, biasValue, 0, rowWidth, span)]
    if i > 0:
      for diff in 1..maxWordLength:
        for variantIndex in 0..1:
          let chosenWord = 2 * (i - 1) + variantIndex
          if ((suffixMatch[chosenWord][diff] shr chosenWord) and 1'u64) != 0'u64:
            result += waysTable[tableIndex(i, j, biasValue + diff, variantIndex, rowWidth, span)]
    if j > 0:
      for diff in 1..maxWordLength:
        for variantIndex in 0..1:
          let chosenWord = 2 * (sequenceLength - j) + variantIndex
          if ((prefixMatch[chosenWord][diff] shr chosenWord) and 1'u64) != 0'u64:
            result += waysTable[tableIndex(i, j, biasValue - diff, variantIndex, rowWidth, span)]
  appendOutput($result)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
