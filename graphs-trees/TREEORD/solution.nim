const flushBlockBytes = 1 shl 17

type TraversalInterval = object
  preStart: int
  inStart: int
  postStart: int
  size: int

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

while hasNextNumber(inputData, scanPos):
  let nodeCount = nextInt(inputData, scanPos)
  var preorder = newSeq[int](nodeCount)
  var postorder = newSeq[int](nodeCount)
  var inorder = newSeq[int](nodeCount)
  var inorderPositions = newSeq[int](nodeCount + 1)
  for nodeIndex in 0 .. nodeCount - 1:
    preorder[nodeIndex] = nextInt(inputData, scanPos)
  for nodeIndex in 0 .. nodeCount - 1:
    postorder[nodeIndex] = nextInt(inputData, scanPos)
  for nodeIndex in 0 .. nodeCount - 1:
    let nodeValue = nextInt(inputData, scanPos)
    inorder[nodeIndex] = nodeValue
    inorderPositions[nodeValue] = nodeIndex
  var pendingIntervals = newSeq[TraversalInterval]()
  pendingIntervals.add(TraversalInterval(preStart: 0, inStart: 0,
      postStart: 0, size: nodeCount))
  var consistent = true
  while pendingIntervals.len > 0 and consistent:
    let current = pendingIntervals.pop()
    if current.size <= 0:
      continue
    let rootValue = preorder[current.preStart]
    if current.size == 1:
      if inorder[current.inStart] != rootValue or postorder[current.postStart] != rootValue:
        consistent = false
      continue
    if postorder[current.postStart + current.size - 1] != rootValue:
      consistent = false
      break
    let rootPosition = inorderPositions[rootValue]
    if rootPosition < current.inStart or rootPosition >= current.inStart + current.size:
      consistent = false
      break
    let leftSize = rootPosition - current.inStart
    let rightSize = current.size - 1 - leftSize
    pendingIntervals.add(TraversalInterval(
        preStart: current.preStart + 1 + leftSize,
        inStart: rootPosition + 1,
        postStart: current.postStart + leftSize,
        size: rightSize))
    pendingIntervals.add(TraversalInterval(
        preStart: current.preStart + 1,
        inStart: current.inStart,
        postStart: current.postStart,
        size: leftSize))
  if consistent:
    appendOutput("yes\n")
  else:
    appendOutput("no\n")
stdout.write outputBuffer
outputBuffer.setLen 0
