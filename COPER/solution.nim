const firstDigitValue = 48
const flushBlockBytes = 1 shl 18
const maxLocationCount = 1000000

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

proc findSlot(slotParent: var seq[int], index: int): int =
  var root = index
  while slotParent[root] != root:
    root = slotParent[root]
  var cursor = index
  while slotParent[cursor] != cursor:
    let nextIndex = slotParent[cursor]
    slotParent[cursor] = root
    cursor = nextIndex
  return root

proc findRow(rowParent: var seq[int], row: int): int =
  var root = row
  while rowParent[root] != root:
    root = rowParent[root]
  var cursor = row
  while rowParent[cursor] != cursor:
    let nextRow = rowParent[cursor]
    rowParent[cursor] = root
    cursor = nextRow
  return root

proc countMoves(locationCount, emptyLocation, recurrenceMultiplier, recurrenceAdd,
                recurrenceModulus, step: int, slotParent, rowParent, freeCount,
                boxDestination: var seq[int]): int =
  let excludedLocation = emptyLocation mod locationCount
  let classCount = gcdValues(step, locationCount)
  let slotsPerClass = locationCount div classCount
  let stepPerClass = step div classCount
  let stepInverse = modInverse(stepPerClass, slotsPerClass)
  for index in 0 .. locationCount:
    slotParent[index] = index
  for index in 0 .. classCount:
    rowParent[index] = index
  for index in 0 .. classCount - 1:
    freeCount[index] = slotsPerClass
  let excludedRow = excludedLocation mod classCount
  let excludedColumn = excludedLocation div classCount
  let excludedUnit = (stepInverse * excludedColumn) mod slotsPerClass
  let excludedIndex = excludedRow * slotsPerClass + excludedUnit
  slotParent[excludedIndex] = excludedIndex + 1
  freeCount[excludedRow] -= 1
  if freeCount[excludedRow] == 0:
    rowParent[excludedRow] = excludedRow + 1
  var currentC = 0
  for boxNumber in 1 .. locationCount - 1:
    currentC = (currentC * recurrenceMultiplier + recurrenceAdd) mod recurrenceModulus
    let classOfC = currentC mod classCount
    let columnOfC = currentC div classCount
    var freeRow = findRow(rowParent, classOfC)
    if freeRow == classCount:
      freeRow = findRow(rowParent, 0)
    let shiftY = (freeRow - classOfC + classCount) mod classCount
    let carry = (classOfC + shiftY) div classCount
    let startColumn = (columnOfC + carry) mod slotsPerClass
    let startUnit = (stepInverse * startColumn) mod slotsPerClass
    let rowStart = freeRow * slotsPerClass
    let rowEnd = rowStart + slotsPerClass
    var foundIndex = findSlot(slotParent, rowStart + startUnit)
    if foundIndex >= rowEnd:
      foundIndex = findSlot(slotParent, rowStart)
    let unitIndex = foundIndex - rowStart
    let columnIndex = (stepPerClass * unitIndex) mod slotsPerClass
    let assignedSlot = freeRow + classCount * columnIndex
    boxDestination[boxNumber] = assignedSlot
    slotParent[foundIndex] = foundIndex + 1
    freeCount[freeRow] -= 1
    if freeCount[freeRow] == 0:
      rowParent[freeRow] = freeRow + 1
  boxDestination[0] = excludedLocation
  for boxNumber in 0 .. locationCount - 1:
    slotParent[boxNumber] = boxDestination[boxNumber]
  var totalMoves = 0
  for startSlot in 0 .. locationCount - 1:
    if slotParent[startSlot] < 0: continue
    var currentSlot = startSlot
    var cycleLength = 0
    var holdsInitialEmpty = false
    while slotParent[currentSlot] >= 0:
      let nextSlot = slotParent[currentSlot]
      slotParent[currentSlot] = -1
      if currentSlot == 0: holdsInitialEmpty = true
      cycleLength += 1
      currentSlot = nextSlot
    if cycleLength > 1:
      if holdsInitialEmpty:
        totalMoves += cycleLength - 1
      else:
        totalMoves += cycleLength + 1
  return totalMoves

var slotParent = newSeq[int](maxLocationCount + 1)
var rowParent = newSeq[int](maxLocationCount + 1)
var freeCount = newSeq[int](maxLocationCount + 1)
var boxDestination = newSeq[int](maxLocationCount + 1)

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
                          recurrenceAdd, recurrenceModulus, step, slotParent,
                          rowParent, freeCount, boxDestination)
  outputBuffer.add $answer
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
stdout.write outputBuffer
