const flushBlockBytes = 1 shl 17
const moduloBase = 1000000007'i64
const hashMultiplier = 2654435761'i64

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

let treeSize = nextInt(inputData, scanPos)
var fruitKinds = newSeq[int64](treeSize)
var childHeads = newSeq[int32](treeSize)
for nodeIndex in 0 .. treeSize - 1:
  childHeads[nodeIndex] = -1
var nextEdges = newSeq[int32](treeSize - 1)
var edgeTargets = newSeq[int32](treeSize - 1)
var edgeIndex = 0
for childIndex in 1 .. treeSize - 1:
  let parentIndex = nextInt(inputData, scanPos)
  edgeTargets[edgeIndex] = int32(childIndex)
  nextEdges[edgeIndex] = childHeads[parentIndex]
  childHeads[parentIndex] = int32(edgeIndex)
  edgeIndex += 1
for nodeIndex in 0 .. treeSize - 1:
  fruitKinds[nodeIndex] = int64(nextInt(inputData, scanPos))

var entryPositions = newSeq[int32](treeSize)
var eulerNodes = newSeq[int32](treeSize)
var firstNodeAtExit = newSeq[int32](treeSize)
var nextNodeAtExit = newSeq[int32](treeSize)
for nodeIndex in 0 .. treeSize - 1:
  firstNodeAtExit[nodeIndex] = -1
  nextNodeAtExit[nodeIndex] = -1
var stackNodes = newSeq[int32](treeSize)
var stackEdges = newSeq[int32](treeSize)
var stackTop = 0
stackNodes[0] = 0
stackEdges[0] = childHeads[0]
entryPositions[0] = 0
eulerNodes[0] = 0
var eulerCount = 1
while stackTop >= 0:
  let currentEdge = stackEdges[stackTop]
  if currentEdge != -1:
    stackEdges[stackTop] = nextEdges[currentEdge]
    let childNode = edgeTargets[currentEdge]
    entryPositions[childNode] = int32(eulerCount)
    eulerNodes[eulerCount] = childNode
    eulerCount += 1
    stackTop += 1
    stackNodes[stackTop] = childNode
    stackEdges[stackTop] = childHeads[childNode]
  else:
    let finishedNode = stackNodes[stackTop]
    nextNodeAtExit[finishedNode] = firstNodeAtExit[eulerCount - 1]
    firstNodeAtExit[eulerCount - 1] = finishedNode
    stackTop -= 1

var bitTree = newSeq[int32](treeSize + 1)

proc bitAdd(position: int, delta: int32) =
  var index = position + 1
  while index <= treeSize:
    bitTree[index] = bitTree[index] + delta
    index += index and -index

proc bitQuery(count: int): int32 =
  result = 0
  var index = count
  while index > 0:
    result = result + bitTree[index]
    index -= index and -index

var hashTableSize = 1
while hashTableSize < treeSize * 2:
  hashTableSize = hashTableSize shl 1
let hashMask = hashTableSize - 1
var hashKeys = newSeq[int64](hashTableSize)
var hashLastPositions = newSeq[int32](hashTableSize)
for slotIndex in 0 .. hashTableSize - 1:
  hashKeys[slotIndex] = -1'i64

var answerValue = 1'i64
for position in 0 .. treeSize - 1:
  let currentNode = eulerNodes[position]
  let fruitKind = fruitKinds[currentNode]
  var hashIndex = int((fruitKind * hashMultiplier) and int64(hashMask))
  while hashKeys[hashIndex] != -1'i64 and hashKeys[hashIndex] != fruitKind:
    hashIndex = (hashIndex + 1) and hashMask
  if hashKeys[hashIndex] == fruitKind:
    bitAdd(int(hashLastPositions[hashIndex]), -1)
  else:
    hashKeys[hashIndex] = fruitKind
  bitAdd(position, 1)
  hashLastPositions[hashIndex] = int32(position)
  var finishedNode = firstNodeAtExit[position]
  while finishedNode >= 0:
    let distinctKinds = bitQuery(position + 1) - bitQuery(int(entryPositions[finishedNode]))
    answerValue = answerValue * int64(distinctKinds) mod moduloBase
    finishedNode = nextNodeAtExit[finishedNode]

appendOutput($answerValue)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
