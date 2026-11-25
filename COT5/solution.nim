const flushBlockBytes = 1 shl 17
const maxTreapNodes = 200005

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

var nodeKeys = newSeq[int](maxTreapNodes)
var nodeWeights = newSeq[int](maxTreapNodes)
var leftChild = newSeq[int](maxTreapNodes)
var rightChild = newSeq[int](maxTreapNodes)
var parentNode = newSeq[int](maxTreapNodes)
var rootNode = 0
var nodeCount = 0

proc rotateLeft(lowerNode: int) =
  let upperNode = rightChild[lowerNode]
  rightChild[lowerNode] = leftChild[upperNode]
  if leftChild[upperNode] != 0:
    parentNode[leftChild[upperNode]] = lowerNode
  parentNode[upperNode] = parentNode[lowerNode]
  if parentNode[lowerNode] == 0:
    rootNode = upperNode
  elif leftChild[parentNode[lowerNode]] == lowerNode:
    leftChild[parentNode[lowerNode]] = upperNode
  else:
    rightChild[parentNode[lowerNode]] = upperNode
  leftChild[upperNode] = lowerNode
  parentNode[lowerNode] = upperNode

proc rotateRight(lowerNode: int) =
  let upperNode = leftChild[lowerNode]
  leftChild[lowerNode] = rightChild[upperNode]
  if rightChild[upperNode] != 0:
    parentNode[rightChild[upperNode]] = lowerNode
  parentNode[upperNode] = parentNode[lowerNode]
  if parentNode[lowerNode] == 0:
    rootNode = upperNode
  elif leftChild[parentNode[lowerNode]] == lowerNode:
    leftChild[parentNode[lowerNode]] = upperNode
  else:
    rightChild[parentNode[lowerNode]] = upperNode
  rightChild[upperNode] = lowerNode
  parentNode[lowerNode] = upperNode

proc findNode(targetKey: int): int =
  var walkNode = rootNode
  while walkNode != 0:
    if targetKey == nodeKeys[walkNode]:
      return walkNode
    elif targetKey < nodeKeys[walkNode]:
      walkNode = leftChild[walkNode]
    else:
      walkNode = rightChild[walkNode]
  return 0

proc insertNode(newKey: int, newWeight: int) =
  nodeCount += 1
  nodeKeys[nodeCount] = newKey
  nodeWeights[nodeCount] = newWeight
  leftChild[nodeCount] = 0
  rightChild[nodeCount] = 0
  parentNode[nodeCount] = 0
  if rootNode == 0:
    rootNode = nodeCount
    return
  var walkNode = rootNode
  while true:
    if newKey < nodeKeys[walkNode]:
      if leftChild[walkNode] == 0:
        leftChild[walkNode] = nodeCount
        parentNode[nodeCount] = walkNode
        break
      walkNode = leftChild[walkNode]
    else:
      if rightChild[walkNode] == 0:
        rightChild[walkNode] = nodeCount
        parentNode[nodeCount] = walkNode
        break
      walkNode = rightChild[walkNode]
  while parentNode[nodeCount] != 0 and nodeWeights[nodeCount] > nodeWeights[parentNode[nodeCount]]:
    let upperNode = parentNode[nodeCount]
    if leftChild[upperNode] == nodeCount:
      rotateRight(upperNode)
    else:
      rotateLeft(upperNode)

proc deleteKey(targetKey: int) =
  let targetNode = findNode(targetKey)
  while leftChild[targetNode] != 0 or rightChild[targetNode] != 0:
    if rightChild[targetNode] == 0 or
       (leftChild[targetNode] != 0 and nodeWeights[leftChild[targetNode]] > nodeWeights[rightChild[targetNode]]):
      rotateRight(targetNode)
    else:
      rotateLeft(targetNode)
  let upperNode = parentNode[targetNode]
  if upperNode == 0:
    rootNode = 0
  elif leftChild[upperNode] == targetNode:
    leftChild[upperNode] = 0
  else:
    rightChild[upperNode] = 0
  parentNode[targetNode] = -1

proc treeDistance(firstKey: int, secondKey: int): int =
  let firstNode = findNode(firstKey)
  let secondNode = findNode(secondKey)
  var firstDepth = 0
  var climbNode = firstNode
  while parentNode[climbNode] != 0:
    firstDepth += 1
    climbNode = parentNode[climbNode]
  var secondDepth = 0
  climbNode = secondNode
  while parentNode[climbNode] != 0:
    secondDepth += 1
    climbNode = parentNode[climbNode]
  var nodeOne = firstNode
  var nodeTwo = secondNode
  var depthOne = firstDepth
  var depthTwo = secondDepth
  while depthOne > depthTwo:
    nodeOne = parentNode[nodeOne]
    depthOne -= 1
  while depthTwo > depthOne:
    nodeTwo = parentNode[nodeTwo]
    depthTwo -= 1
  while nodeOne != nodeTwo:
    nodeOne = parentNode[nodeOne]
    nodeTwo = parentNode[nodeTwo]
  return firstDepth + secondDepth - 2 * depthOne

let operationCount = nextInt(inputData, scanPos)
for operationIndex in 0 .. operationCount - 1:
  let operationCode = nextInt(inputData, scanPos)
  if operationCode == 0:
    let insertedKey = nextInt(inputData, scanPos)
    let insertedWeight = nextInt(inputData, scanPos)
    insertNode(insertedKey, insertedWeight)
  elif operationCode == 1:
    let deletedKey = nextInt(inputData, scanPos)
    deleteKey(deletedKey)
  else:
    let firstKey = nextInt(inputData, scanPos)
    let secondKey = nextInt(inputData, scanPos)
    appendOutput($treeDistance(firstKey, secondKey))
    outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
