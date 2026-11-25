const flushBlockBytes = 1 shl 17
const bigBase: int64 = 1000000000
const limbDigits = 9
const maximumDimension = 30

type TestCase = object
  dimension: int
  budget: int
  points: seq[seq[int64]]

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt64(data: string, pos: var int): int64 =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value: int64 = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int64(int(data[pos]) - 48)
    pos += 1
  return value

proc addBig(left: seq[int32], right: seq[int32]): seq[int32] =
  let longest = max(left.len, right.len)
  var sumValue = newSeq[int32](longest + 1)
  var carry: int64 = 0
  var limbIndex = 0
  while limbIndex < longest:
    var limbSum: int64 = carry
    if limbIndex < left.len:
      limbSum += int64(left[limbIndex])
    if limbIndex < right.len:
      limbSum += int64(right[limbIndex])
    sumValue[limbIndex] = int32(limbSum mod bigBase)
    carry = limbSum div bigBase
    limbIndex += 1
  sumValue[longest] = int32(carry)
  while sumValue.len > 1 and sumValue[sumValue.len - 1] == 0:
    sumValue.setLen(sumValue.len - 1)
  return sumValue

proc subBig(left: seq[int32], right: seq[int32]): seq[int32] =
  var difference = newSeq[int32](left.len)
  var borrow: int64 = 0
  var limbIndex = 0
  while limbIndex < left.len:
    var limbValue: int64 = int64(left[limbIndex]) - borrow
    if limbIndex < right.len:
      limbValue -= int64(right[limbIndex])
    if limbValue < 0:
      limbValue += bigBase
      borrow = 1
    else:
      borrow = 0
    difference[limbIndex] = int32(limbValue)
    limbIndex += 1
  while difference.len > 1 and difference[difference.len - 1] == 0:
    difference.setLen(difference.len - 1)
  return difference

proc toStringBig(value: seq[int32]): string =
  if value.len == 0:
    return "0"
  var decimalText = $value[value.len - 1]
  var limbIndex = value.len - 2
  while limbIndex >= 0:
    var limbText = $value[limbIndex]
    while limbText.len < limbDigits:
      limbText = "0" & limbText
    decimalText.add limbText
    limbIndex -= 1
  return decimalText

proc buildBinomialTable(dimension: int, highest: int): seq[seq[int32]] =
  var row = newSeq[seq[int32]](dimension + 1)
  for index in 0 .. dimension:
    row[index] = @[]
  row[0] = @[int32(1)]
  var table = newSeq[seq[int32]](highest + 1)
  for number in 1 .. highest:
    var upper = number
    if upper > dimension:
      upper = dimension
    var degree = upper
    while degree >= 1:
      row[degree] = addBig(row[degree], row[degree - 1])
      degree -= 1
    if number >= dimension:
      table[number] = row[dimension]
  return table

var activePoints: seq[seq[int64]]
var activeDimension = 0
var activeBudget = 0
var activeTable: seq[seq[int32]]
var currentMaximum: seq[int64]
var positiveTotal: seq[int32]
var negativeTotal: seq[int32]

proc visitSubsets(pointIndex: int, chosenCount: int) =
  if pointIndex == activePoints.len:
    if chosenCount == 0:
      return
    var maximumSum: int64 = 0
    for axis in 0 ..< activeDimension:
      maximumSum += currentMaximum[axis]
    if maximumSum <= int64(activeBudget):
      let termIndex = int(int64(activeBudget) - maximumSum) + activeDimension
      let termValue = activeTable[termIndex]
      if chosenCount mod 2 == 1:
        negativeTotal = addBig(negativeTotal, termValue)
      else:
        positiveTotal = addBig(positiveTotal, termValue)
    return
  visitSubsets(pointIndex + 1, chosenCount)
  var savedMaximum = newSeq[int64](activeDimension)
  for axis in 0 ..< activeDimension:
    savedMaximum[axis] = currentMaximum[axis]
    if activePoints[pointIndex][axis] > currentMaximum[axis]:
      currentMaximum[axis] = activePoints[pointIndex][axis]
  visitSubsets(pointIndex + 1, chosenCount + 1)
  for axis in 0 ..< activeDimension:
    currentMaximum[axis] = savedMaximum[axis]

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = int(nextInt64(inputData, scanPos))
var allCases = newSeq[TestCase](caseCount)
for caseIndex in 0 ..< caseCount:
  var currentCase: TestCase
  currentCase.dimension = int(nextInt64(inputData, scanPos))
  currentCase.budget = int(nextInt64(inputData, scanPos))
  let pointCount = int(nextInt64(inputData, scanPos))
  currentCase.points = newSeq[seq[int64]](pointCount)
  for pointIndex in 0 ..< pointCount:
    currentCase.points[pointIndex] = newSeq[int64](currentCase.dimension)
    for axis in 0 ..< currentCase.dimension:
      currentCase.points[pointIndex][axis] = nextInt64(inputData, scanPos)
  allCases[caseIndex] = currentCase

var largestBudget = newSeq[int](maximumDimension + 1)
for currentCase in allCases:
  if currentCase.budget > largestBudget[currentCase.dimension]:
    largestBudget[currentCase.dimension] = currentCase.budget

var binomialTables = newSeq[seq[seq[int32]]](maximumDimension + 1)
for dimension in 0 .. maximumDimension:
  if largestBudget[dimension] > 0:
    binomialTables[dimension] = buildBinomialTable(dimension,
                                                   largestBudget[dimension] + dimension)

for currentCase in allCases:
  activePoints = currentCase.points
  activeDimension = currentCase.dimension
  activeBudget = currentCase.budget
  activeTable = binomialTables[activeDimension]
  currentMaximum = newSeq[int64](activeDimension)
  positiveTotal = activeTable[activeBudget]
  negativeTotal = @[]
  visitSubsets(0, 0)
  let answer = subBig(positiveTotal, negativeTotal)
  appendOutput(toStringBig(answer))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
