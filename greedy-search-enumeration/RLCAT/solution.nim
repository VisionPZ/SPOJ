const flushBlockBytes = 1 shl 17
const firstDigitValue = 48
const hugeValue = int64(1 shl 60)

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

var logarithm = newSeq[int]()
var sparseMin = newSeq[seq[int64]]()
var sparseMax = newSeq[seq[int64]]()
var treeSize = 1
var segmentTree = newSeq[int64]()

proc rangeMinimum(leftIndex: int, rightIndex: int): int64 =
  let spanLength = rightIndex - leftIndex + 1
  let level = logarithm[spanLength]
  let span = 1 shl level
  let tailIndex = rightIndex - span + 1
  if sparseMin[level][leftIndex] < sparseMin[level][tailIndex]:
    return sparseMin[level][leftIndex]
  return sparseMin[level][tailIndex]

proc rangeMaximum(leftIndex: int, rightIndex: int): int64 =
  let spanLength = rightIndex - leftIndex + 1
  let level = logarithm[spanLength]
  let span = 1 shl level
  let tailIndex = rightIndex - span + 1
  if sparseMax[level][leftIndex] > sparseMax[level][tailIndex]:
    return sparseMax[level][leftIndex]
  return sparseMax[level][tailIndex]

proc queryMinimum(leftIndex: int, rightIndex: int): int64 =
  var minimumValue = hugeValue
  var leftNode = leftIndex + treeSize
  var rightNode = rightIndex + treeSize
  while leftNode <= rightNode:
    if (leftNode and 1) == 1:
      if segmentTree[leftNode] < minimumValue:
        minimumValue = segmentTree[leftNode]
      leftNode += 1
    if (rightNode and 1) == 0:
      if segmentTree[rightNode] < minimumValue:
        minimumValue = segmentTree[rightNode]
      rightNode -= 1
    leftNode = leftNode div 2
    rightNode = rightNode div 2
  return minimumValue

proc updateValue(position: int, value: int64) =
  var nodeIndex = position + treeSize
  segmentTree[nodeIndex] = value
  while nodeIndex > 1:
    nodeIndex = nodeIndex div 2
    let leftChild = segmentTree[nodeIndex shl 1]
    let rightChild = segmentTree[(nodeIndex shl 1) + 1]
    if leftChild < rightChild:
      segmentTree[nodeIndex] = leftChild
    else:
      segmentTree[nodeIndex] = rightChild

let caseCount = nextInt(inputData, scanPos)
for caseIndex in 0 .. caseCount - 1:
  let studentCount = nextInt(inputData, scanPos)
  let threshold = int64(nextInt(inputData, scanPos))
  var compatibility = newSeq[int64](studentCount)
  for studentIndex in 0 .. studentCount - 1:
    compatibility[studentIndex] = int64(nextInt(inputData, scanPos))
  if studentCount == 1:
    appendOutput("1")
    outputBuffer.add '\n'
    continue
  logarithm = newSeq[int](studentCount + 1)
  for spanLength in 2 .. studentCount:
    logarithm[spanLength] = logarithm[spanLength div 2] + 1
  let levelCount = logarithm[studentCount] + 1
  sparseMin = newSeq[seq[int64]](levelCount)
  sparseMax = newSeq[seq[int64]](levelCount)
  sparseMin[0] = compatibility
  sparseMax[0] = compatibility
  var level = 1
  while (1 shl level) <= studentCount:
    let span = 1 shl level
    let half = 1 shl (level - 1)
    let entryCount = studentCount - span + 1
    sparseMin[level] = newSeq[int64](entryCount)
    sparseMax[level] = newSeq[int64](entryCount)
    for startIndex in 0 .. entryCount - 1:
      let leftMin = sparseMin[level - 1][startIndex]
      let rightMin = sparseMin[level - 1][startIndex + half]
      let leftMax = sparseMax[level - 1][startIndex]
      let rightMax = sparseMax[level - 1][startIndex + half]
      if leftMin < rightMin:
        sparseMin[level][startIndex] = leftMin
      else:
        sparseMin[level][startIndex] = rightMin
      if leftMax > rightMax:
        sparseMax[level][startIndex] = leftMax
      else:
        sparseMax[level][startIndex] = rightMax
    level += 1
  var lastReachable = newSeq[int](studentCount)
  for startIndex in 0 .. studentCount - 1:
    let lowerBound = compatibility[startIndex] - threshold
    let upperBound = compatibility[startIndex] + threshold
    var lowIndex = startIndex
    var highIndex = studentCount - 1
    while lowIndex < highIndex:
      let middleIndex = (lowIndex + highIndex + 1) div 2
      if rangeMaximum(startIndex, middleIndex) <= upperBound and
         rangeMinimum(startIndex, middleIndex) >= lowerBound:
        lowIndex = middleIndex
      else:
        highIndex = middleIndex - 1
    lastReachable[startIndex] = lowIndex
  treeSize = 1
  while treeSize < studentCount + 1:
    treeSize = treeSize shl 1
  segmentTree = newSeq[int64](treeSize shl 1)
  for treeIndex in 0 .. segmentTree.len - 1:
    segmentTree[treeIndex] = hugeValue
  segmentTree[treeSize + studentCount] = 0
  var nodeIndex = treeSize - 1
  while nodeIndex >= 1:
    let leftChild = segmentTree[nodeIndex shl 1]
    let rightChild = segmentTree[(nodeIndex shl 1) + 1]
    if leftChild < rightChild:
      segmentTree[nodeIndex] = leftChild
    else:
      segmentTree[nodeIndex] = rightChild
    nodeIndex -= 1
  var answerPens = 0
  var studentIndex = studentCount - 1
  while studentIndex >= 0:
    let nextStart = queryMinimum(studentIndex + 1, lastReachable[studentIndex] + 1)
    answerPens = 1 + int(nextStart)
    updateValue(studentIndex, int64(answerPens))
    studentIndex -= 1
  appendOutput($answerPens)
  outputBuffer.add '\n'

stdout.write outputBuffer
outputBuffer.setLen 0
