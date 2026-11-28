const flushBlockBytes = 1 shl 17
const missingValue = 1000000007

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

let dwarfCount = nextInt(inputData, scanPos)
let requestCount = nextInt(inputData, scanPos)

var baseSize = 1
while baseSize < dwarfCount:
  baseSize = baseSize * 2

var minimumTree = newSeq[int](2 * baseSize)
var maximumTree = newSeq[int](2 * baseSize)
for leafIndex in 0 .. baseSize - 1:
  minimumTree[baseSize + leafIndex] = missingValue
  maximumTree[baseSize + leafIndex] = 0

var heightPositions = newSeq[int](dwarfCount)
for heightIndex in 0 .. dwarfCount - 1:
  heightPositions[heightIndex] = heightIndex + 1
  minimumTree[baseSize + heightIndex] = heightIndex + 1
  maximumTree[baseSize + heightIndex] = heightIndex + 1

for treeIndex in countdown(baseSize - 1, 1):
  minimumTree[treeIndex] = min(minimumTree[2 * treeIndex], minimumTree[2 * treeIndex + 1])
  maximumTree[treeIndex] = max(maximumTree[2 * treeIndex], maximumTree[2 * treeIndex + 1])

proc updateHeight(heightIndex: int, positionValue: int) =
  var treeIndex = baseSize + heightIndex
  minimumTree[treeIndex] = positionValue
  maximumTree[treeIndex] = positionValue
  treeIndex = treeIndex div 2
  while treeIndex >= 1:
    minimumTree[treeIndex] = min(minimumTree[2 * treeIndex], minimumTree[2 * treeIndex + 1])
    maximumTree[treeIndex] = max(maximumTree[2 * treeIndex], maximumTree[2 * treeIndex + 1])
    treeIndex = treeIndex div 2

proc rangeMinimum(leftHeight: int, rightHeight: int): int =
  var leftIndex = baseSize + leftHeight
  var rightIndex = baseSize + rightHeight
  var bestValue = missingValue
  while leftIndex <= rightIndex:
    if (leftIndex mod 2) == 1:
      bestValue = min(bestValue, minimumTree[leftIndex])
      leftIndex += 1
    if (rightIndex mod 2) == 0:
      bestValue = min(bestValue, minimumTree[rightIndex])
      rightIndex -= 1
    leftIndex = leftIndex div 2
    rightIndex = rightIndex div 2
  return bestValue

proc rangeMaximum(leftHeight: int, rightHeight: int): int =
  var leftIndex = baseSize + leftHeight
  var rightIndex = baseSize + rightHeight
  var bestValue = 0
  while leftIndex <= rightIndex:
    if (leftIndex mod 2) == 1:
      bestValue = max(bestValue, maximumTree[leftIndex])
      leftIndex += 1
    if (rightIndex mod 2) == 0:
      bestValue = max(bestValue, maximumTree[rightIndex])
      rightIndex -= 1
    leftIndex = leftIndex div 2
    rightIndex = rightIndex div 2
  return bestValue

for requestIndex in 0 .. requestCount - 1:
  let requestType = nextInt(inputData, scanPos)
  let firstValue = nextInt(inputData, scanPos)
  let secondValue = nextInt(inputData, scanPos)
  if requestType == 1:
    let firstHeight = firstValue - 1
    let secondHeight = secondValue - 1
    let firstPosition = heightPositions[firstHeight]
    let secondPosition = heightPositions[secondHeight]
    heightPositions[firstHeight] = secondPosition
    heightPositions[secondHeight] = firstPosition
    updateHeight(firstHeight, secondPosition)
    updateHeight(secondHeight, firstPosition)
  else:
    let leftHeight = firstValue - 1
    let rightHeight = secondValue - 1
    let smallestPosition = rangeMinimum(leftHeight, rightHeight)
    let largestPosition = rangeMaximum(leftHeight, rightHeight)
    if largestPosition - smallestPosition == rightHeight - leftHeight:
      appendOutput("YES\n")
    else:
      appendOutput("NO\n")

stdout.write outputBuffer
outputBuffer.setLen 0
