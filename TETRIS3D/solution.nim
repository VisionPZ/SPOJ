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

let platformLength = nextInt(inputData, scanPos)
let platformDepth = nextInt(inputData, scanPos)
let blockCount = nextInt(inputData, scanPos)

var gridSize = 1
while gridSize < platformLength or gridSize < platformDepth:
  gridSize *= 2

let nodeCapacity = 4 * gridSize * gridSize
var treeMax = newSeq[int](nodeCapacity)
var treeLazy = newSeq[int](nodeCapacity)

proc applyHeight(nodeIndex: int, value: int) =
  treeMax[nodeIndex] = value
  treeLazy[nodeIndex] = value

proc pushHeight(nodeIndex: int) =
  let pending = treeLazy[nodeIndex]
  if pending != 0:
    let firstChild = 4 * nodeIndex - 2
    applyHeight(firstChild, pending)
    applyHeight(firstChild + 1, pending)
    applyHeight(firstChild + 2, pending)
    applyHeight(firstChild + 3, pending)
    treeLazy[nodeIndex] = 0

proc updateRectangle(nodeIndex: int, leftEdge: int, topEdge: int, rightEdge: int,
                     bottomEdge: int, queryLeft: int, queryTop: int,
                     queryRight: int, queryBottom: int, value: int) =
  if queryRight <= leftEdge or queryLeft >= rightEdge or
     queryBottom <= topEdge or queryTop >= bottomEdge:
    return
  if queryLeft <= leftEdge and rightEdge <= queryRight and
     queryTop <= topEdge and bottomEdge <= queryBottom:
    applyHeight(nodeIndex, value)
    return
  pushHeight(nodeIndex)
  let middleX = (leftEdge + rightEdge) div 2
  let middleY = (topEdge + bottomEdge) div 2
  updateRectangle(4 * nodeIndex - 2, leftEdge, topEdge, middleX, middleY,
                  queryLeft, queryTop, queryRight, queryBottom, value)
  updateRectangle(4 * nodeIndex - 1, middleX, topEdge, rightEdge, middleY,
                  queryLeft, queryTop, queryRight, queryBottom, value)
  updateRectangle(4 * nodeIndex, leftEdge, middleY, middleX, bottomEdge,
                  queryLeft, queryTop, queryRight, queryBottom, value)
  updateRectangle(4 * nodeIndex + 1, middleX, middleY, rightEdge, bottomEdge,
                  queryLeft, queryTop, queryRight, queryBottom, value)
  var highest = treeMax[4 * nodeIndex - 2]
  if treeMax[4 * nodeIndex - 1] > highest:
    highest = treeMax[4 * nodeIndex - 1]
  if treeMax[4 * nodeIndex] > highest:
    highest = treeMax[4 * nodeIndex]
  if treeMax[4 * nodeIndex + 1] > highest:
    highest = treeMax[4 * nodeIndex + 1]
  treeMax[nodeIndex] = highest

proc queryRectangle(nodeIndex: int, leftEdge: int, topEdge: int, rightEdge: int,
                    bottomEdge: int, queryLeft: int, queryTop: int,
                    queryRight: int, queryBottom: int): int =
  if queryRight <= leftEdge or queryLeft >= rightEdge or
     queryBottom <= topEdge or queryTop >= bottomEdge:
    return 0
  if queryLeft <= leftEdge and rightEdge <= queryRight and
     queryTop <= topEdge and bottomEdge <= queryBottom:
    return treeMax[nodeIndex]
  pushHeight(nodeIndex)
  let middleX = (leftEdge + rightEdge) div 2
  let middleY = (topEdge + bottomEdge) div 2
  var highest = queryRectangle(4 * nodeIndex - 2, leftEdge, topEdge, middleX, middleY,
                               queryLeft, queryTop, queryRight, queryBottom)
  let second = queryRectangle(4 * nodeIndex - 1, middleX, topEdge, rightEdge, middleY,
                              queryLeft, queryTop, queryRight, queryBottom)
  if second > highest:
    highest = second
  let third = queryRectangle(4 * nodeIndex, leftEdge, middleY, middleX, bottomEdge,
                             queryLeft, queryTop, queryRight, queryBottom)
  if third > highest:
    highest = third
  let fourth = queryRectangle(4 * nodeIndex + 1, middleX, middleY, rightEdge, bottomEdge,
                              queryLeft, queryTop, queryRight, queryBottom)
  if fourth > highest:
    highest = fourth
  return highest

for blockIndex in 0 .. blockCount - 1:
  let blockLength = nextInt(inputData, scanPos)
  let blockDepth = nextInt(inputData, scanPos)
  let blockHeight = nextInt(inputData, scanPos)
  let startX = nextInt(inputData, scanPos)
  let startY = nextInt(inputData, scanPos)
  let supportHeight = queryRectangle(1, 0, 0, gridSize, gridSize,
                                     startX, startY, startX + blockLength, startY + blockDepth)
  updateRectangle(1, 0, 0, gridSize, gridSize, startX, startY,
                  startX + blockLength, startY + blockDepth, supportHeight + blockHeight)

appendOutput($treeMax[1])
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
