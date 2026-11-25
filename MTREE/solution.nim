const flushBlockBytes = 1 shl 17
const firstDigitValue = 48
const modulusValue = 1000000007

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
    value = value * 10 + int(data[pos]) - firstDigitValue
    pos += 1
  return value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let nodeCount = nextInt(inputData, scanPos)
let edgeCount = nodeCount - 1
var headNode = newSeq[int](nodeCount + 1)
var edgeTarget = newSeq[int](2 * edgeCount)
var edgeWeight = newSeq[int](2 * edgeCount)
var edgeLink = newSeq[int](2 * edgeCount)
for nodeIndex in 1 .. nodeCount:
  headNode[nodeIndex] = -1
var edgeSlot = 0
for edgeNumber in 0 .. edgeCount - 1:
  let firstNode = nextInt(inputData, scanPos)
  let secondNode = nextInt(inputData, scanPos)
  let weightValue = nextInt(inputData, scanPos)
  edgeTarget[edgeSlot] = secondNode
  edgeWeight[edgeSlot] = weightValue
  edgeLink[edgeSlot] = headNode[firstNode]
  headNode[firstNode] = edgeSlot
  edgeSlot += 1
  edgeTarget[edgeSlot] = firstNode
  edgeWeight[edgeSlot] = weightValue
  edgeLink[edgeSlot] = headNode[secondNode]
  headNode[secondNode] = edgeSlot
  edgeSlot += 1

var parentNode = newSeq[int](nodeCount + 1)
var traversalOrder = newSeq[int](nodeCount)
var nodeStack = newSeq[int](nodeCount)
var stackTop = 0
nodeStack[stackTop] = 1
stackTop += 1
var orderCount = 0
while stackTop > 0:
  stackTop -= 1
  let currentNode = nodeStack[stackTop]
  traversalOrder[orderCount] = currentNode
  orderCount += 1
  var linkIndex = headNode[currentNode]
  while linkIndex != -1:
    let neighborNode = edgeTarget[linkIndex]
    if neighborNode != parentNode[currentNode]:
      parentNode[neighborNode] = currentNode
      nodeStack[stackTop] = neighborNode
      stackTop += 1
    linkIndex = edgeLink[linkIndex]

var downSum = newSeq[int64](nodeCount + 1)
var totalWeight: int64 = 0
for reverseIndex in 0 .. orderCount - 1:
  let currentNode = traversalOrder[orderCount - 1 - reverseIndex]
  var childTotal: int64 = 0
  var siblingTotal: int64 = 0
  var linkIndex = headNode[currentNode]
  while linkIndex != -1:
    let neighborNode = edgeTarget[linkIndex]
    if parentNode[neighborNode] == currentNode:
      let childTerm = (int64(edgeWeight[linkIndex]) * downSum[neighborNode]) mod modulusValue
      totalWeight = (totalWeight + childTerm * siblingTotal) mod modulusValue
      siblingTotal = (siblingTotal + childTerm) mod modulusValue
      childTotal = (childTotal + childTerm) mod modulusValue
    linkIndex = edgeLink[linkIndex]
  downSum[currentNode] = childTotal + 1
  if downSum[currentNode] >= modulusValue:
    downSum[currentNode] = downSum[currentNode] - modulusValue
  totalWeight = (totalWeight + siblingTotal) mod modulusValue

appendOutput($totalWeight)
outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
