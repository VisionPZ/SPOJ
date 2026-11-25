# COPER — Crane Operator (SPOJ)

<https://www.spoj.com/problems/COPER/>

## Problem

Each case hides a target arrangement of boxes over numbered locations. The answer is the fewest crane moves that turn the starting arrangement into that target.

Input starts with T, the number of cases. Each of the next T lines holds six integers: N, M, q, p, m, d. Output one line per case with the minimum move count.

The recurrence sets c0 = 0 and c(i+1) = (c(i) * q + p) mod m. Box i goes to (c(i) + d*x + y) mod N, with x and y non-negative, avoiding M and all earlier destinations. Choose the smallest y first, then the smallest x. The forbidden location is `M mod N`, as the note on the judge page says.

The bounds from the statement:

| Item | Bound |
|---|---|
| Test cases T | at most 7 000 |
| Locations N | at most 1 000 000 |
| Forbidden location M | at most 1 000 000 |
| Step d | at most 1 000 000 |
| Recurrence values q, p, m | at most 10 000 |
| Judge limit | 40 s, 1 536 MB |

The million-location bound drives the design. The recurrence modulus stays below ten thousand, so values of c repeat quickly.

Write `g = gcd(d, N)`, `n' = N / g` and `d' = d / g` for the notes below. Here `d'` is the column step inside one class.

The sample case:

```
1
8 3 5 2 7 4
```

```
6
```

The sample answer is six moves.

## Idea

Picture locations as parking spaces and boxes as drivers who follow one fixed route. Each driver takes the first free space on that route, and the crane then untangles the cycles.

The program stores free spaces in bitmaps. One 64-bit word holds 64 spaces, so one bit test skips a whole group of occupied cells. A small parent table over words jumps past words that are completely full. Each box costs one word find, one bit scan and two table reads.

The recurrence values repeat within m steps, and m stays below ten thousand. The program stores one period once. It precomputes the starting unit for every value and both carry cases, so no division runs inside the box loop.

The final pass follows the destination permutation and counts cycles. A compact 32-bit array keeps that random walk in the cache. Scanning every (x, y) pair costs up to N squared steps per box, and a search over arrangements grows exponentially.

One pass over the boxes and one pass over the locations give the answer for every case.

## Why It Works

Five facts carry the proof.

1. For fixed y, the term d*x mod N is always a multiple of g. The box reaches only locations whose residue mod g matches (c(i) + y) mod g.
2. Values y from 0 through g - 1 cover all g residues. The smallest y comes from the first class that still has a free location.
3. Inside one class, d' permutes the n' columns. Multiplying by the inverse of d' turns a column jump into one step.
4. A bitmap word marks occupied units. A parent table over words skips full words, and the trailing zero count gives the first free unit.
5. The destination map is a permutation of locations. A cycle through location 0 costs length minus one moves; each other nontrivial cycle costs length plus one.

These facts reduce the secret rule to two bitmap searches and one cycle sum.

The terms and formulas:

| Term | Meaning |
|---|---|
| `g` | count of residue classes, equal to gcd(d, N) |
| `n'` | locations in one class, equal to N / g |
| `d'` | column step in one class, equal to d / g |
| `stepInverse` | inverse of `d'` modulo `n'`, turns a jump into one step |
| `excludedLocation` | forbidden location, equal to M mod N |
| `startUnitTable` | starting unit for each recurrence value and carry |
| `cycleLength` | size of one cycle in the destination map |

Every size follows from the single division of N by g.

A script trace of the sample case:

```
N=8 M=3 d=4 g=4 n1=2 dp=1 inv=1 excluded=3
box c class col row y startCol startUnit slot
  1 2     2   0   2 0        0         0    2
  2 5     1   1   1 0        1         1    5
  3 6     2   1   2 0        1         1    6
  4 4     0   1   0 0        1         1    4
  5 1     1   0   1 0        0         0    1
  6 0     0   0   0 0        0         0    0
  7 2     2   0   3 1        0         0    7
successor 0->3 1->2 2->5 3->6 4->4 5->1 6->0 7->7
cycle 0 length 3 cost 2
cycle 1 length 3 cost 4
total 6
```

Box 7 skips the full class 2 and lands on 7. The two nontrivial cycles then cost 2 and 4 moves, giving 6.

## Code

