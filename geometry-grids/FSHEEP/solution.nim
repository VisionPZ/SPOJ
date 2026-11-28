import algorithm

{.checks: off.}

const firstDigitValue = 48
const flushBlockBytes = 1 shl 18

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and data[position] != '-' and (data[position] < '0' or data[position] > '9'):
    position += 1
  var sign = 1
  if position < data.len and data[position] == '-':
    sign = -1
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + int(data[position]) - firstDigitValue
    position += 1
  return sign * value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc halfPlane(x: int, y: int): int =
  if y > 0 or (y == 0 and x > 0): 0 else: 1

proc compareAngle(ax: int, ay: int, bx: int, by: int): int =
  let firstHalf = halfPlane(ax, ay)
  let secondHalf = halfPlane(bx, by)
  if firstHalf < secondHalf: return -1
  if firstHalf > secondHalf: return 1
  let turn = ax * by - ay * bx
  if turn > 0: return -1
  if turn < 0: return 1
  return 0

proc crossProduct(ax: int, ay: int, bx: int, by: int): int =
  return ax * by - ay * bx

var vertexX: seq[int]
var vertexY: seq[int]
var radiusSq: seq[int64]
var rayMaxSq: seq[int64]
var vertexOrder: seq[int]

proc compareVertex(leftIndex: int, rightIndex: int): int =
  let angleOrder = compareAngle(vertexX[leftIndex], vertexY[leftIndex], vertexX[rightIndex], vertexY[rightIndex])
  if angleOrder != 0: return angleOrder
  if leftIndex < rightIndex: return -1
  if leftIndex > rightIndex: return 1
  return 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0..<caseCount:
  let vertexCount = nextInt(inputData, scanPos)
  let sheepCount = nextInt(inputData, scanPos)
  vertexX.setLen(vertexCount)
  vertexY.setLen(vertexCount)
  radiusSq.setLen(vertexCount)
  rayMaxSq.setLen(vertexCount)
  vertexOrder.setLen(vertexCount)
  for k in 0..<vertexCount:
    vertexX[k] = nextInt(inputData, scanPos)
    vertexY[k] = nextInt(inputData, scanPos)
    radiusSq[k] = int64(vertexX[k]) * int64(vertexX[k]) + int64(vertexY[k]) * int64(vertexY[k])
    vertexOrder[k] = k
  vertexOrder.sort(compareVertex)
  for k in 0..<vertexCount:
    rayMaxSq[k] = radiusSq[vertexOrder[k]]
  for k in 1..<vertexCount:
    if compareAngle(vertexX[vertexOrder[k]], vertexY[vertexOrder[k]],
                    vertexX[vertexOrder[k - 1]], vertexY[vertexOrder[k - 1]]) == 0 and
       rayMaxSq[k] < rayMaxSq[k - 1]:
      rayMaxSq[k] = rayMaxSq[k - 1]
  var backPos = vertexCount - 2
  while backPos >= 0:
    if compareAngle(vertexX[vertexOrder[backPos]], vertexY[vertexOrder[backPos]],
                    vertexX[vertexOrder[backPos + 1]], vertexY[vertexOrder[backPos + 1]]) == 0 and
       rayMaxSq[backPos] < rayMaxSq[backPos + 1]:
      rayMaxSq[backPos] = rayMaxSq[backPos + 1]
    backPos -= 1

  var insideCount = 0
  for s in 0..<sheepCount:
    let sheepX = nextInt(inputData, scanPos)
    let sheepY = nextInt(inputData, scanPos)
    if sheepX == 0 and sheepY == 0:
      insideCount += 1
      continue
    var lowerBound = 0
    var upperBound = vertexCount
    while lowerBound < upperBound:
      let middle = (lowerBound + upperBound) div 2
      let vertexIndex = vertexOrder[middle]
      if compareAngle(vertexX[vertexIndex], vertexY[vertexIndex], sheepX, sheepY) <= 0:
        lowerBound = middle + 1
      else:
        upperBound = middle
    let firstGreater = lowerBound
    let beforePos = (firstGreater - 1 + vertexCount) mod vertexCount
    let afterPos = firstGreater mod vertexCount
    let beforeIndex = vertexOrder[beforePos]
    let afterIndex = vertexOrder[afterPos]
    if compareAngle(vertexX[beforeIndex], vertexY[beforeIndex], sheepX, sheepY) == 0:
      let sheepRadius = int64(sheepX) * int64(sheepX) + int64(sheepY) * int64(sheepY)
      if sheepRadius <= rayMaxSq[beforePos]:
        insideCount += 1
    else:
      let leftX = vertexX[beforeIndex]
      let leftY = vertexY[beforeIndex]
      let rightX = vertexX[afterIndex]
      let rightY = vertexY[afterIndex]
      if crossProduct(leftX, leftY, sheepX, sheepY) >= 0 and
         crossProduct(sheepX, sheepY, rightX, rightY) >= 0 and
         crossProduct(rightX - leftX, rightY - leftY, sheepX - leftX, sheepY - leftY) >= 0:
        insideCount += 1
  appendOutput($(insideCount))
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
