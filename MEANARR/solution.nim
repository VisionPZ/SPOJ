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

let elementCount = nextInt(inputData, scanPos)
let requiredMean = nextInt(inputData, scanPos)

var prefixSums = newSeq[int64](elementCount + 1)
for elementIndex in 1 .. elementCount:
  let currentValue = nextInt(inputData, scanPos)
  prefixSums[elementIndex] = prefixSums[elementIndex - 1] + int64(currentValue - requiredMean)

var scratchSums = newSeq[int64](elementCount + 1)
var decreasingPairs: int64 = 0

proc mergeCount(leftStart: int, rightEnd: int) =
  if rightEnd - leftStart < 2:
    return
  let middleIndex = (leftStart + rightEnd) div 2
  mergeCount(leftStart, middleIndex)
  mergeCount(middleIndex, rightEnd)
  var leftPos = leftStart
  var rightPos = middleIndex
  var writePos = leftStart
  while leftPos < middleIndex and rightPos < rightEnd:
    if prefixSums[leftPos] <= prefixSums[rightPos]:
      scratchSums[writePos] = prefixSums[leftPos]
      leftPos += 1
    else:
      scratchSums[writePos] = prefixSums[rightPos]
      decreasingPairs += int64(middleIndex - leftPos)
      rightPos += 1
    writePos += 1
  while leftPos < middleIndex:
    scratchSums[writePos] = prefixSums[leftPos]
    leftPos += 1
    writePos += 1
  while rightPos < rightEnd:
    scratchSums[writePos] = prefixSums[rightPos]
    rightPos += 1
    writePos += 1
  for copyPos in leftStart .. rightEnd - 1:
    prefixSums[copyPos] = scratchSums[copyPos]

mergeCount(0, elementCount + 1)
let totalSubarrays = int64(elementCount) * int64(elementCount + 1) div 2
appendOutput($(totalSubarrays - decreasingPairs))
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
