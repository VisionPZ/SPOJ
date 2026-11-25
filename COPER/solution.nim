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
