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
  var signValue = 1
  if pos < data.len and data[pos] == '-':
    signValue = -1
    pos += 1
  var value = 0
  while pos < data.len and data[pos] >= '0' and data[pos] <= '9':
    value = value * 10 + int(data[pos]) - 48
    pos += 1
  return signValue * value

type SegNode = tuple[sumValue: int64, prefixBest: int64, suffixBest: int64, subBest: int64]

proc joinNodes(leftNode, rightNode: SegNode): SegNode =
  result.sumValue = leftNode.sumValue + rightNode.sumValue
  if leftNode.prefixBest > leftNode.sumValue + rightNode.prefixBest:
    result.prefixBest = leftNode.prefixBest
  else:
    result.prefixBest = leftNode.sumValue + rightNode.prefixBest
  if rightNode.suffixBest > rightNode.sumValue + leftNode.suffixBest:
    result.suffixBest = rightNode.suffixBest
  else:
    result.suffixBest = rightNode.sumValue + leftNode.suffixBest
  result.subBest = leftNode.subBest
  if rightNode.subBest > result.subBest:
    result.subBest = rightNode.subBest
  if leftNode.suffixBest + rightNode.prefixBest > result.subBest:
    result.subBest = leftNode.suffixBest + rightNode.prefixBest

var inputValues = newSeq[int](0)
var treeNodes: seq[SegNode]
var treeSize = 0

proc buildTree(nodeIndex, leftBound, rightBound: int) =
  if leftBound == rightBound:
    let singleValue = int64(inputValues[leftBound])
    treeNodes[nodeIndex].sumValue = singleValue
    treeNodes[nodeIndex].prefixBest = singleValue
    treeNodes[nodeIndex].suffixBest = singleValue
    treeNodes[nodeIndex].subBest = singleValue
    return
  let middle = (leftBound + rightBound) div 2
  buildTree(nodeIndex * 2, leftBound, middle)
  buildTree(nodeIndex * 2 + 1, middle + 1, rightBound)
  treeNodes[nodeIndex] = joinNodes(treeNodes[nodeIndex * 2], treeNodes[nodeIndex * 2 + 1])

proc queryTree(nodeIndex, leftBound, rightBound, queryLeft, queryRight: int): SegNode =
  if queryLeft <= leftBound and rightBound <= queryRight:
    return treeNodes[nodeIndex]
  let middle = (leftBound + rightBound) div 2
  if queryRight <= middle:
    return queryTree(nodeIndex * 2, leftBound, middle, queryLeft, queryRight)
  if queryLeft > middle:
    return queryTree(nodeIndex * 2 + 1, middle + 1, rightBound, queryLeft, queryRight)
  let leftPart = queryTree(nodeIndex * 2, leftBound, middle, queryLeft, queryRight)
  let rightPart = queryTree(nodeIndex * 2 + 1, middle + 1, rightBound, queryLeft, queryRight)
  return joinNodes(leftPart, rightPart)

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  treeSize = nextInt(inputData, scanPos)
  inputValues = newSeq[int](treeSize + 1)
  for position in 1 .. treeSize:
    inputValues[position] = nextInt(inputData, scanPos)
  treeNodes = newSeq[SegNode](4 * treeSize + 5)
  buildTree(1, 1, treeSize)
  let queryCount = nextInt(inputData, scanPos)
  for queryIndex in 0 .. queryCount - 1:
    let firstLeft = nextInt(inputData, scanPos)
    let firstRight = nextInt(inputData, scanPos)
    let secondLeft = nextInt(inputData, scanPos)
    let secondRight = nextInt(inputData, scanPos)
    var answer: int64 = -(1 shl 60)
    if firstRight < secondLeft:
      let leftPart = queryTree(1, 1, treeSize, firstLeft, firstRight)
      let rightPart = queryTree(1, 1, treeSize, secondLeft, secondRight)
      answer = leftPart.suffixBest + rightPart.prefixBest
      if firstRight + 1 <= secondLeft - 1:
        answer = answer + queryTree(1, 1, treeSize, firstRight + 1, secondLeft - 1).sumValue
    else:
      if firstLeft <= secondLeft - 1:
        let leftPart = queryTree(1, 1, treeSize, firstLeft, secondLeft - 1)
        let rightPart = queryTree(1, 1, treeSize, secondLeft, secondRight)
        let candidate = leftPart.suffixBest + rightPart.prefixBest
        if candidate > answer:
          answer = candidate
      var overlapRight = firstRight
      if secondRight < overlapRight:
        overlapRight = secondRight
      let middlePart = queryTree(1, 1, treeSize, secondLeft, overlapRight)
      if middlePart.subBest > answer:
        answer = middlePart.subBest
      if firstRight + 1 <= secondRight:
        let leftPart = queryTree(1, 1, treeSize, firstLeft, firstRight)
        let rightPart = queryTree(1, 1, treeSize, firstRight + 1, secondRight)
        let candidate = leftPart.suffixBest + rightPart.prefixBest
        if candidate > answer:
          answer = candidate
    appendOutput($answer)
    outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
