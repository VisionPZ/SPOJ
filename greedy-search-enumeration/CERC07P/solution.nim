const flushBlockBytes = 1 shl 17
const firstDigitValue = 48
const noNeighbor = -1

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and data[pos] != '-' and (data[pos] < '0' or data[pos] > '9'):
    pos += 1
  var signValue = 1
  if pos < data.len and data[pos] == '-':
    signValue = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return signValue * value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

while true:
  let cornerCount = nextInt(inputData, scanPos)
  if cornerCount == 0:
    break
  var cornerX = newSeq[int](cornerCount)
  var cornerY = newSeq[int](cornerCount)
  for cornerIndex in 0 .. cornerCount - 1:
    cornerX[cornerIndex] = nextInt(inputData, scanPos)
    cornerY[cornerIndex] = nextInt(inputData, scanPos)

  var horizontalRank = newSeq[int](cornerCount)
  var verticalRank = newSeq[int](cornerCount)
  for cornerIndex in 0 .. cornerCount - 1:
    var smallerX = 0
    var smallerY = 0
    for otherIndex in 0 .. cornerCount - 1:
      if otherIndex == cornerIndex:
        continue
      if cornerY[otherIndex] == cornerY[cornerIndex] and cornerX[otherIndex] < cornerX[cornerIndex]:
        smallerX += 1
      if cornerX[otherIndex] == cornerX[cornerIndex] and cornerY[otherIndex] < cornerY[cornerIndex]:
        smallerY += 1
    horizontalRank[cornerIndex] = smallerX
    verticalRank[cornerIndex] = smallerY

  var horizontalMate = newSeq[int](cornerCount)
  var verticalMate = newSeq[int](cornerCount)
  for cornerIndex in 0 .. cornerCount - 1:
    horizontalMate[cornerIndex] = noNeighbor
    verticalMate[cornerIndex] = noNeighbor
    var wantedHorizontal = horizontalRank[cornerIndex] + 1
    if horizontalRank[cornerIndex] mod 2 == 1:
      wantedHorizontal = horizontalRank[cornerIndex] - 1
    var wantedVertical = verticalRank[cornerIndex] + 1
    if verticalRank[cornerIndex] mod 2 == 1:
      wantedVertical = verticalRank[cornerIndex] - 1
    for otherIndex in 0 .. cornerCount - 1:
      if otherIndex == cornerIndex:
        continue
      if cornerY[otherIndex] == cornerY[cornerIndex] and horizontalRank[otherIndex] == wantedHorizontal:
        horizontalMate[cornerIndex] = otherIndex
      if cornerX[otherIndex] == cornerX[cornerIndex] and verticalRank[otherIndex] == wantedVertical:
        verticalMate[cornerIndex] = otherIndex

  var outline = newSeq[int](cornerCount)
  var currentCorner = 0
  var previousCorner = noNeighbor
  for stepIndex in 0 .. cornerCount - 1:
    outline[stepIndex] = currentCorner
    var nextCorner = horizontalMate[currentCorner]
    if nextCorner == previousCorner:
      nextCorner = verticalMate[currentCorner]
    previousCorner = currentCorner
    currentCorner = nextCorner

  var signedArea: int64 = 0
  for stepIndex in 0 .. cornerCount - 1:
    let firstCorner = outline[stepIndex]
    let secondCorner = outline[(stepIndex + 1) mod cornerCount]
    signedArea = signedArea + int64(cornerX[firstCorner]) * int64(cornerY[secondCorner])
    signedArea = signedArea - int64(cornerX[secondCorner]) * int64(cornerY[firstCorner])

  var orderedCorners = newSeq[int](cornerCount)
  if signedArea > 0:
    orderedCorners[0] = outline[0]
    for stepIndex in 1 .. cornerCount - 1:
      orderedCorners[stepIndex] = outline[cornerCount - stepIndex]
  else:
    for stepIndex in 0 .. cornerCount - 1:
      orderedCorners[stepIndex] = outline[stepIndex]

  var directionLine = ""
  for stepIndex in 0 .. cornerCount - 1:
    let firstCorner = orderedCorners[stepIndex]
    let secondCorner = orderedCorners[(stepIndex + 1) mod cornerCount]
    let deltaX = cornerX[secondCorner] - cornerX[firstCorner]
    let deltaY = cornerY[secondCorner] - cornerY[firstCorner]
    if deltaX > 0:
      directionLine.add 'E'
    elif deltaX < 0:
      directionLine.add 'W'
    elif deltaY > 0:
      directionLine.add 'N'
    else:
      directionLine.add 'S'

  appendOutput(directionLine)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
