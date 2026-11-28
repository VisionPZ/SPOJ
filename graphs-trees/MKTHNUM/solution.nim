const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and data[pos] != '-' and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var sign = 1
  if pos < data.len and data[pos] == '-':
    sign = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return value * sign

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc mergeSortAsc(data: var seq[int]) =
  let length = data.len
  if length < 2:
    return
  var buffer = newSeq[int](length)
  var runWidth = 1
  while runWidth < length:
    var blockStart = 0
    while blockStart < length:
      var leftPos = blockStart
      var rightPos = blockStart + runWidth
      let leftEnd = if blockStart + runWidth < length: blockStart + runWidth else: length
      let rightEnd = if blockStart + 2 * runWidth < length: blockStart + 2 * runWidth else: length
      var writePos = blockStart
      while leftPos < leftEnd and rightPos < rightEnd:
        if data[leftPos] <= data[rightPos]:
          buffer[writePos] = data[leftPos]
          leftPos = leftPos + 1
        else:
          buffer[writePos] = data[rightPos]
          rightPos = rightPos + 1
        writePos = writePos + 1
      while leftPos < leftEnd:
        buffer[writePos] = data[leftPos]
        leftPos = leftPos + 1
        writePos = writePos + 1
      while rightPos < rightEnd:
        buffer[writePos] = data[rightPos]
        rightPos = rightPos + 1
        writePos = writePos + 1
      blockStart = blockStart + 2 * runWidth
    for index in 0 .. length - 1:
      data[index] = buffer[index]
    runWidth = runWidth * 2

let elementCount = nextInt(inputData, scanPos)
let questionCount = nextInt(inputData, scanPos)
var values = newSeq[int](elementCount)
for index in 0 .. elementCount - 1:
  values[index] = nextInt(inputData, scanPos)

var sortedValues = newSeq[int](elementCount)
for index in 0 .. elementCount - 1:
  sortedValues[index] = values[index]
mergeSortAsc(sortedValues)

var distinctValues = newSeq[int](0)
for index in 0 .. elementCount - 1:
  if index == 0 or sortedValues[index] != sortedValues[index - 1]:
    distinctValues.add sortedValues[index]
let rankCount = distinctValues.len

let maxNodes = elementCount * 20 + 5
var leftChild = newSeq[int](maxNodes)
var rightChild = newSeq[int](maxNodes)
var subtreeCount = newSeq[int](maxNodes)
var versionRoots = newSeq[int](elementCount + 1)
var nodeCursor = 1

proc addVersion(previousNode: int, rangeLeft: int, rangeRight: int, rank: int): int =
  let currentNode = nodeCursor
  nodeCursor = nodeCursor + 1
  leftChild[currentNode] = leftChild[previousNode]
  rightChild[currentNode] = rightChild[previousNode]
  subtreeCount[currentNode] = subtreeCount[previousNode] + 1
  if rangeLeft != rangeRight:
    let rangeMiddle = (rangeLeft + rangeRight) div 2
    if rank <= rangeMiddle:
      leftChild[currentNode] = addVersion(leftChild[previousNode], rangeLeft, rangeMiddle, rank)
    else:
      rightChild[currentNode] = addVersion(rightChild[previousNode], rangeMiddle + 1, rangeRight, rank)
  return currentNode

for index in 0 .. elementCount - 1:
  var rank = 0
  var low = 0
  var high = rankCount - 1
  while low <= high:
    let middle = (low + high) div 2
    if distinctValues[middle] == values[index]:
      rank = middle + 1
      break
    elif distinctValues[middle] < values[index]:
      low = middle + 1
    else:
      high = middle - 1
  versionRoots[index + 1] = addVersion(versionRoots[index], 1, rankCount, rank)

proc kthInRange(rightRoot: int, leftRoot: int, rangeLeft: int, rangeRight: int, order: int): int =
  if rangeLeft == rangeRight:
    return rangeLeft
  let rangeMiddle = (rangeLeft + rangeRight) div 2
  let leftAmount = subtreeCount[leftChild[rightRoot]] - subtreeCount[leftChild[leftRoot]]
  if order <= leftAmount:
    return kthInRange(leftChild[rightRoot], leftChild[leftRoot], rangeLeft, rangeMiddle, order)
  return kthInRange(rightChild[rightRoot], rightChild[leftRoot], rangeMiddle + 1, rangeRight, order - leftAmount)

for questionIndex in 0 .. questionCount - 1:
  let leftIndex = nextInt(inputData, scanPos)
  let rightIndex = nextInt(inputData, scanPos)
  let order = nextInt(inputData, scanPos)
  let rank = kthInRange(versionRoots[rightIndex], versionRoots[leftIndex - 1], 1, rankCount, order)
  appendOutput($distinctValues[rank - 1])
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