Constants and scanner. One read of stdin feeds a digit scanner.

```nim
import bitops

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const maxLocationCount = 1000000
const maxRecurrenceModulus = 10000
const wordBitCount = 64
const maxWordCount = maxLocationCount div wordBitCount + 4

var generation = 0

proc nextInt(inputData: string, scanPos: var int): int =
  while scanPos < inputData.len and (inputData[scanPos] < '0' or inputData[scanPos] > '9'):
    scanPos += 1
  var value = 0
  while scanPos < inputData.len and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    value = value * 10 + int(inputData[scanPos]) - firstDigitValue
    scanPos += 1
  return value
```

`wordBitCount` sets the group size. `maxWordCount` sizes the word tables. The scanner costs one pass over the input bytes.

Arithmetic helpers. Division and inversion set up the column relabeling.

```nim
proc gcdValues(firstValue, secondValue: int): int =
  var dividend = firstValue
  var divisor = secondValue
  while divisor != 0:
    let remainder = dividend mod divisor
    dividend = divisor
    divisor = remainder
  return dividend

proc modInverse(value, modulus: int): int =
  if modulus == 1: return 0
  var oldCoeff = 0
  var coeff = 1
  var oldRem = modulus
  var rem = value mod modulus
  while rem != 0:
    let quotient = oldRem div rem
    let nextOldCoeff = coeff
    coeff = oldCoeff - quotient * coeff
    oldCoeff = nextOldCoeff
    let nextOldRem = rem
    rem = oldRem - quotient * rem
    oldRem = nextOldRem
  return (oldCoeff mod modulus + modulus) mod modulus
```

`gcdValues` yields the class count. `modInverse` handles a single-column class as a special case. Both run once per case.

Bitmap searches. Each word covers sixty-four spaces or classes.

```nim
proc findWord(wordParent: var seq[int], index: int): int =
  var cursor = index
  while wordParent[cursor] != cursor:
    wordParent[cursor] = wordParent[wordParent[cursor]]
    cursor = wordParent[cursor]
  return cursor

proc nextFreeSlot(slotBits, slotWordParent: var seq[int], index: int): int =
  let wordIndex = index div wordBitCount
  let bitOffset = index mod wordBitCount
  let candidate = slotBits[wordIndex] or not (-1 shl bitOffset)
  if candidate != -1:
    return wordIndex * wordBitCount + countTrailingZeroBits(not candidate)
  let freeWord = findWord(slotWordParent, wordIndex + 1)
  return freeWord * wordBitCount + countTrailingZeroBits(not slotBits[freeWord])

proc nextFreeRow(rowBits, rowWordParent: var seq[int], row: int): int =
  let wordIndex = row div wordBitCount
  let bitOffset = row mod wordBitCount
  let candidate = rowBits[wordIndex] or not (-1 shl bitOffset)
  if candidate != -1:
    return wordIndex * wordBitCount + countTrailingZeroBits(not candidate)
  let freeWord = findWord(rowWordParent, wordIndex + 1)
  return freeWord * wordBitCount + countTrailingZeroBits(not rowBits[freeWord])

proc markSlot(slotBits, slotWordParent: var seq[int], index: int) =
  let wordIndex = index div wordBitCount
  slotBits[wordIndex] = slotBits[wordIndex] or (1 shl (index mod wordBitCount))
  if slotBits[wordIndex] == -1:
    slotWordParent[wordIndex] = wordIndex + 1

proc markRow(rowBits, rowWordParent: var seq[int], row: int) =
  let wordIndex = row div wordBitCount
  rowBits[wordIndex] = rowBits[wordIndex] or (1 shl (row mod wordBitCount))
  if rowBits[wordIndex] == -1:
    rowWordParent[wordIndex] = wordIndex + 1
```

`countTrailingZeroBits` picks the first free bit in a word. `findWord` compresses its path while skipping full words. `markSlot` and `markRow` link a word only when it fills.

Per-case setup. The bitmaps, counters and recurrence period start here.

