const flushBlockBytes = 1 shl 17

var inputData = ""
var inputLine = ""
while readLine(stdin, inputLine):
  inputData.add inputLine
  inputData.add '\n'

var scanPos = 0

proc nextInt(data: string, pos: var int): int =
  while pos < data.len and (data[pos] < '0' or data[pos] > '9') and data[pos] != '-':
    pos += 1
  var sign = 1
  if pos < data.len and data[pos] == '-':
    sign = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return sign * value

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

type
  SegmentData = object
    totalSum: int64
    prefixBest: int64
    suffixBest: int64
    subarrayBest: int64

var sumTree: seq[int64]
var prefixTree: seq[int64]
var suffixTree: seq[int64]
var subarrayTree: seq[int64]
var values: seq[int64]

proc combineNodes(leftData, rightData: SegmentData): SegmentData =
  result.totalSum = leftData.totalSum + rightData.totalSum
  result.prefixBest = max(leftData.prefixBest, leftData.totalSum + rightData.prefixBest)
  result.suffixBest = max(rightData.suffixBest, rightData.totalSum + leftData.suffixBest)
  result.subarrayBest = max(max(leftData.subarrayBest, rightData.subarrayBest),
                            leftData.suffixBest + rightData.prefixBest)

proc readNode(nodeIndex: int): SegmentData =
  result.totalSum = sumTree[nodeIndex]
  result.prefixBest = prefixTree[nodeIndex]
  result.suffixBest = suffixTree[nodeIndex]
  result.subarrayBest = subarrayTree[nodeIndex]

proc storeNode(nodeIndex: int, nodeData: SegmentData) =
  sumTree[nodeIndex] = nodeData.totalSum
  prefixTree[nodeIndex] = nodeData.prefixBest
  suffixTree[nodeIndex] = nodeData.suffixBest
  subarrayTree[nodeIndex] = nodeData.subarrayBest

proc buildTree(nodeIndex, leftEdge, rightEdge: int) =
  if rightEdge - leftEdge == 1:
    let leafValue = values[leftEdge]
    storeNode(nodeIndex, SegmentData(totalSum: leafValue, prefixBest: leafValue,
                                     suffixBest: leafValue, subarrayBest: leafValue))
    return
  let middle = (leftEdge + rightEdge) div 2
  buildTree(nodeIndex * 2, leftEdge, middle)
  buildTree(nodeIndex * 2 + 1, middle, rightEdge)
  storeNode(nodeIndex, combineNodes(readNode(nodeIndex * 2), readNode(nodeIndex * 2 + 1)))

proc updateTree(nodeIndex, leftEdge, rightEdge, changedIndex: int, newValue: int64) =
  if rightEdge - leftEdge == 1:
    storeNode(nodeIndex, SegmentData(totalSum: newValue, prefixBest: newValue,
                                     suffixBest: newValue, subarrayBest: newValue))
    return
  let middle = (leftEdge + rightEdge) div 2
  if changedIndex < middle:
    updateTree(nodeIndex * 2, leftEdge, middle, changedIndex, newValue)
  else:
    updateTree(nodeIndex * 2 + 1, middle, rightEdge, changedIndex, newValue)
  storeNode(nodeIndex, combineNodes(readNode(nodeIndex * 2), readNode(nodeIndex * 2 + 1)))

proc queryTree(nodeIndex, leftEdge, rightEdge, queryLeft, queryRight: int): SegmentData =
  if queryLeft <= leftEdge and rightEdge <= queryRight:
    return readNode(nodeIndex)
  let middle = (leftEdge + rightEdge) div 2
  if queryRight <= middle:
    return queryTree(nodeIndex * 2, leftEdge, middle, queryLeft, queryRight)
  if queryLeft >= middle:
    return queryTree(nodeIndex * 2 + 1, middle, rightEdge, queryLeft, queryRight)
  let leftData = queryTree(nodeIndex * 2, leftEdge, middle, queryLeft, queryRight)
  let rightData = queryTree(nodeIndex * 2 + 1, middle, rightEdge, queryLeft, queryRight)
  return combineNodes(leftData, rightData)

let elementCount = nextInt(inputData, scanPos)
values = newSeq[int64](elementCount)
for elementIndex in 0 .. elementCount - 1:
  values[elementIndex] = int64(nextInt(inputData, scanPos))
let treeCapacity = 4 * elementCount + 5
sumTree = newSeq[int64](treeCapacity)
prefixTree = newSeq[int64](treeCapacity)
suffixTree = newSeq[int64](treeCapacity)
subarrayTree = newSeq[int64](treeCapacity)
buildTree(1, 0, elementCount)

let operationCount = nextInt(inputData, scanPos)
for operationIndex in 0 .. operationCount - 1:
  let operationType = nextInt(inputData, scanPos)
  let firstIndex = nextInt(inputData, scanPos) - 1
  let secondValue = nextInt(inputData, scanPos)
  if operationType == 0:
    values[firstIndex] = int64(secondValue)
    updateTree(1, 0, elementCount, firstIndex, int64(secondValue))
  else:
    let answer = queryTree(1, 0, elementCount, firstIndex, secondValue).subarrayBest
    appendOutput($answer)
    outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
