const firstDigitValue = 48
const flushBlockBytes = 1 shl 18

proc nextInt(inputData: string, i: var int): int =
  while i < inputData.len and (inputData[i] < '0' or inputData[i] > '9'):
    i.inc
  result = 0
  while i < inputData.len and inputData[i] >= '0' and inputData[i] <= '9':
    result = result * 10 + (ord(inputData[i]) - firstDigitValue)
    i.inc

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
var i = 0
let testCount = nextInt(inputData, i)

var xPositions = newSeq[int](1)
var yPositions = newSeq[int](1)
var orderByX = newSeq[int](1)
var orderByY = newSeq[int](1)
var xCounts = newSeq[int](1)
var yCounts = newSeq[int](1)
var lastOnRow = newSeq[int](1)
var lastOnColumn = newSeq[int](1)

for j in 0 ..< testCount:
  let sectionCount = nextInt(inputData, i)
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

  for j in 0 .. bucketCount - 1:
    xCounts[j] = 0
    yCounts[j] = 0
    lastOnRow[j] = -1
    lastOnColumn[j] = -1

  while i < inputData.len and inputData[i] <= ' ':
    i.inc

  var currentX = 0
  var currentY = 0
  xPositions[0] = 0
  yPositions[0] = 0
  for j in 1 .. sectionCount:
    case inputData[i]
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
    i.inc
    xPositions[j] = currentX
    yPositions[j] = currentY

  for k in 0 .. sectionCount:
    xCounts[xPositions[k] + coordinateOffset].inc
    yCounts[yPositions[k] + coordinateOffset].inc

  var xRunning = 0
  var yRunning = 0
  for j in 0 .. bucketCount - 1:
    let xBucketSize = xCounts[j]
    let yBucketSize = yCounts[j]
    xCounts[j] = xRunning
    yCounts[j] = yRunning
    xRunning += xBucketSize
    yRunning += yBucketSize

  for k in 0 .. sectionCount:
    let xSlot = xPositions[k] + coordinateOffset
    orderByX[xCounts[xSlot]] = k
    xCounts[xSlot].inc
    let ySlot = yPositions[k] + coordinateOffset
    orderByY[yCounts[ySlot]] = k
    yCounts[ySlot].inc

  var bestLength = 1 shl 30
  var bestBegin = 0
  var bestEnd = 0
  var bestDirection = 'N'

  for j in 0 .. sectionCount:
    let k = orderByX[j]
    let rowSlot = yPositions[k] + coordinateOffset
    let previousBreak = lastOnRow[rowSlot]
    if previousBreak >= 0:
      if abs(k - previousBreak) != 1:
        let lengthValue = xPositions[k] - xPositions[previousBreak]
        considerShortcut(lengthValue, previousBreak, k, true,
          xPositions, yPositions, bestLength, bestBegin, bestEnd, bestDirection)
    lastOnRow[rowSlot] = k

  for j in 0 .. sectionCount:
    let k = orderByY[j]
    let columnSlot = xPositions[k] + coordinateOffset
    let previousBreak = lastOnColumn[columnSlot]
    if previousBreak >= 0:
      if abs(k - previousBreak) != 1:
        let lengthValue = yPositions[k] - yPositions[previousBreak]
        considerShortcut(lengthValue, previousBreak, k, false,
          xPositions, yPositions, bestLength, bestBegin, bestEnd, bestDirection)
    lastOnColumn[columnSlot] = k

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