```nim
proc countMoves(locationCount, emptyLocation, recurrenceMultiplier, recurrenceAdd,
                 recurrenceModulus, step: int, slotBits, slotWordParent, rowBits,
                 rowWordParent, freeCount: var seq[int], boxDestination: var seq[int32],
                 columnFromUnit, classOfValue, startUnitTable, valueStamp,
                 valueIndex, streamValues: var seq[int]): int =
  let excludedLocation = emptyLocation mod locationCount
  let classCount = gcdValues(step, locationCount)
  let slotsPerClass = locationCount div classCount
  let stepPerClass = step div classCount
  let stepUnit = stepPerClass mod slotsPerClass
  let stepInverse = modInverse(stepUnit, slotsPerClass)
  let slotWordCount = (locationCount + wordBitCount - 1) div wordBitCount
  let rowWordCount = (classCount + wordBitCount - 1) div wordBitCount
  for wordIndex in 0 .. slotWordCount:
    slotBits[wordIndex] = 0
    slotWordParent[wordIndex] = wordIndex
  for wordIndex in 0 .. rowWordCount:
    rowBits[wordIndex] = 0
    rowWordParent[wordIndex] = wordIndex
  let trailingSlots = locationCount mod wordBitCount
  if trailingSlots != 0:
    slotBits[slotWordCount - 1] = -1 shl trailingSlots
  let trailingRows = classCount mod wordBitCount
  if trailingRows != 0:
    rowBits[rowWordCount - 1] = -1 shl trailingRows
  for row in 0 .. classCount - 1:
    freeCount[row] = slotsPerClass
  columnFromUnit[0] = 0
  for unit in 1 .. slotsPerClass - 1:
    let nextColumn = columnFromUnit[unit - 1] + stepUnit
    if nextColumn >= slotsPerClass:
      columnFromUnit[unit] = nextColumn - slotsPerClass
    else:
      columnFromUnit[unit] = nextColumn
  generation += 1
  var streamLength = 0
  var currentValue = 0
  while valueStamp[currentValue] != generation:
    valueStamp[currentValue] = generation
    valueIndex[currentValue] = streamLength
    streamValues[streamLength] = currentValue
    streamLength += 1
    currentValue = (currentValue * recurrenceMultiplier + recurrenceAdd) mod recurrenceModulus
  let cycleStart = valueIndex[currentValue]
  for value in 0 .. recurrenceModulus - 1:
    classOfValue[value] = value mod classCount
    let baseColumn = (value div classCount) mod slotsPerClass
    for carryValue in 0 .. 1:
      var startColumn = baseColumn + carryValue
      if startColumn >= slotsPerClass: startColumn -= slotsPerClass
      let startUnit = (stepInverse * startColumn) mod slotsPerClass
      startUnitTable[value * 2 + carryValue] = startUnit
```

The trailing masks mark unused bits as occupied. `columnFromUnit` grows by repeated addition. The generation stamp avoids clearing the period tables.

Configuration build. Each box takes its first free unit in probe order.

```nim
  let excludedRow = excludedLocation mod classCount
  let excludedColumn = excludedLocation div classCount
  let excludedUnit = (stepInverse * excludedColumn) mod slotsPerClass
  let excludedIndex = excludedRow * slotsPerClass + excludedUnit
  markSlot(slotBits, slotWordParent, excludedIndex)
  freeCount[excludedRow] -= 1
  if freeCount[excludedRow] == 0:
    markRow(rowBits, rowWordParent, excludedRow)
  var streamIndex = 1
  if streamIndex >= streamLength: streamIndex = cycleStart
  for boxNumber in 1 .. locationCount - 1:
    let currentValue = streamValues[streamIndex]
    let classOfC = classOfValue[currentValue]
    streamIndex += 1
    if streamIndex >= streamLength: streamIndex = cycleStart
    var freeRow = nextFreeRow(rowBits, rowWordParent, classOfC)
    if freeRow >= classCount:
      freeRow = nextFreeRow(rowBits, rowWordParent, 0)
    var shiftY = freeRow - classOfC
    if shiftY < 0: shiftY += classCount
    var carryValue = 0
    if classOfC + shiftY >= classCount: carryValue = 1
    let startUnit = startUnitTable[currentValue * 2 + carryValue]
    let rowStart = freeRow * slotsPerClass
    let rowEnd = rowStart + slotsPerClass
    var foundIndex = nextFreeSlot(slotBits, slotWordParent, rowStart + startUnit)
    if foundIndex >= rowEnd:
      foundIndex = nextFreeSlot(slotBits, slotWordParent, rowStart)
    let unitIndex = foundIndex - rowStart
    let columnIndex = columnFromUnit[unitIndex]
    boxDestination[boxNumber] = int32(freeRow + classCount * columnIndex)
    markSlot(slotBits, slotWordParent, foundIndex)
    freeCount[freeRow] -= 1
    if freeCount[freeRow] == 0:
      markRow(rowBits, rowWordParent, freeRow)
```

