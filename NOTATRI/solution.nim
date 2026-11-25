const firstDigitValue = 48
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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

proc sortLengths(values: var seq[int], lowIndex: int, highIndex: int) =
  if lowIndex >= highIndex:
    return
  var leftIndex = lowIndex
  var rightIndex = highIndex
  let pivotValue = values[(lowIndex + highIndex) div 2]
  while leftIndex <= rightIndex:
    while values[leftIndex] < pivotValue:
      leftIndex += 1
    while values[rightIndex] > pivotValue:
      rightIndex -= 1
    if leftIndex <= rightIndex:
      swap values[leftIndex], values[rightIndex]
      leftIndex += 1
      rightIndex -= 1
  if lowIndex < rightIndex:
    sortLengths(values, lowIndex, rightIndex)
  if leftIndex < highIndex:
    sortLengths(values, leftIndex, highIndex)

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while true:
  let stickCount = nextInt(inputData, scanPos)
  if stickCount == 0:
    break
  var stickLengths = newSeq[int](stickCount)
  for stickIndex in 0 .. stickCount - 1:
    stickLengths[stickIndex] = nextInt(inputData, scanPos)
  sortLengths(stickLengths, 0, stickCount - 1)
  var losingTriples: int64 = 0
  for longestIndex in 2 .. stickCount - 1:
    var smallerIndex = 0
    var middleIndex = longestIndex - 1
    while middleIndex >= 1:
      while smallerIndex < middleIndex and
            stickLengths[smallerIndex] + stickLengths[middleIndex] < stickLengths[longestIndex]:
        smallerIndex += 1
      losingTriples += int64(min(smallerIndex, middleIndex))
      middleIndex -= 1
  appendOutput($losingTriples)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
