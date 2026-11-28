import algorithm

const flushBlockBytes = 1 shl 17
const modulusValue = 5000000

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return value

proc prefixQuery(tree: seq[int], upperIndex: int): int =
  var total = 0
  var cursor = upperIndex
  while cursor > 0:
    total = (total + tree[cursor]) mod modulusValue
    cursor -= cursor and (-cursor)
  return total

proc addToTree(tree: var seq[int], startIndex: int, deltaValue: int) =
  var cursor = startIndex
  while cursor <= tree.len - 1:
    tree[cursor] = (tree[cursor] + deltaValue) mod modulusValue
    cursor += cursor and (-cursor)

proc findRank(sortedValues: seq[int], targetValue: int): int =
  var lowIndex = 0
  var highIndex = sortedValues.len - 1
  while lowIndex <= highIndex:
    let middleIndex = (lowIndex + highIndex) div 2
    if sortedValues[middleIndex] < targetValue:
      lowIndex = middleIndex + 1
    elif sortedValues[middleIndex] > targetValue:
      highIndex = middleIndex - 1
    else:
      return middleIndex + 1
  return 0

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let elementCount = nextInt(inputData, scanPos)
let subsequenceLength = nextInt(inputData, scanPos)
var sequenceValues = newSeq[int](elementCount)
var sortedValues = newSeq[int](elementCount)
for position in 0 .. elementCount - 1:
  sequenceValues[position] = nextInt(inputData, scanPos)
  sortedValues[position] = sequenceValues[position]
sortedValues.sort(proc (leftValue, rightValue: int): int = cmp(leftValue, rightValue))
var distinctCount = 0
for position in 0 .. elementCount - 1:
  if position == 0 or sortedValues[position] != sortedValues[position - 1]:
    sortedValues[distinctCount] = sortedValues[position]
    distinctCount += 1
sortedValues.setLen(distinctCount)
var fenwickTrees = newSeq[seq[int]](subsequenceLength + 1)
var lastCounts = newSeq[seq[int]](subsequenceLength + 1)
for lengthIndex in 0 .. subsequenceLength:
  fenwickTrees[lengthIndex] = newSeq[int](distinctCount + 1)
  lastCounts[lengthIndex] = newSeq[int](distinctCount + 1)
for position in 0 .. elementCount - 1:
  let valueRank = findRank(sortedValues, sequenceValues[position])
  for lengthIndex in countdown(subsequenceLength, 2):
    let newlyFound = prefixQuery(fenwickTrees[lengthIndex - 1], valueRank - 1)
    var deltaValue = (newlyFound - lastCounts[lengthIndex][valueRank]) mod modulusValue
    if deltaValue < 0:
      deltaValue += modulusValue
    addToTree(fenwickTrees[lengthIndex], valueRank, deltaValue)
    lastCounts[lengthIndex][valueRank] = newlyFound
  var singleDelta = (1 - lastCounts[1][valueRank]) mod modulusValue
  if singleDelta < 0:
    singleDelta += modulusValue
  addToTree(fenwickTrees[1], valueRank, singleDelta)
  lastCounts[1][valueRank] = 1
let answerValue = prefixQuery(fenwickTrees[subsequenceLength], distinctCount)
appendOutput($answerValue)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
