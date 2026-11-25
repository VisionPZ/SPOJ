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

proc edgeSatisfied(edgeStartX: int64, edgeStartY: int64, edgeDeltaX: int64,
                   edgeDeltaY: int64, pointX: int64, pointY: int64,
                   denominator: int64): bool =
  let offsetX = pointX - edgeStartX * denominator
  let offsetY = pointY - edgeStartY * denominator
  let crossValue = edgeDeltaX * offsetY - edgeDeltaY * offsetX
  return crossValue >= 0

proc feasibleAtIntersection(verticesX: seq[int], verticesY: seq[int],
                            firstEdge: int, secondEdge: int): bool =
  let vertexCount = verticesX.len
  let firstStartX = int64(verticesX[firstEdge])
  let firstStartY = int64(verticesY[firstEdge])
  let firstEndIndex = (firstEdge + 1) mod vertexCount
  let firstDeltaX = int64(verticesX[firstEndIndex]) - firstStartX
  let firstDeltaY = int64(verticesY[firstEndIndex]) - firstStartY
  let secondStartX = int64(verticesX[secondEdge])
  let secondStartY = int64(verticesY[secondEdge])
  let secondEndIndex = (secondEdge + 1) mod vertexCount
  let secondDeltaX = int64(verticesX[secondEndIndex]) - secondStartX
  let secondDeltaY = int64(verticesY[secondEndIndex]) - secondStartY
  var denominator = firstDeltaX * secondDeltaY - firstDeltaY * secondDeltaX
  if denominator == 0:
    return false
  let startOffsetX = secondStartX - firstStartX
  let startOffsetY = secondStartY - firstStartY
  let lineParameter = startOffsetX * secondDeltaY - startOffsetY * secondDeltaX
  var pointX = firstStartX * denominator + lineParameter * firstDeltaX
  var pointY = firstStartY * denominator + lineParameter * firstDeltaY
  if denominator < 0:
    denominator = -denominator
    pointX = -pointX
    pointY = -pointY
  for edgeIndex in 0 .. vertexCount - 1:
    let edgeStartX = int64(verticesX[edgeIndex])
    let edgeStartY = int64(verticesY[edgeIndex])
    let nextIndex = (edgeIndex + 1) mod vertexCount
    let edgeDeltaX = int64(verticesX[nextIndex]) - edgeStartX
    let edgeDeltaY = int64(verticesY[nextIndex]) - edgeStartY
    if not edgeSatisfied(edgeStartX, edgeStartY, edgeDeltaX, edgeDeltaY,
                         pointX, pointY, denominator):
      return false
  return true

proc isStarShaped(verticesX: seq[int], verticesY: seq[int]): bool =
  let vertexCount = verticesX.len
  for firstEdge in 0 .. vertexCount - 2:
    for secondEdge in firstEdge + 1 .. vertexCount - 1:
      if feasibleAtIntersection(verticesX, verticesY, firstEdge, secondEdge):
        return true
  return false

while true:
  let vertexCount = nextInt(inputData, scanPos)
  if vertexCount == 0:
    break
  var verticesX = newSeq[int](vertexCount)
  var verticesY = newSeq[int](vertexCount)
  for vertexIndex in 0 .. vertexCount - 1:
    verticesX[vertexIndex] = nextInt(inputData, scanPos)
    verticesY[vertexIndex] = nextInt(inputData, scanPos)
  if isStarShaped(verticesX, verticesY):
    appendOutput("1\n")
  else:
    appendOutput("0\n")

stdout.write outputBuffer
outputBuffer.setLen 0
