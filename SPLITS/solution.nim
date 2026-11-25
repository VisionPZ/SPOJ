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

proc isSpaceCharacter(character: char): bool =
  return character == ' ' or character == '\n' or character == '\r' or character == '\t'

proc nextToken(data: string, pos: var int): string =
  while pos < data.len and isSpaceCharacter(data[pos]):
    pos += 1
  var token = ""
  while pos < data.len and not isSpaceCharacter(data[pos]):
    token.add data[pos]
    pos += 1
  return token

var nodeStart: seq[int]
var nodeFinish: seq[int]
var nodeLabel: seq[int]
var nodePriority: seq[int]
var nodeLeft: seq[int]
var nodeRight: seq[int]
var nodeCount = 0
var priorityState: uint64 = 881726454633252552'u64

proc nextPriority(): int =
  priorityState = priorityState xor (priorityState shl 13)
  priorityState = priorityState xor (priorityState shr 7)
  priorityState = priorityState xor (priorityState shl 17)
  return int(priorityState and 0x7fffffff'u64)

proc createNode(startPosition: int, finishPosition: int, labelIndex: int): int =
  nodeCount += 1
  nodeStart[nodeCount] = startPosition
  nodeFinish[nodeCount] = finishPosition
  nodeLabel[nodeCount] = labelIndex
  nodePriority[nodeCount] = nextPriority()
  nodeLeft[nodeCount] = 0
  nodeRight[nodeCount] = 0
  return nodeCount

proc splitByKey(root: int, keyValue: int, leftRoot: var int, rightRoot: var int) =
  if root == 0:
    leftRoot = 0
    rightRoot = 0
    return
  if nodeStart[root] < keyValue:
    var innerRight = 0
    splitByKey(nodeRight[root], keyValue, innerRight, rightRoot)
    nodeRight[root] = innerRight
    leftRoot = root
  else:
    var innerLeft = 0
    splitByKey(nodeLeft[root], keyValue, leftRoot, innerLeft)
    nodeLeft[root] = innerLeft
    rightRoot = root

proc mergeTrees(leftTree: int, rightTree: int): int =
  if leftTree == 0:
    return rightTree
  if rightTree == 0:
    return leftTree
  if nodePriority[leftTree] > nodePriority[rightTree]:
    nodeRight[leftTree] = mergeTrees(nodeRight[leftTree], rightTree)
    return leftTree
  nodeLeft[rightTree] = mergeTrees(leftTree, nodeLeft[rightTree])
  return rightTree

proc findNode(root: int, position: int): int =
  var currentNode = root
  while currentNode != 0:
    if position < nodeStart[currentNode]:
      currentNode = nodeLeft[currentNode]
    elif position > nodeFinish[currentNode]:
      currentNode = nodeRight[currentNode]
    else:
      return currentNode
  return 0

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let arraySize = nextInt(inputData, scanPos)
let operationCount = nextInt(inputData, scanPos)
var labelStrings = newSeq[string](1)
labelStrings[0] = nextToken(inputData, scanPos)

let nodeCapacity = 3 * operationCount + 5
nodeStart = newSeq[int](nodeCapacity)
nodeFinish = newSeq[int](nodeCapacity)
nodeLabel = newSeq[int](nodeCapacity)
nodePriority = newSeq[int](nodeCapacity)
nodeLeft = newSeq[int](nodeCapacity)
nodeRight = newSeq[int](nodeCapacity)

var treapRoot = createNode(1, arraySize, 0)

for operationIndex in 0 .. operationCount - 1:
  let commandText = nextToken(inputData, scanPos)
  if commandText == "SPLIT":
    let splitPosition = nextInt(inputData, scanPos)
    let leftString = nextToken(inputData, scanPos)
    let rightString = nextToken(inputData, scanPos)
    labelStrings.add leftString
    let leftLabel = labelStrings.len - 1
    labelStrings.add rightString
    let rightLabel = labelStrings.len - 1

    let oldNode = findNode(treapRoot, splitPosition)
    let oldStart = nodeStart[oldNode]
    let oldFinish = nodeFinish[oldNode]
    let oldLabel = nodeLabel[oldNode]

    var beforeTree = 0
    var oldAndAfter = 0
    splitByKey(treapRoot, oldStart, beforeTree, oldAndAfter)
    var oldTree = 0
    var afterTree = 0
    splitByKey(oldAndAfter, oldFinish + 1, oldTree, afterTree)

    var rebuilt = beforeTree
    if oldStart <= splitPosition - 1:
      let leftNode = createNode(oldStart, splitPosition - 1, leftLabel)
      rebuilt = mergeTrees(rebuilt, leftNode)
    let centerNode = createNode(splitPosition, splitPosition, oldLabel)
    rebuilt = mergeTrees(rebuilt, centerNode)
    if splitPosition + 1 <= oldFinish:
      let rightNode = createNode(splitPosition + 1, oldFinish, rightLabel)
      rebuilt = mergeTrees(rebuilt, rightNode)
    rebuilt = mergeTrees(rebuilt, afterTree)
    treapRoot = rebuilt
  else:
    let queryPosition = nextInt(inputData, scanPos)
    let foundNode = findNode(treapRoot, queryPosition)
    appendOutput(labelStrings[nodeLabel[foundNode]])
    outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