`excludedIndex` reserves the forbidden slot. `nextFreeRow` gives the smallest y, with one wrap when needed. `boxDestination` stores each target as a 32-bit value.

Move count. One visit per location sums the cycle costs.

```nim
  boxDestination[0] = int32(excludedLocation)
  var totalMoves = 0
  for startSlot in 0 .. locationCount - 1:
    if boxDestination[startSlot] < 0: continue
    var currentSlot = startSlot
    var cycleLength = 0
    var holdsInitialEmpty = false
    while boxDestination[currentSlot] >= 0:
      let nextSlot = int(boxDestination[currentSlot])
      boxDestination[currentSlot] = -1
      if currentSlot == 0: holdsInitialEmpty = true
      cycleLength += 1
      currentSlot = nextSlot
    if cycleLength > 1:
      if holdsInitialEmpty:
        totalMoves += cycleLength - 1
      else:
        totalMoves += cycleLength + 1
  return totalMoves
```

The `-1` marker replaces a visited array. A cycle through location 0 costs `cycleLength - 1`; others cost `cycleLength + 1`. Fixed points add nothing.

Driver. One input buffer, one output buffer, and block writes.

```nim
var slotBits = newSeq[int](maxWordCount)
var slotWordParent = newSeq[int](maxWordCount)
var rowBits = newSeq[int](maxWordCount)
var rowWordParent = newSeq[int](maxWordCount)
var freeCount = newSeq[int](maxLocationCount + 1)
var boxDestination = newSeq[int32](maxLocationCount + 1)
var columnFromUnit = newSeq[int](maxLocationCount + 1)
var classOfValue = newSeq[int](maxRecurrenceModulus + 1)
var startUnitTable = newSeq[int](2 * maxRecurrenceModulus + 2)
var valueStamp = newSeq[int](maxRecurrenceModulus + 1)
var valueIndex = newSeq[int](maxRecurrenceModulus + 1)
var streamValues = newSeq[int](maxRecurrenceModulus + 2)

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
let caseCount = nextInt(inputData, scanPos)
var outputBuffer = ""
for caseIndex in 0 .. caseCount - 1:
  let locationCount = nextInt(inputData, scanPos)
  let emptyLocation = nextInt(inputData, scanPos)
  let recurrenceMultiplier = nextInt(inputData, scanPos)
  let recurrenceAdd = nextInt(inputData, scanPos)
  let recurrenceModulus = nextInt(inputData, scanPos)
  let step = nextInt(inputData, scanPos)
  let answer = countMoves(locationCount, emptyLocation, recurrenceMultiplier,
                          recurrenceAdd, recurrenceModulus, step, slotBits,
                          slotWordParent, rowBits, rowWordParent, freeCount,
                          boxDestination, columnFromUnit, classOfValue,
                          startUnitTable, valueStamp, valueIndex, streamValues)
  outputBuffer.add $answer
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
stdout.write outputBuffer
```

All six values come from `nextInt` with no token objects. `outputBuffer` flushes at `flushBlockBytes` and once at the end. Every table is allocated once, outside the case loop.

## Complexity

The work splits into input, setup, configuration, cycle count and output.

| Phase | Time | Space |
|---|---|---|
| Input read | one pass over input bytes | input bytes |
| Per-case setup | one word per 64 locations and classes | reused bitmap tables |
| Recurrence tables | at most m values and two carries each | small period tables |
| Configuration build | one word find and two array reads per box | bitmaps and destination array |
| Move count | one visit per location | 32-bit destination array |
| Output | one write per block | block buffer |

Setup and counting both scale with N, and no case allocates a new table.

The overall bounds:

| Measure | Big O |
|---|---|
| Time | O(N α(N / 64) + m) per case, plus output bytes |
| Space | O(N) for the reused tables, O(m) for the period tables |

The function α grows so slowly that it stays below five for any legal N. A naive scan costs O(N squared) per case, so the bitmap pass is the decisive gain.
