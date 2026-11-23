const firstDigitValue = 48
const flushBlockBytes = 1 shl 18

proc nextInt(inputData: string, scanPos: var int): int =
  while scanPos < inputData.len and (inputData[scanPos] < '0' or inputData[scanPos] > '9'):
    scanPos.inc
  result = 0
  while scanPos < inputData.len and inputData[scanPos] >= '0' and inputData[scanPos] <= '9':
    result = result * 10 + (ord(inputData[scanPos]) - firstDigitValue)
    scanPos.inc

proc considerShortcut(lengthValue: int, firstBreak: int, secondBreak: int,
                      horizontal: bool, xPositions: seq[int], yPositions: seq[int],
                      bestLength: var int, bestBegin: var int, bestEnd: var int,
                      bestDirection: var char) =
  var beginBreak = firstBreak
  var endBreak = secondBreak
  if firstBreak > secondBreak:
    beginBreak = secondBreak
    endBreak = firstBreak
  let improves = lengthValue < bestLength or
    (lengthValue == bestLength and beginBreak < bestBegin) or
    (lengthValue == bestLength and beginBreak == bestBegin and endBreak > bestEnd)
  if improves:
    bestLength = lengthValue
    bestBegin = beginBreak
    bestEnd = endBreak
    if horizontal:
      if xPositions[endBreak] > xPositions[beginBreak]:
        bestDirection = 'E'
      else:
        bestDirection = 'W'
    else:
      if yPositions[endBreak] > yPositions[beginBreak]:
        bestDirection = 'N'
      else:
        bestDirection = 'S'

var inputData = ""
var lineBuffer = ""
while readLine(stdin, lineBuffer):
  inputData.add lineBuffer
  inputData.add '\n'

var outputBuffer = ""
var scanPos = 0
let testCount = nextInt(inputData, scanPos)

var xPositions = newSeq[int](1)
var yPositions = newSeq[int](1)
var orderByX = newSeq[int](1)
var orderByY = newSeq[int](1)
var xCounts = newSeq[int](1)
var yCounts = newSeq[int](1)
var lastOnRow = newSeq[int](1)
var lastOnColumn = newSeq[int](1)

for caseIndex in 0 ..< testCount:
  let sectionCount = nextInt(inputData, scanPos)
  let breakCount = sectionCount + 1
  let coordinateOffset = sectionCount + 2
  let bucketCount = 2 * sectionCount + 5

  if xPositions.len < breakCount:
    xPositions.setLen(breakCount)
    yPositions.setLen(breakCount)
    orderByX.setLen(breakCount)
    orderByY.setLen(breakCount)
  if xCounts.len < bucketCount:
    xCounts.setLen(bucketCount)
    yCounts.setLen(bucketCount)
    lastOnRow.setLen(bucketCount)
    lastOnColumn.setLen(bucketCount)

  for bucketIndex in 0 .. bucketCount - 1:
    xCounts[bucketIndex] = 0
    yCounts[bucketIndex] = 0
    lastOnRow[bucketIndex] = -1
    lastOnColumn[bucketIndex] = -1

  while scanPos < inputData.len and inputData[scanPos] <= ' ':
    scanPos.inc

  var currentX = 0
  var currentY = 0
  xPositions[0] = 0
  yPositions[0] = 0
  for sectionIndex in 1 .. sectionCount:
    case inputData[scanPos]
    of 'N':
      currentY.inc
    of 'S':
      currentY.dec
    of 'E':
      currentX.inc
    of 'W':
      currentX.dec
    else:
      discard
    scanPos.inc
    xPositions[sectionIndex] = currentX
    yPositions[sectionIndex] = currentY

  for breakIndex in 0 .. sectionCount:
    xCounts[xPositions[breakIndex] + coordinateOffset].inc
    yCounts[yPositions[breakIndex] + coordinateOffset].inc

  var xRunning = 0
  var yRunning = 0
  for bucketIndex in 0 .. bucketCount - 1:
    let xBucketSize = xCounts[bucketIndex]
    let yBucketSize = yCounts[bucketIndex]
    xCounts[bucketIndex] = xRunning
    yCounts[bucketIndex] = yRunning
    xRunning += xBucketSize
    yRunning += yBucketSize

  for breakIndex in 0 .. sectionCount:
    let xSlot = xPositions[breakIndex] + coordinateOffset
    orderByX[xCounts[xSlot]] = breakIndex
    xCounts[xSlot].inc
    let ySlot = yPositions[breakIndex] + coordinateOffset
    orderByY[yCounts[ySlot]] = breakIndex
    yCounts[ySlot].inc

  var bestLength = 1 shl 30
  var bestBegin = 0
  var bestEnd = 0
  var bestDirection = 'N'

  for orderIndex in 0 .. sectionCount:
    let breakIndex = orderByX[orderIndex]
    let rowSlot = yPositions[breakIndex] + coordinateOffset
    let previousBreak = lastOnRow[rowSlot]
    if previousBreak >= 0:
      if abs(breakIndex - previousBreak) != 1:
        let lengthValue = xPositions[breakIndex] - xPositions[previousBreak]
        considerShortcut(lengthValue, previousBreak, breakIndex, true,
          xPositions, yPositions, bestLength, bestBegin, bestEnd, bestDirection)
    lastOnRow[rowSlot] = breakIndex

  for orderIndex in 0 .. sectionCount:
    let breakIndex = orderByY[orderIndex]
    let columnSlot = xPositions[breakIndex] + coordinateOffset
    let previousBreak = lastOnColumn[columnSlot]
    if previousBreak >= 0:
      if abs(breakIndex - previousBreak) != 1:
        let lengthValue = yPositions[breakIndex] - yPositions[previousBreak]
        considerShortcut(lengthValue, previousBreak, breakIndex, false,
          xPositions, yPositions, bestLength, bestBegin, bestEnd, bestDirection)
    lastOnColumn[columnSlot] = breakIndex

  outputBuffer.add $bestLength
  outputBuffer.add ' '
  outputBuffer.add $bestBegin
  outputBuffer.add ' '
  outputBuffer.add $bestEnd
  outputBuffer.add ' '
  outputBuffer.add bestDirection
  outputBuffer.add '\n'
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

if outputBuffer.len > 0:
  stdout.write outputBuffer
