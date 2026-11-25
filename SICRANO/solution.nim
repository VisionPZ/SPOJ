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

let testCount = nextInt(inputData, scanPos)
for testIndex in 0 .. testCount - 1:
  let pointCount = nextInt(inputData, scanPos)
  let segmentCount = nextInt(inputData, scanPos)
  var pointXs = newSeq[int](pointCount)
  var pointYs = newSeq[int](pointCount)
  for pointIndex in 0 .. pointCount - 1:
    pointXs[pointIndex] = nextInt(inputData, scanPos)
    pointYs[pointIndex] = nextInt(inputData, scanPos)
  for segmentIndex in 0 .. segmentCount - 1:
    let startX = nextInt(inputData, scanPos)
    let startY = nextInt(inputData, scanPos)
    let endX = nextInt(inputData, scanPos)
    let endY = nextInt(inputData, scanPos)
    let deltaX = int64(endX - startX)
    let deltaY = int64(endY - startY)
    var lowX = startX
    var highX = endX
    if lowX > highX:
      let swapValue = lowX
      lowX = highX
      highX = swapValue
    var lowY = startY
    var highY = endY
    if lowY > highY:
      let swapValue = lowY
      lowY = highY
      highY = swapValue
    var pointsOnSegment = 0
    for pointIndex in 0 .. pointCount - 1:
      let candidateX = pointXs[pointIndex]
      let candidateY = pointYs[pointIndex]
      if candidateX < lowX or candidateX > highX or candidateY < lowY or candidateY > highY:
        continue
      let crossProduct = int64(candidateX - startX) * deltaY - int64(candidateY - startY) * deltaX
      if crossProduct == 0:
        pointsOnSegment += 1
    appendOutput($pointsOnSegment)
    outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
