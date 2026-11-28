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

let valueCount = nextInt(inputData, scanPos)
var values = newSeq[int](valueCount)
var prefixSums = newSeq[int64](valueCount + 1)
var sortedValues = newSeq[int](valueCount)
for valueIndex in 0 .. valueCount - 1:
  values[valueIndex] = nextInt(inputData, scanPos)
  prefixSums[valueIndex + 1] = prefixSums[valueIndex] + int64(values[valueIndex])
  sortedValues[valueIndex] = values[valueIndex]
sortedValues.sort(proc(leftValue, rightValue: int): int = leftValue - rightValue)

var uniqueValues = newSeq[int]()
for value in sortedValues:
  if uniqueValues.len == 0 or uniqueValues[uniqueValues.len - 1] != value:
    uniqueValues.add value

proc findValueIndex(value: int): int =
  var lowIndex = 0
  var highIndex = uniqueValues.len - 1
  while lowIndex <= highIndex:
    let middleIndex = (lowIndex + highIndex) div 2
    if uniqueValues[middleIndex] < value:
      lowIndex = middleIndex + 1
    elif uniqueValues[middleIndex] > value:
      highIndex = middleIndex - 1
    else:
      return middleIndex
  return 0

var compressedValues = newSeq[int](valueCount)
for valueIndex in 0 .. valueCount - 1:
  compressedValues[valueIndex] = findValueIndex(values[valueIndex])

var baseSize = 1
while baseSize < uniqueValues.len:
  baseSize *= 2
var treeSums = newSeq[int](baseSize * 2)
var treePeaks = newSeq[int](baseSize * 2)

proc changeCount(valueIndex: int, delta: int) =
  var nodeIndex = baseSize + valueIndex
  treeSums[nodeIndex] = treeSums[nodeIndex] + delta
  treePeaks[nodeIndex] = treeSums[nodeIndex]
  nodeIndex = nodeIndex div 2
  while nodeIndex >= 1:
    let leftChild = nodeIndex * 2
    let rightChild = leftChild + 1
    treeSums[nodeIndex] = treeSums[leftChild] + treeSums[rightChild]
    if treePeaks[leftChild] > treePeaks[rightChild]:
      treePeaks[nodeIndex] = treePeaks[leftChild]
    else:
      treePeaks[nodeIndex] = treePeaks[rightChild]
    nodeIndex = nodeIndex div 2

proc kthValue(rank: int): int =
  var nodeIndex = 1
  var remainingRank = rank
  while nodeIndex < baseSize:
    let leftChild = nodeIndex * 2
    if treeSums[leftChild] >= remainingRank:
      nodeIndex = leftChild
    else:
      remainingRank = remainingRank - treeSums[leftChild]
      nodeIndex = leftChild + 1
  return uniqueValues[nodeIndex - baseSize]

proc largestModeValue(): int =
  let peakCount = treePeaks[1]
  var nodeIndex = 1
  while nodeIndex < baseSize:
    let rightChild = nodeIndex * 2 + 1
    if treePeaks[rightChild] == peakCount:
      nodeIndex = rightChild
    else:
      nodeIndex = rightChild - 1
  return uniqueValues[nodeIndex - baseSize]

let queryCount = nextInt(inputData, scanPos)
var queryLefts = newSeq[int](queryCount)
var queryRights = newSeq[int](queryCount)
var queryOrder = newSeq[int](queryCount)
for queryIndex in 0 .. queryCount - 1:
  queryLefts[queryIndex] = nextInt(inputData, scanPos)
  queryRights[queryIndex] = nextInt(inputData, scanPos)
  queryOrder[queryIndex] = queryIndex

var blockSize = 1
while (blockSize + 1) * (blockSize + 1) <= valueCount:
  blockSize += 1

queryOrder.sort(proc(leftIndex, rightIndex: int): int =
  let leftBlock = queryLefts[leftIndex] div blockSize
  let rightBlock = queryLefts[rightIndex] div blockSize
  if leftBlock != rightBlock:
    return leftBlock - rightBlock
  if (leftBlock and 1) == 0:
    if queryRights[leftIndex] < queryRights[rightIndex]:
      return -1
    if queryRights[leftIndex] > queryRights[rightIndex]:
      return 1
  else:
    if queryRights[leftIndex] > queryRights[rightIndex]:
      return -1
    if queryRights[leftIndex] < queryRights[rightIndex]:
      return 1
  return 0)

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var answers = newSeq[string](queryCount)
var currentLeft = 0
var currentRight = -1

for queryIndex in queryOrder:
  let wantedLeft = queryLefts[queryIndex]
  let wantedRight = queryRights[queryIndex]
  while currentLeft > wantedLeft:
    currentLeft -= 1
    changeCount(compressedValues[currentLeft], 1)
  while currentRight < wantedRight:
    currentRight += 1
    changeCount(compressedValues[currentRight], 1)
  while currentLeft < wantedLeft:
    changeCount(compressedValues[currentLeft], -1)
    currentLeft += 1
  while currentRight > wantedRight:
    changeCount(compressedValues[currentRight], -1)
    currentRight -= 1

  let spanLength = wantedRight - wantedLeft + 1
  let spanTotal = prefixSums[wantedRight + 1] - prefixSums[wantedLeft]
  var medianValue = 0
  if spanLength mod 2 == 1:
    medianValue = kthValue(spanLength div 2 + 1)
  else:
    let lowerRank = spanLength div 2
    let lowerValue = kthValue(lowerRank)
    let upperValue = kthValue(lowerRank + 1)
    medianValue = (lowerValue + upperValue) div 2
  answers[queryIndex] = $(spanTotal div int64(spanLength)) & " " &
                        $medianValue & " " & $largestModeValue()

for queryIndex in 0 .. queryCount - 1:
  appendOutput(answers[queryIndex])
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
