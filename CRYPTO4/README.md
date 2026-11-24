## Problem

Each test case gives a bound m, a damaged plaintext x, and a damaged ciphertext y. The cipher adds a repeating key of length n to each plaintext letter, where 1 <= n <= m. A star marks a lost character. Print x, filling a lost letter only when every consistent key gives that letter. Otherwise print a star.

The judge bounds the run as follows.

| Quantity | Limit |
| --- | --- |
| Test cases | 200 |
| Key length bound m | 100000 |
| Total input size | 2 MB |
| Time limit | 17 s |
| Memory limit | 1536 MB |

The total input bound caps all message lengths together.

## Idea

Each known pair gives a key shift; a length n works when positions sharing a residue modulo n share one shift. The program finds conflicting distances with two FFT (fast Fourier transform) autocorrelations, which count matching shifts in one pass. A naive scan would compare every length with every position; the transform replaces that scan.

Cost per item: one transform per encoded array, and one divisor check per unresolved position.

## Why It Works

For a fully known position the shift is y minus x modulo 26. Two positions with different shifts rule out n exactly when n divides their distance.

The program maps each shift to a point on the unit circle. The real part of the autocorrelation at a distance counts overlapping known pairs when their shifts match. Each mismatch lowers that real part by at least 0.029. The program uses confidenceMargin as the cut.

For each length n, the sieve visits the distances n, 2n, 3n, and so on. The sum of those visits stays below about 12 times the message length.

The largest valid length gives one forced shift per used residue. A lost letter takes y minus that shift when every valid length covers its residue. One uncovered residue leaves the letter lost.

The arrays carry one fact each.

- `conflictAt` holds the conflict flag for a distance.
- `invalidAt` holds a conflict at any multiple of a length.
- `forcedAtLargest` holds the shift forced at a residue.
- `residueValue` holds the shift seen at a residue for the current length.
- `buildDivisors` lists lengths that cover one position when a final check is needed.

The sample case with m set to 4 leaves one valid length.

| Position | Plain | Cipher | Residue mod 3 | Forced shift | Printed |
| --- | --- | --- | --- | --- | --- |
| 0 | * | A | 0 | none | * |
| 1 | B | A | 1 | 25 | B |
| 2 | * | A | 2 | 0 | A |
| 3 | * | A | 0 | none | * |
| 4 | * | A | 1 | 25 | B |
| 5 | A | A | 2 | 0 | A |

Positions 0 and 3 stay lost because residue 0 has no known shift.

## Code

The blocks below come from the program without edits.

```nim
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
```

The read loop stops when readLine reports the end of input. The scanner walks inputData by index and builds no token objects. emitChar flushes every flushBlockBytes bytes, so one case never writes per character.

```nim
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
```

The outer loop runs one pass per bit of size. Bit reversal puts each sample in butterfly order before those passes. This block costs O(size log size) arithmetic.

```nim
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
```

The short branch visits every distance below textLength, so its bound is the message length squared. The transform branch encodes shifts with cosineTable and sineTable. The margin confidenceMargin keeps rounding noise from becoming a conflict.

```nim
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
```

The sieve walks multiples of a length up to textLength and stops at the first conflict. That walk costs about textLength times the harmonic sum of the bound. The last loop stores one forced shift per residue at the largest valid length.

```nim
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
```

```nim
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
```

This pass touches each position once. It keeps letters already known in x and letters with a lost y. It sets one target shift from the largest valid length.

```nim
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
```

The sweep visits valid lengths from large to small and stops after staleSweepLimit quiet lengths. The divisor loop uses smallestFactor and buildDivisors for the remaining positions. Each surviving position pays one divisor scan.

## Complexity

Input reading and parsing take time linear in the total input size and use one buffer.

Conflict detection takes O(textLength log textLength) time for long messages. Messages with at most bruteForceLimit characters use the direct scan instead.

The length sieve takes O(textLength log m) time. The answer setup takes O(textLength + m) time. The sweep is capped by sweepWorkBudget and staleSweepLimit. Divisor scans handle the positions left after the sweep.

Space is O(textLength + m) for the arrays, plus transform arrays of the next power of two above twice the message length.

The total time is O(textLength log textLength + textLength log m) plus the answer work. A naive method tests every length against every position and costs O(m times textLength).
