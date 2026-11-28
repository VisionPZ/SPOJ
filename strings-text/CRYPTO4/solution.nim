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

var i = 0

proc scanInt(): int =
  let dataLength = inputData.len
  while i < dataLength and (inputData[i] < '0' or inputData[i] > '9'):
    i.inc
  result = 0
  while i < dataLength and inputData[i] >= '0' and inputData[i] <= '9':
    result = result * 10 + int(inputData[i]) - firstDigitValue
    i.inc

proc scanWord(): string =
  let dataLength = inputData.len
  while i < dataLength and not ((inputData[i] >= 'A' and inputData[i] <= 'Z') or inputData[i] == '*'):
    i.inc
  let j = i
  while i < dataLength and ((inputData[i] >= 'A' and inputData[i] <= 'Z') or inputData[i] == '*'):
    i.inc
  result = inputData.substr(j, i - 1)

var outputBuffer = ""

proc emitChar(value: char) =
  outputBuffer.add value
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc fftTransform(re: var seq[float], im: var seq[float], inverse: bool) =
  let size = re.len
  var i = 0
  for k in 1 ..< size:
    var bitMask = size shr 1
    while (i and bitMask) != 0:
      i = i xor bitMask
      bitMask = bitMask shr 1
    i = i xor bitMask
    if k < i:
      swap(re[k], re[i])
      swap(im[k], im[i])
  var blockSize = 2
  while blockSize <= size:
    let angle = (if inverse: 2.0 else: -2.0) * circlePi / float(blockSize)
    let stepRe = cos(angle)
    let stepIm = sin(angle)
    let halfBlock = blockSize div 2
    var j = 0
    while j < size:
      var twiddleRe = 1.0
      var twiddleIm = 0.0
      for l in 0 ..< halfBlock:
        let evenRe = re[j + l]
        let evenIm = im[j + l]
        let i = j + l + halfBlock
        let oddRe = re[i] * twiddleRe - im[i] * twiddleIm
        let oddIm = re[i] * twiddleIm + im[i] * twiddleRe
        re[j + l] = evenRe + oddRe
        im[j + l] = evenIm + oddIm
        re[i] = evenRe - oddRe
        im[i] = evenIm - oddIm
        let nextRe = twiddleRe * stepRe - twiddleIm * stepIm
        twiddleIm = twiddleRe * stepIm + twiddleIm * stepRe
        twiddleRe = nextRe
      j += blockSize
    blockSize *= 2
  if inverse:
    for k in 0 ..< size:
      re[k] = re[k] / float(size)
      im[k] = im[k] / float(size)

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
  for k in oldLength .. upperBound:
    smallestFactor[k] = 0
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
      for k in 0 ..< existingCount:
        divisorBuffer.add divisorBuffer[k] * power

let testCount = scanInt()

