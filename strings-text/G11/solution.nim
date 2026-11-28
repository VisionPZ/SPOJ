const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

let capacity = inputData.len + 1
var nodeValue = newSeq[char](capacity)
var leftChild = newSeq[int](capacity)
var rightChild = newSeq[int](capacity)
var nodeHeight = newSeq[int](capacity)
var nodeCount = 0

proc treeHeight(index: int): int =
  if index == 0: return 0
  return nodeHeight[index]

proc refreshHeight(index: int) =
  let leftHeight = treeHeight(leftChild[index])
  let rightHeight = treeHeight(rightChild[index])
  nodeHeight[index] = 1 + (if leftHeight > rightHeight: leftHeight else: rightHeight)

proc rotateRight(index: int): int =
  let pivot = leftChild[index]
  leftChild[index] = rightChild[pivot]
  rightChild[pivot] = index
  refreshHeight(index)
  refreshHeight(pivot)
  return pivot

proc rotateLeft(index: int): int =
  let pivot = rightChild[index]
  rightChild[index] = leftChild[pivot]
  leftChild[pivot] = index
  refreshHeight(index)
  refreshHeight(pivot)
  return pivot

proc insertValue(rootIndex: int, value: char): int =
  if rootIndex == 0:
    nodeCount += 1
    nodeValue[nodeCount] = value
    leftChild[nodeCount] = 0
    rightChild[nodeCount] = 0
    nodeHeight[nodeCount] = 1
    return nodeCount
  if value < nodeValue[rootIndex]:
    leftChild[rootIndex] = insertValue(leftChild[rootIndex], value)
  else:
    rightChild[rootIndex] = insertValue(rightChild[rootIndex], value)
  refreshHeight(rootIndex)
  let balance = treeHeight(leftChild[rootIndex]) - treeHeight(rightChild[rootIndex])
  if balance > 1:
    if value > nodeValue[leftChild[rootIndex]]:
      leftChild[rootIndex] = rotateLeft(leftChild[rootIndex])
    return rotateRight(rootIndex)
  if balance < -1:
    if value < nodeValue[rightChild[rootIndex]]:
      rightChild[rootIndex] = rotateRight(rightChild[rootIndex])
    return rotateLeft(rootIndex)
  return rootIndex

var rootIndex = 0
for index in 0..<inputData.len:
  let current = inputData[index]
  if current > ' ':
    rootIndex = insertValue(rootIndex, current)

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc appendLetter(value: char) =
  outputBuffer.add value
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc walkInorder(index: int) =
  if index == 0: return
  walkInorder(leftChild[index])
  appendLetter(nodeValue[index])
  walkInorder(rightChild[index])

proc walkPreorder(index: int) =
  if index == 0: return
  appendLetter(nodeValue[index])
  walkPreorder(leftChild[index])
  walkPreorder(rightChild[index])

proc walkPostorder(index: int) =
  if index == 0: return
  walkPostorder(leftChild[index])
  walkPostorder(rightChild[index])
  appendLetter(nodeValue[index])

walkInorder(rootIndex)
outputBuffer.add '\n'
walkPreorder(rootIndex)
outputBuffer.add '\n'
walkPostorder(rootIndex)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
