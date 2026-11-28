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

var nodeKey: array[100005, int]
var nodePriority: array[100005, int]
var nodeLeft: array[100005, int]
var nodeRight: array[100005, int]
var nodeSize: array[100005, int]
var nodeCount = 0
var prioritySeed: int64 = 123456789

proc nextPriority(): int =
  prioritySeed = (prioritySeed * 1103515245 + 12345) mod 2147483648
  return int(prioritySeed)

proc treeSize(nodeIndex: int): int =
  if nodeIndex == 0:
    return 0
  return nodeSize[nodeIndex]

proc pullNode(nodeIndex: int) =
  nodeSize[nodeIndex] = 1 + treeSize(nodeLeft[nodeIndex]) + treeSize(nodeRight[nodeIndex])

proc splitTree(root: int, key: int, leftPart: var int, rightPart: var int) =
  if root == 0:
    leftPart = 0
    rightPart = 0
    return
  if nodeKey[root] <= key:
    var innerRight = 0
    splitTree(nodeRight[root], key, innerRight, rightPart)
    nodeRight[root] = innerRight
    leftPart = root
    pullNode(root)
  else:
    var innerLeft = 0
    splitTree(nodeLeft[root], key, leftPart, innerLeft)
    nodeLeft[root] = innerLeft
    rightPart = root
    pullNode(root)

proc mergeTrees(leftPart: int, rightPart: int): int =
  if leftPart == 0:
    return rightPart
  if rightPart == 0:
    return leftPart
  if nodePriority[leftPart] < nodePriority[rightPart]:
    nodeRight[leftPart] = mergeTrees(nodeRight[leftPart], rightPart)
    pullNode(leftPart)
    return leftPart
  nodeLeft[rightPart] = mergeTrees(leftPart, nodeLeft[rightPart])
  pullNode(rightPart)
  return rightPart

proc insertValue(root: var int, key: int) =
  nodeCount += 1
  nodeKey[nodeCount] = key
  nodePriority[nodeCount] = nextPriority()
  nodeLeft[nodeCount] = 0
  nodeRight[nodeCount] = 0
  nodeSize[nodeCount] = 1
  var leftPart = 0
  var rightPart = 0
  splitTree(root, key, leftPart, rightPart)
  root = mergeTrees(mergeTrees(leftPart, nodeCount), rightPart)

proc countUpTo(root: int, key: int): int =
  var current = root
  var total = 0
  while current != 0:
    if nodeKey[current] <= key:
      total += 1 + treeSize(nodeLeft[current])
      current = nodeRight[current]
    else:
      current = nodeLeft[current]
  return total

let itemCount = nextInt(inputData, scanPos)
var sourceValues = newSeq[int](itemCount)
for itemIndex in 0 .. itemCount - 1:
  sourceValues[itemIndex] = nextInt(inputData, scanPos)
var finalValues = newSeq[int](itemCount)
var treeRoot = 0
for itemIndex in countdown(itemCount - 1, 0):
  let baseValue = sourceValues[itemIndex]
  var low = 0
  var high = itemCount
  while low < high:
    let middle = (low + high) div 2
    if middle >= countUpTo(treeRoot, baseValue + middle):
      high = middle
    else:
      low = middle + 1
  let finalValue = baseValue + low
  finalValues[itemIndex] = finalValue
  insertValue(treeRoot, finalValue)
for itemIndex in 0 .. itemCount - 1:
  if itemIndex > 0:
    outputBuffer.add ' '
  appendOutput($finalValues[itemIndex])
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
