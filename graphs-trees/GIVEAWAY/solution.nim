import algorithm

const flushBlockBytes = 1 shl 17
const blockSize = 3400

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

proc compareValues(leftValue, rightValue: int): int =
  if leftValue < rightValue:
    return -1
  if leftValue > rightValue:
    return 1
  return 0

proc lowerBound(sortedValues: openArray[int], target: int): int =
  var lowIndex = 0
  var highIndex = sortedValues.len
  while lowIndex < highIndex:
    let middleIndex = (lowIndex + highIndex) div 2
    if sortedValues[middleIndex] < target:
      lowIndex = middleIndex + 1
    else:
      highIndex = middleIndex
  return lowIndex

let elementCount = nextInt(inputData, scanPos)
var currentValues = newSeq[int](elementCount)
let blockCount = (elementCount + blockSize - 1) div blockSize
var sortedBlocks = newSeq[seq[int]](blockCount)
for blockIndex in 0 .. blockCount - 1:
  sortedBlocks[blockIndex] = newSeq[int](0)
for elementIndex in 0 .. elementCount - 1:
  currentValues[elementIndex] = nextInt(inputData, scanPos)
  sortedBlocks[elementIndex div blockSize].add currentValues[elementIndex]
for blockIndex in 0 .. blockCount - 1:
  sort(sortedBlocks[blockIndex], compareValues)

let queryCount = nextInt(inputData, scanPos)
for queryIndex in 0 .. queryCount - 1:
  let queryType = nextInt(inputData, scanPos)
  if queryType == 0:
    let leftIndex = nextInt(inputData, scanPos) - 1
    let rightIndex = nextInt(inputData, scanPos) - 1
    let threshold = nextInt(inputData, scanPos)
    let leftBlock = leftIndex div blockSize
    let rightBlock = rightIndex div blockSize
    var matchingCount = 0
    if leftBlock == rightBlock:
      for elementIndex in leftIndex .. rightIndex:
        if currentValues[elementIndex] >= threshold:
          matchingCount += 1
    else:
      let leftEnd = (leftBlock + 1) * blockSize - 1
      for elementIndex in leftIndex .. leftEnd:
        if currentValues[elementIndex] >= threshold:
          matchingCount += 1
      let rightStart = rightBlock * blockSize
      for elementIndex in rightStart .. rightIndex:
        if currentValues[elementIndex] >= threshold:
          matchingCount += 1
      for blockIndex in leftBlock + 1 .. rightBlock - 1:
        matchingCount += sortedBlocks[blockIndex].len - lowerBound(sortedBlocks[blockIndex], threshold)
    appendOutput($matchingCount)
    outputBuffer.add '\n'
  else:
    let updateIndex = nextInt(inputData, scanPos) - 1
    let newValue = nextInt(inputData, scanPos)
    let blockIndex = updateIndex div blockSize
    let oldValue = currentValues[updateIndex]
    currentValues[updateIndex] = newValue
    var removalIndex = lowerBound(sortedBlocks[blockIndex], oldValue)
    while removalIndex < sortedBlocks[blockIndex].len - 1:
      sortedBlocks[blockIndex][removalIndex] = sortedBlocks[blockIndex][removalIndex + 1]
      removalIndex += 1
    sortedBlocks[blockIndex].setLen(sortedBlocks[blockIndex].len - 1)
    let insertionIndex = lowerBound(sortedBlocks[blockIndex], newValue)
    sortedBlocks[blockIndex].setLen(sortedBlocks[blockIndex].len + 1)
    var shiftIndex = sortedBlocks[blockIndex].len - 1
    while shiftIndex > insertionIndex:
      sortedBlocks[blockIndex][shiftIndex] = sortedBlocks[blockIndex][shiftIndex - 1]
      shiftIndex -= 1
    sortedBlocks[blockIndex][insertionIndex] = newValue

stdout.write outputBuffer
outputBuffer.setLen 0
