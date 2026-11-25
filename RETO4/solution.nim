import algorithm

const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

proc nextInteger(inputData: string, scanPos: var int): int64 =
  while scanPos < inputData.len and inputData[scanPos] != '-' and
        (inputData[scanPos] < '0' or inputData[scanPos] > '9'):
    scanPos += 1
  var signValue = 1'i64
  if scanPos < inputData.len and inputData[scanPos] == '-':
    signValue = -1'i64
    scanPos += 1
  var parsedValue = 0'i64
  while scanPos < inputData.len and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    parsedValue = parsedValue * 10 + int64(int(inputData[scanPos]) - firstDigitValue)
    scanPos += 1
  return signValue * parsedValue

proc comparePositions(leftPosition: int64, rightPosition: int64): int =
  if leftPosition < rightPosition:
    return -1
  if leftPosition > rightPosition:
    return 1
  return 0

proc travelCost(startPosition: int64, leftEnd: int64, rightEnd: int64): int64 =
  if startPosition <= leftEnd:
    return rightEnd - startPosition
  if startPosition >= rightEnd:
    return startPosition - leftEnd
  let widthCost = rightEnd - leftEnd
  let leftFirstCost = (startPosition - leftEnd) + widthCost
  let rightFirstCost = (rightEnd - startPosition) + widthCost
  if leftFirstCost < rightFirstCost:
    return leftFirstCost
  return rightFirstCost

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0
var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let pointCount = int(nextInteger(inputData, scanPos))
let startPosition = nextInteger(inputData, scanPos)
var checkpointPositions = newSeq[int64](pointCount)
for pointIndex in 0 ..< pointCount:
  checkpointPositions[pointIndex] = nextInteger(inputData, scanPos)

var minimumDistance = 0'i64
if pointCount > 1:
  sort(checkpointPositions, comparePositions)
  let smallest = checkpointPositions[0]
  let largest = checkpointPositions[pointCount - 1]
  let secondSmallest = checkpointPositions[1]
  let secondLargest = checkpointPositions[pointCount - 2]
  minimumDistance = travelCost(startPosition, smallest, largest)
  let skipSmallestCost = travelCost(startPosition, secondSmallest, largest)
  if skipSmallestCost < minimumDistance:
    minimumDistance = skipSmallestCost
  let skipLargestCost = travelCost(startPosition, smallest, secondLargest)
  if skipLargestCost < minimumDistance:
    minimumDistance = skipLargestCost

appendOutput($minimumDistance)
outputBuffer.add '\n'
stdout.write outputBuffer