for l in 0 ..< testCount:
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
  for j in 0 ..< textLength:
    if plainText[j] == '*' or cipherText[j] == '*':
      diffAt[j] = -1
    else:
      let diffValue = (int(cipherText[j]) - int(plainText[j]) + 26) mod 26
      diffAt[j] = int8(diffValue)
      valuePositions[diffValue].add j
      knownCount.inc

  var conflictAt: seq[bool]
  conflictAt.setLen(textLength)

  if textLength <= bruteForceLimit:
    for distance in 1 ..< textLength:
      var hasConflict = false
      for j in 0 ..< textLength - distance:
        let leftDiff = diffAt[j]
        let rightDiff = diffAt[j + distance]
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
    for j in 0 ..< textLength:
      if diffAt[j] >= 0:
        let diffValue = int(diffAt[j])
        realSignal[j] = cosineTable[diffValue]
        imagSignal[j] = sineTable[diffValue]
        realKnown[j] = 1.0

    fftTransform(realSignal, imagSignal, false)
    fftTransform(realKnown, imagKnown, false)

    for k in 0 ..< transformSize:
      realSignal[k] = realSignal[k] * realSignal[k] + imagSignal[k] * imagSignal[k]
      imagSignal[k] = 0.0
      realKnown[k] = realKnown[k] * realKnown[k] + imagKnown[k] * imagKnown[k]
      imagKnown[k] = 0.0

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
    for j in 0 ..< textLength:
      if plainText[j] == '*':
        emitChar('*')
      else:
        emitChar(plainText[j])
    emitChar('\n')
    continue
  let largestValid = validLengths[validCount - 1]
  var forcedAtLargest: seq[int8]
  forcedAtLargest.setLen(largestValid)
  for l in 0 ..< largestValid:
    forcedAtLargest[l] = -1
  for j in 0 ..< textLength:
    if diffAt[j] >= 0:
      let l = j mod largestValid
      if forcedAtLargest[l] < 0:
        forcedAtLargest[l] = diffAt[j]

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
    for k in 2 ..< positions.len:
      stepValue = greatestCommonDivisor(positions[k] - positions[k - 1], stepValue)
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
  for k in 0 .. cipherBound:
    validIndexAt[k] = -1
  for k in 0 ..< validCount:
    validIndexAt[validLengths[k]] = k

  var coverStamp: seq[int]
  coverStamp.setLen(cipherBound + 1)
  for k in 0 .. cipherBound:
    coverStamp[k] = 0
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

  for j in 0 ..< textLength:
    if plainText[j] != '*':
      answerFor[j] = plainText[j]
      pendingFor[j] = 0
      continue
    if cipherText[j] == '*':
      answerFor[j] = '*'
      pendingFor[j] = 0
      continue
    let forcedDiff = forcedAtLargest[j mod largestValid]
    if forcedDiff < 0:
      answerFor[j] = '*'
      pendingFor[j] = 0
      continue
    let diffValue = int(forcedDiff)
    let plainValue = (int(cipherText[j]) - firstLetterValue - diffValue + 26) mod 26
    answerFor[j] = char(firstLetterValue + plainValue)
    if validCount == 1:
      pendingFor[j] = 0
      continue
    if false:
      let l = j - groupFirst[diffValue]
      let modulus = groupNeed[diffValue]
      var coveredEverywhere = (modulus > 0 and l mod modulus == 0)
      if coveredEverywhere:
        for lengthValue in groupCritical[diffValue]:
          let common = greatestCommonDivisor(groupStep[diffValue], lengthValue)
          let reduced = lengthValue div common
          let aligned = l div common
          let wrapped = (aligned mod reduced + reduced) mod reduced
          if wrapped > groupTermCount[diffValue]:
            coveredEverywhere = false
            break
      if coveredEverywhere:
        pendingFor[j] = 0
      else:
        answerFor[j] = '*'
        pendingFor[j] = 0
      continue
    pendingFor[j] = 1
    targetFor[j] = forcedDiff
    checkedFor[j] = 1
    alivePositions.add j

  var residueValue: seq[int8]
  var nextAlive: seq[int] = @[]
  var i = validCount - 2
  var sweepWork = 0
  var staleSweepCount = 0
  while i >= 0 and sweepWork < sweepWorkBudget and staleSweepCount < staleSweepLimit:
    let modulus = validLengths[i]
    residueValue.setLen(modulus)
    for l in 0 ..< modulus:
      residueValue[l] = -1
    for j in 0 ..< textLength:
      if diffAt[j] >= 0:
        residueValue[j mod modulus] = diffAt[j]
    sweepWork += modulus + knownCount
    nextAlive.setLen 0
    var killedNow = 0
    for k in 0 ..< alivePositions.len:
      let j = alivePositions[k]
      let l = j mod modulus
      if residueValue[l] == targetFor[j]:
        checkedFor[j].inc
        nextAlive.add j
        sweepWork.inc
      else:
        pendingFor[j] = 0
        answerFor[j] = '*'
        killedNow.inc
    swap(alivePositions, nextAlive)
    if killedNow == 0:
      staleSweepCount.inc
    else:
      staleSweepCount = 0
    i.dec

  for k in 0 ..< alivePositions.len:
    let j = alivePositions[k]
    let diffValue = int(targetFor[j])
    let l = validCount - checkedFor[j]
    stampCounter.inc
    var coveredCount = 0
    let positions = valuePositions[diffValue]
    for i in 0 ..< positions.len:
      let other = positions[i]
      let distance = if other > j: other - j else: j - other
      buildDivisors(distance)
      for k in 0 ..< divisorBuffer.len:
        let lengthValue = divisorBuffer[k]
        if lengthValue > cipherBound:
          continue
        let i = validIndexAt[lengthValue]
        if i < 0 or i >= l or coverStamp[lengthValue] == stampCounter:
          continue
        coverStamp[lengthValue] = stampCounter
        coveredCount.inc
        if coveredCount == l:
          break
      if coveredCount == l:
        break
    if coveredCount < l:
      answerFor[j] = '*'
    pendingFor[j] = 0

  for j in 0 ..< textLength:
    emitChar(answerFor[j])
  emitChar('\n')

stdout.write outputBuffer
