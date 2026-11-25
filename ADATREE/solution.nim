const flushBlockBytes = 1 shl 17
const maxHeight = 1000000

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

proc hasNextNumber(data: string, pos: int): bool =
  var cursor = pos
  while cursor < data.len and (data[cursor] < '0' or data[cursor] > '9'):
    cursor += 1
  return cursor < data.len

var outputBuffer = ""

proc appendOutput(text: string) =
  outputBuffer.add text
  if outputBuffer.len >= flushBlockBytes:
    stdout.write outputBuffer
    outputBuffer.setLen 0

proc updateTree(tree: var seq[int], treeSize: int, position: int, value: int) =
  var index = position + treeSize
  tree[index] = value
  index = index div 2
  while index >= 1:
    let leftValue = tree[index * 2]
    let rightValue = tree[index * 2 + 1]
    if leftValue > rightValue:
      tree[index] = leftValue
    else:
      tree[index] = rightValue
    index = index div 2

proc queryTree(tree: seq[int], treeSize: int, leftEnd: int, rightEnd: int): int =
  var leftIndex = leftEnd + treeSize
  var rightIndex = rightEnd + treeSize
  var bestValue = 0
  while leftIndex <= rightIndex:
    if (leftIndex and 1) == 1:
      if tree[leftIndex] > bestValue:
        bestValue = tree[leftIndex]
      leftIndex += 1
    if (rightIndex and 1) == 0:
      if tree[rightIndex] > bestValue:
        bestValue = tree[rightIndex]
      rightIndex -= 1
    leftIndex = leftIndex div 2
    rightIndex = rightIndex div 2
  return bestValue

while hasNextNumber(inputData, scanPos):
  let treeLength = nextInt(inputData, scanPos)
  let questionCount = nextInt(inputData, scanPos)
  var pointHead = newSeq[int](maxHeight + 1)
  var pointNext = newSeq[int](treeLength)
  for position in 0 .. treeLength - 1:
    let height = nextInt(inputData, scanPos)
    pointNext[position] = pointHead[height]
    pointHead[height] = position + 1
  var questionHead = newSeq[int](maxHeight + 1)
  var questionNext = newSeq[int](questionCount)
  var leftEnd = newSeq[int](questionCount)
  var rightEnd = newSeq[int](questionCount)
  for questionIndex in 0 .. questionCount - 1:
    let leftPosition = nextInt(inputData, scanPos)
    let rightPosition = nextInt(inputData, scanPos)
    let heightLimit = nextInt(inputData, scanPos)
    leftEnd[questionIndex] = leftPosition
    rightEnd[questionIndex] = rightPosition
    questionNext[questionIndex] = questionHead[heightLimit]
    questionHead[heightLimit] = questionIndex + 1
  var treeSize = 1
  while treeSize < treeLength:
    treeSize = treeSize * 2
  var tree = newSeq[int](treeSize * 2)
  var answer = newSeq[int](questionCount)
  for height in 0 .. maxHeight:
    var pointLink = pointHead[height]
    while pointLink != 0:
      let position = pointLink - 1
      updateTree(tree, treeSize, position, height)
      pointLink = pointNext[position]
    var questionLink = questionHead[height]
    while questionLink != 0:
      let questionIndex = questionLink - 1
      answer[questionIndex] = queryTree(tree, treeSize, leftEnd[questionIndex], rightEnd[questionIndex])
      questionLink = questionNext[questionIndex]
  for questionIndex in 0 .. questionCount - 1:
    appendOutput($answer[questionIndex])
    outputBuffer.add '\n'
stdout.write outputBuffer
outputBuffer.setLen 0
