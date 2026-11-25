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

proc sumRange(firstSize: int, lastSize: int, doorWidth: int, slopeTerm: int, constantTerm: int): int64 =
  if firstSize > lastSize:
    return 0
  let termCount = lastSize - firstSize + 1
  let sumFirst = int64(firstSize + lastSize) * int64(termCount) div 2
  let sumSecond = (int64(lastSize) * int64(lastSize + 1) * int64(2 * lastSize + 1) - int64(firstSize - 1) * int64(firstSize) * int64(2 * firstSize - 1)) div 6
  return int64(doorWidth + 1) * (int64(slopeTerm) * sumFirst + int64(constantTerm) * int64(termCount)) - int64(slopeTerm) * sumSecond - int64(constantTerm) * sumFirst

proc crossingTotal(doorWidth: int, firstDepth: int, secondDepth: int): int64 =
  if doorWidth <= 0 or firstDepth < 1 or secondDepth < 1:
    return 0
  let largestSize = min(doorWidth, firstDepth + secondDepth)
  if largestSize < 2:
    return 0
  let smallerDepth = min(firstDepth, secondDepth)
  let largerDepth = max(firstDepth, secondDepth)
  let firstBreak = smallerDepth + 1
  let secondBreak = largerDepth + 1
  result = sumRange(2, min(firstBreak, largestSize), doorWidth, 1, -1)
  result += sumRange(firstBreak + 1, min(secondBreak, largestSize), doorWidth, 0, smallerDepth)
  result += sumRange(secondBreak + 1, largestSize, doorWidth, -1, largerDepth + smallerDepth + 1)

var caseNumber = 0
while true:
  let roomCount = nextInt(inputData, scanPos)
  if roomCount == 0:
    break
  caseNumber += 1
  var leftEdges = newSeq[int](roomCount)
  var bottomEdges = newSeq[int](roomCount)
  var rightEdges = newSeq[int](roomCount)
  var topEdges = newSeq[int](roomCount)
  for roomIndex in 0 .. roomCount - 1:
    let firstX = nextInt(inputData, scanPos)
    let firstY = nextInt(inputData, scanPos)
    let secondX = nextInt(inputData, scanPos)
    let secondY = nextInt(inputData, scanPos)
    leftEdges[roomIndex] = min(firstX, secondX)
    rightEdges[roomIndex] = max(firstX, secondX)
    bottomEdges[roomIndex] = min(firstY, secondY)
    topEdges[roomIndex] = max(firstY, secondY)
  var squareTotal: int64 = 0
  for roomIndex in 0 .. roomCount - 1:
    let roomWidth = rightEdges[roomIndex] - leftEdges[roomIndex]
    let roomHeight = topEdges[roomIndex] - bottomEdges[roomIndex]
    let shortSide = min(roomWidth, roomHeight)
    let longSide = max(roomWidth, roomHeight)
    squareTotal += int64(longSide - shortSide) * int64(shortSide) * int64(shortSide + 1) div 2
    squareTotal += int64(shortSide) * int64(shortSide + 1) * int64(2 * shortSide + 1) div 6
  for firstRoom in 0 .. roomCount - 1:
    for secondRoom in firstRoom + 1 .. roomCount - 1:
      let verticalOverlap = min(topEdges[firstRoom], topEdges[secondRoom]) - max(bottomEdges[firstRoom], bottomEdges[secondRoom])
      if rightEdges[firstRoom] == leftEdges[secondRoom] or rightEdges[secondRoom] == leftEdges[firstRoom]:
        squareTotal += crossingTotal(verticalOverlap - 2, rightEdges[firstRoom] - leftEdges[firstRoom], rightEdges[secondRoom] - leftEdges[secondRoom])
      let horizontalOverlap = min(rightEdges[firstRoom], rightEdges[secondRoom]) - max(leftEdges[firstRoom], leftEdges[secondRoom])
      if topEdges[firstRoom] == bottomEdges[secondRoom] or topEdges[secondRoom] == bottomEdges[firstRoom]:
        squareTotal += crossingTotal(horizontalOverlap - 2, topEdges[firstRoom] - bottomEdges[firstRoom], topEdges[secondRoom] - bottomEdges[secondRoom])
  appendOutput("Case ")
  appendOutput($caseNumber)
  appendOutput(": ")
  appendOutput($squareTotal)
  appendOutput("\n")

stdout.write outputBuffer
outputBuffer.setLen 0
