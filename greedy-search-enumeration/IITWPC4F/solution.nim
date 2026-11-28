const flushBlockBytes = 1 shl 17
const coordinateLimit = 100000
const treeCapacity = 4 * (coordinateLimit + 1) + 5

type FlipTree = object
  onCounts: array[treeCapacity, int]
  pendingFlips: array[treeCapacity, bool]

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

proc skipSpaces(data: string, pos: var int) =
  while pos < data.len and data[pos] <= ' ':
    pos += 1

proc applyFlip(tree: var FlipTree, nodeIndex: int, leftEdge: int, rightEdge: int) =
  tree.onCounts[nodeIndex] = (rightEdge - leftEdge + 1) - tree.onCounts[nodeIndex]
  tree.pendingFlips[nodeIndex] = not tree.pendingFlips[nodeIndex]

proc pushDown(tree: var FlipTree, nodeIndex: int, leftEdge: int, rightEdge: int) =
  if tree.pendingFlips[nodeIndex] and leftEdge < rightEdge:
    let middle = (leftEdge + rightEdge) div 2
    applyFlip(tree, nodeIndex * 2, leftEdge, middle)
    applyFlip(tree, nodeIndex * 2 + 1, middle + 1, rightEdge)
    tree.pendingFlips[nodeIndex] = false

proc flipRange(tree: var FlipTree, nodeIndex: int, leftEdge: int, rightEdge: int,
               queryLeft: int, queryRight: int) =
  if queryLeft <= leftEdge and rightEdge <= queryRight:
    applyFlip(tree, nodeIndex, leftEdge, rightEdge)
    return
  pushDown(tree, nodeIndex, leftEdge, rightEdge)
  let middle = (leftEdge + rightEdge) div 2
  if queryLeft <= middle:
    flipRange(tree, nodeIndex * 2, leftEdge, middle, queryLeft, queryRight)
  if queryRight > middle:
    flipRange(tree, nodeIndex * 2 + 1, middle + 1, rightEdge, queryLeft, queryRight)
  tree.onCounts[nodeIndex] = tree.onCounts[nodeIndex * 2] + tree.onCounts[nodeIndex * 2 + 1]

proc queryRange(tree: var FlipTree, nodeIndex: int, leftEdge: int, rightEdge: int,
                queryLeft: int, queryRight: int): int =
  if queryLeft <= leftEdge and rightEdge <= queryRight:
    return tree.onCounts[nodeIndex]
  pushDown(tree, nodeIndex, leftEdge, rightEdge)
  let middle = (leftEdge + rightEdge) div 2
  var total = 0
  if queryLeft <= middle:
    total += queryRange(tree, nodeIndex * 2, leftEdge, middle, queryLeft, queryRight)
  if queryRight > middle:
    total += queryRange(tree, nodeIndex * 2 + 1, middle + 1, rightEdge, queryLeft, queryRight)
  return total

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

var columnTree: FlipTree
var rowTree: FlipTree

let queryCount = nextInt(inputData, scanPos)
for queryIndex in 0 .. queryCount - 1:
  skipSpaces(inputData, scanPos)
  let queryKind = inputData[scanPos]
  if queryKind == 'x':
    let lowerBound = nextInt(inputData, scanPos)
    let upperBound = nextInt(inputData, scanPos)
    flipRange(columnTree, 1, 0, coordinateLimit, lowerBound, upperBound)
  elif queryKind == 'y':
    let lowerBound = nextInt(inputData, scanPos)
    let upperBound = nextInt(inputData, scanPos)
    flipRange(rowTree, 1, 0, coordinateLimit, lowerBound, upperBound)
  else:
    let xLower = nextInt(inputData, scanPos)
    let yLower = nextInt(inputData, scanPos)
    let xUpper = nextInt(inputData, scanPos)
    let yUpper = nextInt(inputData, scanPos)
    let columnsOn = queryRange(columnTree, 1, 0, coordinateLimit, xLower, xUpper)
    let rowsOn = queryRange(rowTree, 1, 0, coordinateLimit, yLower, yUpper)
    let columnsOff = (xUpper - xLower + 1) - columnsOn
    let rowsOff = (yUpper - yLower + 1) - rowsOn
    let lampsOn = int64(columnsOn) * int64(rowsOff) + int64(columnsOff) * int64(rowsOn)
    appendOutput($lampsOn)
    outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
