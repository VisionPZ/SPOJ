import math

const flushBlockBytes = 1 shl 18
const firstDigitValue = 48
const firstLetterValue = 65
const circlePi = 3.141592653589793
const letterCount = 26
const bruteForceLimit = 2048
const confidenceMargin = 0.01
const sweepWorkBudget = 4000000000000000000
const staleSweepLimit = 100000000

var inputData = ""
var lineBuffer = ""
while readLine(stdin, lineBuffer):
  inputData.add lineBuffer
  inputData.add '\n'

var scanPos = 0

proc scanInt(): int =
  let dataLength = inputData.len
  while scanPos < dataLength and (inputData[scanPos] < '0' or inputData[scanPos] > '9'):
    scanPos.inc
  result = 0
  while scanPos < dataLength and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    result = result * 10 + int(inputData[scanPos]) - firstDigitValue
    scanPos.inc

proc scanWord(): string =
  let dataLength = inputData.len
  while scanPos < dataLength and not ((inputData[scanPos] >= 'A' and inputData[scanPos] <= 'Z') or inputData[scanPos] == '*'):
    scanPos.inc
  let wordStart = scanPos
  while scanPos < dataLength and ((inputData[scanPos] >= 'A' and inputData[scanPos] <= 'Z') or inputData[scanPos] == '*'):
    scanPos.inc
  result = inputData.substr(wordStart, scanPos - 1)

var outputBuffer = ""

proc emitChar(value: char) =
  outputBuffer.add value
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc fftTransform(re: var seq[float], im: var seq[float], inverse: bool) =
  let size = re.len
  var reverseIndex = 0
  for index in 1 ..< size:
    var bitMask = size shr 1
    while (reverseIndex and bitMask) != 0:
      reverseIndex = reverseIndex xor bitMask
      bitMask = bitMask shr 1
    reverseIndex = reverseIndex xor bitMask
    if index < reverseIndex:
      swap(re[index], re[reverseIndex])
      swap(im[index], im[reverseIndex])
  var blockSize = 2
  while blockSize <= size:
    let angle = (if inverse: 2.0 else: -2.0) * circlePi / float(blockSize)
    let stepRe = cos(angle)
    let stepIm = sin(angle)
    let halfBlock = blockSize div 2
    var blockStart = 0
    while blockStart < size:
      var twiddleRe = 1.0
      var twiddleIm = 0.0
      for offset in 0 ..< halfBlock:
        let evenRe = re[blockStart + offset]
        let evenIm = im[blockStart + offset]
        let oddIndex = blockStart + offset + halfBlock
        let oddRe = re[oddIndex] * twiddleRe - im[oddIndex] * twiddleIm
        let oddIm = re[oddIndex] * twiddleIm + im[oddIndex] * twiddleRe
        re[blockStart + offset] = evenRe + oddRe
        im[blockStart + offset] = evenIm + oddIm
        re[oddIndex] = evenRe - oddRe
        im[oddIndex] = evenIm - oddIm
        let nextRe = twiddleRe * stepRe - twiddleIm * stepIm
        twiddleIm = twiddleRe * stepIm + twiddleIm * stepRe
        twiddleRe = nextRe
      blockStart += blockSize
    blockSize *= 2
  if inverse:
    for index in 0 ..< size:
      re[index] = re[index] / float(size)
      im[index] = im[index] / float(size)

var cosineTable: array[letterCount, float]
var sineTable: array[letterCount, float]
for value in 0 ..< letterCount:
  let angle = 2.0 * circlePi * float(value) / float(letterCount)
  cosineTable[value] = cos(angle)
  sineTable[value] = sin(angle)

proc greatestCommonDivisor(leftValue: int, rightValue: int): int =
  var left = leftValue
  var right = rightValue
  while right != 0:
    let saved = left
    left = right
    right = saved mod right
  result = left

var smallestFactor: seq[int] = @[0, 0]

proc ensureFactors(upperBound: int) =
  if smallestFactor.len > upperBound:
    return
  let oldLength = smallestFactor.len
  smallestFactor.setLen(upperBound + 1)
  for index in oldLength .. upperBound:
    smallestFactor[index] = 0
  if upperBound < 2:
    return
  for candidate in 2 .. upperBound:
    if smallestFactor[candidate] == 0:
      smallestFactor[candidate] = candidate
      if candidate <= upperBound div candidate:
        var multiple = candidate * candidate
        while multiple <= upperBound:
          if smallestFactor[multiple] == 0:
            smallestFactor[multiple] = candidate
          multiple += candidate

var divisorBuffer: seq[int] = @[]

proc buildDivisors(value: int) =
  divisorBuffer.setLen 0
  divisorBuffer.add 1
  var remaining = value
  while remaining > 1:
    let prime = smallestFactor[remaining]
    var exponent = 0
    while remaining mod prime == 0:
      remaining = remaining div prime
      exponent.inc
    let existingCount = divisorBuffer.len
    var power = 1
    for step in 1 .. exponent:
      power *= prime
      for index in 0 ..< existingCount:
        divisorBuffer.add divisorBuffer[index] * power

