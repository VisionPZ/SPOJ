import algorithm

const flushBlockBytes = 1 shl 17

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

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

type QueryRecord = object
  leftPos: int
  rightPos: int
  requiredCount: int
  answerIndex: int

proc compareNumbers(leftValue: int, rightValue: int): int =
  leftValue - rightValue

proc findValueId(sortedValues: seq[int], target: int): int =
  var lowIndex = 0
  var highIndex = sortedValues.len - 1
  while lowIndex <= highIndex:
    let middleIndex = (lowIndex + highIndex) div 2
    if sortedValues[middleIndex] < target:
      lowIndex = middleIndex + 1
    elif sortedValues[middleIndex] > target:
      highIndex = middleIndex - 1
    else:
      return middleIndex
  return lowIndex

let elementCount = nextInt(inputData, scanPos)
let queryCount = nextInt(inputData, scanPos)

var rawValues = newSeq[int](elementCount)
var sortedValues = newSeq[int](elementCount)
for elementIndex in 0 .. elementCount - 1:
  let currentValue = nextInt(inputData, scanPos)
  rawValues[elementIndex] = currentValue
  sortedValues[elementIndex] = currentValue
sortedValues.sort(compareNumbers)

var distinctValues = newSeq[int]()
for sortedValue in sortedValues:
  if distinctValues.len == 0 or distinctValues[distinctValues.len - 1] != sortedValue:
    distinctValues.add sortedValue

var compressedValues = newSeq[int](elementCount)
for elementIndex in 0 .. elementCount - 1:
  compressedValues[elementIndex] = findValueId(distinctValues, rawValues[elementIndex])

var blockSize = 1
while blockSize * blockSize < elementCount:
  blockSize += 1

var queryRecords = newSeq[QueryRecord](queryCount)
for queryIndex in 0 .. queryCount - 1:
  let leftBound = nextInt(inputData, scanPos)
  let rightBound = nextInt(inputData, scanPos)
  let dominanceFactor = nextInt(inputData, scanPos)
  let spanLength = rightBound - leftBound + 1
  queryRecords[queryIndex].leftPos = leftBound - 1
  queryRecords[queryIndex].rightPos = rightBound - 1
  queryRecords[queryIndex].requiredCount = (spanLength + dominanceFactor - 1) div dominanceFactor
  queryRecords[queryIndex].answerIndex = queryIndex

proc compareQueries(leftQuery: QueryRecord, rightQuery: QueryRecord): int =
  let leftBlock = leftQuery.leftPos div blockSize
  let rightBlock = rightQuery.leftPos div blockSize
  if leftBlock != rightBlock:
    return leftBlock - rightBlock
  if (leftBlock and 1) == 1:
    return rightQuery.rightPos - leftQuery.rightPos
  return leftQuery.rightPos - rightQuery.rightPos

queryRecords.sort(compareQueries)

var occurrenceCounts = newSeq[int](distinctValues.len)
var countOfCounts = newSeq[int](elementCount + 1)
var maxFrequency = 0

proc addOccurrence(valueId: int) =
  let oldCount = occurrenceCounts[valueId]
  if oldCount > 0:
    countOfCounts[oldCount] -= 1
  let newCount = oldCount + 1
  occurrenceCounts[valueId] = newCount
  countOfCounts[newCount] += 1
  if newCount > maxFrequency:
    maxFrequency = newCount

proc removeOccurrence(valueId: int) =
  let oldCount = occurrenceCounts[valueId]
  countOfCounts[oldCount] -= 1
  let newCount = oldCount - 1
  occurrenceCounts[valueId] = newCount
  countOfCounts[newCount] += 1
  if oldCount == maxFrequency and countOfCounts[oldCount] == 0:
    maxFrequency -= 1

var answers = newSeq[string](queryCount)
var currentLeft = 0
var currentRight = -1
for query in queryRecords:
  while currentRight < query.rightPos:
    currentRight += 1
    addOccurrence(compressedValues[currentRight])
  while currentLeft > query.leftPos:
    currentLeft -= 1
    addOccurrence(compressedValues[currentLeft])
  while currentRight > query.rightPos:
    removeOccurrence(compressedValues[currentRight])
    currentRight -= 1
  while currentLeft < query.leftPos:
    removeOccurrence(compressedValues[currentLeft])
    currentLeft += 1
  if query.requiredCount <= 1 or maxFrequency >= query.requiredCount:
    answers[query.answerIndex] = "YES\n"
  else:
    answers[query.answerIndex] = "NO\n"

for answerText in answers:
  appendOutput(answerText)
stdout.write outputBuffer
outputBuffer.setLen 0
