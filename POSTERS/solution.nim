import std/algorithm

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int(data[position]) - firstDigitValue
    position += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc compareInts(first, second: int): int =
  return system.cmp(first, second)

var compressedValues: seq[int]
var nextFree: seq[int]

proc findNext(position: int): int =
  var root = position
  while nextFree[root] != root:
    root = nextFree[root]
  var cursor = position
  while nextFree[cursor] != cursor:
    var parent = nextFree[cursor]
    nextFree[cursor] = root
    cursor = parent
  return root

proc lowerBound(value: int): int =
  var low = 0
  var high = compressedValues.len
  while low < high:
    var middle = (low + high) div 2
    if compressedValues[middle] < value:
      low = middle + 1
    else:
      high = middle
  return low

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let posterCount = nextInt(inputData, scanPos)
  var leftBounds = newSeq[int](posterCount)
  var rightBounds = newSeq[int](posterCount)
  compressedValues = newSeq[int](posterCount * 6)
  var compressedPos = 0
  for posterIndex in 0..<posterCount:
    let leftBound = nextInt(inputData, scanPos)
    let rightBound = nextInt(inputData, scanPos)
    leftBounds[posterIndex] = leftBound
    rightBounds[posterIndex] = rightBound
    compressedValues[compressedPos] = leftBound - 1
    compressedPos += 1
    compressedValues[compressedPos] = leftBound
    compressedPos += 1
    compressedValues[compressedPos] = leftBound + 1
    compressedPos += 1
    compressedValues[compressedPos] = rightBound - 1
    compressedPos += 1
    compressedValues[compressedPos] = rightBound
    compressedPos += 1
    compressedValues[compressedPos] = rightBound + 1
    compressedPos += 1
  sort(compressedValues, compareInts)
  var uniqueCount = 0
  for valueIndex in 0..<compressedValues.len:
    if valueIndex == 0 or compressedValues[valueIndex] != compressedValues[uniqueCount - 1]:
      compressedValues[uniqueCount] = compressedValues[valueIndex]
      uniqueCount += 1
  compressedValues.setLen(uniqueCount)
  nextFree = newSeq[int](uniqueCount + 1)
  for freeIndex in 0..uniqueCount:
    nextFree[freeIndex] = freeIndex
  var visibleCount = 0
  for posterIndex in countdown(posterCount - 1, 0):
    let leftIndex = lowerBound(leftBounds[posterIndex])
    let rightIndex = lowerBound(rightBounds[posterIndex])
    var current = findNext(leftIndex)
    if current <= rightIndex:
      visibleCount += 1
      while current <= rightIndex:
        nextFree[current] = findNext(current + 1)
        current = findNext(current)
  appendOutput($(visibleCount))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