let testCount = scanInt()

for caseIndex in 0 ..< testCount:
  let cipherBound = scanInt()
  let plainText = scanWord()
  let cipherText = scanWord()
  let textLength = plainText.len

  var diffAt: seq[int8]
  diffAt.setLen(textLength)
  var knownCount = 0
  var valuePositions: array[letterCount, seq[int]]
  for value in 0 ..< letterCount:
    valuePositions[value].setLen 0
  for position in 0 ..< textLength:
    if plainText[position] == '*' or cipherText[position] == '*':
      diffAt[position] = -1
    else:
      let diffValue = (int(cipherText[position]) - int(plainText[position]) + 26) mod 26
      diffAt[position] = int8(diffValue)
      valuePositions[diffValue].add position
      knownCount.inc

  var conflictAt: seq[bool]
  conflictAt.setLen(textLength)

  if textLength <= bruteForceLimit:
    for distance in 1 ..< textLength:
      var hasConflict = false
      for position in 0 ..< textLength - distance:
        let leftDiff = diffAt[position]
        let rightDiff = diffAt[position + distance]
        if leftDiff >= 0 and rightDiff >= 0 and leftDiff != rightDiff:
          hasConflict = true
          break
      conflictAt[distance] = hasConflict
  else:
    var transformSize = 1
    while transformSize < 2 * textLength:
      transformSize *= 2

    var realSignal: seq[float]
    var imagSignal: seq[float]
    var realKnown: seq[float]
    var imagKnown: seq[float]
    realSignal.setLen(transformSize)
    imagSignal.setLen(transformSize)
    realKnown.setLen(transformSize)
    imagKnown.setLen(transformSize)
    for position in 0 ..< textLength:
      if diffAt[position] >= 0:
        let diffValue = int(diffAt[position])
        realSignal[position] = cosineTable[diffValue]
        imagSignal[position] = sineTable[diffValue]
        realKnown[position] = 1.0

    fftTransform(realSignal, imagSignal, false)
    fftTransform(realKnown, imagKnown, false)

    for index in 0 ..< transformSize:
      realSignal[index] = realSignal[index] * realSignal[index] + imagSignal[index] * imagSignal[index]
      imagSignal[index] = 0.0
      realKnown[index] = realKnown[index] * realKnown[index] + imagKnown[index] * imagKnown[index]
      imagKnown[index] = 0.0

    fftTransform(realSignal, imagSignal, true)
    fftTransform(realKnown, imagKnown, true)

    for distance in 1 ..< textLength:
      if realKnown[distance] > 0.5 and realSignal[distance] < realKnown[distance] - confidenceMargin:
        conflictAt[distance] = true

  var invalidAt: seq[bool]
  invalidAt.setLen(cipherBound + 1)
  var validLengths: seq[int] = @[]
  for lengthValue in 1 .. cipherBound:
    var hasConflict = false
    var distance = lengthValue
    while distance < textLength:
      if conflictAt[distance]:
        hasConflict = true
        break
      distance += lengthValue
    invalidAt[lengthValue] = hasConflict
    if not hasConflict:
      validLengths.add lengthValue

  let validCount = validLengths.len
  if validCount == 0:
    for position in 0 ..< textLength:
      if plainText[position] == '*':
        emitChar('*')
      else:
        emitChar(plainText[position])
    emitChar('\n')
    continue
  let largestValid = validLengths[validCount - 1]
  var forcedAtLargest: seq[int8]
  forcedAtLargest.setLen(largestValid)
  for residue in 0 ..< largestValid:
    forcedAtLargest[residue] = -1
  for position in 0 ..< textLength:
    if diffAt[position] >= 0:
      let residue = position mod largestValid
      if forcedAtLargest[residue] < 0:
        forcedAtLargest[residue] = diffAt[position]

  ensureFactors(textLength)

  var groupStep: array[letterCount, int]
  var groupFirst: array[letterCount, int]
  var groupNeed: array[letterCount, int]
  var groupFull: array[letterCount, bool]
  var groupTermCount: array[letterCount, int]
  var groupCritical: array[letterCount, seq[int]]
  for value in 0 ..< letterCount:
    groupStep[value] = 0
    groupFirst[value] = -1
    groupNeed[value] = 0
    groupFull[value] = false
    groupTermCount[value] = 0
    groupCritical[value] = @[]
    let positions = valuePositions[value]
    if positions.len == 0:
      continue
    groupFirst[value] = positions[0]
    if positions.len == 1:
      groupStep[value] = textLength + 1
      continue
    var stepValue = positions[1] - positions[0]
    for index in 2 ..< positions.len:
      stepValue = greatestCommonDivisor(positions[index] - positions[index - 1], stepValue)
    groupStep[value] = stepValue
    let lastSlot = (textLength - 1 - positions[0]) div stepValue + 1
    groupFull[value] = (positions.len == lastSlot)
    if groupFull[value]:
      groupTermCount[value] = lastSlot - 1
      var needValue = 1
      for lengthValue in validLengths:
        let common = greatestCommonDivisor(stepValue, lengthValue)
        if needValue mod common != 0:
          needValue = needValue div greatestCommonDivisor(needValue, common) * common
        if lengthValue div common > groupTermCount[value]:
          groupCritical[value].add lengthValue
      if groupCritical[value].len > 32:
        groupFull[value] = false
      else:
        groupNeed[value] = int(needValue)

  var validIndexAt: seq[int]
  validIndexAt.setLen(cipherBound + 1)
  for index in 0 .. cipherBound:
    validIndexAt[index] = -1
  for index in 0 ..< validCount:
    validIndexAt[validLengths[index]] = index

  var coverStamp: seq[int]
  coverStamp.setLen(cipherBound + 1)
  for index in 0 .. cipherBound:
    coverStamp[index] = 0
  var stampCounter = 0

  var answerFor: seq[char]
  answerFor.setLen(textLength)
  var pendingFor: seq[int8]
  pendingFor.setLen(textLength)
  var targetFor: seq[int8]
  targetFor.setLen(textLength)
  var checkedFor: seq[int]
  checkedFor.setLen(textLength)
  var alivePositions: seq[int] = @[]

  for position in 0 ..< textLength:
    if plainText[position] != '*':
      answerFor[position] = plainText[position]
      pendingFor[position] = 0
      continue
    if cipherText[position] == '*':
      answerFor[position] = '*'
      pendingFor[position] = 0
      continue
    let forcedDiff = forcedAtLargest[position mod largestValid]
    if forcedDiff < 0:
      answerFor[position] = '*'
      pendingFor[position] = 0
      continue
    let diffValue = int(forcedDiff)
    let plainValue = (int(cipherText[position]) - firstLetterValue - diffValue + 26) mod 26
    answerFor[position] = char(firstLetterValue + plainValue)
    if validCount == 1:
      pendingFor[position] = 0
      continue
    if false:
      let offset = position - groupFirst[diffValue]
      let modulus = groupNeed[diffValue]
      var coveredEverywhere = (modulus > 0 and offset mod modulus == 0)
      if coveredEverywhere:
        for lengthValue in groupCritical[diffValue]:
          let common = greatestCommonDivisor(groupStep[diffValue], lengthValue)
          let reduced = lengthValue div common
          let aligned = offset div common
          let wrapped = (aligned mod reduced + reduced) mod reduced
          if wrapped > groupTermCount[diffValue]:
            coveredEverywhere = false
            break
      if coveredEverywhere:
        pendingFor[position] = 0
      else:
        answerFor[position] = '*'
        pendingFor[position] = 0
      continue
    pendingFor[position] = 1
    targetFor[position] = forcedDiff
    checkedFor[position] = 1
    alivePositions.add position

  var residueValue: seq[int8]
  var nextAlive: seq[int] = @[]
  var sweepIndex = validCount - 2
  var sweepWork = 0
  var staleSweepCount = 0
  while sweepIndex >= 0 and sweepWork < sweepWorkBudget and staleSweepCount < staleSweepLimit:
    let modulus = validLengths[sweepIndex]
    residueValue.setLen(modulus)
    for residue in 0 ..< modulus:
      residueValue[residue] = -1
    for position in 0 ..< textLength:
      if diffAt[position] >= 0:
        residueValue[position mod modulus] = diffAt[position]
    sweepWork += modulus + knownCount
    nextAlive.setLen 0
    var killedNow = 0
    for index in 0 ..< alivePositions.len:
      let position = alivePositions[index]
      let residue = position mod modulus
      if residueValue[residue] == targetFor[position]:
        checkedFor[position].inc
        nextAlive.add position
        sweepWork.inc
      else:
        pendingFor[position] = 0
        answerFor[position] = '*'
        killedNow.inc
    swap(alivePositions, nextAlive)
    if killedNow == 0:
      staleSweepCount.inc
    else:
      staleSweepCount = 0
    sweepIndex.dec

  for index in 0 ..< alivePositions.len:
    let position = alivePositions[index]
    let diffValue = int(targetFor[position])
    let firstUncheckedIndex = validCount - checkedFor[position]
    stampCounter.inc
    var coveredCount = 0
    let positions = valuePositions[diffValue]
    for positionIndex in 0 ..< positions.len:
      let other = positions[positionIndex]
      let distance = if other > position: other - position else: position - other
      buildDivisors(distance)
      for divisorIndex in 0 ..< divisorBuffer.len:
        let lengthValue = divisorBuffer[divisorIndex]
        if lengthValue > cipherBound:
          continue
        let lengthIndex = validIndexAt[lengthValue]
        if lengthIndex < 0 or lengthIndex >= firstUncheckedIndex or coverStamp[lengthValue] == stampCounter:
          continue
        coverStamp[lengthValue] = stampCounter
        coveredCount.inc
        if coveredCount == firstUncheckedIndex:
          break
      if coveredCount == firstUncheckedIndex:
        break
    if coveredCount < firstUncheckedIndex:
      answerFor[position] = '*'
    pendingFor[position] = 0

  for position in 0 ..< textLength:
    emitChar(answerFor[position])
  emitChar('\n')

stdout.write outputBuffer
