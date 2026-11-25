const flushBlockBytes = 1 shl 17
const vertexOffset = 1

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

var nodeCount = 0
var childLeft = newSeq[int](0)
var childRight = newSeq[int](0)
var parentNode = newSeq[int](0)
var reversedFlag = newSeq[bool](0)
var nodeValue = newSeq[int64](0)
var nodeMaxValue = newSeq[int64](0)
var nodeMaxIndex = newSeq[int](0)
var edgeLeftEndpoint = newSeq[int](0)
var edgeRightEndpoint = newSeq[int](0)
var splayStack = newSeq[int](0)
var splayTop = 0

proc pushUp(node: int) =
  var bestValue = nodeValue[node]
  var bestIndex = node
  let leftChild = childLeft[node]
  if leftChild != 0 and nodeMaxValue[leftChild] > bestValue:
    bestValue = nodeMaxValue[leftChild]
    bestIndex = nodeMaxIndex[leftChild]
  let rightChild = childRight[node]
  if rightChild != 0 and nodeMaxValue[rightChild] > bestValue:
    bestValue = nodeMaxValue[rightChild]
    bestIndex = nodeMaxIndex[rightChild]
  nodeMaxValue[node] = bestValue
  nodeMaxIndex[node] = bestIndex

proc reverseNode(node: int) =
  if node == 0:
    return
  let oldLeft = childLeft[node]
  childLeft[node] = childRight[node]
  childRight[node] = oldLeft
  reversedFlag[node] = not reversedFlag[node]

proc pushDown(node: int) =
  if reversedFlag[node]:
    reverseNode(childLeft[node])
    reverseNode(childRight[node])
    reversedFlag[node] = false

proc isSplayRoot(node: int): bool =
  let parent = parentNode[node]
  return parent == 0 or (childLeft[parent] != node and childRight[parent] != node)

proc rotateNode(node: int) =
  let parent = parentNode[node]
  let grandparent = parentNode[parent]
  if childLeft[parent] == node:
    let middle = childRight[node]
    childLeft[parent] = middle
    if middle != 0:
      parentNode[middle] = parent
    childRight[node] = parent
  else:
    let middle = childLeft[node]
    childRight[parent] = middle
    if middle != 0:
      parentNode[middle] = parent
    childLeft[node] = parent
  parentNode[parent] = node
  parentNode[node] = grandparent
  if grandparent != 0:
    if childLeft[grandparent] == parent:
      childLeft[grandparent] = node
    elif childRight[grandparent] == parent:
      childRight[grandparent] = node
  pushUp(parent)
  pushUp(node)

proc splayNode(node: int) =
  splayTop = 0
  var current = node
  splayStack[splayTop] = current
  splayTop += 1
  while not isSplayRoot(current):
    current = parentNode[current]
    splayStack[splayTop] = current
    splayTop += 1
  while splayTop > 0:
    splayTop -= 1
    pushDown(splayStack[splayTop])
  while not isSplayRoot(node):
    current = parentNode[node]
    if not isSplayRoot(current):
      if (childLeft[current] == node) == (childLeft[parentNode[current]] == current):
        rotateNode(current)
      else:
        rotateNode(node)
    rotateNode(node)

proc accessNode(node: int) =
  var lastNode = 0
  var current = node
  while current != 0:
    splayNode(current)
    childRight[current] = lastNode
    pushUp(current)
    lastNode = current
    current = parentNode[current]

proc makeRoot(node: int) =
  accessNode(node)
  splayNode(node)
  reverseNode(node)

proc findRoot(node: int): int =
  accessNode(node)
  splayNode(node)
  var current = node
  pushDown(current)
  while childLeft[current] != 0:
    current = childLeft[current]
    pushDown(current)
  splayNode(current)
  return current

proc splitPath(firstNode: int, secondNode: int) =
  makeRoot(firstNode)
  accessNode(secondNode)
  splayNode(secondNode)

proc linkNodes(firstNode: int, secondNode: int) =
  makeRoot(firstNode)
  if findRoot(secondNode) != firstNode:
    parentNode[firstNode] = secondNode

proc cutNodes(firstNode: int, secondNode: int) =
  makeRoot(firstNode)
  accessNode(secondNode)
  splayNode(secondNode)
  if childLeft[secondNode] == firstNode and childRight[firstNode] == 0:
    childLeft[secondNode] = 0
    parentNode[firstNode] = 0
    pushUp(secondNode)

let vertexCount = nextInt(inputData, scanPos)
let roadCount = nextInt(inputData, scanPos)
nodeCount = vertexCount + roadCount + 2
childLeft = newSeq[int](nodeCount)
childRight = newSeq[int](nodeCount)
parentNode = newSeq[int](nodeCount)
reversedFlag = newSeq[bool](nodeCount)
nodeValue = newSeq[int64](nodeCount)
nodeMaxValue = newSeq[int64](nodeCount)
nodeMaxIndex = newSeq[int](nodeCount)
edgeLeftEndpoint = newSeq[int](nodeCount)
edgeRightEndpoint = newSeq[int](nodeCount)
splayStack = newSeq[int](nodeCount)
for node in 0 .. nodeCount - 1:
  nodeValue[node] = -1
  nodeMaxValue[node] = -1
  nodeMaxIndex[node] = node

var lastAnswer: int64 = 0
var totalCost: int64 = 0
for roadIndex in 0 .. roadCount - 1:
  let encodedA = nextInt(inputData, scanPos)
  let encodedB = nextInt(inputData, scanPos)
  let encodedC = nextInt(inputData, scanPos)
  let realA = int64(encodedA) xor lastAnswer
  let realB = int64(encodedB) xor lastAnswer
  let realC = int64(encodedC) xor lastAnswer
  let edgeNode = vertexCount + roadIndex + vertexOffset
  let nodeA = int(realA) + vertexOffset
  let nodeB = int(realB) + vertexOffset
  childLeft[edgeNode] = 0
  childRight[edgeNode] = 0
  parentNode[edgeNode] = 0
  reversedFlag[edgeNode] = false
  nodeValue[edgeNode] = realC
  nodeMaxValue[edgeNode] = realC
  nodeMaxIndex[edgeNode] = edgeNode
  edgeLeftEndpoint[edgeNode] = nodeA
  edgeRightEndpoint[edgeNode] = nodeB
  if findRoot(nodeA) != findRoot(nodeB):
    linkNodes(edgeNode, nodeA)
    linkNodes(edgeNode, nodeB)
    totalCost = totalCost + realC
  else:
    splitPath(nodeA, nodeB)
    let heavyNode = nodeMaxIndex[nodeB]
    let removedCost = nodeMaxValue[nodeB]
    if removedCost > realC:
      cutNodes(heavyNode, edgeLeftEndpoint[heavyNode])
      cutNodes(heavyNode, edgeRightEndpoint[heavyNode])
      linkNodes(edgeNode, nodeA)
      linkNodes(edgeNode, nodeB)
      totalCost = totalCost + realC - removedCost
  lastAnswer = totalCost
  appendOutput($totalCost)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
