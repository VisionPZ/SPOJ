const firstDigitValue = 48
const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, position: var int): int =
  while position < data.len and (data[position] < '0' or data[position] > '9'):
    position += 1
  var value = 0
  while position < data.len and data[position] >= '0' and data[position] <= '9':
    value = value * 10 + ord(data[position]) - firstDigitValue
    position += 1
  return value

var leftChild: seq[int] = @[]
var rightChild: seq[int] = @[]
var subtreeSize: seq[int] = @[]
var nodePriority: seq[int] = @[]
var nodeChar: seq[char] = @[]
var randomState = 88172645463325252'i64

proc nextRandomValue(): int =
  randomState = randomState xor (randomState shl 13)
  randomState = randomState xor (randomState shr 7)
  randomState = randomState xor (randomState shl 17)
  return int(randomState and ((1'i64 shl 62) - 1))

var spineNodes = newSeq[int](1024)
var spineWalk = newSeq[int](1024)

proc growSpine(length: int) =
  if length >= spineNodes.len:
    spineNodes.setLen spineNodes.len * 2
    spineWalk.setLen spineWalk.len * 2

proc mergeTrees(leftTree, rightTree: int): int =
  if leftTree == 0:
    return rightTree
  if rightTree == 0:
    return leftTree
  var spineLen = 0
  var leftWalk = leftTree
  var rightWalk = rightTree
  while leftWalk != 0 and rightWalk != 0:
    growSpine(spineLen)
    if nodePriority[leftWalk] > nodePriority[rightWalk]:
      spineNodes[spineLen] = leftWalk
      spineWalk[spineLen] = 1
      spineLen += 1
      leftWalk = rightChild[leftWalk]
    else:
      spineNodes[spineLen] = rightWalk
      spineWalk[spineLen] = 0
      spineLen += 1
      rightWalk = leftChild[rightWalk]
  var mergedTree = leftWalk
  if rightWalk != 0:
    mergedTree = rightWalk
  var walkIndex = spineLen - 1
  while walkIndex >= 0:
    let spineNode = spineNodes[walkIndex]
    if spineWalk[walkIndex] == 1:
      rightChild[spineNode] = mergedTree
    else:
      leftChild[spineNode] = mergedTree
    subtreeSize[spineNode] = subtreeSize[leftChild[spineNode]] +
      subtreeSize[rightChild[spineNode]] + 1
    mergedTree = spineNode
    walkIndex -= 1
  return mergedTree

proc splitTree(nodeIndex: int, takeCount: int): tuple[leftTree, rightTree: int] =
  var leftHead = 0
  var leftTail = 0
  var rightHead = 0
  var rightTail = 0
  var leftLen = 0
  var rightLen = 0
  var walkNode = nodeIndex
  var remaining = takeCount
  while walkNode != 0:
    let leftSize = subtreeSize[leftChild[walkNode]]
    growSpine(leftLen + rightLen)
    if remaining <= leftSize:
      spineWalk[rightLen] = walkNode
      rightLen += 1
      if rightTail == 0:
        rightHead = walkNode
      else:
        leftChild[rightTail] = walkNode
      rightTail = walkNode
      walkNode = leftChild[walkNode]
    else:
      remaining -= leftSize + 1
      spineNodes[leftLen] = walkNode
      leftLen += 1
      if leftTail == 0:
        leftHead = walkNode
      else:
        rightChild[leftTail] = walkNode
      leftTail = walkNode
      walkNode = rightChild[walkNode]
  if leftTail != 0:
    rightChild[leftTail] = 0
  if rightTail != 0:
    leftChild[rightTail] = 0
  var walkIndex = leftLen - 1
  while walkIndex >= 0:
    let spineNode = spineNodes[walkIndex]
    subtreeSize[spineNode] = subtreeSize[leftChild[spineNode]] +
      subtreeSize[rightChild[spineNode]] + 1
    walkIndex -= 1
  walkIndex = rightLen - 1
  while walkIndex >= 0:
    let spineNode = spineWalk[walkIndex]
    subtreeSize[spineNode] = subtreeSize[leftChild[spineNode]] +
      subtreeSize[rightChild[spineNode]] + 1
    walkIndex -= 1
  return (leftHead, rightHead)

leftChild.add(0)
rightChild.add(0)
subtreeSize.add(0)
nodePriority.add(0)
nodeChar.add(' ')

let stringLength = nextInt(inputData, scanPos)
let queryCount = nextInt(inputData, scanPos)

while scanPos < inputData.len and inputData[scanPos] <= ' ':
  scanPos += 1
var tokenStart = scanPos
while scanPos < inputData.len and inputData[scanPos] > ' ':
  scanPos += 1

var rootTree = 0
var copyIndex = tokenStart
while copyIndex < scanPos:
  leftChild.add(0)
  rightChild.add(0)
  subtreeSize.add(1)
  nodePriority.add(nextRandomValue())
  nodeChar.add(inputData[copyIndex])
  rootTree = mergeTrees(rootTree, subtreeSize.len - 1)
  copyIndex += 1

for queryIndex in 0..<queryCount:
  let moveLeft = nextInt(inputData, scanPos)
  let moveRight = nextInt(inputData, scanPos)
  let firstParts = splitTree(rootTree, moveLeft - 1)
  let secondParts = splitTree(firstParts.rightTree, moveRight - moveLeft + 1)
  rootTree = mergeTrees(secondParts.leftTree,
    mergeTrees(firstParts.leftTree, secondParts.rightTree))

var outputBuffer = ""
var visitStack: seq[int] = @[]
var walkNode = rootTree
while walkNode != 0 or visitStack.len > 0:
  while walkNode != 0:
    visitStack.add(walkNode)
    walkNode = leftChild[walkNode]
  walkNode = visitStack[visitStack.len - 1]
  visitStack.setLen(visitStack.len - 1)
  outputBuffer.add(nodeChar[walkNode])
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0
  walkNode = rightChild[walkNode]
outputBuffer.add('\n')
stdout.write outputBuffer
outputBuffer.setLen 0
