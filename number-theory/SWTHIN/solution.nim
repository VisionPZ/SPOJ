import tables

const flushBlockBytes = 1 shl 17
const coordinateOffset = 10000
const directionSpan = 20001
const minimumTrainLength = 4

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

proc greatestCommonDivisor(firstValue, secondValue: int): int =
  var left = firstValue
  var right = secondValue
  while right != 0:
    let remainder = left mod right
    left = right
    right = remainder
  return left

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var photoNumber = 0
while true:
  let pointCount = nextInt(inputData, scanPos)
  if pointCount == 0:
    break
  photoNumber += 1
  var xCoordinates = newSeq[int](pointCount)
  var yCoordinates = newSeq[int](pointCount)
  for pointIndex in 0 .. pointCount - 1:
    xCoordinates[pointIndex] = nextInt(inputData, scanPos)
    yCoordinates[pointIndex] = nextInt(inputData, scanPos)
  var bestLineCount = 0
  for anchorIndex in 0 .. pointCount - 1:
    var directionCounts = initTable[int, int]()
    for otherIndex in 0 .. pointCount - 1:
      if otherIndex == anchorIndex:
        continue
      let horizontalStep = xCoordinates[otherIndex] - xCoordinates[anchorIndex]
      let verticalStep = yCoordinates[otherIndex] - yCoordinates[anchorIndex]
      let divisor = greatestCommonDivisor(abs(horizontalStep), abs(verticalStep))
      if divisor == 0:
        continue
      let directionKey = (horizontalStep div divisor + coordinateOffset) * directionSpan + (verticalStep div divisor + coordinateOffset)
      directionCounts[directionKey] = directionCounts.getOrDefault(directionKey) + 1
    for directionKey in directionCounts.keys:
      let lineCount = directionCounts[directionKey] + 1
      if lineCount > bestLineCount:
        bestLineCount = lineCount
  if bestLineCount < minimumTrainLength:
    bestLineCount = 0
  appendOutput("Photo ")
  appendOutput($photoNumber)
  appendOutput(": ")
  appendOutput($bestLineCount)
  appendOutput(" points eliminated\n")

stdout.write outputBuffer
outputBuffer.setLen 0
