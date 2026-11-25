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

let totalNodes = nextInt(inputData, scanPos)
let queryCount = nextInt(inputData, scanPos)
var leftChild = newSeq[int](totalNodes + 1)
var rightChild = newSeq[int](totalNodes + 1)
var subtreeSize = newSeq[int](totalNodes + 1)
var nodePriority = newSeq[int](totalNodes + 1)
var nodeCharacter = newSeq[char](totalNodes + 1)

var randomState = 123456789
proc nextPriority(): int =
  randomState = randomState xor (randomState shl 13)
  randomState = randomState and 0x7fffffff
  randomState = randomState xor (randomState shr 17)
  randomState = randomState xor (randomState shl 5)
  randomState = randomState and 0x7fffffff
  return randomState

var nextNodeIndex = 0
proc createNode(character: char): int =
  nextNodeIndex += 1
  leftChild[nextNodeIndex] = 0
  rightChild[nextNodeIndex] = 0
  subtreeSize[nextNodeIndex] = 1
  nodePriority[nextNodeIndex] = nextPriority()
  nodeCharacter[nextNodeIndex] = character
  return nextNodeIndex

proc refreshSize(nodeIndex: int) =
  subtreeSize[nodeIndex] = subtreeSize[leftChild[nodeIndex]] + subtreeSize[rightChild[nodeIndex]] + 1

proc splitTree(rootIndex: int, leftCount: int, leftResult: var int, rightResult: var int) =
  if rootIndex == 0:
    leftResult = 0
    rightResult = 0
    return
  if subtreeSize[leftChild[rootIndex]] >= leftCount:
    splitTree(leftChild[rootIndex], leftCount, leftResult, leftChild[rootIndex])
    rightResult = rootIndex
  else:
    splitTree(rightChild[rootIndex], leftCount - subtreeSize[leftChild[rootIndex]] - 1, rightChild[rootIndex], rightResult)
    leftResult = rootIndex
  refreshSize(rootIndex)

proc mergeTrees(leftRoot: int, rightRoot: int): int =
  if leftRoot == 0:
    return rightRoot
  if rightRoot == 0:
    return leftRoot
  if nodePriority[leftRoot] > nodePriority[rightRoot]:
    rightChild[leftRoot] = mergeTrees(rightChild[leftRoot], rightRoot)
    refreshSize(leftRoot)
    return leftRoot
  else:
    leftChild[rightRoot] = mergeTrees(leftRoot, leftChild[rightRoot])
    refreshSize(rightRoot)
    return rightRoot

proc writeTree(nodeIndex: int) =
  if nodeIndex == 0:
    return
  writeTree(leftChild[nodeIndex])
  appendOutput($nodeCharacter[nodeIndex])
  writeTree(rightChild[nodeIndex])

while scanPos < inputData.len and inputData[scanPos] <= ' ':
  scanPos += 1

var rootIndex = 0
for characterIndex in 0 .. totalNodes - 1:
  rootIndex = mergeTrees(rootIndex, createNode(inputData[scanPos + characterIndex]))
scanPos += totalNodes

for queryIndex in 0 .. queryCount - 1:
  let leftIndex = nextInt(inputData, scanPos)
  let rightIndex = nextInt(inputData, scanPos)
  var prefixTree = 0
  var remainderTree = 0
  splitTree(rootIndex, leftIndex - 1, prefixTree, remainderTree)
  var movedTree = 0
  var suffixTree = 0
  splitTree(remainderTree, rightIndex - leftIndex + 1, movedTree, suffixTree)
  rootIndex = mergeTrees(mergeTrees(movedTree, prefixTree), suffixTree)

writeTree(rootIndex)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
