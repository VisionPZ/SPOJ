# CRYPTO4 — The Bytelandian Cryptographer (Act IV) (SPOJ)

<https://www.spoj.com/problems/CRYPTO4/>

## Problem

Two copies of a secret message arrive with letters burned away. The remaining letters still reveal the repeating key, so some missing letters can be restored with certainty.

Input: one integer for the case count, then an upper bound m, the damaged plaintext x, and the damaged ciphertext y. Stars mark lost characters.

Output: the plaintext x with stars left only where no key makes the letter certain.

The judge bounds the run as follows:

| Item | Bound |
| --- | --- |
| Test cases | 200 |
| Key length bound m | 100000 |
| Total input size | 2 MB |
| Time limit | 17 s |
| Memory limit | 1536 MB |

The total input bound caps all message lengths together.

The sample input and output:

```
4
1
A*X*C
**CM*
4
*B***A
AAAAAA
6
*B***A
AAAAAA
4
*AA*******
AAAAAAAAAA
```

```
A*XHC
*BA*BA
*B***A
*AA**A****
```

## Idea

Turn each known letter pair into a clue on a 26-hour clock, like matching repeated stripes on two rolls of wallpaper. Positions that share a key position must show the same clock offset.

The program uses two fast Fourier transforms (FFTs, fast ways to correlate sequences) to find every distance where two clues disagree. It then tests each candidate key length against those distances. Surviving lengths vote on each lost letter.

One transform costs O(L log L) for a message of length L, and the length sieve costs O(L log m). Testing every length against every position would cost O(m × L).

The transform finds all conflicting distances at once.

## Why It Works

A known pair fixes one key shift.

1. For a known pair, the shift is `(y - x) mod 26`.
2. Two known positions with different shifts rule out any key length that divides their distance.
3. An autocorrelation (a comparison with a shifted copy) counts agreeing pairs at each distance. The real part of the encoded signal falls when shifts disagree.
4. The largest valid length gives one forced shift per residue (position within the key). A lost letter is filled only when every valid length agrees on that shift.

The arrays carry the following facts:

| Term | Meaning |
| --- | --- |
| `diffAt` | key shift at a known position, or -1 when unknown |
| `conflictAt[distance]` | true when that distance holds disagreeing shifts |
| `validLengths` | key lengths with no conflict on any multiple |
| `forcedAtLargest` | shift forced by the largest valid length at a residue |
| `residueValue` | shifts seen at each residue for one candidate length |
| `confidenceMargin` | 0.01, the cut that rejects rounding noise |

The length sieve visits distances n, 2n, 3n, and so on. The sum of those visits stays below about 12 times the message length.

A script restores the first sample case, where m = 1 and only key length 1 is possible:

| Position | Plain | Cipher | Residue mod 1 | Forced shift | Printed |
| --- | --- | --- | --- | --- | --- |
| 0 | A | `*` | 0 | 5 | A |
| 1 | `*` | `*` | 0 | none | `*` |
| 2 | X | C | 0 | 5 | X |
| 3 | `*` | M | 0 | 5 | H |
| 4 | C | `*` | 0 | none | C |

Position 2 gives shift C minus X, which is 5. Position 3 becomes M minus 5, which is H, so the output is `A*XHC`.

## Code

**Constants.** The thresholds bound the work and the rounding risk.

```nim
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
```

Short messages use a direct scan instead of a transform. The margin keeps rounding noise from becoming a conflict. The budgets cap the final verification work.

**Input and scanners.** One buffer holds the stream, and two scanners read integers and words.

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

The read loop stops when `readLine` reports the end of input. The scanners walk the buffer by index and build no token objects. `emitChar` flushes at 256 KiB, so one case never writes per character.

**Transform and trig tables.** Bit reversal and butterfly steps implement the FFT in place.

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

var cosineTable: array[letterCount, float]
var sineTable: array[letterCount, float]
for value in 0 ..< letterCount:
  let angle = 2.0 * circlePi * float(value) / float(letterCount)
  cosineTable[value] = cos(angle)
  sineTable[value] = sin(angle)
```

The outer loop runs one pass per bit of the transform size. Bit reversal puts each sample in butterfly order first. Each table entry places one letter shift on the unit circle.

**Number theory helpers and case setup.** Divisors of a distance give the key lengths that a known pair can rule out.

```nim
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
```

The sieve stores one smallest prime factor per number. `buildDivisors` multiplies those factors into every divisor. The case setup computes one shift per known pair and records where each shift appears.

**Conflict detection and valid lengths.** A direct scan handles short messages; longer ones use two transforms.

```nim
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
```

The short branch visits every distance below the message length. The transform branch encodes shifts with the two trig tables. The sieve walks multiples of each length and keeps the conflict-free ones.

**Answer setup.** The code groups repeated shifts so that some letters need no further check.

```nim
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
```

The group step is the gcd of gaps between equal shifts. The pass keeps known letters and discards letters with a lost ciphertext. Each remaining letter records one target shift.

**Verification sweep.** The code checks smaller valid lengths, then uses divisors for the positions left over.

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

  for j in 0 ..< textLength:
    emitChar(answerFor[j])
  emitChar('\n')

stdout.write outputBuffer
```

The sweep visits valid lengths from large to small and stops after many quiet lengths. The divisor loop reuses `smallestFactor` to test each remaining position. One final pass emits the restored message.

## Complexity

Conflict detection dominates long messages, and the length sieve adds a logarithmic factor.

| Phase | Time | Space |
| --- | --- | --- |
| Input read | one pass over total input | input bytes |
| Shift setup | O(L) per case | O(L) |
| Conflict detection | O(L log L) or O(L²) if short | O(L) |
| Length sieve | O(L log m) per case | O(m) |
| Answer setup | O(L + m) per case | O(L + m) |
| Verification sweep | bounded by two budgets | O(L + m) |
| Output | one write per 256 KiB block | 256 KiB |
| Total per case | O(L log L + L log m) | O(L + m) |

Here L is the message length and m is the key bound.

The asymptotic bounds are as follows:

| Measure | Big O |
| --- | --- |
| Time | O(L log L + L log m) per case |
| Space | O(L + m) per case |

Testing every length against every position would cost O(m × L) per case.
